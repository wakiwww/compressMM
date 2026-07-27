import SwiftUI

/// 处理进度视图 — 极简黑白科技感
struct ProcessingProgressView: View {
    @ObservedObject var viewModel: ProcessingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var ellipsis = ""

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // 进度条（细线风格 2pt）
                VStack(spacing: 20) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "#1C1C1C"))
                                .frame(height: 2)

                            Rectangle()
                                .fill(Color.white)
                                .frame(width: max(0, CGFloat(viewModel.progress) * geo.size.width), height: 2)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                        }
                    }
                    .frame(height: 2)
                    .padding(.horizontal, 40)

                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.system(size: 32, weight: .thin, design: .default))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("正在降质中\(ellipsis)")
                        .font(.system(size: 17, weight: .medium, design: .default))
                        .foregroundColor(.white)
                        .onReceive(timer) { _ in
                            switch ellipsis.count {
                            case 0: ellipsis = "."
                            case 1: ellipsis = ".."
                            case 2: ellipsis = "..."
                            default: ellipsis = ""
                            }
                        }

                    Text("\(viewModel.selectedPreset.englishName) 模式")
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(hex: "#888888"))
                }

                Text("预计剩余 \(estimatedTimeRemaining)")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#888888"))

                Spacer()

                // 取消按钮
                Button {
                    viewModel.cancelProcessing()
                    dismiss()
                } label: {
                    Text("取消")
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundColor(Color(hex: "#888888"))
                }
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.outputURL) { url in
            if url != nil {
                DispatchQueue.main.async {
                    dismiss()
                }
            }
        }
    }

    private var estimatedTimeRemaining: String {
        guard viewModel.progress > 0.01 else { return "-- 秒" }
        let remaining = (1.0 - viewModel.progress) / viewModel.progress * 5 // rough estimate
        return "\(max(1, Int(remaining))) 秒"
    }
}

#Preview {
    let vm = ProcessingViewModel()
    vm.progress = 0.45
    return ProcessingProgressView(viewModel: vm)
        .preferredColorScheme(.dark)
}