//
//  AWSDataService.swift
//  soteria
//
//  Service to sync user data with AWS DynamoDB via API Gateway
//

import Foundation
import Combine

class AWSDataService: ObservableObject {
    static let shared = AWSDataService()
    
    private let cognitoService = CognitoAuthService.shared
    
    // API Gateway URL (same as PlaidService for consistency)
    private let apiGatewayURL = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod"
    
    // Get app names from token hashes (backend mapping)
    func getAppNamesFromTokens(tokenHashes: [String]) async throws -> [String: String] {
        guard getUserId() != nil else {
            throw NSError(domain: "AWSDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let urlComponents = URLComponents(string: "\(apiGatewayURL)/soteria/app-name")!
        
        guard let url = urlComponents.url else {
            throw NSError(domain: "AWSDataService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0 // 10 second timeout
        
        // Get Cognito ID token for authentication
        if let idToken = try? await cognitoService.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Request body
        let requestBody: [String: Any] = [
            "token_hashes": tokenHashes
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
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let appNames = json["app_names"] as? [String: String] else {
            throw NSError(domain: "AWSDataService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        return appNames
    }
    
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
    
    // Get current user ID from Cognito
    private func getUserId() -> String? {
        return cognitoService.getUserId()
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
        
        // Get Cognito ID token for authentication
        if let idToken = try? await cognitoService.getIDToken() {
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
        
        // Get Cognito ID token for authentication
        if let idToken = try? await cognitoService.getIDToken() {
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
        
        // Get Cognito ID token for authentication
        if let idToken = try? await cognitoService.getIDToken() {
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
    
    // MARK: - Dashboard API (Pre-computed data for fast loading)
    
    struct DashboardData: Codable {
        let totalSaved: Double
        let currentStreak: Int
        let longestStreak: Int
        let activeGoal: GoalData? // Full goal data from API
        let recentRegretCount: Int
        let currentRisk: String? // Risk level as string
        let isQuietModeActive: Bool
        let soteriaMomentsCount: Int
        let currentMood: String? // Current mood level (e.g., "happy", "stressed")
        let recentMoodCount: Int // Mood entries in last 7 days
        let recentPurchaseIntentsCount: Int // Purchase intents in last 7 days
        let lastUpdated: TimeInterval // Timestamp
        
        struct GoalData: Codable {
            let id: String
            let name: String
            let currentAmount: Double
            let targetAmount: Double
            let progress: Double
            let startDate: TimeInterval? // Date as timestamp
            let targetDate: TimeInterval? // Date as timestamp
            let category: String? // Goal category
            let protectionAmount: Double?
            let photoPath: String?
            let description: String?
            let status: String? // Goal status
            let createdDate: TimeInterval? // Date as timestamp
            let completedDate: TimeInterval? // Date as timestamp
            let completedAmount: Double?
        }
    }
    
    /// Get pre-computed dashboard data from backend
    /// This is much faster than loading from multiple services locally
    /// Backend pre-computes: streaks, totals, aggregates, etc.
    func getDashboardData() async throws -> DashboardData {
        guard let userId = getUserId() else {
            throw NSError(domain: "AWSDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let url = URL(string: "\(apiGatewayURL)/soteria/dashboard")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 3.0 // 3 second timeout for fast response (reduced from 5s)
        
        // Get Cognito ID token for authentication
        if let idToken = try? await cognitoService.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Add user_id as query parameter
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        request.url = urlComponents.url
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AWSDataService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // If API fails, return empty data (fallback to local)
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("⚠️ [AWSDataService] Dashboard API failed: \(errorMessage) - falling back to local data")
            throw NSError(domain: "AWSDataService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Parse response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let dashboardDict = json["data"] as? [String: Any] else {
            throw NSError(domain: "AWSDataService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse dashboard response"])
        }
        
        // Decode dashboard data
        let jsonData = try JSONSerialization.data(withJSONObject: dashboardDict)
        let dashboardData = try decoder.decode(DashboardData.self, from: jsonData)
        
        print("✅ [AWSDataService] Dashboard data loaded: saved=\(dashboardData.totalSaved), streak=\(dashboardData.currentStreak)")
        return dashboardData
    }
    
    /// Cache dashboard data locally for instant loading on next launch
    func cacheDashboardData(_ data: DashboardData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        if let encoded = try? encoder.encode(data) {
            UserDefaults.standard.set(encoded, forKey: "cached_dashboard_data")
            print("✅ [AWSDataService] Dashboard data cached locally")
        }
    }
    
    /// Get cached dashboard data (for instant loading)
    func getCachedDashboardData() -> DashboardData? {
        guard let data = UserDefaults.standard.data(forKey: "cached_dashboard_data") else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        if let cached = try? decoder.decode(DashboardData.self, from: data) {
            // Check if cache is fresh (less than 5 minutes old)
            let cacheAge = Date().timeIntervalSince1970 - cached.lastUpdated
            if cacheAge < 300 { // 5 minutes
                print("✅ [AWSDataService] Using cached dashboard data (age: \(Int(cacheAge))s)")
                return cached
            } else {
                print("⚠️ [AWSDataService] Cached dashboard data is stale (age: \(Int(cacheAge))s)")
            }
        }
        
        return nil
    }
}

