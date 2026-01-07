//
//  PartnerLoyaltyService.swift
//  soteria
//
//  Service for managing partner loyalty benefits and redemptions
//

import Foundation
import Combine

struct Partner: Identifiable, Codable {
    let partnerId: String
    let name: String
    let description: String?
    let loyaltyPercentage: Double?
    let loyaltyAmount: Double?
    let loyaltyType: String // "percentage" or "amount"
    let logoUrl: String?
    let category: String?
    let location: String?
    let terms: String?
    let maxRedemptionsPerUser: Int?
    let validUntil: Date?
    let isActive: Bool
    let website: String?
    let hasBrickAndMortar: Bool?
    let checkoutCode: String? // Partner-provided code for members to use at checkout
    
    enum CodingKeys: String, CodingKey {
        case partnerId = "partner_id"
        case name
        case description
        case loyaltyPercentage = "loyalty_percentage"
        case loyaltyAmount = "loyalty_amount"
        case loyaltyType = "loyalty_type"
        case logoUrl = "logo_url"
        case category
        case location
        case terms
        case maxRedemptionsPerUser = "max_redemptions_per_user"
        case validUntil = "valid_until"
        case isActive = "is_active"
        case website
        case hasBrickAndMortar = "has_brick_and_mortar"
        case checkoutCode = "checkout_code"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        partnerId = try container.decode(String.self, forKey: .partnerId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        loyaltyPercentage = try container.decodeIfPresent(Double.self, forKey: .loyaltyPercentage)
        loyaltyAmount = try container.decodeIfPresent(Double.self, forKey: .loyaltyAmount)
        loyaltyType = try container.decodeIfPresent(String.self, forKey: .loyaltyType) ?? "percentage"
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        terms = try container.decodeIfPresent(String.self, forKey: .terms)
        maxRedemptionsPerUser = try container.decodeIfPresent(Int.self, forKey: .maxRedemptionsPerUser)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        hasBrickAndMortar = try container.decodeIfPresent(Bool.self, forKey: .hasBrickAndMortar)
        checkoutCode = try container.decodeIfPresent(String.self, forKey: .checkoutCode)
        
        if let validUntilString = try container.decodeIfPresent(String.self, forKey: .validUntil) {
            let formatter = ISO8601DateFormatter()
            validUntil = formatter.date(from: validUntilString)
        } else {
            validUntil = nil
        }
        
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
    }
    
    var id: String { partnerId }
}

struct Redemption: Identifiable, Codable {
    let redemptionId: String
    let userId: String
    let partnerId: String
    let partnerName: String?
    let loyaltyAmount: Double
    let transactionId: String?
    let redeemedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case redemptionId = "redemption_id"
        case userId = "user_id"
        case partnerId = "partner_id"
        case partnerName = "partner_name"
        case loyaltyAmount = "loyalty_amount"
        case transactionId = "transaction_id"
        case redeemedAt = "redeemed_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        redemptionId = try container.decode(String.self, forKey: .redemptionId)
        userId = try container.decode(String.self, forKey: .userId)
        partnerId = try container.decode(String.self, forKey: .partnerId)
        partnerName = try container.decodeIfPresent(String.self, forKey: .partnerName)
        loyaltyAmount = try container.decode(Double.self, forKey: .loyaltyAmount)
        transactionId = try container.decodeIfPresent(String.self, forKey: .transactionId)
        
        let redeemedAtString = try container.decode(String.self, forKey: .redeemedAt)
        let formatter = ISO8601DateFormatter()
        redeemedAt = formatter.date(from: redeemedAtString) ?? Date()
    }
    
    var id: String { redemptionId }
}

struct PartnerListResponse: Codable {
    let success: Bool
    let partners: [Partner]
    let error: String?
}

struct APIErrorResponse: Codable {
    let message: String?
}

struct ValidateMemberResponse: Codable {
    let success: Bool
    let valid: Bool
    let member: MemberInfo?
    let partner: PartnerInfo?
    let error: String?
}

struct MemberInfo: Codable {
    let userId: String
    let cardType: String
    let isPremium: Bool
    let subscriptionStatus: String
    let memberSince: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case cardType = "card_type"
        case isPremium = "is_premium"
        case subscriptionStatus = "subscription_status"
        case memberSince = "member_since"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        cardType = try container.decode(String.self, forKey: .cardType)
        isPremium = try container.decode(Bool.self, forKey: .isPremium)
        subscriptionStatus = try container.decode(String.self, forKey: .subscriptionStatus)
        
        let memberSinceString = try container.decode(String.self, forKey: .memberSince)
        let formatter = ISO8601DateFormatter()
        memberSince = formatter.date(from: memberSinceString) ?? Date()
    }
}

struct PartnerInfo: Codable {
    let partnerId: String
    let name: String
    let loyaltyPercentage: Double?
    
    enum CodingKeys: String, CodingKey {
        case partnerId = "partner_id"
        case name
        case loyaltyPercentage = "loyalty_percentage"
    }
}

struct RedemptionResponse: Codable {
    let success: Bool
    let redemption: Redemption?
    let error: String?
}

struct DeletePartnerResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

struct UpdatePartnerResponse: Codable {
    let success: Bool
    let partner: Partner?
    let error: String?
}

struct CodeRedemptionResult {
    let success: Bool
    let message: String?
    let redemption: Redemption?
}

class PartnerLoyaltyService: ObservableObject {
    static let shared = PartnerLoyaltyService()
    
    @Published var partners: [Partner] = []
    @Published var redemptions: [Redemption] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiBaseURL = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod"
    private let cognitoService = CognitoAuthService.shared
    
    private init() {
        print("✅ [PartnerLoyaltyService] Initialized")
    }
    
    /// Load all available partners
    func loadPartners(category: String? = nil, location: String? = nil) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        var urlString = "\(apiBaseURL)/soteria/partner/list"
        var queryItems: [URLQueryItem] = []
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let location = location {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
        if let userId = cognitoService.getUserId() {
            queryItems.append(URLQueryItem(name: "user_id", value: userId))
        }
        
        if !queryItems.isEmpty {
            var components = URLComponents(string: urlString)
            components?.queryItems = queryItems
            urlString = components?.url?.absoluteString ?? urlString
        }
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Invalid URL"
            }
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Add authentication token if available
            if let idToken = try await cognitoService.getIDToken() {
                request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            // Parse response body first to check for success field
            let responseString = String(data: data, encoding: .utf8) ?? "{}"
            print("📥 [PartnerLoyaltyService] Response: \(responseString.prefix(500))")
            
            // Check if response contains "message" field (API Gateway error format)
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               jsonObject["message"] != nil && jsonObject["success"] == nil {
                // This is an API Gateway error format
                let errorMessage = jsonObject["message"] as? String ?? "Internal server error"
                throw NSError(domain: "PartnerLoyaltyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            
            let decoder = JSONDecoder()
            let result: PartnerListResponse
            do {
                result = try decoder.decode(PartnerListResponse.self, from: data)
            } catch {
                print("❌ [PartnerLoyaltyService] JSON decode error: \(error)")
                print("❌ [PartnerLoyaltyService] Response data: \(responseString)")
                throw error
            }
            
            // Check if Lambda returned success:false (even with 200 status)
            if !result.success {
                throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.error ?? "Failed to load partners"])
            }
            
            // Also check HTTP status code
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "PartnerLoyaltyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            
            await MainActor.run {
                if result.success {
                    partners = result.partners
                    errorMessage = nil
                } else {
                    errorMessage = result.error ?? "Failed to load partners"
                }
                isLoading = false
            }
            
            print("✅ [PartnerLoyaltyService] Loaded \(result.partners.count) partners")
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            print("❌ [PartnerLoyaltyService] Error loading partners: \(error.localizedDescription)")
        }
    }
    
    /// Validate a member's QR code
    func validateMember(qrData: String, partnerId: String) async throws -> ValidateMemberResponse {
        guard let url = URL(string: "\(apiBaseURL)/soteria/partner/validate-member") else {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "qr_data": qrData,
            "partner_id": partnerId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PartnerLoyaltyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ValidateMemberResponse.self, from: data)
    }
    
    /// Record a redemption
    func recordRedemption(partnerId: String, loyaltyAmount: Double, transactionId: String? = nil) async throws -> Redemption {
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let url = URL(string: "\(apiBaseURL)/soteria/partner/redeem") else {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var requestBody: [String: Any] = [
            "user_id": userId,
            "partner_id": partnerId,
            "loyalty_amount": loyaltyAmount
        ]
        
        if let transactionId = transactionId {
            requestBody["transaction_id"] = transactionId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PartnerLoyaltyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(RedemptionResponse.self, from: data)
        
        guard let redemption = result.redemption else {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.error ?? "Redemption failed"])
        }
        
        // Add to local redemptions list
        await MainActor.run {
            redemptions.insert(redemption, at: 0)
        }
        
        print("✅ [PartnerLoyaltyService] Redemption recorded: \(redemption.redemptionId)")
        return redemption
    }
    
    /// Load user's redemption history
    func loadRedemptionHistory() async {
        // For now, we'll load from local state
        // In the future, we can add an API endpoint to fetch user's redemption history
        print("ℹ️ [PartnerLoyaltyService] Loading redemption history from local state")
    }
    
    /// Update a partner (admin only)
    func updatePartner(partnerId: String, checkoutCode: String?) async throws -> Partner {
        guard let url = URL(string: "\(apiBaseURL)/soteria/partner/\(partnerId)") else {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token
        if let idToken = try await cognitoService.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Build request body
        var requestBody: [String: Any] = [:]
        if let code = checkoutCode, !code.isEmpty {
            let normalizedCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            requestBody["checkout_code"] = normalizedCode
        } else {
            // To clear the code, send null
            requestBody["checkout_code"] = NSNull()
        }
        
        // Use JSONSerialization with .fragmentsAllowed to handle NSNull
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [.fragmentsAllowed])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // Parse response
        let responseString = String(data: data, encoding: .utf8) ?? "{}"
        print("📥 [PartnerLoyaltyService] Update response: \(responseString)")
        
        // Check if response contains "message" field (API Gateway error format)
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           jsonObject["message"] != nil && jsonObject["success"] == nil {
            let errorMessage = jsonObject["message"] as? String ?? "Internal server error"
            throw NSError(domain: "PartnerLoyaltyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(UpdatePartnerResponse.self, from: data)
        
        guard let updatedPartner = result.partner else {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.error ?? "Failed to update partner"])
        }
        
        // Update local partners list
        await MainActor.run {
            if let index = partners.firstIndex(where: { $0.partnerId == partnerId }) {
                partners[index] = updatedPartner
            }
        }
        
        print("✅ [PartnerLoyaltyService] Partner updated: \(partnerId)")
        return updatedPartner
    }
    
    /// Delete a partner (admin only)
    func deletePartner(partnerId: String) async throws {
        guard let url = URL(string: "\(apiBaseURL)/soteria/partner/\(partnerId)") else {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token
        if let idToken = try await cognitoService.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // Parse response
        let responseString = String(data: data, encoding: .utf8) ?? "{}"
        print("📥 [PartnerLoyaltyService] Delete response: \(responseString)")
        
        // Check if response contains "message" field (API Gateway error format)
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           jsonObject["message"] != nil && jsonObject["success"] == nil {
            let errorMessage = jsonObject["message"] as? String ?? "Internal server error"
            throw NSError(domain: "PartnerLoyaltyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(DeletePartnerResponse.self, from: data)
        
        if !result.success {
            throw NSError(domain: "PartnerLoyaltyService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.error ?? "Failed to delete partner"])
        }
        
        // Remove from local partners list
        await MainActor.run {
            partners.removeAll { $0.partnerId == partnerId }
        }
        
        print("✅ [PartnerLoyaltyService] Partner deleted: \(partnerId)")
    }
}

