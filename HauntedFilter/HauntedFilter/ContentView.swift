import SwiftUI
import PhotosUI
import Photos

// MARK: - 导航步骤

enum NavigationStep: Hashable, Identifiable {
    case processing
    case done(URL)

    var id: String {
        switch self {
        case .processing: return "processing"
        case .done: return "done"
        }
    }
}

// MARK: - Hex Color 扩展

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ProcessingViewModel()
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            MainView(
                viewModel: viewModel,
                showPicker: $showPicker
            )
            .navigationDestination(item: $viewModel.navigationStep) { step in
                switch step {
                case .processing:
                    ProcessingProgressView(viewModel: viewModel)
                case .done(let url):
                    PlayerView(videoURL: url, viewModel: viewModel)
                }
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

    private func loadVideoURL(from item: PhotosPickerItem) async throws -> URL? {
        if let url = try? await item.loadTransferable(type: URL.self) {
            return url
        }
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