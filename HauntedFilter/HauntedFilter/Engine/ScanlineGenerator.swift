import Foundation
import CoreImage
import UIKit

/// 生成 VHS 扫描线纹理
struct ScanlineGenerator {

    /// 生成扫描线纹理 CIImage
    /// - Parameters:
    ///   - size: 纹理尺寸（通常与视频尺寸一致）
    ///   - spacing: 扫描线间距（像素）
    ///   - lineThickness: 扫描线厚度（像素）
    /// - Returns: 扫描线 CIImage
    static func generateScanlineTexture(size: CGSize, spacing: CGFloat, lineThickness: CGFloat) -> CIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
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
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()

        return CIImage(cgImage: cgImage)
    }
}