import Foundation

/// 视频处理预设枚举
enum VideoPreset: String, CaseIterable, Identifiable {
    case oldPhone   // 老式座机 / BB机摄像头
    case vhs        // VHS 录像带
    case cctv       // 老式监控 CCTV
    case qubuHuazhen // 🏭 曲埠华臻机械 — 2010诺基亚手机质感

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oldPhone: return "老式座机"
        case .vhs:      return "VHS 录像带"
        case .cctv:     return "监控 CCTV"
        case .qubuHuazhen: return "曲埠华臻机械"
        }
    }

    var subtitle: String {
        switch self {
        case .oldPhone: return "低分辨率 · 偏色 · 电话音"
        case .vhs:      return "扫描线 · 色彩溢出 · 底噪"
        case .cctv:     return "黑白 · 卡顿 · 时间戳"
        case .qubuHuazhen: return "2010诺基亚 · 高压缩 · BGM标配"
        }
    }

    var iconName: String {
        switch self {
        case .oldPhone: return "phone.fill"
        case .vhs:      return "videotape.fill"
        case .cctv:     return "video.fill.badge.ellipsis"
        case .qubuHuazhen: return "gearshape.2.fill"
        }
    }

    /// 推荐压缩量 — 一键设到最佳模拟值
    var recommendedIntensity: Float {
        switch self {
        case .oldPhone: return 55
        case .vhs:      return 60
        case .cctv:     return 65
        case .qubuHuazhen: return 58  // 高压缩但不极端，保持诺基亚质感
        }
    }

    /// 基线参数（新版 0%，≈ 旧版 50% 强度——轻微效果起点）
    var baselineParameters: ProcessingParameters {
        switch self {
        case .oldPhone:
            return ProcessingParameters(
                targetWidth: 480, targetFrameRate: 24, videoBitrate: 2_000_000,
                saturation: 1.0, contrast: 1.0, brightness: 0,
                noiseIntensity: 0.02, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 200, audioHighFreq: 4000, audioSampleRate: 44100, backgroundNoiseLevel: 0
            )
        case .vhs:
            return ProcessingParameters(
                targetWidth: 480, targetFrameRate: 24, videoBitrate: 2_000_000,
                saturation: 1.0, contrast: 1.0, brightness: 0,
                noiseIntensity: 0.01, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 200, audioHighFreq: 4000, audioSampleRate: 44100, backgroundNoiseLevel: 0
            )
        case .cctv:
            return ProcessingParameters(
                targetWidth: 480, targetFrameRate: 24, videoBitrate: 2_000_000,
                saturation: 1.0, contrast: 1.0, brightness: 0,
                noiseIntensity: 0.01, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 200, audioHighFreq: 4000, audioSampleRate: 44100, backgroundNoiseLevel: 0
            )
        case .qubuHuazhen:
            return ProcessingParameters(
                targetWidth: 480, targetFrameRate: 24, videoBitrate: 2_000_000,
                saturation: 1.0, contrast: 1.0, brightness: 0,
                noiseIntensity: 0, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 200, audioHighFreq: 4000, audioSampleRate: 44100, backgroundNoiseLevel: 0
            )
        }
    }

    /// 低强度参数（新版 t=0.0，≈ 旧版全力 90%）
    var lowParameters: ProcessingParameters {
        switch self {
        case .oldPhone:
            return ProcessingParameters(
                targetWidth: 120, targetFrameRate: 6, videoBitrate: 80_000,
                saturation: 0.2, contrast: 1.2, brightness: -0.05,
                noiseIntensity: 0.35, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 300, audioHighFreq: 3000, audioSampleRate: 8000, backgroundNoiseLevel: 0
            )
        case .vhs:
            return ProcessingParameters(
                targetWidth: 160, targetFrameRate: 10, videoBitrate: 150_000,
                saturation: 0.3, contrast: 1.3, brightness: -0.03,
                noiseIntensity: 0.15, chromaShiftPixels: 5, scanlineAlpha: 0.3,
                audioLowFreq: 100, audioHighFreq: 6000, audioSampleRate: 22050, backgroundNoiseLevel: 0.2
            )
        case .cctv:
            return ProcessingParameters(
                targetWidth: 120, targetFrameRate: 5, videoBitrate: 60_000,
                saturation: 0.05, contrast: 1.4, brightness: -0.1,
                noiseIntensity: 0.2, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 200, audioHighFreq: 4000, audioSampleRate: 8000, backgroundNoiseLevel: 0
            )
        case .qubuHuazhen:
            // 高压缩、轻微色彩衰减、保留画面完整性（不过度处理色彩）
            return ProcessingParameters(
                targetWidth: 180, targetFrameRate: 15, videoBitrate: 120_000,
                saturation: 0.75, contrast: 1.05, brightness: 0.02,
                noiseIntensity: 0.08, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 200, audioHighFreq: 4000, audioSampleRate: 22050, backgroundNoiseLevel: 0
            )
        }
    }

    /// 高强度参数（新版 t=1.0 — 像素块级极致阴间）
    var highParameters: ProcessingParameters {
        switch self {
        case .oldPhone:
            return ProcessingParameters(
                targetWidth: 60, targetFrameRate: 3, videoBitrate: 30_000,
                saturation: 0.05, contrast: 1.8, brightness: -0.15,
                noiseIntensity: 0.8, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 300, audioHighFreq: 2400, audioSampleRate: 8000, backgroundNoiseLevel: 0
            )
        case .vhs:
            return ProcessingParameters(
                targetWidth: 60, targetFrameRate: 4, videoBitrate: 30_000,
                saturation: 0.08, contrast: 1.6, brightness: -0.1,
                noiseIntensity: 0.6, chromaShiftPixels: 18, scanlineAlpha: 0.7,
                audioLowFreq: 80, audioHighFreq: 4000, audioSampleRate: 8000, backgroundNoiseLevel: 0.5
            )
        case .cctv:
            return ProcessingParameters(
                targetWidth: 60, targetFrameRate: 2, videoBitrate: 20_000,
                saturation: 0.0, contrast: 2.0, brightness: -0.2,
                noiseIntensity: 0.7, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 100, audioHighFreq: 3000, audioSampleRate: 8000, backgroundNoiseLevel: 0
            )
        case .qubuHuazhen:
            // 极致压缩但不伤色彩，保留诺基亚时代的特征
            return ProcessingParameters(
                targetWidth: 80, targetFrameRate: 8, videoBitrate: 50_000,
                saturation: 0.5, contrast: 1.15, brightness: 0.0,
                noiseIntensity: 0.2, chromaShiftPixels: 0, scanlineAlpha: 0,
                audioLowFreq: 200, audioHighFreq: 4000, audioSampleRate: 16000, backgroundNoiseLevel: 0
            )
        }
    }

    /// 根据强度获取插值后的参数（新版映射）
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

    /// 预设特有的启用标志
    func shouldEnableChromaShift() -> Bool {
        self == .vhs
    }

    func shouldEnableScanlines() -> Bool {
        self == .vhs
    }

    func shouldEnableTimestamp() -> Bool {
        self == .cctv
    }
}