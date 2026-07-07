import Foundation

/// 视频处理预设枚举
enum VideoPreset: String, CaseIterable, Identifiable {
    case oldPhone   // 老式座机 / BB机摄像头
    case vhs        // VHS 录像带
    case cctv       // 老式监控 CCTV

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oldPhone: return "老式座机"
        case .vhs:      return "VHS 录像带"
        case .cctv:     return "监控 CCTV"
        }
    }

    var subtitle: String {
        switch self {
        case .oldPhone: return "低分辨率 · 偏色 · 电话音"
        case .vhs:      return "扫描线 · 色彩溢出 · 底噪"
        case .cctv:     return "黑白 · 卡顿 · 时间戳"
        }
    }

    var iconName: String {
        switch self {
        case .oldPhone: return "phone.fill"
        case .vhs:      return "videotape.fill"
        case .cctv:     return "video.fill.badge.ellipsis"
        }
    }

    /// 低强度 (s=20) 参数
    var lowParameters: ProcessingParameters {
        switch self {
        case .oldPhone:
            return ProcessingParameters(
                targetWidth: 320,
                targetFrameRate: 20,
                videoBitrate: 800_000,
                saturation: 0.9,
                contrast: 1.05,
                brightness: 0,
                noiseIntensity: 0.05,
                chromaShiftPixels: 0,
                scanlineAlpha: 0,
                audioLowFreq: 300,
                audioHighFreq: 3000,
                audioSampleRate: 22050,
                backgroundNoiseLevel: 0
            )
        case .vhs:
            return ProcessingParameters(
                targetWidth: 360,
                targetFrameRate: 24,
                videoBitrate: 1_000_000,
                saturation: 0.8,
                contrast: 1.1,
                brightness: 0,
                noiseIntensity: 0.02,
                chromaShiftPixels: 1,
                scanlineAlpha: 0.1,
                audioLowFreq: 100,
                audioHighFreq: 6000,
                audioSampleRate: 44100,
                backgroundNoiseLevel: 0.05
            )
        case .cctv:
            return ProcessingParameters(
                targetWidth: 320,
                targetFrameRate: 15,
                videoBitrate: 500_000,
                saturation: 0.3,
                contrast: 1.2,
                brightness: -0.05,
                noiseIntensity: 0.03,
                chromaShiftPixels: 0,
                scanlineAlpha: 0,
                audioLowFreq: 200,
                audioHighFreq: 4000,
                audioSampleRate: 16000,
                backgroundNoiseLevel: 0
            )
        }
    }

    /// 高强度 (s=90) 参数
    var highParameters: ProcessingParameters {
        switch self {
        case .oldPhone:
            return ProcessingParameters(
                targetWidth: 120,
                targetFrameRate: 6,
                videoBitrate: 80_000,
                saturation: 0.2,
                contrast: 1.2,
                brightness: -0.05,
                noiseIntensity: 0.35,
                chromaShiftPixels: 0,
                scanlineAlpha: 0,
                audioLowFreq: 300,
                audioHighFreq: 3000,
                audioSampleRate: 6000,
                backgroundNoiseLevel: 0
            )
        case .vhs:
            return ProcessingParameters(
                targetWidth: 160,
                targetFrameRate: 10,
                videoBitrate: 150_000,
                saturation: 0.3,
                contrast: 1.3,
                brightness: -0.03,
                noiseIntensity: 0.15,
                chromaShiftPixels: 5,
                scanlineAlpha: 0.3,
                audioLowFreq: 100,
                audioHighFreq: 6000,
                audioSampleRate: 22050,
                backgroundNoiseLevel: 0.2
            )
        case .cctv:
            return ProcessingParameters(
                targetWidth: 120,
                targetFrameRate: 5,
                videoBitrate: 60_000,
                saturation: 0.05,
                contrast: 1.4,
                brightness: -0.1,
                noiseIntensity: 0.2,
                chromaShiftPixels: 0,
                scanlineAlpha: 0,
                audioLowFreq: 200,
                audioHighFreq: 4000,
                audioSampleRate: 8000,
                backgroundNoiseLevel: 0
            )
        }
    }

    /// 根据强度获取插值后的参数
    func parameters(for intensity: Float) -> ProcessingParameters {
        let clamped = max(20, min(90, intensity))
        let t = (clamped - 20) / 70  // 0.0 ~ 1.0
        return lowParameters.interpolated(towards: highParameters, t: t)
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