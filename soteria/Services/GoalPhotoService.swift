//
//  GoalPhotoService.swift
//  soteria
//
//  Service for uploading and downloading goal photos from AWS S3
//  Photos persist until goal is deleted
//

import Foundation
import UIKit

class GoalPhotoService {
    static let shared = GoalPhotoService()
    
    private let cognitoService = CognitoAuthService.shared
    
    // API Gateway URL (same as other services)
    private let apiGatewayURL = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod"
    
    private init() {
        print("✅ [GoalPhotoService] Initialized")
    }
    
    /// Upload goal photo to S3
    /// - Parameters:
    ///   - image: The goal photo image to upload
    ///   - goalId: The goal ID
    /// - Returns: The S3 URL of the uploaded photo
    func uploadGoalPhoto(image: UIImage, goalId: String) async throws -> String {
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "GoalPhotoService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Resize image to reasonable size (600px max dimension for goal photos)
        let maxDimension: CGFloat = 600
        let resizedImage = max(image.size.width, image.size.height) > maxDimension
            ? image.resized(toMaxDimension: maxDimension)
            : image
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "GoalPhotoService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }
        
        // Convert to base64
        let base64Data = imageData.base64EncodedString()
        
        // Get ID token for authentication
        guard let idToken = try? await cognitoService.getIDToken() else {
            throw NSError(domain: "GoalPhotoService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to get authentication token"])
        }
        
        // Create request
        let url = URL(string: "\(apiGatewayURL)/soteria/goal-photo/upload?user_id=\(userId)&goal_id=\(goalId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0 // 10 seconds for larger images
        
        // Create request body
        let requestBody: [String: Any] = [
            "user_id": userId,
            "goal_id": goalId,
            "photo_data": base64Data,
            "content_type": "image/jpeg"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GoalPhotoService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "GoalPhotoService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let photoUrl = json["photo_url"] as? String else {
            throw NSError(domain: "GoalPhotoService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to parse upload response"])
        }
        
        print("✅ [GoalPhotoService] Goal photo uploaded successfully: \(photoUrl)")
        return photoUrl
    }
    
    /// Download goal photo from S3
    /// - Parameter goalId: The goal ID to download photo for
    /// - Returns: The goal photo image, or nil if not found
    func downloadGoalPhoto(goalId: String) async throws -> UIImage? {
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "GoalPhotoService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get ID token for authentication
        guard let idToken = try? await cognitoService.getIDToken() else {
            throw NSError(domain: "GoalPhotoService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to get authentication token"])
        }
        
        // Create request
        let url = URL(string: "\(apiGatewayURL)/soteria/goal-photo/download?user_id=\(userId)&goal_id=\(goalId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GoalPhotoService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // 404 is OK - photo doesn't exist
        if httpResponse.statusCode == 404 {
            print("ℹ️ [GoalPhotoService] Goal photo not found in S3 (this is OK)")
            return nil
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "GoalPhotoService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let base64Data = json["photo_data"] as? String,
              let imageData = Data(base64Encoded: base64Data),
              let image = UIImage(data: imageData) else {
            throw NSError(domain: "GoalPhotoService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to parse download response"])
        }
        
        print("✅ [GoalPhotoService] Goal photo downloaded successfully")
        return image
    }
    
    /// Delete goal photo from S3 (called when goal is deleted)
    /// - Parameter goalId: The goal ID whose photo should be deleted
    func deleteGoalPhoto(goalId: String) async throws {
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "GoalPhotoService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get ID token for authentication
        guard let idToken = try? await cognitoService.getIDToken() else {
            throw NSError(domain: "GoalPhotoService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to get authentication token"])
        }
        
        // Create request
        let url = URL(string: "\(apiGatewayURL)/soteria/goal-photo/delete?user_id=\(userId)&goal_id=\(goalId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 5.0
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GoalPhotoService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // 404 is OK - photo doesn't exist
        if httpResponse.statusCode == 404 {
            print("ℹ️ [GoalPhotoService] Goal photo not found in S3 (already deleted)")
            return
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "GoalPhotoService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        print("✅ [GoalPhotoService] Goal photo deleted successfully")
    }
}

