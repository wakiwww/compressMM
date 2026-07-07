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
    @Published var selectedPreset: VideoPreset = .oldPhone
    @Published var intensity: Float = 50
    @Published var errorMessage: String?
    @Published var showError = false

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
    }
}