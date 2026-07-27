import Foundation

/// 视频降质模式枚举 — 6 种阴间风格
enum VideoPreset: String, CaseIterable, Identifiable {
    case basement    // 地下录像
    case vhs         // 磁带损坏
    case signal      // 深海信号
    case fallout     // 核辐射
    case dialup      // 古早网络
    case broadcast   // 末世广播

    var id: String { rawValue }

    // MARK: - 显示信息

    var displayName: String {
        switch self {
        case .basement:  return "地下录像"
        case .vhs:       return "磁带损坏"
        case .signal:    return "深海信号"
        case .fallout:   return "核辐射"
        case .dialup:    return "古早网络"
        case .broadcast: return "末世广播"
        }
    }

    var englishName: String {
        switch self {
        case .basement:  return "BASEMENT"
        case .vhs:       return "VHS"
        case .signal:    return "SIGNAL"
        case .fallout:   return "FALLOUT"
        case .dialup:    return "DIALUP"
        case .broadcast: return "BROADCAST"
        }
    }

    var subtitle: String {
        switch self {
        case .basement:  return "超低码率 · 块状压缩噪声 · 8kHz音频"
        case .vhs:       return "模拟抖动 · 色彩偏移 · 扫描线"
        case .signal:    return "马赛克 · 帧丢失 · 随机花屏"
        case .fallout:   return "严重过曝 · 高对比 · 颗粒感"
        case .dialup:    return "极低分辨率 · 高压缩 · 低帧率"
        case .broadcast: return "随机静帧 · 信号条纹 · 色偏"
        }
    }

    var iconName: String {
        switch self {
        case .basement:  return "house.fill"
        case .vhs:       return "waveform"
        case .signal:    return "dot.radiowaves.left.and.right"
        case .fallout:   return "bolt.fill"
        case .dialup:    return "phone.down.fill"
        case .broadcast: return "radio.fill"
        }
    }

    /// 推荐压缩量
    var recommendedIntensity: Float {
        switch self {
        case .basement:  return 60
        case .vhs:       return 55
        case .signal:    return 65
        case .fallout:   return 70
        case .dialup:    return 62
        case .broadcast: return 58
        }
    }

    // MARK: - 参数定义

    /// 基线参数（intensity=0%，轻微效果起点）
    var baselineParameters: ProcessingParameters {
        switch self {
        case .basement:
            return ProcessingParameters(
                targetWidth: 640, targetFrameRate: 24, videoBitrate: 2_000_000,
                saturation: 0.95, contrast: 1.0, brightness: 0,
                noiseIntensity: 0.02, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 200, audioHighFreq: 8000, audioSampleRate: 44100, backgroundNoiseLevel: 0
            )
        case .vhs:
            return ProcessingParameters(
                targetWidth: 640, targetFrameRate: 24, videoBitrate: 2_000_000,
                saturation: 1.0, contrast: 1.0, brightness: 0,
                noiseIntensity: 0.01, chromaShiftPixels: 2, scanlineAlpha: 0.05,
                audioLowFreq: 200, audioHighFreq: 8000, audioSampleRate: 44100, backgroundNoiseLevel: 0.05
            )
        case .signal:
            return ProcessingParameters(
                targetWidth: 640, targetFrameRate: 24, videoBitrate: 2_000_000,
                saturation: 0.9, contrast: 1.05, brightness: 0,
                noiseIntensity: 0.03, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 300, audioHighFreq: 6000, audioSampleRate: 44100, backgroundNoiseLevel: 0
            )
        case .fallout:
            return ProcessingParameters(
                targetWidth: 640, targetFrameRate: 24, videoBitrate: 2_000_000,
                saturation: 0.85, contrast: 1.1, brightness: 0.05,
                noiseIntensity: 0.04, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 300, audioHighFreq: 6000, audioSampleRate: 44100, backgroundNoiseLevel: 0.03
            )
        case .dialup:
            return ProcessingParameters(
                targetWidth: 640, targetFrameRate: 24, videoBitrate: 2_000_000,
                saturation: 0.9, contrast: 1.05, brightness: 0,
                noiseIntensity: 0.03, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 300, audioHighFreq: 6000, audioSampleRate: 44100, backgroundNoiseLevel: 0
            )
        case .broadcast:
            return ProcessingParameters(
                targetWidth: 640, targetFrameRate: 24, videoBitrate: 2_000_000,
                saturation: 0.9, contrast: 1.05, brightness: 0,
                noiseIntensity: 0.02, chromaShiftPixels: 1, scanlineAlpha: 0.03,
                audioLowFreq: 200, audioHighFreq: 8000, audioSampleRate: 44100, backgroundNoiseLevel: 0.02
            )
        }
    }

    /// 低强度参数（intensity=50%，显著降质）
    var lowParameters: ProcessingParameters {
        switch self {
        case .basement:
            return ProcessingParameters(
                targetWidth: 320, targetFrameRate: 15, videoBitrate: 500_000,
                saturation: 0.7, contrast: 1.1, brightness: -0.05,
                noiseIntensity: 0.15, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 200, audioHighFreq: 4000, audioSampleRate: 22050, backgroundNoiseLevel: 0.15
            )
        case .vhs:
            return ProcessingParameters(
                targetWidth: 320, targetFrameRate: 20, videoBitrate: 800_000,
                saturation: 1.1, contrast: 1.1, brightness: -0.02,
                noiseIntensity: 0.08, chromaShiftPixels: 8, scanlineAlpha: 0.25,
                audioLowFreq: 100, audioHighFreq: 6000, audioSampleRate: 32000, backgroundNoiseLevel: 0.15
            )
        case .signal:
            return ProcessingParameters(
                targetWidth: 240, targetFrameRate: 12, videoBitrate: 300_000,
                saturation: 0.6, contrast: 1.15, brightness: -0.03,
                noiseIntensity: 0.2, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 400, audioHighFreq: 4000, audioSampleRate: 16000, backgroundNoiseLevel: 0.1
            )
        case .fallout:
            return ProcessingParameters(
                targetWidth: 360, targetFrameRate: 18, videoBitrate: 600_000,
                saturation: 0.4, contrast: 1.4, brightness: 0.15,
                noiseIntensity: 0.25, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 300, audioHighFreq: 4000, audioSampleRate: 32000, backgroundNoiseLevel: 0.2
            )
        case .dialup:
            return ProcessingParameters(
                targetWidth: 200, targetFrameRate: 10, videoBitrate: 150_000,
                saturation: 0.5, contrast: 1.2, brightness: -0.02,
                noiseIntensity: 0.18, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 300, audioHighFreq: 4000, audioSampleRate: 16000, backgroundNoiseLevel: 0.1
            )
        case .broadcast:
            return ProcessingParameters(
                targetWidth: 320, targetFrameRate: 15, videoBitrate: 400_000,
                saturation: 0.6, contrast: 1.15, brightness: -0.02,
                noiseIntensity: 0.12, chromaShiftPixels: 5, scanlineAlpha: 0.15,
                audioLowFreq: 200, audioHighFreq: 4000, audioSampleRate: 22050, backgroundNoiseLevel: 0.15
            )
        }
    }

    /// 高强度参数（intensity=100%，极致崩坏）
    var highParameters: ProcessingParameters {
        switch self {
        case .basement:
            return ProcessingParameters(
                targetWidth: 80, targetFrameRate: 5, videoBitrate: 50_000,
                saturation: 0.2, contrast: 1.5, brightness: -0.1,
                noiseIntensity: 0.6, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 300, audioHighFreq: 2400, audioSampleRate: 8000, backgroundNoiseLevel: 0.5
            )
        case .vhs:
            return ProcessingParameters(
                targetWidth: 160, targetFrameRate: 12, videoBitrate: 200_000,
                saturation: 1.3, contrast: 1.3, brightness: -0.05,
                noiseIntensity: 0.2, chromaShiftPixels: 18, scanlineAlpha: 0.6,
                audioLowFreq: 80, audioHighFreq: 4000, audioSampleRate: 16000, backgroundNoiseLevel: 0.4
            )
        case .signal:
            return ProcessingParameters(
                targetWidth: 80, targetFrameRate: 6, videoBitrate: 60_000,
                saturation: 0.15, contrast: 1.5, brightness: -0.1,
                noiseIntensity: 0.5, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 500, audioHighFreq: 2000, audioSampleRate: 8000, backgroundNoiseLevel: 0.3
            )
        case .fallout:
            return ProcessingParameters(
                targetWidth: 200, targetFrameRate: 10, videoBitrate: 150_000,
                saturation: 0.05, contrast: 2.0, brightness: 0.3,
                noiseIntensity: 0.7, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 300, audioHighFreq: 2000, audioSampleRate: 16000, backgroundNoiseLevel: 0.6
            )
        case .dialup:
            return ProcessingParameters(
                targetWidth: 60, targetFrameRate: 5, videoBitrate: 40_000,
                saturation: 0.15, contrast: 1.5, brightness: -0.08,
                noiseIntensity: 0.55, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 400, audioHighFreq: 3000, audioSampleRate: 8000, backgroundNoiseLevel: 0.35
            )
        case .broadcast:
            return ProcessingParameters(
                targetWidth: 120, targetFrameRate: 8, videoBitrate: 80_000,
                saturation: 0.2, contrast: 1.4, brightness: -0.08,
                noiseIntensity: 0.4, chromaShiftPixels: 12, scanlineAlpha: 0.4,
                audioLowFreq: 300, audioHighFreq: 3000, audioSampleRate: 8000, backgroundNoiseLevel: 0.45
            )
        }
    }

    // MARK: - 插值计算

    /// 根据强度获取插值后的参数
    /// - intensity 0-50: baseline → low
    /// - intensity 50-100: low → high
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
        self == .vhs || self == .broadcast
    }

    func shouldEnableScanlines() -> Bool {
        self == .vhs || self == .broadcast
    }

    func shouldEnableTimestamp() -> Bool {
        false  // 设计文档中未要求时间戳
    }
}