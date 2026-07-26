import Foundation
import SwiftUI
import PhotosUI
import AVFoundation

/// 安全版本的处理管线协调 ViewModel（避免iOS 27 Beta内存错误）
@MainActor
class ProcessingViewModel_Safe: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var sourceVideoURL: URL?
    @Published var outputURL: URL?
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var selectedPreset: VideoPreset = .oldPhone {
        didSet { recalculateEstimation() }
    }
    @Published var intensity: Float = 50 {
        didSet { recalculateEstimation() }
    }
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - 预估大小 & 警告
    @Published var estimatedOutputSize: String = "未知"
    @Published var showOverCompressionAlert = false
    @Published var compressionRatio: Float = 0
    @Published var sourceFileSize: UInt64 = 0
    @Published var sourceFileSizeFormatted: String = ""
    @Published var alertMessage: String = ""

    /// 缓存视频时长（异步加载，供同步方法使用，避免在主线程同步调用 asset.duration）
    private var cachedDuration: TimeInterval = 0

    private let processor = VideoProcessor_Safe()

    /// 开始处理视频（安全版本）
    func startProcessing() {
        guard let sourceURL = sourceVideoURL else {
            errorMessage = "请先选择视频"
            showError = true
            return
        }

        print("🛡️ 使用安全视频处理器")
        print("📊 视频路径: \(sourceURL.path)")
        print("🎛️ 预设: \(selectedPreset.id), 强度: \(intensity)")

        isProcessing = true
        progress = 0
        outputURL = nil
        errorMessage = nil

        Task {
            do {
                let result = await processor.processVideo(
                    sourceURL: sourceURL,
                    preset: selectedPreset,
                    intensity: intensity
                )

                isProcessing = false

                switch result {
                case .success(let url):
                    print("✅ 视频处理成功: \(url.lastPathComponent)")
                    outputURL = url

                    // 验证生成的文件
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: url.path) {
                        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                        let fileSize = attributes?[.size] as? UInt64 ?? 0
                        print("📁 输出文件大小: \(formatFileSize(fileSize))")
                    } else {
                        print("⚠️ 输出文件未找到")
                    }

                case .failure(let error):
                    print("❌ 视频处理失败: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    /// 取消处理
    func cancelProcessing() {
        processor.cancel()
        isProcessing = false
    }

    /// 重置状态
    func reset() {
        selectedItem = nil
        sourceVideoURL = nil
        outputURL = nil
        isProcessing = false
        progress = 0
        errorMessage = nil
        estimatedOutputSize = "未知"
        compressionRatio = 0
        sourceFileSize = 0
        sourceFileSizeFormatted = ""
    }

    /// 导入视频后更新源文件信息
    func didSelectVideo(url: URL) {
        print("📹 视频已选择: \(url.lastPathComponent)")

        sourceVideoURL = url
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        sourceFileSize = attrs?[.size] as? UInt64 ?? 0
        sourceFileSizeFormatted = formatFileSize(sourceFileSize)

        print("📊 原始文件大小: \(sourceFileSizeFormatted)")

        // 快速显示视频信息 & 缓存时长
        Task {
            let asset = AVAsset(url: url)
            if let duration = try? await asset.load(.duration) {
                await MainActor.run { self.cachedDuration = duration.seconds }
            }
            let videoTracks = try? await asset.loadTracks(withMediaType: .video)
            let audioTracks = try? await asset.loadTracks(withMediaType: .audio)

            print("📊 视频时长: \(duration?.seconds ?? 0.0) 秒")
            print("🎵 音频轨道数: \(audioTracks?.count ?? 0)")
            print("🎬 视频轨道数: \(videoTracks?.count ?? 0)")

            // 如果没有音频轨道，显示警告
            if audioTracks?.isEmpty ?? true {
                DispatchQueue.main.async {
                    self.errorMessage = "警告: 视频文件没有音频轨道"
                    self.showError = true
                }
            }
        }

        recalculateEstimation()
    }

    // MARK: - 预估大小

    func recalculateEstimation() {
        guard let url = sourceVideoURL else {
            estimatedOutputSize = "未知"
            return
        }

        // 使用缓存的时长（由 didSelectVideo 异步加载），避免在主线程同步阻塞
        let duration = cachedDuration
        guard duration > 0, !duration.isNaN else {
            estimatedOutputSize = "无法估算"
            return
        }

        let params = selectedPreset.parameters(for: intensity)

        // 简化的预估计算
        let videoBytes = Double(params.videoBitrate) / 8.0 * duration * 0.8

        let totalBytes = videoBytes // 跳过音频部分计算，简化处理
        estimatedOutputSize = formatFileSize(UInt64(totalBytes))

        // 压缩比
        guard sourceFileSize > 0 else {
            compressionRatio = 0
            return
        }
        compressionRatio = Float(totalBytes) / Float(sourceFileSize)
    }

    /// 检查是否过度压缩
    func checkOverCompression() -> Bool {
        guard sourceFileSize > 0, compressionRatio > 0 else { return false }

        let duration = cachedDuration
        guard duration > 0 else { return false }
        let threshold: Float
        if duration <= 10 {
            threshold = 0.05
        } else if duration >= 60 {
            threshold = 0.12
        } else {
            threshold = 0.05 + Float((duration - 10) / 50) * 0.07
        }

        return compressionRatio < threshold
    }

    /// 生成警告文案
    func generateAlertMessage() -> String {
        let ratioPercent = Int((1 - compressionRatio) * 100)
        return """
        调这么高你要把视频压没吗？
        原始大小：\(sourceFileSizeFormatted)
        预估大小：\(estimatedOutputSize)
        压缩率：\(ratioPercent)%
        """
    }

    // MARK: - Helpers

    func formatFileSize(_ bytes: UInt64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    func formatFileSize(_ bytes: Double) -> String {
        formatFileSize(UInt64(bytes))
    }

    /// 简单的视频基础信息获取
    func getVideoBasicInfo() async -> [String: Any] {
        var info: [String: Any] = [:]

        guard let url = sourceVideoURL else { return info }

        do {
            let asset = AVAsset(url: url)
            let duration = try await asset.load(.duration)
            info["duration"] = duration.seconds

            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            info["video_tracks"] = videoTracks.count

            if let videoTrack = videoTracks.first {
                let naturalSize = try await videoTrack.load(.naturalSize)
                info["size"] = "\(naturalSize.width)x\(naturalSize.height)"
                let frameRate = try await videoTrack.load(.nominalFrameRate)
                info["frame_rate"] = frameRate
            }

            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            info["audio_tracks"] = audioTracks.count
            info["has_audio"] = !audioTracks.isEmpty

            print("📊 视频基本信息: \(info)")

        } catch {
            print("❌ 获取视频信息失败: \(error)")
        }

        return info
    }
}