//
//  DuplicateScreenshotDetector.swift
//  soteria
//
//  Prevents users from uploading the same screenshot multiple times to farm loyalty points
//  Uses perceptual image hashing + metadata fingerprinting
//

import Foundation
import UIKit
import CryptoKit

class DuplicateScreenshotDetector {
    static let shared = DuplicateScreenshotDetector()
    
    // MARK: - Storage
    struct ScreenshotFingerprint: Codable {
        let imageHash: String              // Perceptual hash of the image
        let metadataHash: String           // Hash of extracted text
        let amount: Double                 // Deposit amount
        let extractedDate: String?         // Date from screenshot (if found)
        let bankKeywords: [String]         // Bank names found
        let timestamp: Date                // When uploaded
        let userId: String                 // Who uploaded it
        
        // Composite key for quick lookups
        var compositeKey: String {
            return "\(amount)_\(extractedDate ?? "")_\(bankKeywords.sorted().joined(separator: "_"))"
        }
    }
    
    private let fingerprintsKey = "screenshot_fingerprints"
    private let maxFingerprintAge: TimeInterval = 90 * 24 * 60 * 60 // 90 days
    
    private init() {}
    
    // MARK: - Duplicate Detection
    
    /// Check if a screenshot is a duplicate (already uploaded)
    /// - Parameters:
    ///   - image: The screenshot to check
    ///   - amount: Claimed deposit amount
    ///   - extractedText: Text extracted from the screenshot
    /// - Returns: DuplicateCheckResult indicating if it's a duplicate
    func checkForDuplicate(
        image: UIImage,
        amount: Double,
        extractedText: String,
        bankKeywords: [String]
    ) -> DuplicateCheckResult {
        // Step 1: Generate fingerprints for this image
        let imageHash = generatePerceptualHash(image: image)
        let metadataHash = generateMetadataHash(text: extractedText)
        let extractedDate = extractDateFromText(extractedText)
        
        // Step 2: Load existing fingerprints
        let existingFingerprints = loadFingerprints()
        
        // Step 3: Check for exact image hash match (same pixel data)
        if let exactMatch = existingFingerprints.first(where: { $0.imageHash == imageHash }) {
            let daysSinceUpload = Date().timeIntervalSince(exactMatch.timestamp) / (24 * 60 * 60)
            return .duplicate(
                reason: "Exact image match detected",
                originalTimestamp: exactMatch.timestamp,
                confidence: 1.0,
                details: "Same screenshot uploaded \(Int(daysSinceUpload)) days ago"
            )
        }
        
        // Step 4: Check for metadata match (same text content)
        if let metadataMatch = existingFingerprints.first(where: { $0.metadataHash == metadataHash }) {
            let daysSinceUpload = Date().timeIntervalSince(metadataMatch.timestamp) / (24 * 60 * 60)
            return .duplicate(
                reason: "Identical text content detected",
                originalTimestamp: metadataMatch.timestamp,
                confidence: 0.95,
                details: "Screenshot with same text uploaded \(Int(daysSinceUpload)) days ago"
            )
        }
        
        // Step 5: Check for suspicious similarity (same amount + date + bank within 7 days)
        let recentSimilar = existingFingerprints.filter { fingerprint in
            guard fingerprint.amount == amount else { return false }
            guard fingerprint.extractedDate == extractedDate else { return false }
            guard !Set(fingerprint.bankKeywords).intersection(bankKeywords).isEmpty else { return false }
            
            let daysSinceUpload = Date().timeIntervalSince(fingerprint.timestamp) / (24 * 60 * 60)
            return daysSinceUpload < 7 // Within last 7 days
        }
        
        if !recentSimilar.isEmpty {
            let mostRecent = recentSimilar.sorted { $0.timestamp > $1.timestamp }.first!
            let daysSinceUpload = Date().timeIntervalSince(mostRecent.timestamp) / (24 * 60 * 60)
            return .suspicious(
                reason: "Similar deposit recently uploaded",
                confidence: 0.7,
                details: "Same amount ($\(amount)), date (\(extractedDate ?? "unknown")), and bank uploaded \(Int(daysSinceUpload)) days ago. This could be legitimate (e.g., recurring deposits), but flagged for review."
            )
        }
        
        // Step 6: Check for amount-only duplicates within 24 hours (high-frequency exploit)
        let recentSameAmount = existingFingerprints.filter { fingerprint in
            guard fingerprint.amount == amount else { return false }
            let hoursSinceUpload = Date().timeIntervalSince(fingerprint.timestamp) / (60 * 60)
            return hoursSinceUpload < 24 // Within last 24 hours
        }
        
        if recentSameAmount.count >= 3 {
            return .suspicious(
                reason: "Multiple deposits of same amount in 24 hours",
                confidence: 0.8,
                details: "\(recentSameAmount.count) deposits of $\(amount) in the last 24 hours. Possible duplicate exploitation."
            )
        }
        
        // Step 7: Not a duplicate - safe to proceed
        return .unique
    }
    
    /// Store fingerprint after successful verification
    func storeFingerprint(
        image: UIImage,
        amount: Double,
        extractedText: String,
        bankKeywords: [String],
        userId: String
    ) {
        let imageHash = generatePerceptualHash(image: image)
        let metadataHash = generateMetadataHash(text: extractedText)
        let extractedDate = extractDateFromText(extractedText)
        
        let fingerprint = ScreenshotFingerprint(
            imageHash: imageHash,
            metadataHash: metadataHash,
            amount: amount,
            extractedDate: extractedDate,
            bankKeywords: bankKeywords,
            timestamp: Date(),
            userId: userId
        )
        
        var fingerprints = loadFingerprints()
        fingerprints.append(fingerprint)
        
        // Clean up old fingerprints (>90 days)
        fingerprints = fingerprints.filter { fingerprint in
            Date().timeIntervalSince(fingerprint.timestamp) < maxFingerprintAge
        }
        
        saveFingerprints(fingerprints)
        
        print("✅ [DuplicateDetector] Stored fingerprint for deposit: $\(amount)")
    }
    
    // MARK: - Perceptual Image Hashing
    
    /// Generate a perceptual hash (pHash) of the image
    /// This allows detection of near-identical images (e.g., screenshots of same screen)
    private func generatePerceptualHash(image: UIImage) -> String {
        // Step 1: Resize to 32x32 (standardize)
        let resized = image.resized(toMaxDimension: 32)
        
        // Step 2: Convert to grayscale and get pixel data
        guard let cgImage = resized.cgImage,
              let pixelData = cgImage.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return "INVALID_HASH"
        }
        
        // Step 3: Calculate average pixel value
        let pixelCount = cgImage.width * cgImage.height
        var sum: Int = 0
        for i in 0..<pixelCount {
            let offset = i * 4 // RGBA
            sum += Int(data[offset]) // Red channel (good enough for grayscale)
        }
        let average = sum / pixelCount
        
        // Step 4: Generate hash (1 bit per pixel: above/below average)
        var hashBits: [Bool] = []
        for i in 0..<pixelCount {
            let offset = i * 4
            hashBits.append(Int(data[offset]) > average)
        }
        
        // Step 5: Convert bits to hex string
        var hashString = ""
        for i in stride(from: 0, to: hashBits.count, by: 8) {
            var byte: UInt8 = 0
            for j in 0..<8 {
                if i + j < hashBits.count && hashBits[i + j] {
                    byte |= (1 << j)
                }
            }
            hashString += String(format: "%02x", byte)
        }
        
        return hashString
    }
    
    /// Generate a hash of the extracted text (for duplicate text detection)
    private func generateMetadataHash(text: String) -> String {
        // Normalize text (lowercase, remove whitespace, sort words)
        let normalized = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .sorted()
            .joined(separator: " ")
        
        // Hash using SHA256
        let data = Data(normalized.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Extract date from text (if present)
    private func extractDateFromText(_ text: String) -> String? {
        // Look for date patterns: MM/DD/YYYY, Jan 9 2026, etc.
        let datePatterns = [
            #"\d{1,2}/\d{1,2}/\d{2,4}"#, // 1/9/26 or 01/09/2026
            #"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},?\s+\d{4}"# // Jan 9 2026
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, range: range) {
                    return (text as NSString).substring(with: match.range)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Persistence
    
    private func loadFingerprints() -> [ScreenshotFingerprint] {
        guard let data = UserDefaults.standard.data(forKey: fingerprintsKey),
              let fingerprints = try? JSONDecoder().decode([ScreenshotFingerprint].self, from: data) else {
            return []
        }
        return fingerprints
    }
    
    private func saveFingerprints(_ fingerprints: [ScreenshotFingerprint]) {
        if let encoded = try? JSONEncoder().encode(fingerprints) {
            UserDefaults.standard.set(encoded, forKey: fingerprintsKey)
        }
    }
    
    /// Clear all fingerprints (for testing or user request)
    func clearAllFingerprints() {
        UserDefaults.standard.removeObject(forKey: fingerprintsKey)
        print("🗑️ [DuplicateDetector] Cleared all fingerprints")
    }
    
    /// Get statistics for debugging
    func getStats() -> (totalFingerprints: Int, oldestFingerprint: Date?, newestFingerprint: Date?) {
        let fingerprints = loadFingerprints()
        let oldest = fingerprints.map { $0.timestamp }.min()
        let newest = fingerprints.map { $0.timestamp }.max()
        return (fingerprints.count, oldest, newest)
    }
}

// MARK: - Result Types

enum DuplicateCheckResult {
    case unique // Safe to proceed
    case duplicate(reason: String, originalTimestamp: Date, confidence: Double, details: String)
    case suspicious(reason: String, confidence: Double, details: String)
    
    var isDuplicate: Bool {
        switch self {
        case .duplicate: return true
        default: return false
        }
    }
    
    var isSuspicious: Bool {
        switch self {
        case .suspicious: return true
        default: return false
        }
    }
    
    var shouldBlock: Bool {
        // Block if duplicate with high confidence
        switch self {
        case .duplicate(_, _, let confidence, _):
            return confidence >= 0.9
        case .suspicious(_, let confidence, _):
            return confidence >= 0.85
        default:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .unique:
            return "Screenshot is unique"
        case .duplicate(let reason, _, let confidence, let details):
            return "Duplicate detected (\(Int(confidence * 100))%): \(reason). \(details)"
        case .suspicious(let reason, let confidence, let details):
            return "Suspicious (\(Int(confidence * 100))%): \(reason). \(details)"
        }
    }
}

