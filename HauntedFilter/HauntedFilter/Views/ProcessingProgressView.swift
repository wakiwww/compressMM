import SwiftUI

/// 处理进度视图
struct ProcessingProgressView: View {
    @ObservedObject var viewModel: ProcessingViewModel

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

#Preview {
    let vm = ProcessingViewModel()
    vm.progress = 0.45
    return ProcessingProgressView(viewModel: vm)
}