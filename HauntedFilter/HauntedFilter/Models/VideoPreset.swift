import Foundation

/// 视频降质模式 — 3 种风格
enum VideoPreset: String, CaseIterable, Identifiable {
    case egg       // 鸡蛋 — 极低帧率马赛克，保留原色
    case rain      // 雨夜骑行男 — 满帧极端马赛克，不碰色彩，音频削低频
    case netease   // 岡易云vip — 音视频全损，双管齐下

    var id: String { rawValue }

    // MARK: - 显示信息

    var displayName: String {
        switch self {
        case .egg:     return "鸡蛋"
        case .rain:    return "雨夜骑行男"
        case .netease: return "岡易云vip"
        }
    }

    var englishName: String {
        switch self {
        case .egg:     return "EGG"
        case .rain:    return "RAIN"
        case .netease: return "NETEASE"
        }
    }

    var subtitle: String {
        switch self {
        case .egg:     return "3fps · 肉眼可见马赛克 · 保留原色"
        case .rain:    return "10fps · 极端像素化 · 冷灰调 · 高频刺耳"
        case .netease: return "音质全损 · 视频全损 · 双管齐下"
        }
    }

    var iconName: String {
        switch self {
        case .egg:     return "circle.grid.3x3.fill"
        case .rain:    return "cloud.rain.fill"
        case .netease: return "music.note.list"
        }
    }

    /// 原汁原味压缩量 — 一键出效果
    var sweetSpotIntensity: Float {
        switch self {
        case .egg:     return 50
        case .rain:    return 55
        case .netease: return 50
        }
    }

    // MARK: - 参数定义

    /// 基线（0%）：极轻微效果
    var baselineParameters: ProcessingParameters {
        ProcessingParameters(
            targetWidth: 640, targetFrameRate: 24, videoBitrate: 2_000_000,
            saturation: 1.0, contrast: 1.0, brightness: 0,
            noiseIntensity: 0, chromaShiftPixels: 0, scanlineAlpha: 0,
            audioLowFreq: 20, audioHighFreq: 20000, audioSampleRate: 44100, backgroundNoiseLevel: 0
        )
    }

    /// 中档（50%）：原汁原味效果
    var lowParameters: ProcessingParameters {
        switch self {
        case .egg:
            // 3fps + 100px 缩放 = 肉眼可见大块马赛克，保留原色
            // 音频：电话音质
            return ProcessingParameters(
                targetWidth: 100, targetFrameRate: 3, videoBitrate: 300_000,
                saturation: 1.0, contrast: 1.0, brightness: 0,
                noiseIntensity: 0.12, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 400, audioHighFreq: 3500, audioSampleRate: 11025, backgroundNoiseLevel: 0.15
            )
        case .rain:
            // 30fps 满帧，70px 缩放 → 不可辨认的像素块
            // 冷灰调：饱和度略降 + 色温偏冷；音频：高频拉爆刺耳失真
            return ProcessingParameters(
                targetWidth: 70, targetFrameRate: 10, videoBitrate: 400_000,
                saturation: 0.75, contrast: 1.05, brightness: -0.02,
                noiseIntensity: 0.45, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 1500, audioHighFreq: 5000, audioSampleRate: 8000, backgroundNoiseLevel: 0.45
            )
        case .netease:
            // 音视频全损：视频马赛克 + 音频烂到几乎听不清
            return ProcessingParameters(
                targetWidth: 110, targetFrameRate: 5, videoBitrate: 250_000,
                saturation: 0.35, contrast: 1.5, brightness: -0.06,
                noiseIntensity: 0.5, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 600, audioHighFreq: 2500, audioSampleRate: 8000, backgroundNoiseLevel: 0.45
            )
        }
    }

    /// 高档（100%）：拉满效果，编码安全
    var highParameters: ProcessingParameters {
        switch self {
        case .egg:
            // 极致大块马赛克，原色不动，音频极度压缩
            return ProcessingParameters(
                targetWidth: 40, targetFrameRate: 3, videoBitrate: 120_000,
                saturation: 1.0, contrast: 1.05, brightness: 0,
                noiseIntensity: 0.25, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 500, audioHighFreq: 2500, audioSampleRate: 8000, backgroundNoiseLevel: 0.25
            )
        case .rain:
            // 拉到纯色块 + 冷灰 + 高频全爆刺耳
            return ProcessingParameters(
                targetWidth: 35, targetFrameRate: 10, videoBitrate: 150_000,
                saturation: 0.5, contrast: 1.1, brightness: -0.04,
                noiseIntensity: 0.7, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 2000, audioHighFreq: 6000, audioSampleRate: 8000, backgroundNoiseLevel: 0.55
            )
        case .netease:
            // 彻底摧毁 — 视频严重马赛克 + 音频几乎不可辨认
            return ProcessingParameters(
                targetWidth: 55, targetFrameRate: 5, videoBitrate: 120_000,
                saturation: 0.1, contrast: 2.0, brightness: -0.1,
                noiseIntensity: 0.7, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 800, audioHighFreq: 2000, audioSampleRate: 8000, backgroundNoiseLevel: 0.7
            )
        }
    }

    // MARK: - 插值

    func parameters(for intensity: Float) -> ProcessingParameters {
        let clamped = max(0, min(100, intensity))
        if clamped <= 50 {
            let t = clamped / 50.0
            return baselineParameters.interpolated(towards: lowParameters, t: t)
        } else {
            let t = (clamped - 50) / 50.0
            return lowParameters.interpolated(towards: highParameters, t: t)
        }
    }

    // MARK: - 特效开关（全部关闭，纯靠分辨率缩放 + 噪声 + 对比度出效果）

    func shouldEnableChromaShift() -> Bool { false }
    func shouldEnableScanlines() -> Bool { false }
    func shouldEnableTimestamp() -> Bool { false }
}