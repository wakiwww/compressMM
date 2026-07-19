import Foundation
import SwiftUI
import AVFoundation

extension ProcessingViewModel {
    // MARK: - BGM相关属性

    @Published var selectedBGM: BGM? = nil
    @Published var isBGMEnabled: Bool = true
    @Published var bgmVolume: Float = 0.7
    @Published var bgmLoading: Bool = false
    @Published var bgmError: String?

    private let bgmManager = BGMManager.shared

    /// 初始化时加载可用的BGM
    func initializeBGM() {
        Task {
            await bgmManager.loadAvailableBGM()

            await MainActor.run {
                if let defaultBGM = bgmManager.defaultBGM() {
                    selectedBGM = defaultBGM
                }
            }
        }
    }

    /// 获取所有可用的BGM
    var availableBGM: [BGM] {
        bgmManager.availableBGM
    }

    /// 选择特定的BGM
    func selectBGM(_ bgm: BGM?) {
        selectedBGM = bgm
    }

    /// 切换BGM启用状态
    func toggleBGM() {
        isBGMEnabled = !isBGMEnabled
    }

    /// 开始处理视频（带BGM支持）
    func startProcessingWithBGM() {
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
            }

            do {
                let asset = AVAsset(url: sourceURL)
                let videoDuration = try await asset.load(.duration).seconds

                // 处理BGM（如果启用）
                var bgmURL: URL? = nil
                if isBGMEnabled, let bgm = selectedBGM {
                    await MainActor.run { bgmLoading = true }

                    bgmURL = await bgm.adaptedBGM(for: videoDuration)

                    await MainActor.run { bgmLoading = false }

                    if bgmURL == nil {
                        await MainActor.run {
                            bgmError = "BGM处理失败，将继续处理视频但不添加BGM"
                        }
                    }
                }

                // 处理视频
                let result = await processor.processVideoWithBGM(
                    sourceURL: sourceURL,
                    preset: selectedPreset,
                    intensity: intensity,
                    bgmURL: bgmURL,
                    bgmVolume: isBGMEnabled ? bgmVolume : 0.0
                )

                await MainActor.run {
                    isProcessing = false

                    switch result {
                    case .success(let url):
                        outputURL = url
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    /// 获取视频时长（用于BGM适配显示）
    func getVideoDuration() async -> TimeInterval? {
        guard let sourceURL = sourceVideoURL else { return nil }

        do {
            let asset = AVAsset(url: sourceURL)
            let duration = try await asset.load(.duration).seconds
            return duration.isFinite && duration > 0 ? duration : nil
        } catch {
            return nil
        }
    }

    /// 格式化时长显示
    func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    /// 计算BGM与视频的时长差异
    func calculateBGMVideoDurationDifference() async -> String? {
        guard let sourceURL = sourceVideoURL,
              let selectedBGM = selectedBGM else { return nil }

        do {
            let asset = AVAsset(url: sourceURL)
            let videoDuration = try await asset.load(.duration).seconds

            let bgmDuration = selectedBGM.duration
            let diff = videoDuration - bgmDuration

            if abs(diff) < 0.5 {
                return "时长匹配 ✓"
            } else if diff > 0 {
                // BGM较短，需要循环
                let loopsNeeded = Int(ceil(videoDuration / bgmDuration))
                return "BGM较短，将循环 \(loopsNeeded) 次 (\(formatDuration(abs(diff))) 差)"
            } else {
                // BGM较长，需要裁剪
                return "BGM较长，将自动裁剪 (\(formatDuration(abs(diff))) 差)"
            }
        } catch {
            return nil
        }
    }

    /// 清除BGM相关的临时文件
    func cleanupBGMFiles() {
        let tempDirectory = FileManager.default.temporaryDirectory
        let bgmFiles = ["bgm_cut_", "bgm_loop_"]

        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(
                at: tempDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            for file in tempFiles {
                let fileName = file.lastPathComponent
                if bgmFiles.contains(where: { fileName.hasPrefix($0) }) {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("清理BGM临时文件失败: \(error)")
        }
    }
}