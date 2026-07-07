import SwiftUI
import PhotosUI

/// 主页：导入按钮 + 预设选择 + 滑块
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
                Text("轻微")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("阴间")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.6))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }

    // MARK: - 处理按钮

    private var processButton: some View {
        Button {
            viewModel.startProcessing()
        } label: {
            HStack {
                Image(systemName: "film.badge.magnifyingglass")
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