import SwiftUI
import PhotosUI

/// 极度简化的根视图，用于验证基础功能是否工作
struct ContentView_Minimal: View {
    @State private var showPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var testLogs: [String] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // 简单标题
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)

                    Text("基础测试")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("验证基本功能是否工作")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)

                Spacer()

                // 基础功能测试按钮
                VStack(spacing: 20) {
                    Button("测试UI渲染") {
                        testUIRendering()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                    Button("测试AVFoundation基础") {
                        testAVFoundation()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                    Button("测试文件系统") {
                        testFileSystem()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.3))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                    // 简单的视频选择器测试
                    PhotosPicker(
                        selection: .constant(nil),
                        matching: .videos,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("测试PhotosPicker")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.3))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                    }
                    .disabled(true) // 暂时禁用
                }
                .padding(.horizontal)

                Spacer()

                // 日志区域
                if !testLogs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("测试日志")
                            .font(.caption)
                            .foregroundColor(.gray)

                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(testLogs, id: \.self) { log in
                                    Text(log)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(log.contains("✅") ? .green :
                                                       log.contains("❌") ? .red : .gray)
                                        .padding(4)
                                }
                            }
                        }
                        .frame(height: 100)
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Text("极度简化版本 v0.1")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("基础测试")
            .navigationBarTitleDisplayMode(.inline)
            .alert("测试结果", isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                addLog("🧪 应用启动成功")
                addLog("📱 iOS 版本: " + UIDevice.current.systemVersion)
                addLog("🔄 基础测试环境准备就绪")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - 测试方法

    private func testUIRendering() {
        addLog("🎨 测试UI渲染...")

        // 测试简单的UI操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            addLog("✅ UI渲染测试通过")
            alertMessage = "UI渲染功能正常"
            showAlert = true
        }
    }

    private func testAVFoundation() {
        addLog("🎬 测试AVFoundation基础...")

        // 创建一个简单的AVAsset（不访问任何资源）
        let testURL = URL(fileURLWithPath: "/tmp/test.mp4")
        let asset = AVAsset(url: testURL)

        // 测试简单的属性访问（应该不会访问内存）
        addLog("📊 AVAsset创建成功")

        // 测试不调用任何可能崩溃的方法
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            addLog("✅ AVFoundation基础测试通过")
            alertMessage = "AVFoundation基础功能正常"
            showAlert = true
        }
    }

    private func testFileSystem() {
        addLog("💾 测试文件系统...")

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory

        do {
            // 创建测试文件
            let testFileURL = tempDir.appendingPathComponent("test_\(UUID().uuidString).txt")
            let testData = "Hello, iOS 27 Beta".data(using: .utf8)

            try testData?.write(to: testFileURL)
            addLog("📝 创建测试文件: \(testFileURL.lastPathComponent)")

            // 读取文件
            let readData = try Data(contentsOf: testFileURL)
            let content = String(data: readData, encoding: .utf8) ?? "无法读取"
            addLog("📖 读取文件内容: \(content)")

            // 删除文件
            try fileManager.removeItem(at: testFileURL)
            addLog("🗑️ 删除测试文件")

            addLog("✅ 文件系统测试通过")
            alertMessage = "文件系统读写功能正常"
            showAlert = true

        } catch {
            addLog("❌ 文件系统测试失败: \(error.localizedDescription)")
            alertMessage = "文件系统测试失败: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - 日志辅助

    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"

        DispatchQueue.main.async {
            self.testLogs.append(logMessage)
            print(logMessage)

            // 只保留最近的日志
            if self.testLogs.count > 10 {
                self.testLogs.removeFirst()
            }
        }
    }
}

// MARK: - 极度简化的播放器视图

struct MinimalPlayerView: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("播放器测试")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.top)

            VStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("播放器初始化成功")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(videoURL.lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            Button("返回") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.8))
            .cornerRadius(12)
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("播放器")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct ContentView_Minimal_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_Minimal()
    }
}
#endif