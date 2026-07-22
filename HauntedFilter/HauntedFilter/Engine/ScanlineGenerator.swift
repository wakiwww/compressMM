import Foundation
import CoreImage
import CoreGraphics

/// 生成 VHS 扫描线纹理
struct ScanlineGenerator {

    /// 生成扫描线纹理 CIImage（线程安全）
    /// - Parameters:
    ///   - size: 纹理尺寸（通常与视频尺寸一致）
    ///   - spacing: 扫描线间距（像素）
    /// 安全生成扫描线纹理 CIImage（使用 CGContext 纯内存绘制，避免 CVPixelBuffer 锁定引致的崩溃）
    static func generateScanlineTexture(size: CGSize, spacing: CGFloat, lineThickness: CGFloat) -> CIImage? {
        let width = Int(size.width)
        let height = Int(size.height)

        guard width > 0, height > 0 else { return nil }

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
            return nil
        }

        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.3)

        var y: CGFloat = 0
        while y < size.height {
            context.fill(CGRect(x: 0, y: y, width: size.width, height: lineThickness))
            y += spacing
        }

        guard let cgImage = context.makeImage() else { return nil }
        return CIImage(cgImage: cgImage)
    }

    /// 简化版本的扫描线生成器
    static func generateSimpleScanlineTexture(size: CGSize) -> CIImage? {
        return generateScanlineTexture(size: size, spacing: 4, lineThickness: 2)
    }
}