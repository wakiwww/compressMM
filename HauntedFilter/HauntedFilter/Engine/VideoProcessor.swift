import Foundation
import AVFoundation
import CoreImage
import UIKit

/// 核心视频处理器：AVAssetReader → CIFilter 链 → AVAssetWriter
@MainActor
class VideoProcessor: ObservableObject {
    @Published var progress: Double = 0
    @Published var isProcessing = false
    @Published var isCancelled = false
    @Published var errorMessage: String?

    /// 仅由后台串行队列（serialQueue）读写，nonisolated(unsafe) 绕开 @MainActor 隔离检查。
    nonisolated(unsafe) private var ciContext: CIContext?
    nonisolated(unsafe) private var scanlineTexture: CIImage?

    /// 线程安全的取消标志。
    /// @Published var isCancelled 只在主线程更新（供 UI 绑定）；
    /// 后台队列里一律通过 cancelFlag.value 读写，避免 Data Race。
    let cancelFlag = AtomicBool(false)

    init() {
        // 延迟初始化，避免在初始化时可能导致的崩溃
        print("✅ VideoProcessor初始化完成（CIContext延迟初始化）")
    }

    /// 处理视频
    func processVideo(sourceURL: URL, preset: VideoPreset, intensity: Float) async -> Result<URL, Error> {
        await withCheckedContinuation { continuation in
            processVideo(sourceURL: sourceURL, preset: preset, intensity: intensity) { result in
                continuation.resume(returning: result)
            }
        }
    }

    func processVideo(
        sourceURL: URL,
        preset: VideoPreset,
        intensity: Float,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard !isProcessing else {
            completion(.failure(ProcessingError.alreadyProcessing))
            return
        }

        isProcessing = true
        isCancelled = false
        cancelFlag.value = false   // 同步重置线程安全标志
        progress = 0
        errorMessage = nil

        let parameters = preset.parameters(for: intensity)
        let asset = AVURLAsset(url: sourceURL)

        // 使用 Task.detached 避免继承 @MainActor 上下文导致死锁
        Task.detached { [weak self] in
            guard let self = self else {
                await MainActor.run {
                    completion(.failure(ProcessingError.unknown))
                }
                return
            }

            do {
                let outputURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mp4")

                try await self.processAsset(asset, parameters: parameters, preset: preset, outputURL: outputURL)

                await MainActor.run {
                    self.isProcessing = false
                    self.progress = 1.0
                    completion(.success(outputURL))
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    /// 取消处理（可从任意线程调用）
    nonisolated func cancel() {
        cancelFlag.value = true
        Task { @MainActor [weak self] in
            self?.isCancelled = true
        }
    }

    // MARK: - 核心处理逻辑（以下方法由后台队列调用，标记 nonisolated）

    nonisolated private func processAsset(
        _ asset: AVAsset,
        parameters: ProcessingParameters,
        preset: VideoPreset,
        outputURL: URL
    ) async throws {
        // 加载视频轨道
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw ProcessingError.noVideoTrack
        }

        // 异步加载视频属性（含方向矫正）
        let naturalSize = try await videoTrack.load(.naturalSize)
        let frameRate = try await videoTrack.load(.nominalFrameRate)
        let preferredTransform = try await videoTrack.load(.preferredTransform)

        // 始终使用自然像素尺寸编码；preferredTransform 负责方向
        let finalSourceSize = naturalSize != .zero ? naturalSize : CGSize(width: 1920, height: 1080)
        let finalSourceFrameRate = frameRate > 0 ? frameRate : 30.0
        let isPortrait = abs(preferredTransform.b) == 1.0 && abs(preferredTransform.c) == 1.0

        print("🔍 视频处理设置：尺寸=\(finalSourceSize.width)x\(finalSourceSize.height) (\(isPortrait ? "竖屏" : "横屏")), 帧率=\(finalSourceFrameRate) FPS")

        // 加载音频轨道
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        let audioTrack = audioTracks.first

        // --- AVAssetReader 设置 ---
        let reader = try AVAssetReader(asset: asset)

        let readerOutputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
        ]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)

        // --- AVAssetWriter 设置 ---
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            throw ProcessingError.writerCreationFailed
        }

        // 编码器 H.264 最低安全阈值，过低会导致编码失败
        let safeBitrate = max(100_000, parameters.videoBitrate)
        let safeFrameRate = max(5.0, parameters.targetFrameRate)
        let videoCompressionSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(finalSourceSize.width),
            AVVideoHeightKey: Int(finalSourceSize.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: safeBitrate,
                AVVideoMaxKeyFrameIntervalKey: Int(safeFrameRate * 2),
                AVVideoExpectedSourceFrameRateKey: Int(safeFrameRate),
            ] as [String: Any],
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoCompressionSettings)
        writerInput.expectsMediaDataInRealTime = false
        writerInput.transform = preferredTransform  // 保留原始视频方向
        writer.add(writerInput)

        // --- 音频设置 ---
        var audioWriterInput: AVAssetWriterInput?
        var audioReaderOutput: AVAssetReaderTrackOutput?

        // 添加音频轨道处理（真机正常）
        if let audioTrack = audioTrack {
            print("🎵 检测到音频轨道，开始音频处理初始化")

            // 音频读取器输出设置
            let audioReaderSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVNumberOfChannelsKey: 2
            ]

            audioReaderOutput = AVAssetReaderTrackOutput(
                track: audioTrack,
                outputSettings: audioReaderSettings
            )
            audioReaderOutput?.alwaysCopiesSampleData = false

            if let audioReaderOutput = audioReaderOutput {
                reader.add(audioReaderOutput)
                print("✅ 音频读取器已添加")
            }

            // 音频写入器输入设置 — 采样率 + 码率均降质
            let safeSampleRate = Self.nearestValidAACSampleRate(for: parameters.audioSampleRate)
            let audioBitrate = max(24_000, Int(safeSampleRate * 2.5))  // 8kHz→24kbps, 11kHz→27kbps, 极低码率
            let audioWriterSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: safeSampleRate,
                AVNumberOfChannelsKey: 1,         // 单声道增加复古感
                AVEncoderBitRateKey: audioBitrate
            ]

            audioWriterInput = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: audioWriterSettings
            )
            audioWriterInput?.expectsMediaDataInRealTime = false

            if let audioWriterInput = audioWriterInput {
                writer.add(audioWriterInput)
                print("✅ 音频写入器已添加")
            }
        } else {
            print("⚠️ 视频中没有检测到音频轨道")
        }

        // 异步加载时长
        let duration = try await asset.load(.duration)

        // --- 开始读写 ---
        reader.startReading()
        guard writer.startWriting() else {
            throw ProcessingError.writerStartFailed(writer.error ?? ProcessingError.unknown)
        }
        writer.startSession(atSourceTime: .zero)

        // 预估总帧数（用于进度）
        let estimatedTotalFrames = Int(duration.seconds * Double(finalSourceFrameRate))
        var processedFrames = 0

        // --- 逐帧处理 ---
        let serialQueue = DispatchQueue(label: "com.hauntedfilter.writer")
        let audioQueue = DispatchQueue(label: "com.hauntedfilter.audio")
        let videoGroup = DispatchGroup()
        let audioGroup = DispatchGroup()
        var frameSkipper = FrameSkipper(sourceFrameRate: Double(finalSourceFrameRate), targetFrameRate: parameters.targetFrameRate)

        // 预生成扫描线纹理（简化处理）
        let scanlineForSize = ScanlineGenerator.generateScanlineTexture(
            size: finalSourceSize,
            spacing: 4,
            lineThickness: 2
        )
        self.scanlineTexture = scanlineForSize

        if scanlineForSize == nil {
            print("⚠️ 扫描线纹理生成失败，将跳过扫描线效果")
        } else {
            print("✅ 扫描线纹理生成成功，尺寸: \(finalSourceSize)")
        }

        // 启动音频处理（并行处理）
        // 用 AtomicBool 追踪音频是否仍在进行，避免通过 self 跨队列访问 @Published 属性
        let audioActive = AtomicBool(audioReaderOutput != nil && audioWriterInput != nil)
        // 提前捕获 cancelFlag 引用，闭包内无需经过 self，彻底消除 Data Race
        let cancelRef = cancelFlag

        if let audioReaderOutput = audioReaderOutput, let audioWriterInput = audioWriterInput {
            audioGroup.enter()

            let weakAudioWriter = audioWriterInput
            let weakAudioReader = audioReaderOutput
            // 注意：不再捕获 [weak self]，所有状态通过值类型或 AtomicBool 传递
            // 用变量追踪是否已完成，防止重复 leave
            var audioDidFinish = false
            audioWriterInput.requestMediaDataWhenReady(on: audioQueue) {
                // 如果写入器已失败，立即完成
                if writer.status == .failed {
                    if !audioDidFinish {
                        audioDidFinish = true
                        audioActive.value = false
                        audioGroup.leave()
                    }
                    return
                }
                while weakAudioWriter.isReadyForMoreMediaData {
                    if cancelRef.value {
                        if !audioDidFinish {
                            audioDidFinish = true
                            weakAudioWriter.markAsFinished()
                            audioActive.value = false
                            audioGroup.leave()
                        }
                        return
                    }
                    if let sampleBuffer = weakAudioReader.copyNextSampleBuffer() {
                        weakAudioWriter.append(sampleBuffer)
                    } else {
                        print("✅ 音频数据处理完成")
                        if !audioDidFinish {
                            audioDidFinish = true
                            weakAudioWriter.markAsFinished()
                            audioActive.value = false
                            audioGroup.leave()
                        }
                        return
                    }
                }
                // while 循环退出（isReadyForMoreMediaData = false）但未完成
                if writer.status == .failed && !audioDidFinish {
                    audioDidFinish = true
                    audioActive.value = false
                    print("⚠️ 音频写入器已失败，信号完成")
                    audioGroup.leave()
                }
            }

            print("🎵 音频处理已启动")
        }

        // 启动视频处理
        videoGroup.enter()
        var videoDidFinish = false
        writerInput.requestMediaDataWhenReady(on: serialQueue) { [weak self] in
            guard let self = self else {
                if !videoDidFinish {
                    videoDidFinish = true
                    writerInput.markAsFinished()
                    videoGroup.leave()
                }
                return
            }

            // 如果写入器已失败，立即完成
            if writer.status == .failed {
                if !videoDidFinish {
                    videoDidFinish = true
                    print("⚠️ 视频写入器已失败，提前完成")
                    videoGroup.leave()
                }
                return
            }

            while writerInput.isReadyForMoreMediaData {
                // 通过 cancelRef（AtomicBool）读取，不经过 @Published 属性，线程安全
                if cancelRef.value {
                    if !videoDidFinish {
                        videoDidFinish = true
                        writerInput.markAsFinished()
                        videoGroup.leave()
                    }
                    return
                }
                guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                    print("✅ 视频数据处理完成")
                    if !videoDidFinish {
                        videoDidFinish = true
                        writerInput.markAsFinished()
                        videoGroup.leave()
                    }
                    return
                }

                let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

                // 帧跳过：只写入符合目标帧率的帧
                guard frameSkipper.shouldWriteFrame(at: presentationTimeStamp) else {
                    continue
                }

                // 处理帧
                if let processedBuffer = self.processSampleBuffer(sampleBuffer,
                                                                   parameters: parameters,
                                                                   preset: preset,
                                                                   sourceSize: finalSourceSize,
                                                                   scanlineTexture: scanlineForSize) {
                    writerInput.append(processedBuffer)
                }

                processedFrames += 1
                // 每 5 帧更新一次进度，让进度条有可见的加载过程
                if processedFrames % 5 == 0 {
                    let progressValue = min(0.99, Double(processedFrames) / Double(max(estimatedTotalFrames, 1)))
                    DispatchQueue.main.async { [weak self] in
                        self?.progress = progressValue
                    }
                }
            }

            // while 循环退出（isReadyForMoreMediaData == false）但未完成
            // 如果写入器已失败，不会再收到回调，需在此 leave
            if writer.status == .failed && !videoDidFinish {
                videoDidFinish = true
                print("⚠️ 视频写入器状态失败，信号完成")
                videoGroup.leave()
            }
        }

        // 等待视频和音频处理都完成
        let videoComplete: DispatchTimeoutResult = await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: videoGroup.wait(timeout: .now() + 120.0))
            }
        }
        let audioComplete: Bool
        if audioActive.value {
            audioComplete = await withCheckedContinuation { continuation in
                DispatchQueue.global().async {
                    continuation.resume(returning: audioGroup.wait(timeout: .now() + 120.0) == .success)
                }
            }
        } else {
            audioComplete = true
        }

        if videoComplete != .success {
            print("⚠️ 视频处理可能未完成")
        }

        if !audioComplete {
            print("⚠️ 音频处理可能未完成，强制标记完成")
            audioWriterInput?.markAsFinished()
        }

        // --- 完成 ---
        if cancelFlag.value {
            reader.cancelReading()
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: outputURL)
            throw ProcessingError.cancelled
        }

        // 如果写入器已失败（例如音频编码器初始化失败），直接抛出错误
        if writer.status == .failed {
            throw writer.error ?? ProcessingError.writerFinishFailed
        }

        // 仅在状态为 .writing 时调用 finishWriting（否则会崩溃）
        if writer.status == .writing {
            writer.finishWriting { }
        }

        // 等待写入完成（使用异步方式）
        let writerDeadline = Date().addingTimeInterval(30)
        while writer.status == .writing {
            if Date() > writerDeadline {
                throw ProcessingError.timeout
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        if writer.status == .failed {
            throw writer.error ?? ProcessingError.writerFinishFailed
        }
    }

    // MARK: - 帧处理（以下方法由后台队列调用，标记 nonisolated）

    nonisolated private func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        parameters: ProcessingParameters,
        preset: VideoPreset,
        sourceSize: CGSize,
        scanlineTexture: CIImage?
    ) -> CMSampleBuffer? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // 应用滤镜链
        ciImage = FilterChainBuilder.applyFilters(
            to: ciImage,
            parameters: parameters,
            preset: preset,
            scanlineTexture: scanlineTexture,
            timestamp: Date(),
            sourceSize: sourceSize
        )

        // 确保 extent 限制在 origin (0, 0)
        let renderImage = ciImage.cropped(to: CGRect(origin: .zero, size: sourceSize))

        // 渲染回 CVPixelBuffer
        let outputBuffer = createPixelBuffer(from: renderImage, size: sourceSize)
        guard let outputPixelBuffer = outputBuffer else {
            return nil
        }

        // 使用 CIContext 渲染（硬件加速配置）
        let context = ciContext ?? {
            print("初始化硬件加速 CIContext...")
            let newContext = CIContext(options: [.useSoftwareRenderer: false, .cacheIntermediates: false])
            ciContext = newContext
            return newContext
        }()

        context.render(renderImage, to: outputPixelBuffer)

        // 创建新的 CMSampleBuffer
        var timingInfo = CMSampleTimingInfo()
        timingInfo.duration = CMSampleBufferGetDuration(sampleBuffer)
        timingInfo.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        timingInfo.decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)

        var formatDescription: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: outputPixelBuffer,
            formatDescriptionOut: &formatDescription
        )

        guard let fd = formatDescription else { return nil }

        var newSampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: outputPixelBuffer,
            formatDescription: fd,
            sampleTiming: &timingInfo,
            sampleBufferOut: &newSampleBuffer
        )

        return newSampleBuffer
    }

    nonisolated private func createPixelBuffer(from image: CIImage, size: CGSize) -> CVPixelBuffer? {
        let width = Int(size.width)
        let height = Int(size.height)

        var pixelBuffer: CVPixelBuffer?
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            pixelBufferAttributes as CFDictionary,
            &pixelBuffer
        )

        return status == kCVReturnSuccess ? pixelBuffer : nil
    }

    // MARK: - 音频处理

    // 音频处理已集成到主处理流程中，与视频处理并行执行

    // MARK: - 工具方法

    /// 合法的 AAC 编码采样率列表（Hz）
    private static let validAACSampleRates: [Double] = [
        8000, 11025, 12000, 16000, 22050, 24000,
        32000, 44100, 48000, 64000, 88200, 96000
    ]

    /// 将任意采样率四舍五入到最近的合法 AAC 采样率
    nonisolated static func nearestValidAACSampleRate(for rate: Double) -> Double {
        let clamped = max(validAACSampleRates.first!, min(validAACSampleRates.last!, rate))
        return validAACSampleRates.min(by: { abs($0 - clamped) < abs($1 - clamped) }) ?? 44100
    }
}

// MARK: - 错误定义

enum ProcessingError: LocalizedError {
    case alreadyProcessing
    case noVideoTrack
    case writerCreationFailed
    case writerStartFailed(Error)
    case writerFinishFailed
    case cancelled
    case timeout
    case unknown

    var errorDescription: String? {
        switch self {
        case .alreadyProcessing: return "正在处理中，请等待完成"
        case .noVideoTrack: return "视频中没有找到视频轨道"
        case .writerCreationFailed: return "无法创建视频写入器"
        case .writerStartFailed(let error): return "写入器启动失败: \(error.localizedDescription)"
        case .writerFinishFailed: return "视频写入完成失败"
        case .cancelled: return "处理已取消"
        case .timeout: return "处理超时"
        case .unknown: return "未知错误"
        }
    }
}