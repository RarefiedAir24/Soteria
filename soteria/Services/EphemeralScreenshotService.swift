//
//  EphemeralScreenshotService.swift
//  soteria
//
//  PRIVACY-FIRST: Screenshots are NEVER stored, only verified and discarded
//  This service replaces DepositScreenshotService for maximum security
//

import Foundation
import UIKit

/// Privacy-first screenshot verification service
/// Images are processed in-memory only and immediately discarded after verification
class EphemeralScreenshotService {
    static let shared = EphemeralScreenshotService()
    
    // MARK: - Verification Metadata Storage
    struct VerificationMetadata: Codable {
        let depositId: String
        let isVerified: Bool
        let confidence: Double
        let verifiedAt: Date
        let extractedAmount: Double?
        let reason: String
        
        // NO image data stored here!
    }
    
    private let metadataKey = "deposit_verification_metadata"
    
    private init() {}
    
    // MARK: - Ephemeral Verification
    
    /// Verify a screenshot WITHOUT storing it
    /// - Parameters:
    ///   - image: The screenshot (in-memory only)
    ///   - depositId: The deposit ID
    ///   - claimedAmount: The amount user claims to have deposited
    /// - Returns: Verification result (image is discarded after)
    func verifyScreenshotEphemerally(
        image: UIImage,
        depositId: String,
        claimedAmount: Double
    ) async throws -> ScreenshotVerificationService.VerificationResult {
        print("🔒 [EphemeralScreenshot] Verifying screenshot (ephemeral mode)")
        
        // Step 1: Local pre-screening
        if let quickReject = ScreenshotVerificationService.shared.performLocalPreScreening(
            image: image,
            claimedAmount: claimedAmount
        ) {
            // Failed pre-screening, reject immediately
            saveVerificationMetadata(depositId: depositId, result: quickReject)
            print("❌ [EphemeralScreenshot] Pre-screening failed: \(quickReject.reason)")
            return quickReject
        }
        
        // Step 2: Full AI verification
        let result = try await ScreenshotVerificationService.shared.verifyScreenshot(
            image: image,
            claimedAmount: claimedAmount
        )
        
        // Step 3: 🚨 FRAUD PREVENTION: Check for duplicate screenshots
        // Users could farm points by uploading the same screenshot repeatedly
        let duplicateCheck = DuplicateScreenshotDetector.shared.checkForDuplicate(
            image: image,
            amount: claimedAmount,
            extractedText: result.extractedText,
            bankKeywords: result.foundKeywords ?? []
        )
        
        if duplicateCheck.shouldBlock {
            print("🚫 [EphemeralScreenshot] DUPLICATE DETECTED: \(duplicateCheck.description)")
            
            // Return rejection result
            let rejectionResult = ScreenshotVerificationService.VerificationResult(
                isValid: false,
                confidence: 0.0,
                extractedAmount: result.extractedAmount,
                extractedText: result.extractedText,
                fraudIndicators: ["Duplicate screenshot detected"],
                reason: duplicateCheck.description,
                foundKeywords: result.foundKeywords
            )
            
            saveVerificationMetadata(depositId: depositId, result: rejectionResult)
            return rejectionResult
        }
        
        if duplicateCheck.isSuspicious {
            print("⚠️ [EphemeralScreenshot] SUSPICIOUS: \(duplicateCheck.description)")
            // Log but allow (for now) - monitor for patterns
        }
        
        // Step 4: Store fingerprint for future duplicate detection
        if result.isValid, let userId = CognitoAuthService.shared.getUserId() {
            DuplicateScreenshotDetector.shared.storeFingerprint(
                image: image,
                amount: claimedAmount,
                extractedText: result.extractedText,
                bankKeywords: result.foundKeywords ?? [],
                userId: userId
            )
        }
        
        // Step 5: Save metadata only (NOT the image)
        saveVerificationMetadata(depositId: depositId, result: result)
        
        print("✅ [EphemeralScreenshot] Verification complete: \(result.isValid ? "PASS" : "FAIL") (confidence: \(result.confidence))")
        print("🗑️ [EphemeralScreenshot] Image discarded (never stored)")
        
        // Image goes out of scope here and is garbage collected
        return result
    }
    
    // MARK: - Metadata Storage (NOT images)
    
    /// Save verification metadata (result, confidence, date - NOT image)
    private func saveVerificationMetadata(
        depositId: String,
        result: ScreenshotVerificationService.VerificationResult
    ) {
        let metadata = VerificationMetadata(
            depositId: depositId,
            isVerified: result.isValid,
            confidence: result.confidence,
            verifiedAt: Date(),
            extractedAmount: result.extractedAmount,
            reason: result.reason
        )
        
        var allMetadata = loadAllVerificationMetadata()
        allMetadata[depositId] = metadata
        
        if let encoded = try? JSONEncoder().encode(allMetadata) {
            UserDefaults.standard.set(encoded, forKey: metadataKey)
        }
        
        print("💾 [EphemeralScreenshot] Saved metadata for deposit: \(depositId)")
    }
    
    /// Load verification metadata for a specific deposit
    func getVerificationMetadata(for depositId: String) -> VerificationMetadata? {
        let allMetadata = loadAllVerificationMetadata()
        return allMetadata[depositId]
    }
    
    /// Load all verification metadata
    private func loadAllVerificationMetadata() -> [String: VerificationMetadata] {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let metadata = try? JSONDecoder().decode([String: VerificationMetadata].self, from: data) else {
            return [:]
        }
        return metadata
    }
    
    /// Check if a deposit has been verified
    func isDepositVerified(_ depositId: String) -> Bool {
        return getVerificationMetadata(for: depositId)?.isVerified ?? false
    }
    
    /// Get verification confidence for a deposit
    func getVerificationConfidence(_ depositId: String) -> Double? {
        return getVerificationMetadata(for: depositId)?.confidence
    }
    
    // MARK: - Cleanup (Legacy Screenshots)
    
    /// Delete any legacy screenshots from old storage system
    /// Call this on app launch to clean up after migration
    func cleanupLegacyScreenshots() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let screenshotsDir = documentsDirectory.appendingPathComponent("deposit_screenshots")
        
        if fileManager.fileExists(atPath: screenshotsDir.path) {
            do {
                let files = try fileManager.contentsOfDirectory(at: screenshotsDir, includingPropertiesForKeys: nil)
                for file in files {
                    try fileManager.removeItem(at: file)
                }
                print("🗑️ [EphemeralScreenshot] Deleted \(files.count) legacy screenshots")
            } catch {
                print("⚠️ [EphemeralScreenshot] Failed to clean up legacy screenshots: \(error)")
            }
        }
        
        // Also clean up UserDefaults thumbnails
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        let screenshotKeys = allKeys.filter { $0.hasPrefix("deposit_screenshot_") }
        
        for key in screenshotKeys {
            defaults.removeObject(forKey: key)
        }
        
        if !screenshotKeys.isEmpty {
            print("🗑️ [EphemeralScreenshot] Deleted \(screenshotKeys.count) legacy UserDefaults screenshots")
        }
    }
    
    /// Delete verification metadata older than X days
    /// Call this periodically to clean up old metadata
    func cleanupOldMetadata(olderThanDays days: Int = 90) {
        var allMetadata = loadAllVerificationMetadata()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let oldMetadataCount = allMetadata.count
        allMetadata = allMetadata.filter { $0.value.verifiedAt > cutoffDate }
        
        if let encoded = try? JSONEncoder().encode(allMetadata) {
            UserDefaults.standard.set(encoded, forKey: metadataKey)
        }
        
        let deletedCount = oldMetadataCount - allMetadata.count
        if deletedCount > 0 {
            print("🗑️ [EphemeralScreenshot] Deleted \(deletedCount) old metadata records (>90 days)")
        }
    }
}

