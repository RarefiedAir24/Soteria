//
//  PlaidService.swift
//  rever
//
//  Created by Frank Schioppa on 12/7/25.
//

import Foundation
import Combine
import FirebaseAuth
import LinkKit

struct BankAccount: Identifiable, Codable {
    let id: String
    var name: String
    var accountType: String // "checking", "savings", etc.
    var last4: String
    var institutionName: String
    var accessToken: String? // Plaid access token (should be stored securely)
    
    var displayName: String {
        return "\(institutionName) ••••\(last4)"
    }
}

class PlaidService: ObservableObject {
    static let shared = PlaidService()
    
    @Published var isConnected: Bool = false
    @Published var bankAccounts: [BankAccount] = []
    @Published var selectedAccount: BankAccount? = nil
    
    // Plaid Configuration
    // TODO: Replace with your actual Plaid keys from Plaid Dashboard
    // Get these from: https://dashboard.plaid.com/developers/keys
    private let plaidClientId = "YOUR_PLAID_CLIENT_ID"
    private let plaidSecret = "YOUR_PLAID_SECRET"
    private let plaidEnvironment = "sandbox" // "sandbox", "development", or "production"
    
    // AWS API Gateway endpoint
    // Format: https://{api-id}.execute-api.{region}.amazonaws.com/{stage}
    // Note: API must be deployed to 'prod' stage for this URL to work
    private let awsApiGatewayURL = "https://vus7x2s6o7.execute-api.us-east-1.amazonaws.com/prod"
    
    // Link token for Plaid Link (obtained from backend)
    @Published var linkToken: String? = nil
    @Published var isCreatingLinkToken: Bool = false
    
    private let accountsKey = "plaid_bank_accounts"
    
    private init() {
        loadAccounts()
        isConnected = !bankAccounts.isEmpty
        selectedAccount = bankAccounts.first
    }
    
    // Load accounts from UserDefaults
    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([BankAccount].self, from: data) {
            bankAccounts = decoded
        }
    }
    
    // Save accounts to UserDefaults
    private func saveAccounts() {
        // Note: In production, access tokens should be stored in Keychain, not UserDefaults
        if let encoded = try? JSONEncoder().encode(bankAccounts) {
            UserDefaults.standard.set(encoded, forKey: accountsKey)
        }
    }
    
    // Create a link token from AWS Lambda
    // AWS Lambda will call Plaid's /link/token/create endpoint
    func createLinkToken() async throws -> String {
        isCreatingLinkToken = true
        defer { isCreatingLinkToken = false }
        
        print("🔗 [PlaidService] Creating link token from AWS Lambda...")
        
        // Get Firebase user ID and token
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get Firebase ID token for AWS authentication
        let firebaseIdToken = try await user.getIDToken()
        
        // Call AWS Lambda function via API Gateway
        guard let url = URL(string: "\(awsApiGatewayURL)/plaid/create-link-token") else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid AWS API Gateway URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(firebaseIdToken)", forHTTPHeaderField: "Authorization")
        
        // Request body - AWS Lambda will handle Plaid API call
        let body: [String: Any] = [
            "user_id": user.uid,
            "client_name": "SOTERIA",
            "products": ["auth", "transactions"],
            "country_codes": ["US"],
            "language": "en"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make the actual API call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(errorMessage)"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let token = json?["link_token"] as? String else {
            throw NSError(domain: "PlaidService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response: missing link_token"])
        }
        
        linkToken = token
        print("✅ [PlaidService] Link token created: \(token)")
        return token
        
        // For now, simulate the API call
        // In production, make actual network request:
        /*
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create link token"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let token = json?["link_token"] as? String else {
            throw NSError(domain: "PlaidService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response from backend"])
        }
        
        linkToken = token
        return token
        */
        
        // Simulate for now
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let simulatedToken = "link-sandbox-\(UUID().uuidString)"
        linkToken = simulatedToken
        print("✅ [PlaidService] Link token created: \(simulatedToken)")
        return simulatedToken
    }
    
    // Start Plaid Link flow
    func startLinkFlow() async {
        do {
            // First, get a link token from backend
            let token = try await createLinkToken()
            
            // TODO: Initialize and present Plaid Link SDK
            // This requires the Plaid Link iOS SDK to be added to the project
            /*
            let linkConfiguration = PLKConfiguration(linkToken: token) { success in
                if success {
                    let linkViewController = PLKLinkViewController(configuration: linkConfiguration, delegate: self)
                    // Present linkViewController
                }
            }
            */
            
            print("🔗 [PlaidService] Starting Plaid Link with token: \(token)")
            
            // For now, we'll use a placeholder
            // In production, this would present the Plaid Link UI
            
        } catch {
            print("❌ [PlaidService] Failed to start Link flow: \(error.localizedDescription)")
        }
    }
    
    // Handle successful Plaid Link connection
    func handleLinkSuccess(publicToken: String, metadata: [String: Any]?) {
        print("✅ [PlaidService] Link successful! Public token: \(publicToken)")
        
        // Exchange public_token for access_token via backend
        Task {
            do {
                try await exchangePublicToken(publicToken: publicToken, metadata: metadata)
            } catch {
                print("❌ [PlaidService] Failed to exchange public token: \(error.localizedDescription)")
            }
        }
    }
    
    // Exchange public_token for access_token
    // This should be done on your backend for security
    private func exchangePublicToken(publicToken: String, metadata: [String: Any]?) async throws {
        print("🔄 [PlaidService] Exchanging public token for access token...")
        
        // Call AWS Lambda function via API Gateway to exchange token
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let firebaseIdToken = try await user.getIDToken()
        
        guard let url = URL(string: "\(awsApiGatewayURL)/plaid/exchange-public-token") else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid AWS API Gateway URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(firebaseIdToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "public_token": publicToken,
            "user_id": user.uid
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make the actual API call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(errorMessage)"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String,
              let itemId = json?["item_id"] as? String,
              let accounts = json?["accounts"] as? [[String: Any]],
              let firstAccount = accounts.first else {
            throw NSError(domain: "PlaidService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response: missing required fields"])
        }
        
        // Create bank account from response
        let accountId = firstAccount["account_id"] as? String ?? UUID().uuidString
        let accountName = firstAccount["name"] as? String ?? "Savings Account"
        let mask = firstAccount["mask"] as? String ?? "0000"
        let institutionName = json?["institution_name"] as? String ?? "Bank"
        
        let account = BankAccount(
            id: accountId,
            name: accountName,
            accountType: firstAccount["type"] as? String ?? "savings",
            last4: mask,
            institutionName: institutionName,
            accessToken: accessToken // Store securely in Keychain
        )
        
        await MainActor.run {
            addAccount(account)
        }
        
        // Parse metadata to get account info
        if let accounts = metadata?["accounts"] as? [[String: Any]],
           let firstAccount = accounts.first,
           let accountId = firstAccount["id"] as? String,
           let accountName = firstAccount["name"] as? String,
           let mask = firstAccount["mask"] as? String,
           let institution = metadata?["institution"] as? [String: Any],
           let institutionName = institution["name"] as? String {
            
            let account = BankAccount(
                id: accountId,
                name: accountName,
                accountType: firstAccount["type"] as? String ?? "savings",
                last4: mask,
                institutionName: institutionName,
                accessToken: "access-sandbox-\(UUID().uuidString)" // In production, this comes from backend
            )
            
            await MainActor.run {
                addAccount(account)
            }
        }
    }
    
    // Fetch account information from Plaid
    private func fetchAccountInfo(accessToken: String, itemId: String) async throws {
        // TODO: Call your backend to get account info using Plaid's /accounts/get endpoint
        print("📊 [PlaidService] Fetching account info for item: \(itemId)")
    }
    
    // Transfer money to savings account via AWS Lambda
    // AWS Lambda will call Plaid's Transfer API
    func transferToSavings(amount: Double, accountId: String) async throws {
        guard let account = bankAccounts.first(where: { $0.id == accountId }) else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Account not found"])
        }
        
        guard amount > 0 else {
            throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Amount must be greater than 0"])
        }
        
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "PlaidService", code: -3, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let firebaseIdToken = try await user.getIDToken()
        
        guard let url = URL(string: "\(awsApiGatewayURL)/plaid/transfer") else {
            throw NSError(domain: "PlaidService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid AWS API Gateway URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(firebaseIdToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "account_id": accountId,
            "amount": amount,
            "user_id": user.uid
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("💰 [PlaidService] Transferring $\(amount) to \(account.displayName)")
        
        // Make the actual API call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PlaidService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Transfer failed: \(errorMessage)"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let transferId = json?["transfer_id"] as? String
        print("✅ [PlaidService] Transfer successful! Transfer ID: \(transferId ?? "unknown")")
    }
    
    // Add a connected account (called after Plaid Link completes)
    func addAccount(_ account: BankAccount) {
        bankAccounts.append(account)
        if selectedAccount == nil {
            selectedAccount = account
        }
        isConnected = true
        saveAccounts()
    }
    
    // Remove account
    func removeAccount(_ account: BankAccount) {
        bankAccounts.removeAll { $0.id == account.id }
        if selectedAccount?.id == account.id {
            selectedAccount = bankAccounts.first
        }
        isConnected = !bankAccounts.isEmpty
        saveAccounts()
    }
    
    // Set selected account for transfers
    func setSelectedAccount(_ account: BankAccount) {
        selectedAccount = account
    }
}

