//
//  QRCodeService.swift
//  soteria
//
//  Generates QR codes for premium member cards
//

import Foundation
import UIKit
import CoreImage

class QRCodeService {
    static let shared = QRCodeService()
    
    private init() {}
    
    /// Generates a QR code image from a string
    /// - Parameter string: The data to encode in the QR code
    /// - Parameter size: The desired size of the QR code image (default: 200x200)
    /// - Returns: A UIImage of the QR code, or nil if generation fails
    func generateQRCode(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        guard let data = string.data(using: .utf8) else {
            print("❌ [QRCodeService] Failed to convert string to data")
            return nil
        }
        
        // Create QR code filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            print("❌ [QRCodeService] QR code filter not available")
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        guard let ciImage = filter.outputImage else {
            print("❌ [QRCodeService] Failed to generate CIImage")
            return nil
        }
        
        // Scale the image to desired size
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            print("❌ [QRCodeService] Failed to create CGImage")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Generates a QR code for a premium member card
    /// The QR code contains: user_id, card_type, member_since, and a verification token
    /// - Parameters:
    ///   - userId: The user's unique ID
    ///   - cardType: The card type (gold, platinum, black)
    ///   - memberSince: The sign-up date
    /// - Returns: A UIImage of the QR code
    func generateMemberCardQRCode(userId: String, cardType: String, memberSince: Date) -> UIImage? {
        // Create a JSON payload with member info
        let payload: [String: Any] = [
            "user_id": userId,
            "card_type": cardType,
            "member_since": ISO8601DateFormatter().string(from: memberSince),
            "app": "soteria",
            "version": "1.0"
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ [QRCodeService] Failed to create JSON payload")
            return nil
        }
        
        // Generate QR code with appropriate size for card display
        return generateQRCode(from: jsonString, size: CGSize(width: 120, height: 120))
    }
    
    /// Generates a verification token for the QR code
    /// This would typically be generated server-side and stored securely
    /// For now, we'll create a simple hash-based token
    func generateVerificationToken(userId: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let combined = "\(userId)_\(timestamp)_soteria_premium"
        
        // Simple hash (in production, use proper cryptographic hashing)
        let hash = combined.hash
        return String(abs(hash))
    }
}

