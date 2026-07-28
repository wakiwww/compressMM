import SwiftUI
import AVKit
import Photos

/// 完成页 — 处理完成后预览、保存、分享
struct PlayerView: View {
    let videoURL: URL
    @ObservedObject var viewModel: ProcessingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var showCheckmark = false
    @State private var showCompare = false
    @State private var saveSuccess = false
    @State private var saveMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // 完成对勾
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(.white)
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            showCheckmark = true
                        }
                    }

                Text("处理完成")
                    .font(.system(size: 22, weight: .medium, design: .default))
                    .foregroundColor(.white)

                // 视频预览
                VideoPlayer(player: player ?? AVPlayer())
                    .frame(height: 240)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#1C1C1C"), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                Spacer()

                // 操作按钮
                VStack(spacing: 12) {
                    // 预览对比
                    Button {
                        showCompare = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.and.right")
                                .font(.system(size: 14))
                            Text("预览对比")
                                .font(.system(size: 15, weight: .medium, design: .default))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 1)
                        )
                    }

                    // 保存到相册
                    Button {
                        saveToPhotoLibrary()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14))
                            Text("保存到相册")
                                .font(.system(size: 17, weight: .semibold, design: .default))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                    }

                    // 分享
                    ShareLink(item: videoURL) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                            Text("分享")
                                .font(.system(size: 15, weight: .medium, design: .default))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)

                // 重新处理（保留视频，回编辑页调整参数）
                Button {
                    viewModel.reprocess()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                        Text("重新处理")
                            .font(.system(size: 15, weight: .medium, design: .default))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                }

                // 再来一个（清空视频，重新导入）
                Button {
                    viewModel.reset()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("再来一个")
                            .font(.system(size: 15, weight: .medium, design: .default))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "#888888"))
                }
                .padding(.top, 4)

                Spacer()
                    .frame(height: 24)
            }
        }
        .onAppear {
            player = AVPlayer(url: videoURL)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(isPresented: $showCompare) {
            ComparePreviewView(
                originalURL: viewModel.sourceVideoURL,
                degradedURL: videoURL
            )
        }
        .alert(saveSuccess ? "已保存" : "保存失败", isPresented: .init(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )) {
            Button("确定", role: .cancel) { saveMessage = nil }
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private func saveToPhotoLibrary() {
        // 强制暂停播放，避免音频在保存后继续播放
        player?.pause()
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                saveSuccess = success
                if success {
                    saveMessage = "视频已保存到相册"
                } else {
                    saveMessage = error?.localizedDescription ?? "保存失败"
                }
            }
        }
    }
}

// MARK: - 对比预览

/// 原始 vs 降质对比预览 — 左右拖动分屏
struct ComparePreviewView: View {
    let originalURL: URL?
    let degradedURL: URL

    @Environment(\.dismiss) private var dismiss
    @State private var sliderPosition: CGFloat = 0.5
    @State private var timePosition: Double = 0
    @State private var videoDuration: Double = 10
    @State private var originalFrame: UIImage?
    @State private var degradedFrame: UIImage?
    @State private var isLoadingFrame = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("对比预览")
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "xmark").font(.system(size: 16)).foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                if originalURL != nil {
                    GeometryReader { geo in
                        ZStack {
                            if let orig = originalFrame {
                                Image(uiImage: orig)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                            } else {
                                Rectangle().fill(Color(hex: "#0A0A0A"))
                            }

                            if let deg = degradedFrame {
                                Image(uiImage: deg)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                                    .mask(
                                        HStack(spacing: 0) {
                                            Rectangle().fill(Color.black)
                                                .frame(width: max(0, geo.size.width * sliderPosition))
                                            Rectangle().fill(Color.clear)
                                        }
                                    )
                            }

                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2)
                                .position(x: geo.size.width * sliderPosition, y: geo.size.height / 2)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "arrow.left.and.right")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.black)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 4)
                                .position(x: geo.size.width * sliderPosition, y: geo.size.height / 2)
                                .gesture(
                                    DragGesture()
                                        .onChanged { v in
                                            sliderPosition = max(0, min(1, v.location.x / geo.size.width))
                                        }
                                )

                            if isLoadingFrame {
                                ProgressView().tint(.white)
                                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                            }
                        }
                    }
                } else {
                    Rectangle().fill(Color(hex: "#0A0A0A"))
                        .overlay(Text("无原始视频").foregroundColor(Color(hex: "#555555")))
                }

                HStack {
                    Text("原始").foregroundColor(.white)
                    Spacer()
                    Text("降质").foregroundColor(.white)
                }
                .font(.system(size: 13, weight: .medium, design: .default))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                VStack(spacing: 4) {
                    Slider(value: $timePosition, in: 0...max(videoDuration, 0.1)) { _ in
                        grabFrames()
                    }
                    .tint(.white)
                    .padding(.horizontal, 20)

                    HStack {
                        Text(formatTime(timePosition))
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(Color(hex: "#888888"))
                        Spacer()
                        Text(formatTime(videoDuration))
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(Color(hex: "#888888"))
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 12)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadDuration { grabFrames() }
        }
    }

    private func loadDuration(completion: @escaping () -> Void) {
        let asset = AVAsset(url: degradedURL)
        Task {
            do {
                let d = try await asset.load(.duration).seconds
                await MainActor.run {
                    videoDuration = d > 0 ? d : 10
                    timePosition = videoDuration / 2
                    completion()
                }
            } catch {
                await MainActor.run { videoDuration = 10; timePosition = 5; completion() }
            }
        }
    }

    private func grabFrames() {
        guard let origURL = originalURL else { return }
        let degURL = degradedURL
        let t = CMTime(seconds: timePosition, preferredTimescale: 600)
        isLoadingFrame = true

        DispatchQueue.global(qos: .userInitiated).async {
            let origGen = AVAssetImageGenerator(asset: AVAsset(url: origURL))
            origGen.appliesPreferredTrackTransform = true
            origGen.requestedTimeToleranceBefore = .zero
            origGen.requestedTimeToleranceAfter = .zero

            let degGen = AVAssetImageGenerator(asset: AVAsset(url: degURL))
            degGen.appliesPreferredTrackTransform = true
            degGen.requestedTimeToleranceBefore = .zero
            degGen.requestedTimeToleranceAfter = .zero

            var oImg: UIImage?, dImg: UIImage?
            if let cg = try? origGen.copyCGImage(at: t, actualTime: nil) { oImg = UIImage(cgImage: cg) }
            if let cg = try? degGen.copyCGImage(at: t, actualTime: nil) { dImg = UIImage(cgImage: cg) }

            DispatchQueue.main.async {
                originalFrame = oImg; degradedFrame = dImg; isLoadingFrame = false
            }
        }
    }

    private func formatTime(_ s: Double) -> String {
        guard s.isFinite else { return "00:00" }
        return String(format: "%02d:%02d", Int(s)/60, Int(s)%60)
    }
}

#Preview {
    PlayerView(
        videoURL: URL(fileURLWithPath: "/tmp/test.mp4"),
        viewModel: ProcessingViewModel()
    )
    .preferredColorScheme(.dark)
}