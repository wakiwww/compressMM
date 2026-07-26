import Foundation
import SwiftUI
import PhotosUI
import AVFoundation

/// 处理管线协调 ViewModel
@MainActor
class ProcessingViewModel: ObservableObject {
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

    /// 缓存视频时长（异步加载，供 checkOverCompression 同步使用）
    private var cachedDuration: TimeInterval = 0

    private let processor = VideoProcessor()

    /// 开始处理视频
    func startProcessing() {
        guard let sourceURL = sourceVideoURL else {
            errorMessage = "请先选择视频"
            showError = true
            return
        }

        isProcessing = true
        progress = 0
        outputURL = nil

        processor.processVideo(
            sourceURL: sourceURL,
            preset: selectedPreset,
            intensity: intensity
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.isProcessing = false

                switch result {
                case .success(let url):
                    self.outputURL = url
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
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
        sourceVideoURL = url
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        sourceFileSize = attrs?[.size] as? UInt64 ?? 0
        sourceFileSizeFormatted = formatFileSize(sourceFileSize)
        // 异步加载时长并缓存
        Task {
            if let duration = try? await AVURLAsset(url: url).load(.duration).seconds,
               duration > 0 {
                await MainActor.run { self.cachedDuration = duration }
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

        let asset = AVURLAsset(url: url)

        // 异步加载duration
        Task {
            do {
                let duration = try await asset.load(.duration).seconds
                guard duration > 0, !duration.isNaN else {
                    await MainActor.run {
                        estimatedOutputSize = "无法估算"
                    }
                    return
                }

                let params = selectedPreset.parameters(for: intensity)

                // 视频部分: bitrate(bps) / 8 * 时长 * 校正因子
                let videoBytes = Double(params.videoBitrate) / 8.0 * duration * 0.9

                // 音频部分: AAC 编码近似
                let audioBytes = params.audioSampleRate * 2.0 * duration * 0.3

                let totalBytes = videoBytes + audioBytes

                await MainActor.run {
                    estimatedOutputSize = formatFileSize(UInt64(totalBytes))

                    // 压缩比
                    guard sourceFileSize > 0 else {
                        compressionRatio = 0
                        return
                    }
                    compressionRatio = Float(totalBytes) / Float(sourceFileSize)
                }
            } catch {
                await MainActor.run {
                    estimatedOutputSize = "无法估算"
                    print("无法加载duration: \(error)")
                }
            }
        }
    }

    /// 检查是否过度压缩（调用方在 UI 层判断）
    func checkOverCompression() -> Bool {
        guard sourceFileSize > 0, compressionRatio > 0 else { return false }

        // 动态阈值：根据视频时长调整
        // 短视频(≤10s)更宽容: 5%, 长视频(>60s)更保守: 12%
        let duration = cachedDuration
        guard duration > 0 else { return false }
        let threshold: Float
        if duration <= 10 {
            threshold = 0.05
        } else if duration >= 60 {
            threshold = 0.12
        } else {
            // 线性插值 10s→0.05, 60s→0.12
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
}