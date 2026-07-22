import SwiftUI
import AVKit
import Photos

/// 预览播放器 + 导出/分享
struct PlayerView: View {
    let videoURL: URL
    @ObservedObject var viewModel: ProcessingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            // 播放器
            VideoPlayer(player: AVPlayer(url: videoURL))
                .frame(maxHeight: 400)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)

            // 信息提示
            Text("预览效果 — 可拖动进度条查看\"阴间\"质感")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()

            // 操作按钮
            VStack(spacing: 12) {
                // 导出到相册
                Button {
                    exportVideoToPhotoLibrary()
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

                // 分享
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

                // 重新处理
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
        .navigationTitle("处理完成")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func exportVideoToPhotoLibrary() {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    // 可以显示一个 toast
                    print("导出成功")
                } else if let error {
                    print("导出失败: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    PlayerView(
        videoURL: URL(fileURLWithPath: "/tmp/preview.mp4"),
        viewModel: ProcessingViewModel()
    )
}