//
//  ScreenshotVerificationService.swift
//  soteria
//
//  Validates deposit screenshots using AWS Textract to prevent fraud
//

import Foundation
import UIKit

class ScreenshotVerificationService {
    static let shared = ScreenshotVerificationService()
    
    private let apiGatewayURL = "https://g3ksyd36e5.execute-api.us-east-1.amazonaws.com/prod"
    
    // MARK: - Verification Result
    struct VerificationResult {
        let isValid: Bool
        let confidence: Double // 0.0 to 1.0
        let extractedAmount: Double?
        let extractedText: String
        let fraudIndicators: [String]
        let reason: String
        let foundKeywords: [String]? // Bank keywords found (for duplicate detection)
        
        var shouldAwardPoints: Bool {
            return isValid && confidence >= 0.7 && fraudIndicators.isEmpty
        }
        
        var pointsMultiplier: Double {
            // Award partial points based on confidence
            if confidence >= 0.9 { return 0.5 }      // High confidence: 50% points
            else if confidence >= 0.7 { return 0.3 } // Medium confidence: 30% points
            else { return 0.0 }                      // Low confidence: No points
        }
    }
    
    private init() {}
    
    // MARK: - Screenshot Verification
    
    /// Verify a deposit screenshot for authenticity
    /// - Parameters:
    ///   - image: The screenshot image
    ///   - claimedAmount: The amount the user claims to have deposited
    /// - Returns: Verification result with confidence score
    func verifyScreenshot(image: UIImage, claimedAmount: Double) async throws -> VerificationResult {
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ScreenshotVerification", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Call AWS Lambda with Textract
        let result = try await analyzeScreenshotWithTextract(base64Image: base64Image, claimedAmount: claimedAmount)
        
        return result
    }
    
    // MARK: - AWS Textract Analysis
    
    private func analyzeScreenshotWithTextract(base64Image: String, claimedAmount: Double) async throws -> VerificationResult {
        let url = URL(string: "\(apiGatewayURL)/soteria/verify-screenshot")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        // Get Cognito auth token
        if let idToken = try? await CognitoAuthService.shared.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: [String: Any] = [
            "image": base64Image,
            "claimed_amount": claimedAmount
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ScreenshotVerification", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "ScreenshotVerification", code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Verification failed with status \(httpResponse.statusCode)"])
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "ScreenshotVerification", code: -3,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        return parseVerificationResult(json: json, claimedAmount: claimedAmount)
    }
    
    // MARK: - Local Pre-Screening (Fast)
    
    /// Quick local checks before sending to AWS (saves API calls)
    func performLocalPreScreening(image: UIImage, claimedAmount: Double) -> VerificationResult? {
        var fraudIndicators: [String] = []
        
        // Check 1: Image dimensions (bank screenshots are typically phone screenshots)
        let size = image.size
        let aspectRatio = size.width / size.height
        
        if aspectRatio < 0.4 || aspectRatio > 0.7 {
            fraudIndicators.append("Unusual aspect ratio for phone screenshot")
        }
        
        // Check 2: Image size (too small = likely fake/cropped)
        if size.width < 300 || size.height < 400 {
            fraudIndicators.append("Image resolution too low")
        }
        
        // Check 3: Unrealistic amounts
        if claimedAmount > 100000 {
            fraudIndicators.append("Claimed amount exceeds $100k")
        }
        
        if claimedAmount < 0.01 {
            fraudIndicators.append("Claimed amount too small")
        }
        
        // If any critical issues found, reject immediately
        if !fraudIndicators.isEmpty {
            return VerificationResult(
                isValid: false,
                confidence: 0.0,
                extractedAmount: nil,
                extractedText: "",
                fraudIndicators: fraudIndicators,
                reason: "Failed local pre-screening: \(fraudIndicators.joined(separator: ", "))",
                foundKeywords: nil
            )
        }
        
        return nil // Pass to AWS for full verification
    }
    
    // MARK: - Result Parsing
    
    private func parseVerificationResult(json: [String: Any], claimedAmount: Double) -> VerificationResult {
        let isValid = json["is_valid"] as? Bool ?? false
        let confidence = json["confidence"] as? Double ?? 0.0
        let extractedAmount = json["extracted_amount"] as? Double
        let extractedText = json["extracted_text"] as? String ?? ""
        let fraudIndicators = json["fraud_indicators"] as? [String] ?? []
        let reason = json["reason"] as? String ?? "Unknown"
        let foundKeywords = json["found_keywords"] as? [String]
        
        return VerificationResult(
            isValid: isValid,
            confidence: confidence,
            extractedAmount: extractedAmount,
            extractedText: extractedText,
            fraudIndicators: fraudIndicators,
            reason: reason,
            foundKeywords: foundKeywords
        )
    }
}

