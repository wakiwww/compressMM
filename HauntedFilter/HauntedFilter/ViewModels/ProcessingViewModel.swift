import Foundation
import SwiftUI
import PhotosUI
import AVFoundation
import Combine

/// 处理管线协调 ViewModel — 统一管理导航状态，消除 onChange 时序问题
@MainActor
class ProcessingViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var sourceVideoURL: URL?
    @Published var outputURL: URL?
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var selectedPreset: VideoPreset = .egg {
        didSet { recalculateEstimation() }
    }
    @Published var intensity: Float = 50 {
        didSet { recalculateEstimation() }
    }
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - 导航（直接驱动 NavigationStack，避免 onChange 冲突）
    @Published var navigationStep: NavigationStep?

    // MARK: - 预估大小
    @Published var estimatedOutputSize: String = "未知"
    @Published var compressionRatio: Float = 0
    @Published var sourceFileSize: UInt64 = 0
    @Published var sourceFileSizeFormatted: String = ""
    @Published var videoDuration: String?

    // MARK: - 实时预览
    @Published var previewOriginalFrame: UIImage?
    @Published var previewDegradedFrame: UIImage?
    private var previewTask: Task<Void, Never>?
    private let previewContext = CIContext(options: [.useSoftwareRenderer: false, .cacheIntermediates: false])

    // MARK: - UI 状态
    @Published var isImporting = false
    @Published var isPreparing = false

    // MARK: - 编码安全预估
    @Published var encodingWarning: String?

    // MARK: - 音频控制
    @Published var audioExpanded = true
    @Published var audioMode: AudioMode = .followVideo
    @Published var audioIntensity: Float = 50

    // MARK: - 输出设置
    @Published var outputResolution: OutputResolution = .followMode
    @Published var outputFrameRate: OutputFrameRate = .followMode
    @Published var saveLocation: SaveLocation = .photoLibrary

    /// 缓存视频时长
    private var cachedDuration: TimeInterval = 0

    private let processor = VideoProcessor()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 处理生命周期

    func startProcessing() {
        guard let sourceURL = sourceVideoURL else {
            errorMessage = "请先选择视频"
            showError = true
            return
        }

        let params = selectedPreset.parameters(for: intensity)

        // 预检：编码安全
        if let warning = validateEncodingParams(params) {
            errorMessage = warning
            showError = true
            return
        }

        isPreparing = true
        progress = 0
        outputURL = nil
        cancellables.removeAll()

        // 短暂准备动画后平滑切换
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)  // 0.4s
            guard isPreparing else { return }  // 用户可能已取消
            isProcessing = true
            isPreparing = false
            navigationStep = .processing
        }

        // 同步 processor 的进度到 viewModel
        processor.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.progress = value
            }
            .store(in: &cancellables)

        processor.processVideo(
            sourceURL: sourceURL,
            preset: selectedPreset,
            intensity: intensity
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.progress = 1.0
                self.isProcessing = false
                self.cancellables.removeAll()

                switch result {
                case .success(let url):
                    self.outputURL = url
                    self.navigationStep = .done(url)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.navigationStep = nil
                }
            }
        }
    }

    func cancelProcessing() {
        processor.cancel()
        isProcessing = false
        isPreparing = false
        navigationStep = nil
    }

    func reset() {
        selectedItem = nil
        sourceVideoURL = nil
        outputURL = nil
        isProcessing = false
        progress = 0
        errorMessage = nil
        navigationStep = nil
        estimatedOutputSize = "未知"
        compressionRatio = 0
        sourceFileSize = 0
        sourceFileSizeFormatted = ""
        encodingWarning = nil
        isImporting = false
        isPreparing = false
        previewOriginalFrame = nil
        previewDegradedFrame = nil
        previewTask?.cancel()
        cancellables.removeAll()
    }

    /// 重新处理：保留已导入的视频，仅清除输出结果，返回编辑页
    func reprocess() {
        outputURL = nil
        isProcessing = false
        isPreparing = false
        progress = 0
        errorMessage = nil
        navigationStep = nil
        cancellables.removeAll()
    }

    func didSelectVideo(url: URL) {
        sourceVideoURL = url
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        sourceFileSize = attrs?[.size] as? UInt64 ?? 0
        sourceFileSizeFormatted = formatFileSize(sourceFileSize)
        Task {
            let asset = AVURLAsset(url: url)
            // 提取封面帧
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 360, height: 640)
            if let cg = try? generator.copyCGImage(at: .zero, actualTime: nil) {
                await MainActor.run { self.previewOriginalFrame = UIImage(cgImage: cg) }
            }
            // 时长
            if let duration = try? await asset.load(.duration).seconds,
               duration > 0 {
                let mins = Int(duration) / 60
                let secs = Int(duration) % 60
                await MainActor.run {
                    self.cachedDuration = duration
                    self.videoDuration = String(format: "%02d:%02d", mins, secs)
                }
            }
        }
        recalculateEstimation()
    }

    // MARK: - 编码安全预检

    /// 返回 nil 表示安全，返回警告文案表示可能失败
    func validateEncodingParams(_ params: ProcessingParameters) -> String? {
        // 分辨率过低 → Core Image 可能产出无效帧
        if params.targetWidth < 35 {
            return "目标分辨率过低（\(params.targetWidth)px），编码器可能无法处理。请适当降低阴间程度。"
        }
        // 帧率过低 → 关键帧间隔非法
        if params.targetFrameRate < 3 {
            return "目标帧率过低（\(Int(params.targetFrameRate))fps），编码器可能拒绝。请适当降低阴间程度。"
        }
        // 码率过低
        if params.videoBitrate < 50_000 {
            return "目标码率过低（\(params.videoBitrate / 1000)kbps），无法编码。请适当降低阴间程度。"
        }
        return nil
    }

    /// 实时更新编码安全警告（滑块拖动时调用）
    func updateEncodingWarning() {
        let params = selectedPreset.parameters(for: intensity)
        encodingWarning = validateEncodingParams(params)
    }

    // MARK: - 预估大小

    func recalculateEstimation() {
        updateEncodingWarning()
        schedulePreviewUpdate()

        guard let url = sourceVideoURL else {
            estimatedOutputSize = "未知"
            return
        }

        let asset = AVURLAsset(url: url)
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
                let totalBytes = videoBytes + audioBytes

                await MainActor.run {
                    estimatedOutputSize = formatFileSize(UInt64(totalBytes))
                    guard sourceFileSize > 0 else {
                        compressionRatio = 0
                        return
                    }
                    compressionRatio = Float(totalBytes) / Float(sourceFileSize)
                }
            } catch {
                await MainActor.run {
                    estimatedOutputSize = "无法估算"
                }
            }
        }
    }

    // MARK: - 实时预览

    /// 防抖延迟 0.15s，滑块拖动时避免每帧都跑 CIFilter
    private func schedulePreviewUpdate() {
        guard previewOriginalFrame != nil else { return }
        previewTask?.cancel()
        previewTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)  // 0.15s debounce
            guard !Task.isCancelled else { return }
            await generatePreview()
        }
    }

    private func generatePreview() async {
        guard let original = previewOriginalFrame else { return }
        let params = selectedPreset.parameters(for: intensity)
        let preset = selectedPreset

        // 在后台线程跑 CIFilter
        let degraded = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let ciImage = CIImage(image: original) else { return nil }
            let sourceSize = ciImage.extent.size

            // 复用 FilterChainBuilder 的滤镜逻辑（不含 scanline — 预览不需要）
            let filtered = FilterChainBuilder.applyFilters(
                to: ciImage,
                parameters: params,
                preset: preset,
                scanlineTexture: nil,
                timestamp: Date(),
                sourceSize: sourceSize
            )
            .cropped(to: CGRect(origin: .zero, size: sourceSize))

            // 渲染回 UIImage
            let context = CIContext(options: [.useSoftwareRenderer: false, .cacheIntermediates: false])
            guard let cg = context.createCGImage(filtered, from: filtered.extent) else { return nil }
            return UIImage(cgImage: cg)
        }.value

        await MainActor.run {
            if !Task.isCancelled {
                self.previewDegradedFrame = degraded
            }
        }
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