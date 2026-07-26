import SwiftUI
import PhotosUI

/// 主页：导入按钮 + 预设选择 + 滑块 + 预估大小 + 智能提示
struct MainView: View {
    @ObservedObject var viewModel: ProcessingViewModel
    @Binding var showPicker: Bool
    @Binding var navigateToPlayer: Bool
    @Binding var navigateToProgress: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题区
                titleSection

                // 视频导入区
                importSection

                // 预设选择
                presetSection

                // 强度滑块
                intensitySection

                // 预计输出大小
                estimatedSizeSection

                // 过度压缩提示（非打断式）
                compressionWarningHint

                // 处理按钮
                processButton
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

    // MARK: - 标题区

    private var titleSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundStyle(.red.opacity(0.8))

            Text("阴间录像滤镜")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("导入视频 → 选择预设 → 一键生成复古失真质感")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.top, 16)
    }

    // MARK: - 导入区

    private var importSection: some View {
        VStack(spacing: 12) {
            if viewModel.sourceVideoURL != nil {
                // 已选择视频
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("视频已导入")
                        .foregroundColor(.white)
                    Spacer()
                    Text(viewModel.sourceFileSizeFormatted)
                        .font(.caption)
                        .foregroundColor(.gray)
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
                // 未选择 - 导入按钮
                Button {
                    showPicker = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.viewfinder")
                            .font(.system(size: 40))
                        Text("点击导入视频")
                            .font(.headline)
                        Text("支持最长 60 秒视频")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(.gray.opacity(0.5))
                    )
                }
            }
        }
    }

    // MARK: - 预设选择

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择预设")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(VideoPreset.allCases) { preset in
                        PresetCardView(
                            preset: preset,
                            isSelected: viewModel.selectedPreset == preset
                        )
                        .onTapGesture {
                            viewModel.selectedPreset = preset
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - 强度滑块

    private var intensitySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("阴间程度")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(viewModel.intensity))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.red.opacity(0.8))
            }

            Slider(value: $viewModel.intensity, in: 0...100, step: 1)
                .tint(.red.opacity(0.7))

            HStack {
                Text("原片")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()

                // 推荐压缩量按钮
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.intensity = viewModel.selectedPreset.recommendedIntensity
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                            .font(.caption2)
                        Text("推荐压缩量")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }

                Text("像素块")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.6))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }

    // MARK: - 预计输出大小

    @ViewBuilder
    private var estimatedSizeSection: some View {
        if viewModel.sourceVideoURL != nil {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.doc")
                        .foregroundColor(.orange)
                    Text("预计输出大小")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(viewModel.estimatedOutputSize)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }

                if viewModel.compressionRatio > 0 {
                    // 压缩进度条
                    ProgressView(
                        value: Double(viewModel.compressionRatio),
                        total: 1.0
                    )
                    .tint(viewModel.compressionRatio < 0.1 ? .red : .orange)

                    HStack {
                        Text("原始: \(viewModel.sourceFileSizeFormatted)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int((1 - viewModel.compressionRatio) * 100))% 压缩")
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

    // MARK: - 过度压缩提示（不打断操作）

    @ViewBuilder
    private var compressionWarningHint: some View {
        if viewModel.sourceVideoURL != nil && viewModel.showOverCompressionAlert {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)

                Text(viewModel.alertMessage)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.red.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.yellow.opacity(0.4), lineWidth: 0.5)
                    )
            )
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: - 处理按钮

    private var processButton: some View {
        Button {
            viewModel.startProcessing()
        } label: {
            HStack {
                Image(systemName: "film.fill")
                Text("开始处理")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.sourceVideoURL != nil
                    ? Color.red.opacity(0.7)
                    : Color.gray.opacity(0.3)
            )
            .cornerRadius(14)
        }
        .disabled(viewModel.sourceVideoURL == nil)
        .padding(.top, 8)
    }
}

#Preview {
    MainView(
        viewModel: ProcessingViewModel(),
        showPicker: .constant(false),
        navigateToPlayer: .constant(false),
        navigateToProgress: .constant(false)
    )
}