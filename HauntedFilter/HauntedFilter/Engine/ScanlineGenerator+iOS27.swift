import Foundation
import CoreImage
import UIKit

/// 修复iOS 27 Beta兼容性的扫描线生成器
struct ScanlineGenerator_iOS27 {

    /// 安全生成扫描线纹理 CIImage（iOS 27 Beta修复版）
    /// - Parameters:
    ///   - size: 纹理尺寸（通常与视频尺寸一致）
    ///   - spacing: 扫描线间距（像素）
    ///   - lineThickness: 扫描线厚度（像素）
    /// - Returns: 扫描线 CIImage，失败返回nil
    static func generateScanlineTextureSafe(
        size: CGSize,
        spacing: CGFloat,
        lineThickness: CGFloat
    ) -> CIImage? {
        print("🎨 生成扫描线纹理 (安全版) - 尺寸: \(size), 间距: \(spacing), 厚度: \(lineThickness)")

        // 确保尺寸有效
        guard size.width > 0, size.height > 0 else {
            print("❌ 无效的尺寸: \(size)")
            return nil
        }

        // 方法1：使用CoreGraphics直接绘制（优先）
        if let cgImage = createScanlineImageWithCG(size: size, spacing: spacing, lineThickness: lineThickness) {
            print("✅ 使用CoreGraphics创建扫描线成功")
            return CIImage(cgImage: cgImage)
        }

        // 方法2：使用UIGraphicsImageRenderer（iOS 11+）
        if #available(iOS 11.0, *) {
            if let uiImage = createScanlineImageWithUIRenderer(size: size, spacing: spacing, lineThickness: lineThickness) {
                print("✅ 使用UIGraphicsImageRenderer创建扫描线成功")
                return CIImage(image: uiImage)
            }
        }

        // 方法3：使用原始方法（最后尝试）
        if let ciImage = generateScanlineTextureFallback(size: size, spacing: spacing, lineThickness: lineThickness) {
            print("✅ 使用备用方法创建扫描线成功")
            return ciImage
        }

        print("❌ 所有扫描线创建方法都失败")
        return nil
    }

    // MARK: - 方法1: 使用CoreGraphics直接绘制

    private static func createScanlineImageWithCG(
        size: CGSize,
        spacing: CGFloat,
        lineThickness: CGFloat
    ) -> CGImage? {
        print("🎨 尝试方法1: CoreGraphics直接绘制")

        let width = Int(size.width)
        let height = Int(size.height)

        // 创建Bitmap上下文
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("❌ 创建CGContext失败")
            return nil
        }

        // 绘制扫描线
        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.3) // 黑色半透明

        var y: CGFloat = 0
        while y < size.height {
            let rect = CGRect(x: 0, y: y, width: size.width, height: lineThickness)
            context.fill(rect)
            y += spacing
        }

        // 从上下文获取CGImage
        guard let cgImage = context.makeImage() else {
            print("❌ 从CGContext生成CGImage失败")
            return nil
        }

        return cgImage
    }

    // MARK: - 方法2: 使用UIGraphicsImageRenderer（iOS 11+）

    @available(iOS 11.0, *)
    private static func createScanlineImageWithUIRenderer(
        size: CGSize,
        spacing: CGFloat,
        lineThickness: CGFloat
    ) -> UIImage? {
        print("🎨 尝试方法2: UIGraphicsImageRenderer")

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext

            // 透明背景
            cgContext.clear(CGRect(origin: .zero, size: size))

            // 绘制黑色扫描线
            UIColor.black.withAlphaComponent(0.3).setFill()

            var y: CGFloat = 0
            while y < size.height {
                let rect = CGRect(x: 0, y: y, width: size.width, height: lineThickness)
                cgContext.fill(rect)
                y += spacing
            }
        }

        return image
    }

    // MARK: - 方法3: 备用方法（原始方法包装在安全块中）

    private static func generateScanlineTextureFallback(
        size: CGSize,
        spacing: CGFloat,
        lineThickness: CGFloat
    ) -> CIImage? {
        print("🎨 尝试方法3: 备用方法")

        // 使用原始方法但包装在安全执行中
        return try? generateScanlineTextureOriginal(
            size: size,
            spacing: spacing,
            lineThickness: lineThickness
        )
    }

    private static func generateScanlineTextureOriginal(
        size: CGSize,
        spacing: CGFloat,
        lineThickness: CGFloat
    ) throws -> CIImage? {
        // 原始逻辑，但可能会抛出异常
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            print("❌ 获取UIGraphics当前上下文失败")
            return nil
        }

        // 透明背景
        context.clear(CGRect(origin: .zero, size: size))

        // 绘制黑色扫描线
        context.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)

        var y: CGFloat = 0
        while y < size.height {
            context.fill(CGRect(x: 0, y: y, width: size.width, height: lineThickness))
            y += spacing
        }

        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            print("❌ 从UIGraphics上下文获取CGImage失败")
            return nil
        }

        return CIImage(cgImage: cgImage)
    }

    // MARK: - 简化的扫描线纹理（性能优化）

    /// 生成简化的扫描线纹理（针对性能优化）
    static func generateSimpleScanlineTexture(size: CGSize) -> CIImage? {
        print("🎨 生成简化扫描线纹理 - 尺寸: \(size)")

        // 对于iOS 27 Beta，可以使用更简单的方法
        // 创建一个小的重复纹理而不是整个屏幕大小

        let smallSize = CGSize(width: 8, height: 8)

        guard let context = CGContext(
            data: nil,
            width: Int(smallSize.width),
            height: Int(smallSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 4 * Int(smallSize.width),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("❌ 创建简化扫描线CGContext失败")
            return nil
        }

        // 绘制简化的扫描线模式
        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.15)
        context.fill(CGRect(x: 0, y: 0, width: smallSize.width, height: 2))
        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 0) // 透明
        context.fill(CGRect(x: 0, y: 2, width: smallSize.width, height: 6))

        guard let cgImage = context.makeImage() else {
            print("❌ 生成简化扫描线CGImage失败")
            return nil
        }

        let smallTexture = CIImage(cgImage: cgImage)

        // 使用tile filter将小纹理平铺到整个尺寸
        guard let tileFilter = CIFilter(name: "CIAffineTile") else {
            print("❌ 创建CIAffineTile滤镜失败")
            return smallTexture
        }

        // 计算缩放比例以填满目标尺寸
        let scaleX = size.width / smallSize.width
        let scaleY = size.height / smallSize.height
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)

        tileFilter.setValue(smallTexture, forKey: kCIInputImageKey)
        tileFilter.setValue(transform, forKey: kCIInputTransformKey)

        guard let tiledImage = tileFilter.outputImage else {
            print("❌ 平铺扫描线纹理失败")
            return smallTexture
        }

        // 裁剪到准确尺寸
        return tiledImage.cropped(to: CGRect(origin: .zero, size: size))
    }

    // MARK: - 预生成的纹理缓存

    /// 纹理缓存以避免重复生成
    private static var textureCache: [String: CIImage] = [:]

    static func getScanlineTextureCached(
        size: CGSize,
        spacing: CGFloat,
        lineThickness: CGFloat
    ) -> CIImage? {
        let cacheKey = "\(size.width)x\(size.height)_\(spacing)_\(lineThickness)"

        if let cached = textureCache[cacheKey] {
            print("✅ 从缓存获取扫描线纹理: \(cacheKey)")
            return cached
        }

        print("🔄 生成新的扫描线纹理: \(cacheKey)")
        if let texture = generateScanlineTextureSafe(size: size, spacing: spacing, lineThickness: lineThickness) {
            textureCache[cacheKey] = texture
            return texture
        }

        // 如果失败，尝试简化版本
        if let simpleTexture = generateSimpleScanlineTexture(size: size) {
            textureCache[cacheKey] = simpleTexture
            return simpleTexture
        }

        return nil
    }

    /// 清理缓存
    static func clearCache() {
        print("🧹 清理扫描线纹理缓存")
        textureCache.removeAll()
    }
}

// MARK: - 兼容性包装器

/// 向后兼容的扫描线生成器
struct ScanlineGeneratorCompatible {
    /// 主生成方法（自动选择最佳实现）
    static func generateScanlineTexture(
        size: CGSize,
        spacing: CGFloat,
        lineThickness: CGFloat
    ) -> CIImage? {
        // 首先尝试新的安全方法
        if let texture = ScanlineGenerator_iOS27.generateScanlineTextureSafe(
            size: size,
            spacing: spacing,
            lineThickness: lineThickness
        ) {
            return texture
        }

        // 如果失败，尝试缓存方法
        if let texture = ScanlineGenerator_iOS27.getScanlineTextureCached(
            size: size,
            spacing: spacing,
            lineThickness: lineThickness
        ) {
            return texture
        }

        // 最后尝试原始方法（包装在安全块中）
        print("⚠️ 备用方法：尝试原始扫描线生成器")
        return ScanlineGenerator.generateScanlineTexture(
            size: size,
            spacing: spacing,
            lineThickness: lineThickness
        )
    }

    /// 简化的纹理生成（性能优化）
    static func generateSimpleTexture(size: CGSize) -> CIImage? {
        ScanlineGenerator_iOS27.generateSimpleScanlineTexture(size: size)
    }
}

// MARK: - VideoProcessor 扩展

extension VideoProcessor {
    /// 使用兼容的扫描线生成器
    func getScanlineTextureSafe(size: CGSize) -> CIImage? {
        print("🛡️ 获取安全的扫描线纹理 - 尺寸: \(size)")

        // 使用兼容的生成器
        let texture = ScanlineGeneratorCompatible.generateScanlineTexture(
            size: size,
            spacing: 4,
            lineThickness: 2
        )

        if texture == nil {
            print("⚠️ 扫描线纹理生成失败，继续无纹理处理")
        } else {
            print("✅ 扫描线纹理生成成功")
        }

        return texture
    }
}