//
//  MemberNumberService.swift
//  soteria
//
//  Service for generating and managing unique member numbers for premium cards
//

import Foundation
import Combine

class MemberNumberService: ObservableObject {
    static let shared = MemberNumberService()
    
    @Published var memberNumber: String?
    
    private let cognitoService = CognitoAuthService.shared
    private let apiBaseURL = "https://g3ksyd36e5.execute-api.us-east-1.amazonaws.com/prod"
    
    private init() {
        print("✅ [MemberNumberService] Initialized")
        loadMemberNumber()
    }
    
    /// Loads the member number from UserDefaults (cached) or fetches from backend
    func loadMemberNumber() {
        // First check UserDefaults cache
        if let cached = UserDefaults.standard.string(forKey: "premium_member_number") {
            memberNumber = cached
            print("✅ [MemberNumberService] Loaded cached member number: \(cached)")
            return
        }
        
        // If not cached and user is premium, fetch from backend
        if SubscriptionService.shared.isPremium {
            Task {
                await fetchMemberNumber()
            }
        }
    }
    
    /// Fetches or generates member number from backend
    func fetchMemberNumber() async {
        guard let userId = cognitoService.getUserId() else {
            print("⚠️ [MemberNumberService] No user ID available")
            return
        }
        
        guard let url = URL(string: "\(apiBaseURL)/soteria/member-number?user_id=\(userId)") else {
            print("❌ [MemberNumberService] Invalid URL")
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Member number endpoint may not require authentication
            // Try to add auth token if available, but proceed without it if unavailable
            do {
                if let idToken = try await cognitoService.getIDToken() {
                    // Use token directly without "Bearer " prefix for this endpoint
                    request.setValue(idToken, forHTTPHeaderField: "Authorization")
                }
            } catch {
                print("⚠️ [MemberNumberService] Could not get auth token, proceeding without auth")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "MemberNumberService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "MemberNumberService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(MemberNumberResponse.self, from: data)
            
            await MainActor.run {
                if let number = result.memberNumber {
                    memberNumber = number
                    // Cache in UserDefaults
                    UserDefaults.standard.set(number, forKey: "premium_member_number")
                    print("✅ [MemberNumberService] Fetched member number: \(number)")
                } else {
                    print("⚠️ [MemberNumberService] No member number in response")
                }
            }
        } catch {
            print("❌ [MemberNumberService] Error fetching member number: \(error.localizedDescription)")
            // Fallback: Generate a temporary local number (will be replaced when backend is ready)
            await MainActor.run {
                generateLocalMemberNumber()
            }
        }
    }
    
    /// Generates a temporary local member number (fallback until backend is ready)
    private func generateLocalMemberNumber() {
        guard let userId = cognitoService.getUserId() else { return }
        
        // Create a deterministic number from user ID (temporary solution)
        let hash = abs(userId.hash)
        let number = String(format: "SOT-%06d", hash % 1000000)
        
        memberNumber = number
        UserDefaults.standard.set(number, forKey: "premium_member_number")
        print("⚠️ [MemberNumberService] Generated temporary local member number: \(number)")
    }
    
    /// Formats the member number for display (e.g., "SOT-123456")
    var formattedMemberNumber: String {
        guard let number = memberNumber else { return "" }
        // Ensure it has SOT- prefix
        if number.hasPrefix("SOT-") {
            return number
        }
        return "SOT-\(number)"
    }
}

struct MemberNumberResponse: Codable {
    let success: Bool
    let memberNumber: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case memberNumber = "member_number"
        case error
    }
}

