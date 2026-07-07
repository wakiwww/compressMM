import Foundation
import AVFoundation
import CoreImage
import UIKit

/// 核心视频处理器：AVAssetReader → CIFilter 链 → AVAssetWriter
class VideoProcessor: ObservableObject {
    @Published var progress: Double = 0
    @Published var isProcessing = false
    @Published var isCancelled = false
    @Published var errorMessage: String?

    private let processingQueue = DispatchQueue(label: "com.hauntedfilter.videoprocessor", qos: .userInitiated)
    private let ciContext = CIContext()
    private var scanlineTexture: CIImage?

    init() {
        scanlineTexture = ScanlineGenerator.generateScanlineTexture(
            size: CGSize(width: 1920, height: 1080),
            spacing: 4,
            lineThickness: 2
        )
    }

    /// 处理视频
    /// - Parameters:
    ///   - sourceURL: 源视频 URL
    ///   - preset: 预设
    ///   - intensity: 强度 (0-100)
    ///   - completion: 完成回调，返回输出文件 URL
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
        progress = 0
        errorMessage = nil

        let parameters = preset.parameters(for: intensity)
        let asset = AVAsset(url: sourceURL)

        processingQueue.async { [weak self] in
            guard let self = self else { return }

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")

            do {
                try self.processAsset(asset, parameters: parameters, preset: preset, outputURL: outputURL)

                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.progress = 1.0
                    completion(.success(outputURL))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    /// 取消处理
    func cancel() {
        isCancelled = true
    }

    // MARK: - 核心处理逻辑

    private func processAsset(
        _ asset: AVAsset,
        parameters: ProcessingParameters,
        preset: VideoPreset,
        outputURL: URL
    ) throws {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            throw ProcessingError.noVideoTrack
        }

        let sourceSize = videoTrack.naturalSize
        let sourceFrameRate = videoTrack.nominalFrameRate

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

        let videoCompressionSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(sourceSize.width),
            AVVideoHeightKey: Int(sourceSize.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: parameters.videoBitrate,
                AVVideoMaxKeyFrameIntervalKey: Int(parameters.targetFrameRate * 2),
                AVVideoExpectedSourceFrameRateKey: Int(parameters.targetFrameRate),
            ] as [String: Any],
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoCompressionSettings)
        writerInput.expectsMediaDataInRealTime = false
        writer.add(writerInput)

        // --- 音频设置 ---
        let audioReaderWriter = try setupAudioReading(for: asset, writer: writer, parameters: parameters)

        // --- 开始读写 ---
        reader.startReading()
        guard writer.startWriting() else {
            throw ProcessingError.writerStartFailed(writer.error ?? ProcessingError.unknown)
        }
        writer.startSession(atSourceTime: .zero)

        // 预估总帧数（用于进度）
        let duration = asset.duration.seconds
        let estimatedTotalFrames = Int(duration * Double(sourceFrameRate))
        var processedFrames = 0

        // --- 逐帧处理 ---
        let serialQueue = DispatchQueue(label: "com.hauntedfilter.writer")
        let group = DispatchGroup()
        var frameSkipper = FrameSkipper(sourceFrameRate: Double(sourceFrameRate), targetFrameRate: parameters.targetFrameRate)

        // 预生成扫描线纹理
        let scanlineForSize = ScanlineGenerator.generateScanlineTexture(
            size: sourceSize,
            spacing: 4,
            lineThickness: 2
        )
        self.scanlineTexture = scanlineForSize

        writerInput.requestMediaDataWhenReady(on: serialQueue) {
            while writerInput.isReadyForMoreMediaData, !self.isCancelled {
                guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                    writerInput.markAsFinished()
                    group.leave()
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
                                                                   sourceSize: sourceSize,
                                                                   scanlineTexture: scanlineForSize) {
                    writerInput.append(processedBuffer)
                }

                processedFrames += 1
                let progress = min(1.0, Double(processedFrames) / Double(max(estimatedTotalFrames, 1)))
                DispatchQueue.main.async {
                    self.progress = progress
                }
            }

            if self.isCancelled {
                writerInput.markAsFinished()
                group.leave()
            }
        }

        group.enter()
        group.wait()

        // --- 处理音频 ---
        if let (audioReader, audioWriterInput) = audioReaderWriter {
            processAudio(reader: audioReader, writerInput: audioWriterInput)
        }

        // --- 完成 ---
        if isCancelled {
            reader.cancelReading()
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: outputURL)
            throw ProcessingError.cancelled
        }

        writer.finishWriting {
            // 音频处理完成后 finishWriting 会在 audio completion 中调用
        }

        // 等待写入完成
        let writerTimeout = DispatchTime.now() + .seconds(30)
        while writer.status == .writing {
            if DispatchTime.now() > writerTimeout {
                throw ProcessingError.timeout
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        if writer.status == .failed {
            throw writer.error ?? ProcessingError.writerFinishFailed
        }
    }

    // MARK: - 帧处理

    private func processSampleBuffer(
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

        // 渲染回 CVPixelBuffer
        let outputBuffer = createPixelBuffer(from: ciImage, size: sourceSize)
        guard let outputPixelBuffer = outputBuffer else {
            return nil
        }

        // 使用 CIContext 渲染
        ciContext.render(ciImage, to: outputPixelBuffer)

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

    private func createPixelBuffer(from image: CIImage, size: CGSize) -> CVPixelBuffer? {
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

    private func setupAudioReading(
        for asset: AVAsset,
        writer: AVAssetWriter,
        parameters: ProcessingParameters
    ) throws -> (AVAssetReader, AVAssetWriterInput)? {
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            return nil // 无音轨，跳过
        }

        let audioReader = try AVAssetReader(asset: asset)
        let audioReaderOutput = AVAssetReaderTrackOutput(
            track: audioTrack,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVNumberOfChannelsKey: 2,
            ]
        )
        audioReaderOutput.alwaysCopiesSampleData = false
        audioReader.add(audioReaderOutput)

        let audioWriterInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: parameters.audioSampleRate,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 64000,
            ]
        )
        audioWriterInput.expectsMediaDataInRealTime = false
        writer.add(audioWriterInput)

        return (audioReader, audioWriterInput)
    }

    private func processAudio(reader: AVAssetReader, writerInput: AVAssetWriterInput) {
        reader.startReading()
        let queue = DispatchQueue(label: "com.hauntedfilter.audio")

        writerInput.requestMediaDataWhenReady(on: queue) {
            while writerInput.isReadyForMoreMediaData {
                guard let reader = reader.outputs.first as? AVAssetReaderTrackOutput else { break }

                if let sampleBuffer = reader.copyNextSampleBuffer() {
                    writerInput.append(sampleBuffer)
                } else {
                    writerInput.markAsFinished()
                    break
                }
            }
        }

        // 等待音频读取完成
        let timeout = DispatchTime.now() + .seconds(30)
        while reader.status == .reading {
            if DispatchTime.now() > timeout { break }
            Thread.sleep(forTimeInterval: 0.1)
        }
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