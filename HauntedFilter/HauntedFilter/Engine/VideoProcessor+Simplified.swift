import Foundation
import AVFoundation

/// iOS 27 beta的简化视频处理器
class VideoProcessorSimplified: ObservableObject {
    @Published var progress: Double = 0
    @Published var isProcessing = false
    @Published var isCancelled = false
    @Published var errorMessage: String?

    private let processingQueue = DispatchQueue(label: "com.hauntedfilter.videoprocessorsimplified", qos: .userInitiated)
    private var ciContext: CIContext?

    /// 简化的视频处理（只处理视频，保留原始音频）
    func processVideo(
        sourceURL: URL,
        preset: VideoPreset,
        intensity: Float
    ) async -> Result<URL, Error> {
        await withCheckedContinuation { continuation in
            processVideo(
                sourceURL: sourceURL,
                preset: preset,
                intensity: intensity
            ) { result in
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
            completion(.failure(SimplifiedProcessingError.alreadyProcessing))
            return
        }

        isProcessing = true
        isCancelled = false
        progress = 0
        errorMessage = nil

        let parameters = preset.parameters(for: intensity)
        let asset = AVURLAsset(url: sourceURL)

        processingQueue.async { [weak self] in
            guard let self = self else { return }

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")

            do {
                try self.processSimplified(
                    asset: asset,
                    parameters: parameters,
                    preset: preset,
                    outputURL: outputURL
                )

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

    // MARK: - 简化处理逻辑

    private func processSimplified(
        asset: AVURLAsset,
        parameters: ProcessingParameters,
        preset: VideoPreset,
        outputURL: URL
    ) throws {
        print("🎬 开始简化视频处理（保留原始音频）")

        // 1. 准备AVComposition（保留原始音频）
        let composition = AVMutableComposition()

        // 2. 添加视频轨道
        guard let videoTrack = try? await(asset.loadTracks(withMediaType: .video)).first else {
            throw SimplifiedProcessingError.noVideoTrack
        }

        let videoDuration = try await(asset.load(.duration))

        let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        let videoTimeRange = CMTimeRange(start: .zero, duration: videoDuration)
        try compositionVideoTrack?.insertTimeRange(
            videoTimeRange,
            of: videoTrack,
            at: .zero
        )

        // 3. 添加音频轨道（保留原始音频）
        if let audioTrack = try? await(asset.loadTracks(withMediaType: .audio)).first {
            print("🎵 检测到音频轨道，将保留原始音频")

            let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )

            try compositionAudioTrack?.insertTimeRange(
                videoTimeRange,
                of: audioTrack,
                at: .zero
            )
        } else {
            print("⚠️ 视频中没有音频轨道")
        }

        // 4. 应用视频滤镜（在导出时应用）
        let videoComposition = createVideoComposition(
            composition: composition,
            parameters: parameters,
            preset: preset
        )

        // 5. 导出视频（保留音频）
        let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        )

        guard let exportSession = exportSession else {
            throw SimplifiedProcessingError.exportFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = videoComposition
        exportSession.audioTimePitchAlgorithm = .timeDomain

        let group = DispatchGroup()
        group.enter()

        var exportError: Error?

        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("✅ 视频导出成功（包含原始音频）")
            case .failed:
                exportError = exportSession.error ?? SimplifiedProcessingError.exportFailed
                print("❌ 视频导出失败: \(exportError?.localizedDescription ?? "未知错误")")
            case .cancelled:
                exportError = SimplifiedProcessingError.cancelled
                print("❌ 视频导出被取消")
            default:
                exportError = SimplifiedProcessingError.exportFailed
                print("❌ 视频导出失败（未知状态）")
            }
            group.leave()
        }

        // 等待导出完成（最大60秒）
        let result = group.wait(timeout: .now() + 60.0)

        if result == .timedOut {
            exportSession.cancelExport()
            throw SimplifiedProcessingError.timeout
        }

        if let error = exportError {
            throw error
        }
    }

    // MARK: - 视频合成

    private func createVideoComposition(
        composition: AVMutableComposition,
        parameters: ProcessingParameters,
        preset: VideoPreset
    ) -> AVMutableVideoComposition? {
        guard let videoTrack = composition.tracks(withMediaType: .video).first else {
            return nil
        }

        let videoComposition = AVMutableVideoComposition()
        let videoSize = videoTrack.naturalSize

        // 设置视频尺寸和帧率
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(parameters.targetFrameRate))

        // 创建视频层指令
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

        // 应用简单的滤镜效果（这里简化处理）
        // 在实际应用中，这里可以使用CIFilter应用效果
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        // 应用视频滤镜（可选，简化版本）
        if let ciFilter = createCIFilter(for: preset, intensity: parameters.intensity) {
            // 如果需要应用CoreImage滤镜，可以在这里处理
            // 为了简化，暂时不应用复杂滤镜
            print("🎨 准备应用滤镜预设: \(preset)")
        }

        return videoComposition
    }

    private func createCIFilter(for preset: VideoPreset, intensity: Float) -> CIFilter? {
        // 这里是简化的滤镜创建
        // 在实际应用中，根据preset创建不同的CIFilter
        switch preset {
        case .oldPhone:
            let filter = CIFilter(name: "CIColorControls")
            filter?.setValue(0.5, forKey: kCIInputSaturationKey)
            return filter
        case .vhs:
            let filter = CIFilter(name: "CISepiaTone")
            filter?.setValue(0.3, forKey: kCIInputIntensityKey)
            return filter
        case .glitch, .retroVideo, .filmGrain:
            // 简化处理，返回nil
            return nil
        }
    }
}

// MARK: - 错误定义

enum SimplifiedProcessingError: LocalizedError {
    case alreadyProcessing
    case noVideoTrack
    case exportFailed
    case cancelled
    case timeout
    case unknown

    var errorDescription: String? {
        switch self {
        case .alreadyProcessing: return "正在处理中，请等待完成"
        case .noVideoTrack: return "视频中没有找到视频轨道"
        case .exportFailed: return "视频导出失败"
        case .cancelled: return "处理已取消"
        case .timeout: return "处理超时"
        case .unknown: return "未知错误"
        }
    }
}