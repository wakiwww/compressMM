import Foundation

/// BGM处理错误
enum BGMError: LocalizedError {
    case cutFailed
    case loopFailed
    case exportFailed
    case invalidURL
    case audioTrackNotFound
    case invalidDuration
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .cutFailed:
            return "BGM裁剪失败"
        case .loopFailed:
            return "BGM循环处理失败"
        case .exportFailed:
            return "BGM导出失败"
        case .invalidURL:
            return "BGM文件路径无效"
        case .audioTrackNotFound:
            return "未找到音频轨道"
        case .invalidDuration:
            return "时长无效"
        case .unsupportedFormat:
            return "不支持的音频格式"
        }
    }
}