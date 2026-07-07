import Foundation
import AVFoundation

extension AVAsset {
    /// 视频的自然尺寸（考虑 preferredTransform）
    var naturalSize: CGSize {
        guard let track = tracks(withMediaType: .video).first else {
            return .zero
        }
        let size = track.naturalSize
        let transform = track.preferredTransform
        let isPortrait = abs(transform.b) == 1.0 && abs(transform.c) == 1.0
        return isPortrait ? CGSize(width: size.height, height: size.width) : size
    }

    /// 视频时长（格式化字符串）
    var durationString: String {
        let seconds = duration.seconds
        if seconds.isNaN || seconds.isInfinite { return "--:--" }
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    /// 视频时长是否超过限制
    func isLongerThan(seconds limit: Double) -> Bool {
        return duration.seconds > limit
    }
}