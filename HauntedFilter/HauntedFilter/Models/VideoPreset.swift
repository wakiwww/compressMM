import Foundation

/// 视频降质模式 — 3 种风格
enum VideoPreset: String, CaseIterable, Identifiable {
    case egg       // 鸡蛋 — 极低帧率马赛克，保留原色
    case rain      // 雨夜骑行男 — 满帧极端马赛克，不可辨认
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
        case .egg:     return "5fps · 肉眼可见马赛克 · 保留原色"
        case .rain:    return "30fps · 极端像素化 · 不可辨认"
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

    /// 原汁原味压缩量 — 一键出效果，同时保证编码安全
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
            // 5fps + 极低分辨率放缩 = 肉眼可见马赛克，保留原色
            return ProcessingParameters(
                targetWidth: 140, targetFrameRate: 5, videoBitrate: 500_000,
                saturation: 1.0, contrast: 1.0, brightness: 0,
                noiseIntensity: 0.08, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 200, audioHighFreq: 8000, audioSampleRate: 22050, backgroundNoiseLevel: 0.05
            )
        case .rain:
            // 30fps 满帧，但极端低分辨率放大 → 完全不可辨认的像素块
            return ProcessingParameters(
                targetWidth: 100, targetFrameRate: 30, videoBitrate: 500_000,
                saturation: 0.7, contrast: 1.3, brightness: -0.03,
                noiseIntensity: 0.3, chromaShiftPixels: 4, scanlineAlpha: 0.1,
                audioLowFreq: 150, audioHighFreq: 6000, audioSampleRate: 22050, backgroundNoiseLevel: 0.1
            )
        case .netease:
            // 音视频全损
            return ProcessingParameters(
                targetWidth: 140, targetFrameRate: 8, videoBitrate: 300_000,
                saturation: 0.4, contrast: 1.4, brightness: -0.05,
                noiseIntensity: 0.35, chromaShiftPixels: 3, scanlineAlpha: 0.05,
                audioLowFreq: 300, audioHighFreq: 3000, audioSampleRate: 8000, backgroundNoiseLevel: 0.3
            )
        }
    }

    /// 高档（100%）：拉满效果，但仍保证编码安全
    var highParameters: ProcessingParameters {
        switch self {
        case .egg:
            // 极致马赛克，原色不动
            return ProcessingParameters(
                targetWidth: 60, targetFrameRate: 5, videoBitrate: 150_000,
                saturation: 1.0, contrast: 1.05, brightness: 0,
                noiseIntensity: 0.15, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 300, audioHighFreq: 4000, audioSampleRate: 16000, backgroundNoiseLevel: 0.1
            )
        case .rain:
            // 拉到几乎纯色块
            return ProcessingParameters(
                targetWidth: 50, targetFrameRate: 30, videoBitrate: 200_000,
                saturation: 0.4, contrast: 1.6, brightness: -0.05,
                noiseIntensity: 0.5, chromaShiftPixels: 8, scanlineAlpha: 0.2,
                audioLowFreq: 100, audioHighFreq: 4000, audioSampleRate: 16000, backgroundNoiseLevel: 0.2
            )
        case .netease:
            // 彻底摧毁
            return ProcessingParameters(
                targetWidth: 60, targetFrameRate: 6, videoBitrate: 120_000,
                saturation: 0.15, contrast: 1.8, brightness: -0.08,
                noiseIntensity: 0.6, chromaShiftPixels: 6, scanlineAlpha: 0.1,
                audioLowFreq: 400, audioHighFreq: 2000, audioSampleRate: 8000, backgroundNoiseLevel: 0.5
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

    // MARK: - 特效开关

    func shouldEnableChromaShift() -> Bool {
        self == .rain || self == .netease
    }

    func shouldEnableScanlines() -> Bool {
        self == .rain || self == .netease
    }

    func shouldEnableTimestamp() -> Bool { false }
}