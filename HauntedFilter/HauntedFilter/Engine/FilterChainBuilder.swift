import Foundation
import CoreImage

/// 根据预设+强度值构建 CIFilter 链
struct FilterChainBuilder {

    /// 对单帧图片应用完整的滤镜链
    /// - Parameters:
    ///   - sourceImage: 原始帧 CIImage
    ///   - parameters: 处理参数（含插值后的值）
    ///   - preset: 当前预设
    ///   - scanlineTexture: 扫描线纹理（可选，仅 VHS 预设需要）
    ///   - timestamp: 当前帧时间戳（可选，仅 CCTV 预设需要）
    ///   - sourceSize: 原始视频尺寸
    /// - Returns: 处理后 CIImage
    static func applyFilters(
        to sourceImage: CIImage,
        parameters: ProcessingParameters,
        preset: VideoPreset,
        scanlineTexture: CIImage?,
        timestamp: Date?,
        sourceSize: CGSize
    ) -> CIImage {
        var image = sourceImage

        // 1. 降分辨率 + 放大（伪低分辨率效果）
        if parameters.targetWidth < Int(sourceSize.width) {
            let scale = CGFloat(parameters.targetWidth) / sourceSize.width
            if let scaleFilter = CIFilter(name: "CILanczosScaleTransform") {
                scaleFilter.setValue(image, forKey: kCIInputImageKey)
                scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
                scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
                if let downscaled = scaleFilter.outputImage {
                    // 放大回原尺寸
                    let upScale = sourceSize.width / CGFloat(parameters.targetWidth)
                    if let upFilter = CIFilter(name: "CILanczosScaleTransform") {
                        upFilter.setValue(downscaled, forKey: kCIInputImageKey)
                        upFilter.setValue(upScale, forKey: kCIInputScaleKey)
                        upFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
                        if let upscaled = upFilter.outputImage {
                            image = upscaled.cropped(to: CGRect(origin: .zero, size: sourceSize))
                        }
                    }
                }
            }
        }

        // 2. 色彩调整（饱和度、对比度、亮度）
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(image, forKey: kCIInputImageKey)
            colorControls.setValue(parameters.saturation, forKey: kCIInputSaturationKey)
            colorControls.setValue(parameters.contrast, forKey: kCIInputContrastKey)
            colorControls.setValue(parameters.brightness, forKey: kCIInputBrightnessKey)
            if let output = colorControls.outputImage {
                image = output
            }
        }

        // 3. 偏色（通道偏移）— 按预设应用不同色调（EGG 保留原色不做处理）
        let colorTint: (r: Float, g: Float, b: Float)? = {
            switch preset {
            case .egg:     return nil                    // 鸡蛋：保留原色
            case .rain:    return (0.9, 0.85, 0.95)     // 雨夜：冷蓝灰调
            case .netease: return (0.85, 0.8, 0.7)      // 岡易云：复古褪色
            }
        }()
        if let tint = colorTint {
            if let colorMatrix = CIFilter(name: "CIColorMatrix") {
                colorMatrix.setValue(image, forKey: kCIInputImageKey)
                colorMatrix.setValue(CIVector(x: CGFloat(tint.r), y: 0, z: 0, w: 0), forKey: "inputRVector")
                colorMatrix.setValue(CIVector(x: 0, y: CGFloat(tint.g), z: 0, w: 0), forKey: "inputGVector")
                colorMatrix.setValue(CIVector(x: 0, y: 0, z: CGFloat(tint.b), w: 0), forKey: "inputBVector")
                if let output = colorMatrix.outputImage {
                    image = output
                }
            }
        }

        // 4. 色彩溢出（Chroma Bleeding）- 仅 VHS 预设
        if preset.shouldEnableChromaShift() && parameters.chromaShiftPixels > 0 {
            image = applyChromaShift(to: image, shiftPixels: parameters.chromaShiftPixels)
        }

        // 5. 噪点颗粒感
        if parameters.noiseIntensity > 0.01 {
            image = applyNoise(to: image, intensity: parameters.noiseIntensity)
        }

        // 6. 扫描线叠加 - 仅 VHS 预设
        if preset.shouldEnableScanlines(), let scanline = scanlineTexture, parameters.scanlineAlpha > 0 {
            let tintedScanline = scanline.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(parameters.scanlineAlpha))
            ])
            if let composited = CIFilter(name: "CISourceOverCompositing") {
                composited.setValue(tintedScanline, forKey: kCIInputImageKey)
                composited.setValue(image, forKey: kCIInputBackgroundImageKey)
                if let output = composited.outputImage {
                    image = output
                }
            }
        }

        return image.cropped(to: CGRect(origin: .zero, size: sourceSize))
    }

    // MARK: - 色彩溢出

    private static func applyChromaShift(to image: CIImage, shiftPixels: Float) -> CIImage {
        let shift = CGFloat(shiftPixels) / image.extent.width

        // 红色通道右移
        let redShiftFilter = CIFilter(name: "CIAffineTransform")
        redShiftFilter?.setValue(image, forKey: kCIInputImageKey)
        let redTransform = CGAffineTransform(translationX: shift * image.extent.width, y: 0)
        redShiftFilter?.setValue(redTransform, forKey: kCIInputTransformKey)

        // 蓝色通道左移
        let blueShiftFilter = CIFilter(name: "CIAffineTransform")
        blueShiftFilter?.setValue(image, forKey: kCIInputImageKey)
        let blueTransform = CGAffineTransform(translationX: -shift * image.extent.width * 0.5, y: 0)
        blueShiftFilter?.setValue(blueTransform, forKey: kCIInputTransformKey)

        guard let redShifted = redShiftFilter?.outputImage,
              let blueShifted = blueShiftFilter?.outputImage else {
            return image
        }

        // 从原图中提取 G 通道，从偏移图中提取 R/B 通道
        let extractRed = CIFilter(name: "CIColorMatrix")
        extractRed?.setValue(redShifted, forKey: kCIInputImageKey)
        extractRed?.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
        extractRed?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        extractRed?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")

        let extractGreen = CIFilter(name: "CIColorMatrix")
        extractGreen?.setValue(image, forKey: kCIInputImageKey)
        extractGreen?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        extractGreen?.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        extractGreen?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")

        let extractBlue = CIFilter(name: "CIColorMatrix")
        extractBlue?.setValue(blueShifted, forKey: kCIInputImageKey)
        extractBlue?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        extractBlue?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        extractBlue?.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")

        // 合并通道
        guard let rImage = extractRed?.outputImage,
              let gImage = extractGreen?.outputImage,
              let bImage = extractBlue?.outputImage else {
            return image
        }

        let addFilter = CIFilter(name: "CIAdditionCompositing")
        addFilter?.setValue(rImage, forKey: kCIInputImageKey)
        addFilter?.setValue(gImage, forKey: kCIInputBackgroundImageKey)

        let addFilter2 = CIFilter(name: "CIAdditionCompositing")
        addFilter2?.setValue(addFilter?.outputImage, forKey: kCIInputImageKey)
        addFilter2?.setValue(bImage, forKey: kCIInputBackgroundImageKey)

        return addFilter2?.outputImage ?? image
    }

    // MARK: - 噪点颗粒感（优化版本：避免高频创建无限 Extent 导致 GPU 内存爆满）

    private static var sharedNoiseImage: CIImage? = {
        if let randomGenerator = CIFilter(name: "CIRandomGenerator"),
           let output = randomGenerator.outputImage {
            return output.cropped(to: CGRect(x: 0, y: 0, width: 2048, height: 2048))
        }
        return nil
    }()

    private static func applyNoise(to image: CIImage, intensity: Float) -> CIImage {
        guard let noiseBase = sharedNoiseImage else { return image }
        let targetExtent = image.extent
        let noiseTile = noiseBase.cropped(to: targetExtent)

        // 将噪点缩放到合适的强度
        let coloredNoise = noiseTile.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity * 0.3)),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity * 0.3)),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity * 0.3)),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity * 0.5))
        ])

        if let blend = CIFilter(name: "CISourceOverCompositing") {
            blend.setValue(coloredNoise, forKey: kCIInputImageKey)
            blend.setValue(image, forKey: kCIInputBackgroundImageKey)
            if let output = blend.outputImage {
                return output.cropped(to: targetExtent)
            }
        }

        return image
    }
}