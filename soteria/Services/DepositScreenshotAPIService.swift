//
//  DepositScreenshotAPIService.swift
//  soteria
//
//  API service for syncing deposit screenshots to cloud storage
//

import Foundation
import UIKit

class DepositScreenshotAPIService {
    static let shared = DepositScreenshotAPIService()
    
    private let cognitoService = CognitoAuthService.shared
    private let localScreenshotService = DepositScreenshotService.shared
    
    // API Gateway URL (same as other services)
    private let apiGatewayURL = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod"
    
    private init() {
        print("✅ [DepositScreenshotAPIService] Initialized")
    }
    
    /// Upload screenshot to S3 via API Gateway
    /// - Parameters:
    ///   - image: The screenshot image to upload
    ///   - depositId: The deposit ID
    /// - Returns: The S3 URL of the uploaded screenshot
    func uploadScreenshot(image: UIImage, depositId: String) async throws -> String {
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Resize image to reasonable size (1200px max dimension)
        let resizedImage = image.resized(toMaxDimension: 1200)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }
        
        // Convert to base64
        let base64Data = imageData.base64EncodedString()
        
        // Get ID token for authentication
        guard let idToken = try? await cognitoService.getIDToken() else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to get authentication token"])
        }
        
        // Create request
        let url = URL(string: "\(apiGatewayURL)/soteria/deposit-screenshot/upload?user_id=\(userId)&deposit_id=\(depositId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15.0 // 15 seconds for larger images
        
        // Create request body
        let requestBody: [String: Any] = [
            "image_data": base64Data,
            "deposit_id": depositId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "DepositScreenshotAPIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Upload failed: \(errorMessage)"])
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let s3Url = json["s3_url"] as? String else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        print("✅ [DepositScreenshotAPIService] Screenshot uploaded to S3: \(s3Url)")
        return s3Url
    }
    
    /// Download screenshot from S3 via API Gateway
    /// - Parameter depositId: The deposit ID
    /// - Returns: The screenshot image, or nil if not found
    func downloadScreenshot(depositId: String) async throws -> UIImage? {
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get ID token for authentication
        guard let idToken = try? await cognitoService.getIDToken() else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to get authentication token"])
        }
        
        // Create request
        let url = URL(string: "\(apiGatewayURL)/soteria/deposit-screenshot/download?user_id=\(userId)&deposit_id=\(depositId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                // Screenshot not found - not an error
                return nil
            }
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "DepositScreenshotAPIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Download failed: \(errorMessage)"])
        }
        
        // Parse image from response
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to parse image"])
        }
        
        // Cache locally
        localScreenshotService.saveScreenshot(image, for: depositId)
        localScreenshotService.saveScreenshotToUserDefaults(image, for: depositId)
        
        print("✅ [DepositScreenshotAPIService] Screenshot downloaded from S3: \(depositId)")
        return image
    }
    
    /// Delete screenshot from S3 via API Gateway
    /// - Parameter depositId: The deposit ID
    func deleteScreenshot(depositId: String) async throws {
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get ID token for authentication
        guard let idToken = try? await cognitoService.getIDToken() else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to get authentication token"])
        }
        
        // Create request
        let url = URL(string: "\(apiGatewayURL)/soteria/deposit-screenshot/delete?user_id=\(userId)&deposit_id=\(depositId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0
        
        // Make request
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "DepositScreenshotAPIService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 404 else {
            throw NSError(domain: "DepositScreenshotAPIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        }
        
        print("✅ [DepositScreenshotAPIService] Screenshot deleted from S3: \(depositId)")
    }
    
    /// Sync all local screenshots to cloud (background task)
    /// This should be called periodically or when app comes to foreground
    func syncAllScreenshots() async {
        let plaidService = PlaidService.shared
        let deposits = plaidService.depositHistory.filter { $0.type == .manual }
        
        print("🔄 [DepositScreenshotAPIService] Syncing \(deposits.count) deposit screenshots...")
        
        for deposit in deposits {
            // Check if screenshot exists locally
            if let localScreenshot = localScreenshotService.loadScreenshot(for: deposit.id) {
                // Check if already synced (we could add a flag to SavingsDeposit)
                // For now, try to upload (API will handle duplicates)
                do {
                    _ = try await uploadScreenshot(image: localScreenshot, depositId: deposit.id)
                    print("✅ [DepositScreenshotAPIService] Synced screenshot for deposit: \(deposit.id)")
                } catch {
                    print("⚠️ [DepositScreenshotAPIService] Failed to sync screenshot for deposit \(deposit.id): \(error.localizedDescription)")
                }
            }
        }
        
        print("✅ [DepositScreenshotAPIService] Sync complete")
    }
}

