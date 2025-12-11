//
//  PlaidService.swift
//  soteria
//
//  Plaid integration for account connection and automatic savings transfers
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseCore

// MARK: - Models

enum SavingsMode {
    case automatic  // Real transfers via Plaid (user has savings account)
    case virtual    // Track amounts, no transfers (user has only checking)
    case manual     // No accounts connected, just tracking
}

struct ConnectedAccount: Codable, Identifiable {
    let id: String // account_id from Plaid
    let name: String
    let mask: String // Last 4 digits
    let type: String // "depository"
    let subtype: String // "checking" or "savings"
    var balance: Double? // Current balance (read-only)
}

struct Transfer: Codable, Identifiable {
    let id: String // transfer_id from Plaid
    let amount: Double
    let timestamp: Date
    let status: String // "pending", "posted", "failed"
    let fromAccount: String // account_id
    let toAccount: String // account_id
}

// MARK: - PlaidService

class PlaidService: ObservableObject {
    static let shared = PlaidService()
    
    // API Gateway URL - Switches between local dev and production
    #if DEBUG
    // Local development server (run: npm start in local-dev-server/)
    // For iOS Simulator: use localhost
    // For Physical Device: use Mac's IP address (10.0.0.52)
    #if targetEnvironment(simulator)
    private let apiGatewayURL = "http://localhost:8000"
    #else
    // Physical device - use Mac's IP address
    // Find your Mac's IP: ifconfig | grep "inet " | grep -v 127.0.0.1
    private let apiGatewayURL = "http://10.0.0.52:8000"
    #endif
    #else
    // Production AWS API Gateway
    private let apiGatewayURL = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod"
    #endif
    
    @Published var savingsMode: SavingsMode = .manual
    @Published var connectedAccounts: [ConnectedAccount] = []
    @Published var checkingAccount: ConnectedAccount? = nil
    @Published var savingsAccount: ConnectedAccount? = nil
    @Published var protectionAmount: Double = 10.0 // Default $10 per protection
    @Published var totalSaved: Double = 0 // Sum of all transfers
    @Published var virtualSavings: Double = 0 // Tracked but not transferred (for virtual mode)
    @Published var transferHistory: [Transfer] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private init() {
        // Load saved state synchronously - UserDefaults reads are fast and won't block
        loadSavedState()
    }
    
    // MARK: - Account Connection
    
    /// Create Plaid Link token for account connection
    func createLinkToken() async throws -> String {
        // Check if Firebase is configured
        guard FirebaseApp.app() != nil else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"])
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let url = URL(string: "\(apiGatewayURL)/soteria/plaid/create-link-token") else {
            throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get Firebase ID token for authentication
        if let idToken = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: [String: Any] = [
            "user_id": userId,
            "client_name": "Soteria",
            "products": ["auth", "transactions"], // Note: "balance" is not a valid product
            "country_codes": ["US"],
            "language": "en"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            // Connection error - provide helpful message
            #if DEBUG
            var errorMsg = "Cannot connect to local dev server at \(apiGatewayURL).\n\n"
            #if targetEnvironment(simulator)
            errorMsg += "Simulator detected. Please check:\n1. Server is running: curl http://localhost:8000/health\n2. Server is accessible"
            #else
            errorMsg += "Physical device detected.\n\nYou need to use your Mac's IP address instead of localhost:\n1. Find Mac IP: ifconfig | grep 'inet ' | grep -v 127.0.0.1\n2. Update PlaidService.swift line 47 to: http://YOUR_MAC_IP:8000\n3. Example: http://10.0.0.52:8000"
            #endif
            #else
            let errorMsg = "Cannot connect to server. Please check your internet connection."
            #endif
            throw NSError(domain: "PlaidService", code: -5, userInfo: [
                NSLocalizedDescriptionKey: errorMsg,
                NSUnderlyingErrorKey: urlError
            ])
        } catch {
            throw NSError(domain: "PlaidService", code: -5, userInfo: [
                NSLocalizedDescriptionKey: "Connection error: \(error.localizedDescription)",
                NSUnderlyingErrorKey: error
            ])
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PlaidService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let linkToken = json["link_token"] as? String else {
            throw NSError(domain: "PlaidService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse link token"])
        }
        
        print("✅ [PlaidService] Link token created")
        return linkToken
    }
    
    /// Exchange public token for access token and store account info
    func exchangePublicToken(_ publicToken: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let url = URL(string: "\(apiGatewayURL)/soteria/plaid/exchange-public-token") else {
            throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let idToken = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: [String: Any] = [
            "public_token": publicToken,
            "user_id": userId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PlaidService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accounts = json["accounts"] as? [[String: Any]] else {
            throw NSError(domain: "PlaidService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse accounts"])
        }
        
        // Parse accounts
        var connectedAccounts: [ConnectedAccount] = []
        for accountData in accounts {
            if let accountId = accountData["account_id"] as? String,
               let name = accountData["name"] as? String,
               let mask = accountData["mask"] as? String,
               let type = accountData["type"] as? String,
               let subtype = accountData["subtype"] as? String {
                connectedAccounts.append(ConnectedAccount(
                    id: accountId,
                    name: name,
                    mask: mask,
                    type: type,
                    subtype: subtype,
                    balance: nil
                ))
            }
        }
        
        // Update state
        await MainActor.run {
            self.connectedAccounts = connectedAccounts
            self.checkingAccount = connectedAccounts.first { $0.subtype == "checking" }
            self.savingsAccount = connectedAccounts.first { $0.subtype == "savings" }
            
            // Determine savings mode
            if self.savingsAccount != nil {
                self.savingsMode = .automatic
            } else if self.checkingAccount != nil {
                self.savingsMode = .virtual
            } else {
                self.savingsMode = .manual
            }
            
            self.saveState()
        }
        
        // Load initial balances
        await refreshBalances()
        
        print("✅ [PlaidService] Accounts connected: \(connectedAccounts.count) accounts, mode: \(savingsMode)")
    }
    
    // MARK: - Balance Reading
    
    /// Refresh account balances (read-only)
    func refreshBalances() async {
        guard let checkingAccount = checkingAccount else { return }
        
        do {
            let balance = try await getBalance(accountId: checkingAccount.id)
            await MainActor.run {
                if let index = self.connectedAccounts.firstIndex(where: { $0.id == checkingAccount.id }) {
                    self.connectedAccounts[index].balance = balance
                    self.checkingAccount?.balance = balance
                }
            }
        } catch {
            print("⚠️ [PlaidService] Failed to refresh checking balance: \(error)")
        }
        
        if let savingsAccount = savingsAccount {
            do {
                let balance = try await getBalance(accountId: savingsAccount.id)
                await MainActor.run {
                    if let index = self.connectedAccounts.firstIndex(where: { $0.id == savingsAccount.id }) {
                        self.connectedAccounts[index].balance = balance
                        self.savingsAccount?.balance = balance
                        self.totalSaved = balance // For automatic mode, total saved = savings balance
                    }
                }
            } catch {
                print("⚠️ [PlaidService] Failed to refresh savings balance: \(error)")
            }
        }
    }
    
    /// Get balance for a specific account
    private func getBalance(accountId: String) async throws -> Double {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var urlComponents = URLComponents(string: "\(apiGatewayURL)/soteria/plaid/balance")!
        urlComponents.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "account_id", value: accountId)
        ]
        
        guard let url = urlComponents.url else {
            throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let idToken = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PlaidService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let balance = json["balance"] as? Double else {
            throw NSError(domain: "PlaidService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse balance"])
        }
        
        return balance
    }
    
    // MARK: - Transfers
    
    /// Initiate transfer from checking to savings (automatic mode only)
    func initiateTransfer(amount: Double) async throws -> Transfer {
        guard savingsMode == .automatic else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Automatic transfers require a savings account"])
        }
        
        guard let checkingAccount = checkingAccount,
              let savingsAccount = savingsAccount else {
            throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Both checking and savings accounts required"])
        }
        
        // Check balance first
        let balance = try await getBalance(accountId: checkingAccount.id)
        guard balance >= amount else {
            throw NSError(domain: "PlaidService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Insufficient funds"])
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "PlaidService", code: -4, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let url = URL(string: "\(apiGatewayURL)/soteria/plaid/transfer") else {
            throw NSError(domain: "PlaidService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let idToken = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: [String: Any] = [
            "user_id": userId,
            "from_account_id": checkingAccount.id,
            "to_account_id": savingsAccount.id,
            "amount": amount
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PlaidService", code: -6, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let transferId = json["transfer_id"] as? String,
              let status = json["status"] as? String else {
            throw NSError(domain: "PlaidService", code: -7, userInfo: [NSLocalizedDescriptionKey: "Failed to parse transfer response"])
        }
        
        let transfer = Transfer(
            id: transferId,
            amount: amount,
            timestamp: Date(),
            status: status,
            fromAccount: checkingAccount.id,
            toAccount: savingsAccount.id
        )
        
        await MainActor.run {
            self.transferHistory.append(transfer)
            self.saveState()
        }
        
        // Refresh balances after transfer
        await refreshBalances()
        
        print("✅ [PlaidService] Transfer initiated: $\(amount), status: \(status)")
        return transfer
    }
    
    /// Record virtual savings (for virtual mode - no actual transfer)
    func recordVirtualSavings(amount: Double) {
        guard savingsMode == .virtual else { return }
        
        virtualSavings += amount
        saveState()
        print("✅ [PlaidService] Virtual savings recorded: $\(amount), total: $\(virtualSavings)")
    }
    
    // MARK: - State Management
    
    private func saveState() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        if let accountsData = try? encoder.encode(connectedAccounts) {
            UserDefaults.standard.set(accountsData, forKey: "plaid_connected_accounts")
        }
        
        if let transfersData = try? encoder.encode(transferHistory) {
            UserDefaults.standard.set(transfersData, forKey: "plaid_transfer_history")
        }
        
        UserDefaults.standard.set(protectionAmount, forKey: "plaid_protection_amount")
        UserDefaults.standard.set(virtualSavings, forKey: "plaid_virtual_savings")
        UserDefaults.standard.set(totalSaved, forKey: "plaid_total_saved")
        UserDefaults.standard.set(savingsMode.rawValue, forKey: "plaid_savings_mode")
    }
    
    private func loadSavedState() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        if let accountsData = UserDefaults.standard.data(forKey: "plaid_connected_accounts"),
           let accounts = try? decoder.decode([ConnectedAccount].self, from: accountsData) {
            connectedAccounts = accounts
            checkingAccount = accounts.first { $0.subtype == "checking" }
            savingsAccount = accounts.first { $0.subtype == "savings" }
        }
        
        if let transfersData = UserDefaults.standard.data(forKey: "plaid_transfer_history"),
           let transfers = try? decoder.decode([Transfer].self, from: transfersData) {
            transferHistory = transfers
        }
        
        protectionAmount = UserDefaults.standard.double(forKey: "plaid_protection_amount")
        if protectionAmount == 0 {
            protectionAmount = 10.0 // Default
        }
        
        virtualSavings = UserDefaults.standard.double(forKey: "plaid_virtual_savings")
        totalSaved = UserDefaults.standard.double(forKey: "plaid_total_saved")
        
        if let modeString = UserDefaults.standard.string(forKey: "plaid_savings_mode"),
           let mode = SavingsMode(rawValue: modeString) {
            savingsMode = mode
        } else {
            // Determine mode from accounts
            if savingsAccount != nil {
                savingsMode = .automatic
            } else if checkingAccount != nil {
                savingsMode = .virtual
            } else {
                savingsMode = .manual
            }
        }
    }
    
    /// Disconnect all accounts
    func disconnectAccounts() {
        connectedAccounts = []
        checkingAccount = nil
        savingsAccount = nil
        savingsMode = .manual
        transferHistory = []
        totalSaved = 0
        virtualSavings = 0
        saveState()
        print("✅ [PlaidService] Accounts disconnected")
    }
}

// MARK: - SavingsMode Extension

extension SavingsMode: RawRepresentable {
    var rawValue: String {
        switch self {
        case .automatic: return "automatic"
        case .virtual: return "virtual"
        case .manual: return "manual"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "automatic": self = .automatic
        case "virtual": self = .virtual
        case "manual": self = .manual
        default: return nil
        }
    }
}

