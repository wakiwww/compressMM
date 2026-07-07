import Foundation

/// 视频和音频处理参数
struct ProcessingParameters {
    // MARK: - 视频参数
    var targetWidth: Int            // 缩放目标宽度 (px)
    var targetFrameRate: Double     // 目标帧率 (fps)
    var videoBitrate: Int           // 编码码率 (bps)
    var saturation: Float           // 饱和度 (0-1)
    var contrast: Float             // 对比度 (1.0 = 原始)
    var brightness: Float           // 亮度偏移 (-1 ~ 1)
    var noiseIntensity: Float       // 噪点混合强度 (0-1)
    var chromaShiftPixels: Float    // 色彩偏移像素数
    var scanlineAlpha: Float        // 扫描线透明度 (0-1)

    // MARK: - 音频参数
    var audioLowFreq: Float         // 带通低切 (Hz)
    var audioHighFreq: Float        // 带通高切 (Hz)
    var audioSampleRate: Double     // 音频采样率 (Hz)
    var backgroundNoiseLevel: Float // 底噪混合音量 (0-1)

    /// 在两个参数集之间线性插值
    func interpolated(towards other: ProcessingParameters, t: Float) -> ProcessingParameters {
        let t = max(0, min(1, t))
        return ProcessingParameters(
            targetWidth: Int(lerp(Float(targetWidth), Float(other.targetWidth), t)),
            targetFrameRate: lerp(targetFrameRate, other.targetFrameRate, Double(t)),
            videoBitrate: Int(lerp(Float(videoBitrate), Float(other.videoBitrate), t)),
            saturation: lerp(saturation, other.saturation, t),
            contrast: lerp(contrast, other.contrast, t),
            brightness: lerp(brightness, other.brightness, t),
            noiseIntensity: lerp(noiseIntensity, other.noiseIntensity, t),
            chromaShiftPixels: lerp(chromaShiftPixels, other.chromaShiftPixels, t),
            scanlineAlpha: lerp(scanlineAlpha, other.scanlineAlpha, t),
            audioLowFreq: lerp(audioLowFreq, other.audioLowFreq, t),
            audioHighFreq: lerp(audioHighFreq, other.audioHighFreq, t),
            audioSampleRate: lerp(audioSampleRate, other.audioSampleRate, Double(t)),
            backgroundNoiseLevel: lerp(backgroundNoiseLevel, other.backgroundNoiseLevel, t)
        )
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }
}