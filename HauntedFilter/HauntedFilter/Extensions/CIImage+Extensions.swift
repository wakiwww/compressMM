import Foundation
import CoreImage

extension CIImage {
    /// 将 CIImage 缩放到指定尺寸
    func scaledTo(size: CGSize) -> CIImage {
        let scaleX = size.width / extent.width
        let scaleY = size.height / extent.height
        return applyingFilter("CILanczosScaleTransform", parameters: [
            kCIInputScaleKey: min(scaleX, scaleY),
            kCIInputAspectRatioKey: 1.0,
        ])
    }
}