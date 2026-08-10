import Foundation
import AVFoundation

extension AVAsset {
    /// 异步获取视频的自然尺寸（考虑 preferredTransform）
    /// - Note: iOS 16+ 需要使用异步 API
    @available(iOS 16.0, *)
    func naturalSize() async throws -> CGSize {
        let tracks = try await loadTracks(withMediaType: .video)
        guard let track = tracks.first else {
            return .zero
        }

        let size = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        let isPortrait = abs(transform.b) == 1.0 && abs(transform.c) == 1.0
        return isPortrait ? CGSize(width: size.height, height: size.width) : size
    }

    /// 异步获取视频时长（格式化字符串）
    @available(iOS 16.0, *)
    func durationString() async throws -> String {
        let duration = try await load(.duration)
        let seconds = duration.seconds
        if seconds.isNaN || seconds.isInfinite { return "--:--" }
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    /// 异步检查视频时长是否超过限制
    @available(iOS 16.0, *)
    func isLongerThan(seconds limit: Double) async throws -> Bool {
        let duration = try await load(.duration)
        return duration.seconds > limit
    }
}