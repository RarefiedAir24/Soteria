//
//  PlaidService.swift
//  soteria
//
//  Plaid integration for account connection and automatic savings transfers
//

import Foundation
import Combine

// MARK: - Models

enum SavingsMode {
    case automatic  // Transfers available via Plaid (user has savings account) - user-initiated
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

struct SavingsDeposit: Codable, Identifiable {
    let id: String
    let amount: Double
    let timestamp: Date
    let type: DepositType
    let goalId: String? // Optional: which goal this deposit was added to
    let source: String? // Optional: "manual", "plaid", "virtual", "decision_window", etc.
    let screenshotPath: String? // Optional: path to screenshot for manual deposits
    let referenceId: String? // Optional: reference ID from banking institution
    
    enum DepositType: String, Codable {
        case manual = "manual"
        case plaid = "plaid"
        case virtual = "virtual"
        case decisionWindow = "decision_window"
        case goalDeposit = "goal_deposit" // Direct deposit to a goal
    }
    
    init(amount: Double, type: DepositType, goalId: String? = nil, source: String? = nil, screenshotPath: String? = nil, referenceId: String? = nil, id: String? = nil) {
        self.id = id ?? UUID().uuidString
        self.amount = amount
        self.timestamp = Date()
        self.type = type
        self.goalId = goalId
        self.source = source
        self.screenshotPath = screenshotPath
        self.referenceId = referenceId
    }
}

// MARK: - PlaidService

class PlaidService: ObservableObject {
    static let shared: PlaidService = {
        let startTime = Date()
        let service = PlaidService()
        // CRITICAL: Don't access StartupDiagnostics.shared during initialization
        // StartupDiagnostics.shared.logServiceAccess("PlaidService", startTime: startTime)
        return service
    }()
    
    private let cognitoService: CognitoAuthService = {
        let startTime = Date()
        let service = CognitoAuthService.shared
        // CRITICAL: Don't access StartupDiagnostics.shared during initialization
        // StartupDiagnostics.shared.logServiceAccess("CognitoAuthService (from PlaidService)", startTime: startTime)
        return service
    }()
    
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
    @Published var depositHistory: [SavingsDeposit] = [] // All deposits with timestamps for savings tracker
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Track save transfer count for monthly goal prompt
    private let monthlyGoalPromptShownKey = "monthly_goal_prompt_shown"
    
    private init() {
        // Load saved state synchronously - UserDefaults reads are fast and won't block
        loadSavedState()
    }
    
    // MARK: - Account Connection
    
    /// Create Plaid Link token for account connection
    func createLinkToken() async throws -> String {
        // Use Cognito authentication instead of Firebase
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let url = URL(string: "\(apiGatewayURL)/soteria/plaid/create-link-token") else {
            throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        // Get Cognito ID token for authentication
        if let idToken = try? await cognitoService.getIDToken() {
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
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [PlaidService] Server error (\(httpResponse.statusCode)): \(errorString)")
            
            // Try to parse JSON error response for better error messages
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let errorMessage = errorJson["error"] as? String ?? errorJson["message"] as? String ?? errorString
                let errorCode = errorJson["error_code"] as? String ?? ""
                let errorType = errorJson["error_type"] as? String ?? ""
                
                // Check for invalid credentials error
                if errorCode == "INVALID_CLIENT_ID" || errorCode == "INVALID_SECRET" ||
                   errorMessage.lowercased().contains("invalid client") ||
                   errorMessage.lowercased().contains("invalid secret") {
                    throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid Plaid credentials. Please verify your Client ID and Secret in the Plaid Dashboard.",
                        "error_code": errorCode,
                        "error_type": errorType
                    ])
                }
                
                throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: errorMessage,
                    "error_code": errorCode,
                    "error_type": errorType
                ])
            }
            
            throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString])
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
        // Use Cognito authentication instead of Firebase
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let url = URL(string: "\(apiGatewayURL)/soteria/plaid/exchange-public-token") else {
            throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        // Get Cognito ID token for authentication
        if let idToken = try? await cognitoService.getIDToken() {
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
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
            print("❌ [PlaidService] Failed to parse JSON response: \(responseString)")
            throw NSError(domain: "PlaidService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: \(responseString)"])
        }
        
        print("✅ [PlaidService] Exchange token response: \(json)")
        
        guard let accounts = json["accounts"] as? [[String: Any]] else {
            print("❌ [PlaidService] No 'accounts' key in response. Response keys: \(json.keys)")
            throw NSError(domain: "PlaidService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse accounts - response: \(json)"])
        }
        
        print("✅ [PlaidService] Found \(accounts.count) accounts in response")
        
        // Parse accounts
        var connectedAccounts: [ConnectedAccount] = []
        for accountData in accounts {
            print("🔍 [PlaidService] Parsing account: \(accountData)")
            // Handle both "account_id" and "id" for compatibility
            let accountId = (accountData["account_id"] as? String) ?? (accountData["id"] as? String)
            
            if let accountId = accountId,
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
                print("✅ [PlaidService] Parsed account: \(name) (\(subtype))")
            } else {
                print("⚠️ [PlaidService] Failed to parse account data - missing fields. accountId: \(accountId ?? "nil"), name: \(accountData["name"] ?? "nil"), mask: \(accountData["mask"] ?? "nil"), type: \(accountData["type"] ?? "nil"), subtype: \(accountData["subtype"] ?? "nil")")
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
    
    /// Fetch connected accounts from backend/DynamoDB
    func fetchConnectedAccounts() async {
        guard let userId = cognitoService.getUserId() else {
            print("⚠️ [PlaidService] Cannot fetch accounts - user not authenticated")
            return
        }
        
        guard let url = URL(string: "\(apiGatewayURL)/soteria/plaid/get-accounts") else {
            print("❌ [PlaidService] Invalid URL for fetching accounts")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        // Get Cognito ID token for authentication
        if let idToken = try? await cognitoService.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: [String: Any] = [
            "user_id": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [PlaidService] Invalid response when fetching accounts")
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ [PlaidService] Server error (\(httpResponse.statusCode)) when fetching accounts: \(errorMessage)")
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accounts = json["accounts"] as? [[String: Any]] else {
                print("⚠️ [PlaidService] No accounts found or invalid response format")
                // If no accounts, that's okay - user just hasn't connected any yet
                await MainActor.run {
                    self.connectedAccounts = []
                    self.checkingAccount = nil
                    self.savingsAccount = nil
                    self.savingsMode = .manual
                    self.saveState()
                }
                return
            }
            
            print("✅ [PlaidService] Fetched \(accounts.count) accounts from backend")
            
            // Parse accounts
            var connectedAccounts: [ConnectedAccount] = []
            for accountData in accounts {
                print("🔍 [PlaidService] Parsing account from fetch: \(accountData)")
                // Handle both "account_id" and "id" for compatibility
                let accountId = (accountData["account_id"] as? String) ?? (accountData["id"] as? String)
                
                if let accountId = accountId,
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
                    print("✅ [PlaidService] Successfully parsed account: \(name) (\(subtype))")
                } else {
                    print("⚠️ [PlaidService] Failed to parse account - missing fields. accountId: \(accountId ?? "nil"), name: \(accountData["name"] ?? "nil"), mask: \(accountData["mask"] ?? "nil"), type: \(accountData["type"] ?? "nil"), subtype: \(accountData["subtype"] ?? "nil")")
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
            
            print("✅ [PlaidService] Loaded \(connectedAccounts.count) accounts, mode: \(savingsMode)")
            
        } catch {
            print("❌ [PlaidService] Error fetching accounts: \(error)")
        }
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
            // Silently fail for demo - balance endpoint may not be configured yet
            // Only log if it's not a 404 (endpoint not found)
            if let error = error as NSError?, error.code != 404 {
                print("⚠️ [PlaidService] Failed to refresh checking balance: \(error.localizedDescription)")
            }
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
                // Silently fail for demo - balance endpoint may not be configured yet
                // Only log if it's not a 404 (endpoint not found)
                if let error = error as NSError?, error.code != 404 {
                    print("⚠️ [PlaidService] Failed to refresh savings balance: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Get balance for a specific account
    private func getBalance(accountId: String) async throws -> Double {
        // Use Cognito authentication instead of Firebase
        guard let userId = cognitoService.getUserId() else {
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
        request.timeoutInterval = 10.0
        
        // Get Cognito ID token for authentication
        if let idToken = try? await cognitoService.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PlaidService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            // For 404, provide a more specific error message
            if httpResponse.statusCode == 404 {
                throw NSError(domain: "PlaidService", code: 404, userInfo: [
                    NSLocalizedDescriptionKey: errorMessage,
                    "path": "/soteria/plaid/balance"
                ])
            }
            throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let balance = json["balance"] as? Double else {
            throw NSError(domain: "PlaidService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse balance"])
        }
        
        return balance
    }
    
    // MARK: - Transfers
    
    /// Initiate transfer from checking to savings (user-initiated, requires savings account)
    func initiateTransfer(amount: Double) async throws -> Transfer {
        guard savingsMode == .automatic else {
            throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transfers require a savings account"])
        }
        
        guard let checkingAccount = checkingAccount,
              let savingsAccount = savingsAccount else {
            throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Both checking and savings accounts required"])
        }
        
        // Use Cognito authentication instead of Firebase
        // Check balance first
        let balance = try await getBalance(accountId: checkingAccount.id)
        guard balance >= amount else {
            throw NSError(domain: "PlaidService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Insufficient funds"])
        }
        
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "PlaidService", code: -4, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let url = URL(string: "\(apiGatewayURL)/soteria/plaid/transfer") else {
            throw NSError(domain: "PlaidService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        // Get Cognito ID token for authentication
        if let idToken = try? await cognitoService.getIDToken() {
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
    func recordVirtualSavings(amount: Double, goalId: String? = nil) {
        guard savingsMode == .virtual else { return }
        
        // Get active goal ID if not provided
        let depositGoalId = goalId ?? GoalsService.shared.activeGoal?.id
        
        virtualSavings += amount
        totalSaved += amount // Track total saved for users without goals
        
        // Create unique deposit record with timestamp
        let deposit = SavingsDeposit(
            amount: amount,
            type: .virtual,
            goalId: depositGoalId,
            source: "virtual_savings"
        )
        depositHistory.append(deposit)
        
        saveState()
        updateGoalProgress(amount: amount, goalId: depositGoalId)
        
        // Record savings streak
        StreakService.shared.recordSavings()
        
        print("✅ [PlaidService] Virtual savings recorded: $\(amount), total: $\(virtualSavings), timestamp: \(deposit.timestamp), goalId: \(depositGoalId ?? "none")")
        
        // Check if we should show monthly goal prompt
        checkAndShowMonthlyGoalPrompt()
    }
    
    /// Record a confirmed deposit (when transfer status becomes "posted")
    /// This is called when a Plaid transfer is confirmed by the bank
    /// - Parameters:
    ///   - amount: The deposit amount
    ///   - goalId: Optional goal ID
    ///   - transferId: Optional Plaid transfer ID (used as reference ID for tracking)
    func recordConfirmedDeposit(amount: Double, goalId: String? = nil, transferId: String? = nil) {
        let wasFirstDeposit = totalSaved == 0
        
        // Get active goal ID if not provided
        let depositGoalId = goalId ?? GoalsService.shared.activeGoal?.id
        
        totalSaved += amount
        
        // Create unique deposit record with timestamp
        // Use transferId as referenceId for accurate tracking with banking institution
        let deposit = SavingsDeposit(
            amount: amount,
            type: .plaid,
            goalId: depositGoalId,
            source: "plaid_transfer",
            screenshotPath: nil,
            referenceId: transferId // Store Plaid transfer_id as reference ID
        )
        depositHistory.append(deposit)
        
        saveState()
        updateGoalProgress(amount: amount, goalId: depositGoalId)
        
        // Record savings streak
        StreakService.shared.recordSavings()
        
        print("✅ [PlaidService] Confirmed deposit recorded: $\(amount), total saved: $\(totalSaved), timestamp: \(deposit.timestamp), goalId: \(depositGoalId ?? "none"), transferId: \(transferId ?? "none")")
        
        // Post notification for deposit made (for UI refresh)
        NotificationCenter.default.post(
            name: NSNotification.Name("DepositMade"),
            object: ["amount": amount, "goalId": depositGoalId as Any]
        )
        
        // Check if this is the first deposit
        if wasFirstDeposit {
            NotificationCenter.default.post(
                name: NSNotification.Name("FirstDepositMade"),
                object: amount
            )
        }
        
        // Check if we should show monthly goal prompt
        checkAndShowMonthlyGoalPrompt()
    }
    
    /// Record a manual deposit (for users without Plaid)
    /// This allows users to manually track their savings deposits.
    /// 
    /// Use cases:
    /// - Physical cash savings (e.g., piggy bank, cash envelope)
    /// - Deposits made outside the app to unintegrated bank accounts
    /// - Any savings that occur outside of Plaid-connected accounts
    /// 
    /// NOTE: This does NOT use Plaid API. It only updates local tracking.
    /// No bank transfers or API calls are made.
    func recordManualDeposit(amount: Double, goalId: String? = nil, screenshotPath: String? = nil, referenceId: String? = nil, depositId: String? = nil) {
        let wasFirstDeposit = totalSaved == 0
        
        // Get active goal ID if not provided
        let depositGoalId = goalId ?? GoalsService.shared.activeGoal?.id
        
        totalSaved += amount
        
        // Create unique deposit record with timestamp
        // Use provided depositId if available (for screenshot matching), otherwise generate new one
        let deposit = SavingsDeposit(
            amount: amount,
            type: .manual,
            goalId: depositGoalId,
            source: "manual_entry",
            screenshotPath: screenshotPath,
            referenceId: referenceId,
            id: depositId
        )
        depositHistory.append(deposit)
        
        saveState() // Saves to UserDefaults only - no API calls
        updateGoalProgress(amount: amount, goalId: depositGoalId)
        
        // Record savings streak
        StreakService.shared.recordSavings()
        
        print("✅ [PlaidService] Manual deposit recorded: $\(amount), total saved: \(totalSaved), timestamp: \(deposit.timestamp), goalId: \(depositGoalId ?? "none"), referenceId: \(referenceId ?? "none"), screenshot: \(screenshotPath != nil ? "yes" : "no")")
        
        // Post notification for deposit made (for UI refresh)
        NotificationCenter.default.post(
            name: NSNotification.Name("DepositMade"),
            object: ["amount": amount, "goalId": depositGoalId as Any]
        )
        
        // Sync screenshot to cloud in background (if provided)
        if screenshotPath != nil, let screenshot = DepositScreenshotService.shared.loadScreenshot(for: deposit.id) {
            Task {
                do {
                    _ = try await DepositScreenshotAPIService.shared.uploadScreenshot(image: screenshot, depositId: deposit.id)
                    print("✅ [PlaidService] Screenshot synced to cloud for deposit: \(deposit.id)")
                } catch {
                    print("⚠️ [PlaidService] Failed to sync screenshot to cloud: \(error.localizedDescription)")
                    // Screenshot is still saved locally, so this is not critical
                }
            }
        }
        
        // Check if this is the first deposit
        if wasFirstDeposit {
            NotificationCenter.default.post(
                name: NSNotification.Name("FirstDepositMade"),
                object: amount
            )
        }
        
        // Check if we should show monthly goal prompt
        checkAndShowMonthlyGoalPrompt()
    }
    
    /// Update goal progress when a deposit is made
    /// Note: This is called AFTER a deposit record is created, so the deposit already has the goalId
    private func updateGoalProgress(amount: Double, goalId: String?) {
        let goalsService = GoalsService.shared
        
        // If a specific goalId was provided, add to that goal
        if let goalId = goalId {
            if let goal = goalsService.getGoal(byId: goalId) {
                goalsService.addToGoal(goalId: goalId, amount: amount)
                print("✅ [PlaidService] Added $\(amount) to goal: \(goal.name)")
            } else {
                print("⚠️ [PlaidService] Goal not found for ID: \(goalId), deposit not added to goal")
            }
        } else if let activeGoal = goalsService.activeGoal {
            // Fallback: add to active goal if no specific goalId provided
            goalsService.addToGoal(goalId: activeGoal.id, amount: amount)
            print("✅ [PlaidService] Added $\(amount) to active goal: \(activeGoal.name)")
        } else {
            print("⚠️ [PlaidService] No goal specified and no active goal, deposit not added to any goal")
        }
        
        // NOTE: SavingsReminderService.updateProgressNotification removed - Savings Reminders feature removed
        // Goal progress notifications are handled by GoalNotificationService
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
        
        // Save deposit history with timestamps for savings tracker
        if let depositsData = try? encoder.encode(depositHistory) {
            UserDefaults.standard.set(depositsData, forKey: "plaid_deposit_history")
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
        
        // Load deposit history with timestamps for savings tracker
        if let depositsData = UserDefaults.standard.data(forKey: "plaid_deposit_history"),
           let deposits = try? decoder.decode([SavingsDeposit].self, from: depositsData) {
            depositHistory = deposits.sorted { $0.timestamp > $1.timestamp } // Most recent first
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
    
    // MARK: - Monthly Goal Prompt
    
    /// Check if we should show the monthly goal prompt after 3 save transfers
    private func checkAndShowMonthlyGoalPrompt() {
        // Check if we've already shown the prompt
        let hasShownPrompt = UserDefaults.standard.bool(forKey: monthlyGoalPromptShownKey)
        if hasShownPrompt {
            return
        }
        
        // Count save transfers (plaid, virtual, or manual)
        let saveTransferCount = depositHistory.filter { deposit in
            deposit.type == .plaid || deposit.type == .virtual || deposit.type == .manual
        }.count
        
        // Show prompt after 3 saves
        if saveTransferCount >= 3 {
            // Mark as shown so we don't show it again
            UserDefaults.standard.set(true, forKey: monthlyGoalPromptShownKey)
            
            // Post notification to show the prompt
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowMonthlyGoalPrompt"),
                object: nil
            )
            
            print("✅ [PlaidService] Monthly goal prompt triggered after \(saveTransferCount) save transfers")
        }
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

