//
//  DepositScreenshotService.swift
//  soteria
//
//  Handles storage and retrieval of deposit screenshots
//

import Foundation
import UIKit

class DepositScreenshotService {
    static let shared = DepositScreenshotService()
    
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private init() {}
    
    /// Save screenshot for a deposit
    /// Returns the file path if successful, nil otherwise
    func saveScreenshot(_ image: UIImage, for depositId: String) -> String? {
        // Create screenshots directory if it doesn't exist
        let screenshotsDir = documentsDirectory.appendingPathComponent("deposit_screenshots")
        if !fileManager.fileExists(atPath: screenshotsDir.path) {
            try? fileManager.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
        }
        
        // Resize image to reasonable size (max 1200px width/height)
        let resizedImage = image.resized(toMaxDimension: 1200)
        
        // Save as JPEG with reasonable quality
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            print("❌ [DepositScreenshotService] Failed to convert image to JPEG")
            return nil
        }
        
        // Save to file
        let fileName = "\(depositId).jpg"
        let filePath = screenshotsDir.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: filePath)
            print("✅ [DepositScreenshotService] Screenshot saved: \(filePath.path)")
            return filePath.path
        } catch {
            print("❌ [DepositScreenshotService] Failed to save screenshot: \(error)")
            return nil
        }
    }
    
    /// Load screenshot for a deposit
    func loadScreenshot(for depositId: String) -> UIImage? {
        let screenshotsDir = documentsDirectory.appendingPathComponent("deposit_screenshots")
        let fileName = "\(depositId).jpg"
        let filePath = screenshotsDir.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: filePath.path),
              let imageData = try? Data(contentsOf: filePath),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    /// Delete screenshot for a deposit
    func deleteScreenshot(for depositId: String) {
        let screenshotsDir = documentsDirectory.appendingPathComponent("deposit_screenshots")
        let fileName = "\(depositId).jpg"
        let filePath = screenshotsDir.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: filePath.path) {
            try? fileManager.removeItem(at: filePath)
            print("✅ [DepositScreenshotService] Screenshot deleted: \(filePath.path)")
        }
    }
    
    /// Save screenshot to UserDefaults as fallback (for smaller images)
    /// This is used as a backup if file system storage fails
    func saveScreenshotToUserDefaults(_ image: UIImage, for depositId: String) {
        // Only save small thumbnails to UserDefaults (max 300px)
        let thumbnail = image.resized(toMaxDimension: 300)
        if let imageData = thumbnail.jpegData(compressionQuality: 0.7) {
            let key = "deposit_screenshot_\(depositId)"
            UserDefaults.standard.set(imageData, forKey: key)
            print("✅ [DepositScreenshotService] Screenshot thumbnail saved to UserDefaults: \(depositId)")
        }
    }
    
    /// Load screenshot from UserDefaults (fallback)
    func loadScreenshotFromUserDefaults(for depositId: String) -> UIImage? {
        let key = "deposit_screenshot_\(depositId)"
        if let imageData = UserDefaults.standard.data(forKey: key),
           let image = UIImage(data: imageData) {
            return image
        }
        return nil
    }
}

