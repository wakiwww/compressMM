import Foundation
import SwiftUI
import PhotosUI
import AVFoundation

/// 扩展的处理管线协调 ViewModel（支持BGM）
@MainActor
class ProcessingViewModelEx: ObservableObject {
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

    // BGM相关属性
    @Published var selectedBGM: BGM? = nil
    @Published var isBGMEnabled: Bool = false {
        didSet {
            if !isBGMEnabled {
                bgmVolume = 0
            } else if bgmVolume == 0 {
                bgmVolume = 0.7
            }
        }
    }
    @Published var bgmVolume: Float = 0 {
        didSet {
            if bgmVolume > 0 && !isBGMEnabled {
                isBGMEnabled = true
            }
        }
    }
    @Published var bgmLoading: Bool = false
    @Published var bgmDurationInfo: String = ""

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
    private let bgmManager = BGMManager.shared

    /// 所有可用的BGM
    var availableBGM: [BGM] {
        bgmManager.availableBGM
    }

    init() {
        // 初始化时加载BGM
        Task {
            await bgmManager.loadAvailableBGM()
            await MainActor.run {
                if let defaultBGM = bgmManager.defaultBGM() {
                    selectedBGM = defaultBGM
                }
            }
        }
    }

    /// 开始处理视频（带BGM支持）
    func startProcessing() {
        guard let sourceURL = sourceVideoURL else {
            errorMessage = "请先选择视频"
            showError = true
            return
        }

        Task {
            await MainActor.run {
                isProcessing = true
                progress = 0
                outputURL = nil
                errorMessage = nil
            }

            do {
                // 首先处理视频（无BGM）
                let processedVideoURL = try await processVideo(sourceURL: sourceURL)

                // 如果需要，合并BGM
                if isBGMEnabled, let selectedBGM = selectedBGM, bgmVolume > 0 {
                    await MainActor.run { bgmLoading = true }

                    // 获取视频时长
                    let videoAsset = AVAsset(url: processedVideoURL)
                    let videoDuration = try await videoAsset.load(.duration).seconds

                    // 适配BGM
                    if let adaptedBGMURL = await selectedBGM.adaptedBGM(for: videoDuration) {
                        // 合并BGM
                        let result = await BGMMergeProcessor.mergeVideoWithBGM(
                            videoURL: processedVideoURL,
                            bgmURL: adaptedBGMURL,
                            bgmVolume: bgmVolume
                        )

                        switch result {
                        case .success(let finalURL):
                            await MainActor.run {
                                self.outputURL = finalURL
                                self.cleanupTempFiles(originalURL: processedVideoURL, bgmURL: adaptedBGMURL)
                            }
                        case .failure(let error):
                            throw error
                        }
                    } else {
                        // BGM适配失败，使用无BGM的视频
                        await MainActor.run {
                            self.outputURL = processedVideoURL
                        }
                    }

                    await MainActor.run { bgmLoading = false }
                } else {
                    // 不使用BGM
                    await MainActor.run {
                        self.outputURL = processedVideoURL
                    }
                }

                await MainActor.run {
                    self.isProcessing = false
                    self.progress = 1.0
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    print("处理失败: \(error)")
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
        selectedBGM = bgmManager.defaultBGM()
        isBGMEnabled = false
        bgmVolume = 0
        bgmDurationInfo = ""
    }

    /// 导入视频后更新源文件信息
    func didSelectVideo(url: URL) {
        sourceVideoURL = url
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        sourceFileSize = attrs?[.size] as? UInt64 ?? 0
        sourceFileSizeFormatted = formatFileSize(sourceFileSize)
        // 异步加载视频时长并缓存，避免在主线程同步阻塞
        Task {
            if let duration = try? await AVURLAsset(url: url).load(.duration).seconds,
               duration > 0 {
                await MainActor.run { self.cachedDuration = duration }
            }
        }
        recalculateEstimation()
        updateBGMDurationInfo()
    }

    /// 选择BGM
    func selectBGM(_ bgm: BGM?) {
        selectedBGM = bgm
        updateBGMDurationInfo()
    }

    /// 更新BGM时长信息
    func updateBGMDurationInfo() {
        bgmDurationInfo = ""

        guard let sourceURL = sourceVideoURL,
              let selectedBGM = selectedBGM else { return }

        Task {
            do {
                let asset = AVAsset(url: sourceURL)
                let videoDuration = try await asset.load(.duration).seconds

                let bgmDuration = selectedBGM.duration
                let diff = videoDuration - bgmDuration

                var info = "视频: \(formatDuration(videoDuration)), BGM: \(formatDuration(bgmDuration))"

                if abs(diff) < 0.5 {
                    info += " ✓"
                } else if diff > 0 {
                    // BGM较短，需要循环
                    let loopsNeeded = Int(ceil(videoDuration / bgmDuration))
                    info += " (将循环 \(loopsNeeded) 次)"
                } else {
                    // BGM较长，需要裁剪
                    info += " (将自动裁剪)"
                }

                await MainActor.run {
                    self.bgmDurationInfo = info
                }
            } catch {
                // 忽略错误
            }
        }
    }

    // MARK: - 预估大小

    func recalculateEstimation() {
        guard let url = sourceVideoURL else {
            estimatedOutputSize = "未知"
            return
        }

        let asset = AVURLAsset(url: url)
        // 使用 async/await 异步加载，避免在主线程同步阻塞（iOS 16+ 强制要求）
        Task {
            do {
                let duration = try await asset.load(.duration).seconds
                guard duration > 0, !duration.isNaN else {
                    await MainActor.run { estimatedOutputSize = "无法估算" }
                    return
                }

                let params = selectedPreset.parameters(for: intensity)
                let videoBytes = Double(params.videoBitrate) / 8.0 * duration * 0.9
                let audioBytes = params.audioSampleRate * 2.0 * duration * 0.3
                let bgmFactor: Double = isBGMEnabled ? 1.2 : 1.0
                let adjustedAudioBytes = audioBytes * bgmFactor
                let totalBytes = videoBytes + adjustedAudioBytes

                await MainActor.run {
                    estimatedOutputSize = formatFileSize(UInt64(totalBytes))
                    guard sourceFileSize > 0 else {
                        compressionRatio = 0
                        return
                    }
                    compressionRatio = Float(totalBytes) / Float(sourceFileSize)
                }
            } catch {
                await MainActor.run { estimatedOutputSize = "无法估算" }
            }
        }
    }

    /// 检查是否过度压缩
    func checkOverCompression() -> Bool {
        guard sourceFileSize > 0, compressionRatio > 0 else { return false }

        // 使用异步加载后缓存的时长，避免同步阻塞主线程
        let duration = cachedDuration
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

    // MARK: - 私有方法

    private func processVideo(sourceURL: URL) async throws -> URL {
        try await processor.processVideo(
            sourceURL: sourceURL,
            preset: selectedPreset,
            intensity: intensity
        ).get()
    }

    private func cleanupTempFiles(originalURL: URL, bgmURL: URL) {
        // 清理临时文件
        try? FileManager.default.removeItem(at: originalURL)
        try? FileManager.default.removeItem(at: bgmURL)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func formatFileSize(_ bytes: UInt64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    func formatFileSize(_ bytes: Double) -> String {
        formatFileSize(UInt64(bytes))
    }
}