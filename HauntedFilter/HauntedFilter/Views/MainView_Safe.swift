import SwiftUI
import PhotosUI

/// 安全版本的主页：简化UI，避免可能的复杂交互导致崩溃
struct MainView_Safe: View {
    @ObservedObject var viewModel: ProcessingViewModel_Safe
    @Binding var showPicker: Bool
    @Binding var navigateToPlayer: Bool
    @Binding var navigateToProgress: Bool

    @State private var showAdvancedOptions = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 简化标题区
                titleSection

                // 简化导入区
                importSection

                // 基本预设选择
                presetSection

                // 基础滑块
                intensitySection

                // 高级选项（可选）
                if showAdvancedOptions {
                    advancedOptionsSection
                }

                // 基本估计信息
                estimatedSizeSection

                // 处理按钮
                processButton

                // 调试选项
                debugOptions
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("阴间录像")
        .navigationBarTitleDisplayMode(.inline)
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        .onChange(of: viewModel.isProcessing) { newValue in
            if newValue {
                navigateToProgress = true
            }
        }
        .onChange(of: viewModel.outputURL) { newValue in
            if newValue != nil {
                navigateToPlayer = true
            }
        }
        .onChange(of: viewModel.intensity) { _ in
            updateWarning()
        }
        .onChange(of: viewModel.selectedPreset) { _ in
            updateWarning()
        }
    }

    // MARK: - 更新提示状态

    private func updateWarning() {
        viewModel.recalculateEstimation()
        if viewModel.checkOverCompression() {
            viewModel.alertMessage = viewModel.generateAlertMessage()
            viewModel.showOverCompressionAlert = true
        } else {
            viewModel.showOverCompressionAlert = false
        }
    }

    // MARK: - 标题区（简化）

    private var titleSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "film.stack")
                .font(.system(size: 40))
                .foregroundStyle(.red.opacity(0.8))

            Text("阴间录像")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("简单视频处理")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.top, 16)
    }

    // MARK: - 导入区（简化）

    private var importSection: some View {
        VStack(spacing: 12) {
            if viewModel.sourceVideoURL != nil {
                // 已选择视频 - 简单显示
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("视频已准备")
                        .foregroundColor(.white)
                    Spacer()
                    Button("重新选择") {
                        viewModel.reset()
                        showPicker = true
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            } else {
                // 未选择 - 简单按钮
                Button {
                    showPicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.square")
                        Text("选择视频")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - 预设选择（简化）

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("滤镜预设")
                .font(.headline)
                .foregroundColor(.white)

            // 简化：使用Picker而不是滚动卡片
            Picker("预设", selection: $viewModel.selectedPreset) {
                ForEach(VideoPreset.allCases) { preset in
                    Text(preset.id.capitalized)
                        .tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
    }

    // MARK: - 强度滑块（简化）

    private var intensitySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("效果强度")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(viewModel.intensity))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.red.opacity(0.8))
            }

            Slider(value: $viewModel.intensity, in: 0...100, step: 5)
                .tint(.red.opacity(0.7))

            HStack {
                Text("弱")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Button("恢复默认") {
                    withAnimation {
                        viewModel.intensity = 50
                    }
                }
                .font(.caption2)
                .foregroundColor(.orange)
                Spacer()
                Text("强")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.6))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }

    // MARK: - 高级选项（可折叠）

    private var advancedOptionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("高级选项")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    showAdvancedOptions = false
                } label: {
                    Image(systemName: "chevron.up")
                        .foregroundColor(.gray)
                }
            }

            // 这里可以添加高级选项，比如降噪级别等
            Text("当前使用安全处理模式")
                .font(.caption)
                .foregroundColor(.gray)

            Text("优化了iOS 27 Beta兼容性")
                .font(.caption)
                .foregroundColor(.green.opacity(0.8))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - 预计输出大小（简化）

    @ViewBuilder
    private var estimatedSizeSection: some View {
        if viewModel.sourceVideoURL != nil {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text("预计大小")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(viewModel.estimatedOutputSize)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }

                if viewModel.compressionRatio > 0 {
                    // 简单的压缩指示器
                    HStack {
                        Text("原始: \(viewModel.sourceFileSizeFormatted)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("压缩: \(Int((1 - viewModel.compressionRatio) * 100))%")
                            .font(.caption2)
                            .foregroundColor(
                                viewModel.compressionRatio < 0.1 ? .red : .gray
                            )
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.15))
            .cornerRadius(12)
        }
    }

    // MARK: - 处理按钮

    private var processButton: some View {
        Button {
            viewModel.startProcessing()
        } label: {
            HStack {
                if viewModel.isProcessing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                    Text("处理中...")
                        .fontWeight(.semibold)
                } else {
                    Image(systemName: "play.circle.fill")
                    Text("开始处理")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.sourceVideoURL != nil && !viewModel.isProcessing
                    ? Color.red.opacity(0.7)
                    : Color.gray.opacity(0.3)
            )
            .cornerRadius(14)
        }
        .disabled(viewModel.sourceVideoURL == nil || viewModel.isProcessing)
        .padding(.top, 16)
    }

    // MARK: - 调试选项

    private var debugOptions: some View {
        VStack(spacing: 8) {
            Button("显示高级选项") {
                showAdvancedOptions = true
            }
            .font(.caption)
            .foregroundColor(.blue)

            Button("重置所有设置") {
                viewModel.reset()
            }
            .font(.caption)
            .foregroundColor(.orange)

            Text("安全模式 v1.0")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.top, 8)
    }
}

#if DEBUG
struct MainView_Safe_Previews: PreviewProvider {
    static var previews: some View {
        MainView_Safe(
            viewModel: ProcessingViewModel_Safe(),
            showPicker: .constant(false),
            navigateToPlayer: .constant(false),
            navigateToProgress: .constant(false)
        )
    }
}
#endif