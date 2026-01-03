//
//  PremiumCardBarcode.swift
//  soteria
//
//  Horizontal barcode component for premium member card back
//

import SwiftUI
import CoreImage

struct PremiumCardBarcode: View {
    let userId: String
    let cardType: String
    let memberSince: Date
    let isBlack: Bool
    
    @State private var barcodeImage: UIImage? = nil
    
    var body: some View {
        Group {
            if let barcodeImg = barcodeImage {
                Image(uiImage: barcodeImg)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFill() // Use fill to span full width
                    .frame(maxWidth: .infinity)
                    .frame(height: 50) // Fixed height for consistent scanning
                    .clipped() // Clip to frame boundaries
            } else {
                // Placeholder while generating
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        ProgressView()
                            .tint(isBlack ? .white : .gray)
                            .scaleEffect(0.7)
                    )
            }
        }
        .onAppear {
            generateBarcode()
        }
    }
    
    private func generateBarcode() {
        // Create barcode data string (same format as QR code for consistency)
        let dateFormatter = ISO8601DateFormatter()
        let memberSinceString = dateFormatter.string(from: memberSince)
        
        let barcodeData: [String: Any] = [
            "user_id": userId,
            "card_type": cardType,
            "member_since": memberSinceString,
            "app": "soteria",
            "version": "1.0"
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: barcodeData, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ [PremiumCardBarcode] Failed to create barcode data")
            return
        }
        
        // Generate Code128 barcode (horizontal barcode)
        barcodeImage = generateCode128Barcode(from: jsonString)
    }
    
    private func generateCode128Barcode(from text: String) -> UIImage? {
        guard let data = text.data(using: .utf8) else { return nil }
        
        // Use Code128 barcode filter (available in iOS 11+)
        guard let filter = CIFilter(name: "CICode128BarcodeGenerator") else {
            print("⚠️ [PremiumCardBarcode] Code128 filter not available (iOS 11+), using QR code style")
            // Fallback to QR code styled as horizontal barcode
            return generateQRCodeBarcode(from: text)
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(0.0, forKey: "inputQuietSpace") // No quiet space for full-width barcode
        
        guard let ciImage = filter.outputImage else {
            print("❌ [PremiumCardBarcode] Failed to generate Code128 barcode")
            return generateQRCodeBarcode(from: text)
        }
        
        // Scale up for better resolution - make it wide enough to span magnetic strip
        // Use higher scaleX to make barcode wider for better scanning
        let scaleX = 4.0 // Increased for wider barcode
        let scaleY = 50.0 // Taller for horizontal barcode visibility
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert CIImage to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // Fallback to QR code styled as horizontal barcode if Code128 not available
    private func generateQRCodeBarcode(from text: String) -> UIImage? {
        guard let data = text.data(using: .utf8) else { return nil }
        
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let ciImage = qrFilter.outputImage else { return nil }
        
        // Scale to make it wider and shorter (horizontal barcode style)
        // This creates a rectangular barcode-like appearance that spans the magnetic strip
        let scaleX = 12.0 // Increased for wider barcode to span magnetic strip
        let scaleY = 2.0 // Taller for better scanning
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

