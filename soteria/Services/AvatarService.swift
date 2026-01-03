//
//  AvatarService.swift
//  soteria
//
//  Service for uploading and downloading user avatars from AWS S3
//

import Foundation
import UIKit

class AvatarService {
    static let shared = AvatarService()
    
    private let cognitoService = CognitoAuthService.shared
    
    // API Gateway URL (same as other services)
    private let apiGatewayURL = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod"
    
    private init() {
        print("✅ [AvatarService] Initialized")
    }
    
    /// Upload avatar to S3
    /// - Parameter image: The avatar image to upload
    /// - Returns: The S3 URL of the uploaded avatar
    func uploadAvatar(image: UIImage) async throws -> String {
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "AvatarService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Resize image to reasonable size (200x200 for avatar)
        let resizedImage = image.resized(to: CGSize(width: 200, height: 200))
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "AvatarService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }
        
        // Convert to base64
        let base64Data = imageData.base64EncodedString()
        
        // Get ID token for authentication
        guard let idToken = try? await cognitoService.getIDToken() else {
            throw NSError(domain: "AvatarService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to get authentication token"])
        }
        
        // Create request
        let url = URL(string: "\(apiGatewayURL)/soteria/avatar/upload?user_id=\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 5.0 // Reduced timeout to prevent long delays
        
        // Create request body
        let requestBody: [String: Any] = [
            "user_id": userId,
            "avatar_data": base64Data,
            "content_type": "image/jpeg"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AvatarService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AvatarService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let avatarUrl = json["avatar_url"] as? String else {
            throw NSError(domain: "AvatarService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to parse upload response"])
        }
        
        print("✅ [AvatarService] Avatar uploaded successfully: \(avatarUrl)")
        return avatarUrl
    }
    
    /// Download avatar from S3
    /// - Parameter userId: The user ID to download avatar for (defaults to current user)
    /// - Returns: The avatar image, or nil if not found
    func downloadAvatar(userId: String? = nil) async throws -> UIImage? {
        let targetUserId = userId ?? cognitoService.getUserId()
        
        guard let targetUserId = targetUserId else {
            throw NSError(domain: "AvatarService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get ID token for authentication
        guard let idToken = try? await cognitoService.getIDToken() else {
            throw NSError(domain: "AvatarService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to get authentication token"])
        }
        
        // Create request
        let url = URL(string: "\(apiGatewayURL)/soteria/avatar/download?user_id=\(targetUserId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 5.0 // Reduced timeout to prevent long delays
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AvatarService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // 404 is OK - avatar doesn't exist
        if httpResponse.statusCode == 404 {
            print("ℹ️ [AvatarService] Avatar not found in S3 (this is OK)")
            return nil
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AvatarService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let base64Data = json["avatar_data"] as? String,
              let imageData = Data(base64Encoded: base64Data),
              let image = UIImage(data: imageData) else {
            throw NSError(domain: "AvatarService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to parse download response"])
        }
        
        print("✅ [AvatarService] Avatar downloaded successfully")
        return image
    }
}

// MARK: - UIImage Extension for Resizing
// Note: UIImage.resized() extension is defined in ProfileView.swift
// This service uses that existing extension

