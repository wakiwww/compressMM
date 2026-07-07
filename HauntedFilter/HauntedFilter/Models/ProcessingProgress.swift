import Foundation

/// 处理进度信息
struct ProcessingProgress {
    let processedFrames: Int
    let totalFrames: Int
    let elapsedTime: TimeInterval

    var fractionCompleted: Double {
        guard totalFrames > 0 else { return 0 }
        return min(1.0, Double(processedFrames) / Double(totalFrames))
    }

    var percentage: Int {
        Int(fractionCompleted * 100)
    }
}