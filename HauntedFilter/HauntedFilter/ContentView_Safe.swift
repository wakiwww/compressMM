import SwiftUI
import PhotosUI

/// 安全版本的根视图，避免iOS 27 Beta的内存访问错误
struct ContentView_Safe: View {
    @StateObject private var viewModel = ProcessingViewModel_Safe()
    @State private var showPicker = false
    @State private var navigateToPlayer = false
    @State private var navigateToProgress = false
    @State private var appLoaded = false

    var body: some View {
        NavigationStack {
            Group {
                if !appLoaded {
                    // 启动加载视图（提供更长的延迟让初始化完成）
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text("应用启动中...")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("安全模式初始化")
                            .font(.caption2)
                            .foregroundColor(.blue.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .onAppear {
                        print("🛡️ ContentView_Safe: 应用启动中 (安全模式)...")
                        print("📱 使用安全组件以避免内存访问错误")
                        // 给初始化更多时间，避免竞争条件
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            appLoaded = true
                            print("✅ ContentView_Safe: 应用加载完成")
                        }
                    }
                } else {
                    // 使用安全版本的主界面
                    MainView_Safe(
                        viewModel: viewModel,
                        showPicker: $showPicker,
                        navigateToPlayer: $navigateToPlayer,
                        navigateToProgress: $navigateToProgress
                    )
                }
            }
            .navigationDestination(isPresented: $navigateToPlayer) {
                if let outputURL = viewModel.outputURL {
                    // 使用简化的播放器（如果需要，可以稍后创建安全版本）
                    SimplePlayerView(videoURL: outputURL, viewModel: viewModel)
                }
            }
            .navigationDestination(isPresented: $navigateToProgress) {
                SimpleProcessingProgressView(viewModel: viewModel)
            }
            .photosPicker(
                isPresented: $showPicker,
                selection: $viewModel.selectedItem,
                matching: .videos,
                photoLibrary: .shared()
            )
            .onChange(of: viewModel.selectedItem) { newItem in
                guard let newItem else { return }
                print("📹 选择了新的视频项目")

                Task {
                    // 使用安全的数据转换方法
                    do {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            print("📊 视频数据加载成功，大小: \(formatBytes(data.count))")
                            if let url = saveVideoDataToTemp(data) {
                                print("✅ 视频保存到临时文件: \(url.lastPathComponent)")
                                viewModel.didSelectVideo(url: url)
                            } else {
                                print("❌ 无法保存视频到临时文件")
                            }
                        } else {
                            print("❌ 无法加载视频数据")
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveVideoDataToTemp(_ data: Data) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        print("💾 尝试保存数据到: \(tempURL.lastPathComponent)")

        do {
            try data.write(to: tempURL)

            // 验证写入成功
            let fileSize = try FileManager.default.attributesOfItem(atPath: tempURL.path)[.size] as? Int64 ?? 0
            print("✅ 文件保存成功，大小: \(formatBytes(Int(fileSize)))")

            return tempURL
        } catch {
            print("❌ 保存失败: \(error.localizedDescription)")
            return nil
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}

// MARK: - 简化播放器视图

struct SimplePlayerView: View {
    let videoURL: URL
    @ObservedObject var viewModel: ProcessingViewModel_Safe
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("处理完成")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.top)

            // 简单的文件信息
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("视频已保存")
                        .foregroundColor(.white)
                    Spacer()
                }

                // 文件信息
                if let fileSize = getFileSize() {
                    Text("文件大小: \(fileSize)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text("路径: \(videoURL.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            // 基本操作按钮
            VStack(spacing: 12) {
                Button {
                    exportToPhotoLibrary()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("保存到相册")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(12)
                }

                ShareLink(item: videoURL) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("分享视频")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }

                Button {
                    dismiss()
                    viewModel.outputURL = nil
                } label: {
                    Text("重新处理")
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("完成")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func getFileSize() -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: videoURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                return formatBytes(Int(fileSize))
            }
        } catch {
            print("无法获取文件大小: \(error)")
        }
        return nil
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    private func exportToPhotoLibrary() {
        print("导出视频到相册: \(videoURL.lastPathComponent)")
        // 这里需要实现实际的导出逻辑
        // 暂时只打印日志
    }
}

// MARK: - 简化处理进度视图

struct SimpleProcessingProgressView: View {
    @ObservedObject var viewModel: ProcessingViewModel_Safe

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 进度圆圈
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.progress))
                    .stroke(Color.red.opacity(0.8), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)

                Text("\(Int(viewModel.progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("正在处理视频...")
                    .font(.headline)
                    .foregroundColor(.white)

                ProgressView(value: viewModel.progress)
                    .tint(.red.opacity(0.7))
                    .padding(.horizontal, 40)

                Text("安全模式处理中")
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.8))

                Text("请稍候，不要退出此页面")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // 取消按钮
            Button(role: .destructive) {
                viewModel.cancelProcessing()
            } label: {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("取消处理")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("处理中")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

#if DEBUG
struct ContentView_Safe_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_Safe()
    }
}
#endif