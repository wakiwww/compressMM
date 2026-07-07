import Foundation
import CoreImage
import Accelerate

extension CVPixelBuffer {
    /// 从 CIImage 创建 CVPixelBuffer
    static func create(from ciImage: CIImage, context: CIContext) -> CVPixelBuffer? {
        let size = ciImage.extent.size
        var pixelBuffer: CVPixelBuffer?

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height),
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        context.render(ciImage, to: buffer)

        return buffer
    }
}