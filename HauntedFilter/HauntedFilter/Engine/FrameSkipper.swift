import Foundation
import CoreMedia

/// 帧率控制：决定哪些帧写入输出
struct FrameSkipper {
    let sourceFrameRate: Double
    let targetFrameRate: Double
    var accumulatedTime: Double = 0
    var wroteFirstFrame = false

    /// 基于 presentationTimeStamp 的精确帧跳过
    /// 返回 true 表示当前帧应该写入输出
    mutating func shouldWriteFrame(at presentationTimeStamp: CMTime) -> Bool {
        guard targetFrameRate > 0, targetFrameRate < sourceFrameRate else {
            return true // 不降帧率
        }

        let currentTime = presentationTimeStamp.seconds

        // 第一帧总是写入
        guard wroteFirstFrame else {
            wroteFirstFrame = true
            accumulatedTime = currentTime
            return true
        }

        let frameInterval = 1.0 / targetFrameRate
        let elapsed = currentTime - accumulatedTime

        if elapsed >= frameInterval {
            // 跳过中间帧，写入当前帧
            accumulatedTime = currentTime
            return true
        }

        return false
    }
}