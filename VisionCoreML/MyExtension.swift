import CoreImage
import UIKit

extension CIImage {
    func cropImage(rect:CGRect) -> CIImage {
        UIGraphicsBeginImageContext(CGSize(width:rect.size.width, height:rect.size.height))
        let filter:CIFilter! = CIFilter(name: "CICrop")
        filter.setValue(self, forKey:kCIInputImageKey)
        filter.setValue(CIVector(cgRect:rect), forKey:"inputRectangle")
        let ciContext:CIContext = CIContext(options: nil)
        let cgImage = ciContext.createCGImage(filter!.outputImage!, from:filter!.outputImage!.extent)!
        UIGraphicsEndImageContext()
        return CIImage(cgImage:cgImage)
    }
    func copyImage() -> CIImage {
        let uiImage:UIImage = UIImage(ciImage: self)
        UIGraphicsBeginImageContext(self.extent.size)
        uiImage.draw(in: self.extent)
        let copyImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return CIImage(cgImage:copyImage.cgImage!)
    }
}

extension UIImage {
    var safeCiImage: CIImage? {
        return self.ciImage ?? CIImage(image: self)
    }
    var safeCgImage: CGImage? {
        if let cgImge = self.cgImage {
            return cgImge
        }
        if let ciImage = safeCiImage {
            let context = CIContext(options: nil)
            return context.createCGImage(ciImage, from: ciImage.extent)
        }
        return nil
    }
    /// rotated (degrees=0-359)
    func rotated(degrees: CGFloat, flipVertical: Bool = false, flipHorizontal: Bool = false) -> UIImage? {
        guard let ciImage = safeCiImage else {
            return nil
        }
        guard let filter = CIFilter(name: "CIAffineTransform") else {
            return nil
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setDefaults()
        let newAngle = degrees * CGFloat(M_PI) / 180.0 * CGFloat(-1)
        var transform = CATransform3DIdentity
        transform = CATransform3DRotate(transform, CGFloat(newAngle), 0, 0, 1)
        transform = CATransform3DRotate(transform, (flipVertical ? 1.0 : 0) * CGFloat.pi, 0, 1, 0)
        transform = CATransform3DRotate(transform, (flipHorizontal ? 1.0 : 0) * CGFloat.pi, 1, 0, 0)
        let affineTransform = CATransform3DGetAffineTransform(transform)
        filter.setValue(NSValue(cgAffineTransform: affineTransform), forKey: kCIInputTransformKey)
        guard let outputImage = filter.outputImage else {
            return nil
        }
        let context = CIContext(options: [CIContextOption.useSoftwareRenderer: true])
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

extension CGRect {
    func scaled(sz:CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * sz.width,
            y: self.origin.y * sz.height,
            width: self.size.width * sz.width,
            height: self.size.height * sz.height
        )
    }
    func upsidedown(h:CGFloat) -> CGRect {
        return CGRect(
            x: self.origin.x,
            y: (h - self.size.height - self.origin.y),
            width: self.size.width,
            height: self.size.height
        )
    }
    func expanded() -> CGRect {
        let b:CGFloat = self.width/8
        return CGRect(
            x: self.minX-(b*1),
            y: self.minY-(b*3),
            width: self.size.width+(b*2),
            height: self.size.height+(b*4)
        )
    }
    func convert(sz:CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * sz.width,
            y: (1.0 - self.maxY) * sz.height,
            width: self.size.width * sz.width,
            height: self.size.height * sz.height
        )
    }
}

extension CGPoint {
    func scaled(sz: CGSize) -> CGPoint {
        return CGPoint(x:self.x * sz.width, y: self.y * sz.height)
    }
    func upsidedown(h:CGFloat) -> CGPoint {
        return CGPoint(x:self.x, y:h-self.y)
    }
}
