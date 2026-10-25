//
//  QRCodeGenerator.swift
//  MedicalWallet
//
//  Builds the QR code shown on the emergency card
//

import UIKit
import CoreImage.CIFilterBuiltins

enum QRCodeGenerator {
    static func image(from text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)) else {
            return nil
        }
        guard let cgImage = CIContext().createCGImage(output, from: output.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
