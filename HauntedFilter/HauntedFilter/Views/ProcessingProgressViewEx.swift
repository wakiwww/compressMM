import SwiftUI

/// 处理进度视图（扩展版本）
struct ProcessingProgressViewEx: View {
    @ObservedObject var viewModel: ProcessingViewModelEx

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 加载动画
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

                VStack(spacing: 4) {
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    if viewModel.bgmLoading {
                        Text("BGM处理中")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            VStack(spacing: 12) {
                if viewModel.bgmLoading {
                    Text("正在处理背景音乐...")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("正在适配BGM时长...")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("正在处理视频...")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                ProgressView(value: viewModel.progress)
                    .tint(viewModel.bgmLoading ? Color.blue.opacity(0.7) : Color.red.opacity(0.7))
                    .padding(.horizontal, 40)

                Text(viewModel.bgmLoading ? "BGM处理中，请稍候..." : "请稍候，不要退出此页面")
                    .font(.caption)
                    .foregroundColor(.gray)

                // BGM处理状态
                if let bgm = viewModel.selectedBGM, viewModel.isBGMEnabled {
                    HStack(spacing: 6) {
                        Image(systemName: "music.note")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("将添加: \(bgm.displayName)")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
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
struct ProcessingProgressViewEx_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ProcessingViewModelEx()
        vm.progress = 0.45
        vm.bgmLoading = true
        return ProcessingProgressViewEx(viewModel: vm)
    }
}
#endif