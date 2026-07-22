import SwiftUI
import PhotosUI
import Photos

struct ContentView: View {
    @StateObject private var viewModel = ProcessingViewModel()
    @State private var showPicker = false
    @State private var navigateToPlayer = false
    @State private var navigateToProgress = false

    var body: some View {
        NavigationStack {
            MainView(
                viewModel: viewModel,
                showPicker: $showPicker,
                navigateToPlayer: $navigateToPlayer,
                navigateToProgress: $navigateToProgress
            )
            .navigationDestination(isPresented: $navigateToPlayer) {
                if let outputURL = viewModel.outputURL {
                    PlayerView(videoURL: outputURL, viewModel: viewModel)
                }
            }
            .navigationDestination(isPresented: $navigateToProgress) {
                ProcessingProgressView(viewModel: viewModel)
            }
            .photosPicker(
                isPresented: $showPicker,
                selection: $viewModel.selectedItem,
                matching: .videos,
                photoLibrary: .shared()
            )
            .onChange(of: viewModel.selectedItem) { newItem in
                guard let newItem else { return }
                Task {
                    // 使用 loadTransferable(type: URL.self) 直接获取文件 URL，
                    // 避免把整个视频 Data 读入内存导致 OOM 闪退
                    do {
                        guard let url = try await loadVideoURL(from: newItem) else { return }
                        await MainActor.run {
                            viewModel.didSelectVideo(url: url)
                        }
                    } catch {
                        print("视频加载失败: \(error)")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - 视频 URL 加载（零拷贝，不把视频读入内存）

    private func loadVideoURL(from item: PhotosPickerItem) async throws -> URL? {
        // 优先用 URL 类型直接拿路径（iOS 16+ Photos framework 支持）
        if let url = try? await item.loadTransferable(type: URL.self) {
            // Photos 返回的是临时沙盒 URL，直接可用
            return url
        }

        // Fallback：用 Data 类型但做流式写入（兼容旧系统）
        // 注意：仅在 URL 方式失败时走此路径
        guard let data = try await item.loadTransferable(type: Data.self) else {
            return nil
        }
        return saveVideoDataToTemp(data)
    }

    private func saveVideoDataToTemp(_ data: Data) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save video data: \(error)")
            return nil
        }
    }
}

#Preview {
    ContentView()
}