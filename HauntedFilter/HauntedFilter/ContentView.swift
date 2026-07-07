import SwiftUI
import PhotosUI

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
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let url = saveVideoDataToTemp(data) {
                        viewModel.sourceVideoURL = url
                    }
                }
            }
        }
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