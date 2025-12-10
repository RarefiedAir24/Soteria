//
//  AWSDataService.swift
//  soteria
//
//  Service to sync user data with AWS DynamoDB via API Gateway
//

import Foundation
import Combine
import FirebaseAuth

class AWSDataService: ObservableObject {
    static let shared = AWSDataService()
    
    // API Gateway URL - Update this after creating the API Gateway
    private let apiGatewayURL = "https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod"
    
    // Data type constants
    enum DataType: String {
        case appNames = "app_names"
        case purchaseIntents = "purchase_intents"
        case goals = "goals"
        case regrets = "regrets"
        case moods = "moods"
        case quietHours = "quiet_hours"
        case appUsage = "app_usage"
        case unblockEvents = "unblock_events"
    }
    
    private init() {
        print("✅ [AWSDataService] Initialized")
    }
    
    // Get current user ID from Firebase Auth
    private func getUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    // Sync data to AWS
    func syncData<T: Codable>(_ data: T, dataType: DataType) async throws {
        guard let userId = getUserId() else {
            throw NSError(domain: "AWSDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Encode data to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        guard let jsonData = try? encoder.encode(data),
              let dataDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "AWSDataService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode data"])
        }
        
        // Prepare request
        let url = URL(string: "\(apiGatewayURL)/soteria/sync")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0 // 10 second timeout to prevent long freezes
        
        // Get Firebase ID token for authentication
        if let idToken = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Request body
        let requestBody: [String: Any] = [
            "user_id": userId,
            "data_type": dataType.rawValue,
            "data": dataDict
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AWSDataService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AWSDataService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Parse response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let success = json["success"] as? Bool, success {
            print("✅ [AWSDataService] Data synced successfully: \(dataType.rawValue)")
        } else {
            throw NSError(domain: "AWSDataService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Sync failed"])
        }
    }
    
    // Get data from AWS (generic array)
    func getData<T: Codable>(dataType: DataType, itemId: String? = nil) async throws -> [T] {
        guard let userId = getUserId() else {
            throw NSError(domain: "AWSDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Build URL with query parameters
        var urlComponents = URLComponents(string: "\(apiGatewayURL)/soteria/data")!
        urlComponents.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "data_type", value: dataType.rawValue)
        ]
        
        if let itemId = itemId {
            urlComponents.queryItems?.append(URLQueryItem(name: "item_id", value: itemId))
        }
        
        guard let url = urlComponents.url else {
            throw NSError(domain: "AWSDataService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0 // 10 second timeout to prevent long freezes
        
        // Get Firebase ID token for authentication
        if let idToken = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AWSDataService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AWSDataService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success else {
            throw NSError(domain: "AWSDataService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        // Handle different data types
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        var results: [T] = []
        
        // Special handling for app_names (it's a dictionary, not an array)
        if dataType == .appNames, let dataDict = json["data"] as? [String: String] {
            // Convert dictionary to array of key-value pairs, then decode
            if let jsonData = try? JSONSerialization.data(withJSONObject: dataDict),
               let decoded = try? decoder.decode(T.self, from: jsonData) {
                results.append(decoded)
            }
        } else if let dataArray = json["data"] as? [[String: Any]] {
            // Array of items
            for item in dataArray {
                if let jsonData = try? JSONSerialization.data(withJSONObject: item),
                   let decoded = try? decoder.decode(T.self, from: jsonData) {
                    results.append(decoded)
                }
            }
        } else if let singleItem = json["data"] as? [String: Any] {
            // Single item
            if let jsonData = try? JSONSerialization.data(withJSONObject: singleItem),
               let decoded = try? decoder.decode(T.self, from: jsonData) {
                results.append(decoded)
            }
        }
        
        print("✅ [AWSDataService] Retrieved \(results.count) item(s): \(dataType.rawValue)")
        return results
    }
    
    // Special method for app_names (returns dictionary)
    func getAppNames() async throws -> [Int: String] {
        guard let userId = getUserId() else {
            throw NSError(domain: "AWSDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var urlComponents = URLComponents(string: "\(apiGatewayURL)/soteria/data")!
        urlComponents.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "data_type", value: DataType.appNames.rawValue)
        ]
        
        guard let url = urlComponents.url else {
            throw NSError(domain: "AWSDataService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0 // 10 second timeout to prevent long freezes
        
        if let idToken = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AWSDataService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AWSDataService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let dataDict = json["data"] as? [String: String] else {
            throw NSError(domain: "AWSDataService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        // Convert string keys to Int keys
        var result: [Int: String] = [:]
        for (key, value) in dataDict {
            if let index = Int(key) {
                result[index] = value
            }
        }
        
        return result
    }
    
    // Batch sync multiple items
    func batchSync<T: Codable>(_ items: [T], dataType: DataType) async throws {
        for item in items {
            try await syncData(item, dataType: dataType)
        }
    }
    
    // Update API Gateway URL (call this after creating the API Gateway)
    func updateAPIGatewayURL(_ url: String) {
        // This would need to be a mutable property, but for now we'll use a static approach
        // In production, you might want to store this in UserDefaults or a config file
        print("⚠️ [AWSDataService] To update API Gateway URL, modify the apiGatewayURL property in AWSDataService.swift")
    }
}

