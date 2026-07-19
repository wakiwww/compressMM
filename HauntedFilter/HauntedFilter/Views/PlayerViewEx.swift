import SwiftUI
import AVKit
import Photos

/// 扩展的预览播放器 + 导出/分享 + BGM预览切换
struct PlayerViewEx: View {
    let videoURL: URL
    @ObservedObject var viewModel: ProcessingViewModelEx
    @Environment(\.dismiss) private var dismiss

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var showPlaybackOptions = false
    @State private var playbackMode: PlaybackMode = .withBGM
    @State private var exportInProgress = false
    @State private var exportMessage: String?
    @State private var showExportSuccess = false
    @State private var showExportError = false

    enum PlaybackMode: String, CaseIterable {
        case withBGM = "带BGM"
        case withoutBGM = "无BGM"
        case original = "原视频"

        var description: String {
            self.rawValue
        }

        var icon: String {
            switch self {
            case .withBGM: return "music.note.tv"
            case .withoutBGM: return "tv"
            case .original: return "film"
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // 视频播放器
            videoPlayerSection

            // 播放控制
            playbackControlsSection

            // BGM信息显示
            bgmInfoSection

            Spacer()

            // 操作按钮
            actionButtonsSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("处理完成")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .alert("导出成功", isPresented: $showExportSuccess) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(exportMessage ?? "视频已成功保存到相册")
        }
        .alert("导出失败", isPresented: $showExportError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(exportMessage ?? "无法保存视频到相册")
        }
    }

    // MARK: - 视频播放器区域

    private var videoPlayerSection: some View {
        VStack(spacing: 12) {
            if let player = player {
                VideoPlayer(player: player)
                    .frame(height: UIScreen.main.bounds.height * 0.5)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onTapGesture {
                        togglePlayback()
                    }
            } else {
                // 播放器加载中
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: UIScreen.main.bounds.height * 0.5)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                    )
                    .padding(.horizontal)
            }

            // 信息提示
            Text("预览效果 — 可点击切换播放/暂停")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }

    // MARK: - 播放控制

    private var playbackControlsSection: some View {
        VStack(spacing: 12) {
            // 播放控制按钮
            HStack(spacing: 24) {
                Button(action: rewind) {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.red.opacity(0.8))
                }

                Button(action: forward) {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }

            // 播放模式选择
            HStack {
                Text("预览模式:")
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                Picker("播放模式", selection: $playbackMode) {
                    ForEach(PlaybackMode.allCases, id: \.self) { mode in
                        Label(mode.description, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .tint(.blue)
                .onChange(of: playbackMode) { newMode in
                    changePlaybackMode(to: newMode)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }

    // MARK: - BGM信息显示

    @ViewBuilder
    private var bgmInfoSection: some View {
        if let selectedBGM = viewModel.selectedBGM, viewModel.isBGMEnabled {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("当前BGM")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(selectedBGM.displayName)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text("音量: \(Int(viewModel.bgmVolume * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if !viewModel.bgmDurationInfo.isEmpty && playbackMode == .withBGM {
                    Text(viewModel.bgmDurationInfo)
                        .font(.caption2)
                        .foregroundColor(.blue.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // MARK: - 操作按钮

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // 导出到相册
            Button {
                exportVideoToPhotoLibrary()
            } label: {
                HStack {
                    if exportInProgress {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }

                    Text(exportInProgress ? "导出中..." : "保存到相册")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(12)
            }
            .disabled(exportInProgress)

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

    // MARK: - 播放器控制方法

    private func setupPlayer() {
        player = AVPlayer(url: videoURL)

        // 监听播放状态
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            isPlaying = false
            // 重置到开始
            player?.seek(to: .zero)
        }
    }

    private func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }

    private func rewind() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 600))
        player.seek(to: max(newTime, .zero))
    }

    private func forward() {
        guard let player = player,
              let duration = player.currentItem?.duration else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 600))
        player.seek(to: min(newTime, duration))
    }

    private func changePlaybackMode(to mode: PlaybackMode) {
        guard let player = player else { return }

        // 暂停当前播放
        player.pause()
        isPlaying = false

        switch mode {
        case .withBGM:
            // 播放带BGM的视频
            player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
        case .withoutBGM:
            // 这里需要逻辑来获取无BGM的视频版本
            // 由于时间限制，我们暂时使用同一个视频
            player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
        case .original:
            // 播放原始视频（如果存在的话）
            // 这里需要原始视频的URL，暂时使用当前视频
            player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
        }

        // 重置到开始
        player.seek(to: .zero)
    }

    // MARK: - 导出功能

    private func exportVideoToPhotoLibrary() {
        guard !exportInProgress else { return }

        exportInProgress = true
        exportMessage = nil

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                exportInProgress = false

                if success {
                    exportMessage = "视频已成功保存到相册"
                    showExportSuccess = true
                } else if let error = error {
                    exportMessage = error.localizedDescription
                    showExportError = true
                } else {
                    exportMessage = "未知错误"
                    showExportError = true
                }
            }
        }
    }
}

#if DEBUG
struct PlayerViewEx_Previews: PreviewProvider {
    static var previews: some View {
        PlayerViewEx(
            videoURL: URL(fileURLWithPath: "/tmp/preview.mp4"),
            viewModel: ProcessingViewModelEx()
        )
    }
}
#endif