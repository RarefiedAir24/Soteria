//
//  UnitService.swift
//  Soteria
//
//  Service for Unit Banking API integration
//  Handles account creation, transactions, and goal tracking
//

import Foundation

class UnitService {
    static let shared = UnitService()
    
    // MARK: - Configuration
    
    /// Unit API base URL
    private let baseURL = "https://api.s.unit.sh" // Sandbox URL
    
    /// API Token (stored securely in Keychain)
    private var apiToken: String? {
        get {
            return KeychainHelper.get(key: "unit_api_token")
        }
        set {
            if let token = newValue {
                KeychainHelper.set(key: "unit_api_token", value: token)
            } else {
                KeychainHelper.delete(key: "unit_api_token")
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load token if available
        if apiToken == nil {
            // Token should be set via setAPIToken() method
            print("⚠️ [UnitService] API token not set. Call setAPIToken() before making API calls.")
        }
    }
    
    // MARK: - Token Management
    
    /// Set the Unit API token
    /// - Parameter token: The JWT token from Unit dashboard
    func setAPIToken(_ token: String) {
        apiToken = token
        // Log token info for debugging (first 50 chars only for security)
        let tokenPreview = token.prefix(50)
        print("✅ [UnitService] API token set (preview: \(tokenPreview)...)")
        print("✅ [UnitService] Token length: \(token.count) characters")
        
        // Verify token is actually stored
        if let storedToken = KeychainHelper.get(key: "unit_api_token") {
            let storedPreview = storedToken.prefix(50)
            print("✅ [UnitService] Token verified in Keychain (preview: \(storedPreview)...)")
            if storedToken == token {
                print("✅ [UnitService] Stored token matches provided token")
            } else {
                print("⚠️ [UnitService] Stored token does NOT match provided token!")
            }
        } else {
            print("⚠️ [UnitService] Token not found in Keychain after setting")
        }
        
        // Verify token format (should start with "v2.public.")
        if token.hasPrefix("v2.public.") {
            print("✅ [UnitService] Token format looks correct (starts with v2.public.)")
        } else {
            print("⚠️ [UnitService] Token format may be incorrect (doesn't start with v2.public.)")
        }
    }
    
    /// Check if API token is configured
    var isConfigured: Bool {
        return apiToken != nil
    }
    
    /// Verify the API token by calling the /identity endpoint
    func verifyToken() async throws -> Bool {
        let (data, response) = try await makeRequest(endpoint: "/identity")
        
        if response.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("✅ [UnitService] Token verified successfully")
                if let data = json["data"] as? [String: Any] {
                    print("📋 [UnitService] Token info: \(data)")
                }
                return true
            }
        } else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [UnitService] Token verification failed: \(response.statusCode) - \(errorString)")
            return false
        }
        
        return false
    }
    
    // MARK: - API Request Helpers
    
    private func makeRequest(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        guard let token = apiToken else {
            throw UnitError.notConfigured("API token not set. Call setAPIToken() first.")
        }
        
        // Log token preview for debugging
        let tokenPreview = token.prefix(50)
        print("🔑 [UnitService] Using token (preview: \(tokenPreview)...)")
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw UnitError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        let authHeader = "Bearer \(token)"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        print("🔑 [UnitService] Authorization header set (length: \(authHeader.count) chars)")
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UnitError.invalidResponse
        }
        
        // Log response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📡 [UnitService] \(method) \(endpoint) → \(httpResponse.statusCode)")
            if httpResponse.statusCode >= 400 {
                print("❌ [UnitService] Error response: \(jsonString)")
            }
        }
        
        return (data, httpResponse)
    }
    
    // MARK: - Customer Management
    
    /// Create an application in Unit (which creates a customer if approved)
    /// - Parameters:
    ///   - firstName: Customer's first name
    ///   - lastName: Customer's last name
    ///   - email: Customer's email
    ///   - ssn: Social Security Number (required for KYC)
    ///   - dateOfBirth: Date of birth (required for KYC)
    ///   - phone: Phone number (required)
    ///   - address: Physical address (required for KYC)
    /// - Returns: Application ID (customer will be created if application is approved)
    func createCustomer(
        firstName: String,
        lastName: String,
        email: String,
        ssn: String,
        dateOfBirth: Date,
        phone: String,
        address: UnitAddress
    ) async throws -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Format phone number (remove non-digits, ensure it starts with country code)
        let cleanedPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        let phoneNumber: String
        if cleanedPhone.hasPrefix("1") && cleanedPhone.count == 11 {
            // Already has country code
            phoneNumber = cleanedPhone
        } else if cleanedPhone.count == 10 {
            // Add US country code
            phoneNumber = "1\(cleanedPhone)"
        } else {
            phoneNumber = cleanedPhone
        }
        
        let body: [String: Any] = [
            "data": [
                "type": "individualApplication",
                "attributes": [
                    "fullName": [
                        "first": firstName,
                        "last": lastName
                    ],
                    "email": email,
                    "ssn": ssn,
                    "dateOfBirth": dateFormatter.string(from: dateOfBirth),
                    "phone": [
                        "countryCode": String(phoneNumber.prefix(1)),
                        "number": String(phoneNumber.dropFirst())
                    ],
                    "address": [
                        "street": address.street,
                        "city": address.city,
                        "state": address.state,
                        "postalCode": address.postalCode,
                        "country": address.country
                    ],
                    "requestedProducts": ["Banking"]
                ],
                "relationships": [
                    "org": [
                        "data": [
                            "type": "org",
                            "id": "8599"
                        ]
                    ]
                ]
            ]
        ]
        
        let (data, response) = try await makeRequest(
            endpoint: "/applications",
            method: "POST",
            body: body
        )
        
        guard response.statusCode == 201 else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw UnitError.apiError("Failed to create application: \(response.statusCode) - \(errorString)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let applicationData = json?["data"] as? [String: Any],
              let applicationId = applicationData["id"] as? String else {
            throw UnitError.invalidResponse
        }
        
        // Check application status
        if let attributes = applicationData["attributes"] as? [String: Any],
           let status = attributes["status"] as? String {
            print("📋 [UnitService] Application created: \(applicationId), status: \(status)")
            
            if status == "Approved" {
                // If approved, get the customer ID from relationships
                if let relationships = applicationData["relationships"] as? [String: Any],
                   let customer = relationships["customer"] as? [String: Any],
                   let customerData = customer["data"] as? [String: Any],
                   let customerId = customerData["id"] as? String {
                    print("✅ [UnitService] Application approved - Customer ID: \(customerId)")
                    return customerId
                }
            } else if status == "Denied" {
                let message = attributes["message"] as? String ?? "Application was denied"
                let detailedMessage = """
                Application was denied by Unit's identity verification system.
                
                \(message)
                
                This is common in sandbox testing. You can:
                1. Try using different test data
                2. Use the "Link Existing Account" option if you have an approved account
                3. Contact Unit support for sandbox identity verification assistance
                """
                throw UnitError.apiError(detailedMessage)
            } else if status == "PendingReview" || status == "Pending" {
                // Pending or other status
                print("⏳ [UnitService] Application pending review - Application ID: \(applicationId)")
                // For pending applications, we can't create an account yet
                throw UnitError.apiError("Application is pending review. Please wait for approval before creating an account.")
            } else {
                // Unknown status
                print("⚠️ [UnitService] Application status: \(status) - Application ID: \(applicationId)")
                throw UnitError.apiError("Application created but status is '\(status)'. Please check the Unit dashboard for details.")
            }
        }
        
        // If we can't determine status, return application ID (caller will need to check status later)
        print("⚠️ [UnitService] Could not determine application status - Application ID: \(applicationId)")
        return applicationId
    }
    
    // MARK: - Account Management
    
    /// Create a deposit account for a user
    /// - Parameters:
    ///   - customerId: The Unit customer ID
    ///   - userId: Your app's user ID (for tagging)
    /// - Returns: Account ID and account details
    func createDepositAccount(
        customerId: String,
        userId: String
    ) async throws -> UnitAccount {
        let body: [String: Any] = [
            "data": [
                "type": "depositAccount",
                "attributes": [
                    "depositProduct": "checking",
                    "tags": [
                        "user_id": userId,
                        "app": "soteria"
                    ]
                ],
                "relationships": [
                    "customer": [
                        "data": [
                            "type": "customer",
                            "id": customerId
                        ]
                    ]
                ]
            ]
        ]
        
        let (data, response) = try await makeRequest(
            endpoint: "/accounts",
            method: "POST",
            body: body
        )
        
        guard response.statusCode == 201 else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            throw UnitError.apiError("Failed to create account: \(response.statusCode) - \(errorData ?? [:])")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accountData = json?["data"] as? [String: Any] else {
            throw UnitError.invalidResponse
        }
        
        let accountId = accountData["id"] as? String ?? ""
        let attributes = accountData["attributes"] as? [String: Any] ?? [:]
        let accountNumber = attributes["accountNumber"] as? String ?? ""
        let routingNumber = attributes["routingNumber"] as? String ?? ""
        
        print("✅ [UnitService] Account created: \(accountId)")
        
        return UnitAccount(
            id: accountId,
            accountNumber: accountNumber,
            routingNumber: routingNumber,
            customerId: customerId
        )
    }
    
    /// Get account by ID and verify it exists
    /// - Parameter accountId: The Unit account ID
    /// - Returns: UnitAccount if found, nil otherwise
    func getAccount(accountId: String) async throws -> UnitAccount? {
        let (data, response) = try await makeRequest(
            endpoint: "/accounts/\(accountId)"
        )
        
        guard response.statusCode == 200 else {
            if response.statusCode == 404 {
                return nil // Account doesn't exist
            }
            throw UnitError.apiError("Failed to get account: \(response.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accountData = json?["data"] as? [String: Any] else {
            throw UnitError.invalidResponse
        }
        
        let id = accountData["id"] as? String ?? ""
        let attributes = accountData["attributes"] as? [String: Any] ?? [:]
        let accountNumber = attributes["accountNumber"] as? String ?? ""
        let routingNumber = attributes["routingNumber"] as? String ?? ""
        let relationships = accountData["relationships"] as? [String: Any] ?? [:]
        let customer = relationships["customer"] as? [String: Any] ?? [:]
        let customerData = customer["data"] as? [String: Any] ?? [:]
        let customerId = customerData["id"] as? String ?? ""
        
        return UnitAccount(
            id: id,
            accountNumber: accountNumber,
            routingNumber: routingNumber,
            customerId: customerId
        )
    }
    
    /// Get account balance
    /// - Parameter accountId: The Unit account ID
    /// - Returns: Current balance
    func getAccountBalance(accountId: String) async throws -> Double {
        let (data, response) = try await makeRequest(
            endpoint: "/accounts/\(accountId)"
        )
        
        guard response.statusCode == 200 else {
            throw UnitError.apiError("Failed to get account: \(response.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accountData = json?["data"] as? [String: Any],
              let attributes = accountData["attributes"] as? [String: Any],
              let balanceString = attributes["balance"] as? String,
              let balance = Double(balanceString) else {
            throw UnitError.invalidResponse
        }
        
        return balance / 100.0 // Unit returns amounts in cents
    }
    
    /// Find customer by email
    /// - Parameter email: Customer email address
    /// - Returns: Customer ID if found, nil otherwise
    func findCustomerByEmail(email: String) async throws -> String? {
        // Unit API: GET /customers?filter[email]=email
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        let (data, response) = try await makeRequest(
            endpoint: "/customers?filter[email]=\(encodedEmail)"
        )
        
        guard response.statusCode == 200 else {
            throw UnitError.apiError("Failed to search customers: \(response.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        print("🔍 [UnitService] Customer search response: \(json)")
        
        guard let customersData = json?["data"] as? [[String: Any]] else {
            print("⚠️ [UnitService] No customers data in response")
            return nil // No customer found
        }
        
        print("✅ [UnitService] Found \(customersData.count) customer(s)")
        
        guard let firstCustomer = customersData.first,
              let customerId = firstCustomer["id"] as? String else {
            print("⚠️ [UnitService] Customer data missing ID")
            return nil
        }
        
        print("✅ [UnitService] Customer ID: \(customerId)")
        return customerId
    }
    
    /// Find accounts by customer ID (works for both individual and business customers)
    /// - Parameter customerId: The Unit customer ID
    /// - Returns: Array of accounts for this customer
    func findAccountsByCustomer(customerId: String) async throws -> [UnitAccount] {
        // Unit API: GET /accounts?filter[customerId]=customerId
        // This works for both individual and business customers
        let endpoint = "/accounts?filter[customerId]=\(customerId)"
        let (data, response) = try await makeRequest(endpoint: endpoint)
        
        guard response.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [UnitService] Failed to search accounts: \(response.statusCode) - \(errorString)")
            // Try listing all accounts as fallback
            print("🔄 [UnitService] Trying fallback: list all accounts...")
            return try await listAllAccountsForCustomer(customerId: customerId)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let json = json {
            print("🔍 [UnitService] Accounts response keys: \(json.keys)")
            if let dataArray = json["data"] as? [[String: Any]] {
                print("🔍 [UnitService] Found \(dataArray.count) accounts in response")
            }
        }
        
        guard let accountsData = json?["data"] as? [[String: Any]] else {
            print("⚠️ [UnitService] No accounts data in response or empty array")
            // Try listing all accounts as fallback
            return try await listAllAccountsForCustomer(customerId: customerId)
        }
        
        print("✅ [UnitService] Found \(accountsData.count) accounts for customer \(customerId)")
        
        var accounts: [UnitAccount] = []
        for accountData in accountsData {
            let id = accountData["id"] as? String ?? ""
            let type = accountData["type"] as? String ?? ""
            let attributes = accountData["attributes"] as? [String: Any] ?? [:]
            let accountNumber = attributes["accountNumber"] as? String ?? ""
            let routingNumber = attributes["routingNumber"] as? String ?? ""
            let relationships = accountData["relationships"] as? [String: Any] ?? [:]
            let customer = relationships["customer"] as? [String: Any] ?? [:]
            let customerData = customer["data"] as? [String: Any] ?? [:]
            let accountCustomerId = customerData["id"] as? String ?? ""
            
            print("📋 [UnitService] Account: id=\(id), type=\(type), number=\(accountNumber), customer=\(accountCustomerId)")
            
            // Only include if customer matches
            if accountCustomerId == customerId {
                accounts.append(UnitAccount(
                    id: id,
                    accountNumber: accountNumber,
                    routingNumber: routingNumber,
                    customerId: customerId
                ))
            }
        }
        
        return accounts
    }
    
    /// List all accounts and filter by customer ID (fallback method)
    /// - Parameter customerId: The Unit customer ID
    /// - Returns: Array of accounts for this customer
    private func listAllAccountsForCustomer(customerId: String) async throws -> [UnitAccount] {
        print("🔄 [UnitService] Trying to list all accounts as fallback...")
        let (data, response) = try await makeRequest(endpoint: "/accounts")
        
        guard response.statusCode == 200 else {
            throw UnitError.apiError("Failed to list accounts: \(response.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accountsData = json?["data"] as? [[String: Any]] else {
            return []
        }
        
        print("📋 [UnitService] Found \(accountsData.count) total accounts, filtering for customer \(customerId)")
        
        var accounts: [UnitAccount] = []
        for accountData in accountsData {
            let relationships = accountData["relationships"] as? [String: Any] ?? [:]
            let customer = relationships["customer"] as? [String: Any] ?? [:]
            let customerData = customer["data"] as? [String: Any] ?? [:]
            let accountCustomerId = customerData["id"] as? String ?? ""
            
            // Only include accounts for this customer
            if accountCustomerId == customerId {
                let id = accountData["id"] as? String ?? ""
                let attributes = accountData["attributes"] as? [String: Any] ?? [:]
                let accountNumber = attributes["accountNumber"] as? String ?? ""
                let routingNumber = attributes["routingNumber"] as? String ?? ""
                
                print("✅ [UnitService] Found matching account: \(id), number: \(accountNumber)")
                
                accounts.append(UnitAccount(
                    id: id,
                    accountNumber: accountNumber,
                    routingNumber: routingNumber,
                    customerId: customerId
                ))
            }
        }
        
        return accounts
    }
    
    /// Find accounts by user ID tag
    /// - Parameter userId: Your app's user ID
    /// - Returns: Array of accounts tagged with this user_id
    /// Note: Unit API may not support tag filtering - this may return empty
    func findAccountsByUserId(userId: String) async throws -> [UnitAccount] {
        // Unit API doesn't support filter[tags] in query params
        // Instead, we'll get all accounts and filter by tags in code
        // Or skip this method and rely on customer lookup
        print("⚠️ [UnitService] Tag filtering not supported by Unit API - skipping user_id lookup")
        return []
    }
    
    /// List all accounts (for debugging/finding accounts)
    /// - Returns: Array of all accounts
    func listAllAccounts() async throws -> [UnitAccount] {
        let (data, response) = try await makeRequest(endpoint: "/accounts")
        
        guard response.statusCode == 200 else {
            throw UnitError.apiError("Failed to list accounts: \(response.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accountsData = json?["data"] as? [[String: Any]] else {
            return []
        }
        
        print("📋 [UnitService] Found \(accountsData.count) total accounts in Unit")
        
        var accounts: [UnitAccount] = []
        for accountData in accountsData {
            let id = accountData["id"] as? String ?? ""
            let type = accountData["type"] as? String ?? ""
            let attributes = accountData["attributes"] as? [String: Any] ?? [:]
            let accountNumber = attributes["accountNumber"] as? String ?? ""
            let routingNumber = attributes["routingNumber"] as? String ?? ""
            let relationships = accountData["relationships"] as? [String: Any] ?? [:]
            let customer = relationships["customer"] as? [String: Any] ?? [:]
            let customerData = customer["data"] as? [String: Any] ?? [:]
            let customerId = customerData["id"] as? String ?? ""
            
            print("📋 [UnitService] Account: id=\(id), type=\(type), number=\(accountNumber), customer=\(customerId)")
            
            accounts.append(UnitAccount(
                id: id,
                accountNumber: accountNumber,
                routingNumber: routingNumber,
                customerId: customerId
            ))
        }
        
        return accounts
    }
    
    /// Find existing Unit account for user by email or user ID
    /// - Parameters:
    ///   - email: User's email address
    ///   - userId: Your app's user ID
    /// - Returns: UnitAccount if found, nil otherwise
    func findExistingAccount(email: String, userId: String) async -> UnitAccount? {
        // Find by email (find customer, then their accounts)
        do {
            if let customerId = try await findCustomerByEmail(email: email) {
                print("✅ [UnitService] Found customer: \(customerId)")
                let accounts = try await findAccountsByCustomer(customerId: customerId)
                
                if let account = accounts.first {
                    print("✅ [UnitService] Found account by email: \(account.id), number: \(account.accountNumber)")
                    // Save to UserDefaults
                    UserDefaults.standard.set(account.id, forKey: "unit_account_id")
                    UserDefaults.standard.set(account.accountNumber, forKey: "unit_account_number")
                    UserDefaults.standard.set(account.routingNumber, forKey: "unit_routing_number")
                    UserDefaults.standard.set(true, forKey: "unit_account_created")
                    return account
                } else {
                    print("⚠️ [UnitService] Customer found but no accounts for customer: \(customerId)")
                    print("🔄 [UnitService] Trying to list all accounts to find any linked to this customer...")
                    
                    // Fallback: List all accounts and find one linked to this customer
                    let allAccounts = try await listAllAccounts()
                    if let account = allAccounts.first(where: { $0.customerId == customerId }) {
                        print("✅ [UnitService] Found account via list all: \(account.id), number: \(account.accountNumber)")
                        // Save to UserDefaults
                        UserDefaults.standard.set(account.id, forKey: "unit_account_id")
                        UserDefaults.standard.set(account.accountNumber, forKey: "unit_account_number")
                        UserDefaults.standard.set(account.routingNumber, forKey: "unit_routing_number")
                        UserDefaults.standard.set(true, forKey: "unit_account_created")
                        return account
                    } else {
                        print("⚠️ [UnitService] No accounts found even after listing all accounts")
                        print("💡 [UnitService] If account exists, you may need to provide the account ID manually")
                    }
                }
            } else {
                print("⚠️ [UnitService] No customer found for email: \(email)")
            }
        } catch {
            print("❌ [UnitService] Error finding account: \(error)")
        }
        
        print("⚠️ [UnitService] No existing account found for email: \(email), userId: \(userId)")
        return nil
    }
    
    /// Verify if user has a Unit account by checking stored account ID
    /// - Returns: true if account exists and is valid, false otherwise
    func verifyAccountExists() async -> Bool {
        guard let accountId = UserDefaults.standard.string(forKey: "unit_account_id"),
              !accountId.isEmpty else {
            return false
        }
        
        do {
            let account = try await getAccount(accountId: accountId)
            if let account = account {
                // Update UserDefaults with latest account info
                UserDefaults.standard.set(account.accountNumber, forKey: "unit_account_number")
                UserDefaults.standard.set(account.routingNumber, forKey: "unit_routing_number")
                UserDefaults.standard.set(true, forKey: "unit_account_created")
                return true
            }
        } catch {
            print("⚠️ [UnitService] Failed to verify account: \(error)")
        }
        
        return false
    }
    
    // MARK: - Transaction Management
    
    /// Create a payment/deposit and tag it with a goal_id
    /// - Parameters:
    ///   - accountId: The Unit account ID
    ///   - amount: Amount in dollars (will be converted to cents)
    ///   - goalId: The goal ID to tag this transaction with
    ///   - goalName: The goal name (for description)
    ///   - description: Optional description
    /// - Returns: Transaction ID
    func createGoalDeposit(
        accountId: String,
        amount: Double,
        goalId: String,
        goalName: String,
        description: String? = nil
    ) async throws -> String {
        let amountInCents = Int(amount * 100)
        
        let body: [String: Any] = [
            "data": [
                "type": "payment",
                "attributes": [
                    "amount": amountInCents,
                    "direction": "Credit",
                    "description": description ?? "Deposit to \(goalName)",
                    "tags": [
                        "goal_id": goalId,
                        "goal_name": goalName
                    ]
                ],
                "relationships": [
                    "account": [
                        "data": [
                            "type": "account",
                            "id": accountId
                        ]
                    ]
                ]
            ]
        ]
        
        let (data, response) = try await makeRequest(
            endpoint: "/payments",
            method: "POST",
            body: body
        )
        
        guard response.statusCode == 201 else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            throw UnitError.apiError("Failed to create payment: \(response.statusCode) - \(errorData ?? [:])")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let paymentData = json?["data"] as? [String: Any],
              let paymentId = paymentData["id"] as? String else {
            throw UnitError.invalidResponse
        }
        
        print("✅ [UnitService] Payment created: \(paymentId) for goal: \(goalId)")
        return paymentId
    }
    
    /// Get transactions for a specific goal
    /// - Parameters:
    ///   - accountId: The Unit account ID
    ///   - goalId: The goal ID to filter by
    /// - Returns: Array of transactions tagged with this goal_id
    func getGoalTransactions(
        accountId: String,
        goalId: String
    ) async throws -> [UnitTransaction] {
        // Note: Unit API may require filtering via query parameters
        // This is a placeholder - actual implementation depends on Unit's API
        let (data, response) = try await makeRequest(
            endpoint: "/accounts/\(accountId)/transactions?filter[tags][goal_id]=\(goalId)"
        )
        
        guard response.statusCode == 200 else {
            throw UnitError.apiError("Failed to get transactions: \(response.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let transactionsData = json?["data"] as? [[String: Any]] else {
            return []
        }
        
        var transactions: [UnitTransaction] = []
        for transactionData in transactionsData {
            let id = transactionData["id"] as? String ?? ""
            let attributes = transactionData["attributes"] as? [String: Any] ?? [:]
            let amountString = attributes["amount"] as? String ?? "0"
            let amount = (Double(amountString) ?? 0) / 100.0 // Convert from cents
            let tags = attributes["tags"] as? [String: String] ?? [:]
            let description = attributes["description"] as? String ?? ""
            let createdAt = attributes["createdAt"] as? String ?? ""
            
            transactions.append(UnitTransaction(
                id: id,
                amount: amount,
                description: description,
                goalId: tags["goal_id"],
                goalName: tags["goal_name"],
                createdAt: createdAt
            ))
        }
        
        return transactions
    }
    
    /// Calculate goal balance by summing transactions
    /// - Parameters:
    ///   - accountId: The Unit account ID
    ///   - goalId: The goal ID
    /// - Returns: Total balance for this goal
    func getGoalBalance(
        accountId: String,
        goalId: String
    ) async throws -> Double {
        let transactions = try await getGoalTransactions(accountId: accountId, goalId: goalId)
        return transactions.reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Models

struct UnitAccount {
    let id: String
    let accountNumber: String
    let routingNumber: String
    let customerId: String
}

struct UnitTransaction {
    let id: String
    let amount: Double
    let description: String
    let goalId: String?
    let goalName: String?
    let createdAt: String
}

struct UnitAddress {
    let street: String
    let city: String
    let state: String
    let postalCode: String
    let country: String
}

// MARK: - Errors

enum UnitError: LocalizedError {
    case notConfigured(String)
    case invalidURL
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured(let message):
            return "Unit API not configured: \(message)"
        case .invalidURL:
            return "Invalid Unit API URL"
        case .invalidResponse:
            return "Invalid response from Unit API"
        case .apiError(let message):
            return "Unit API error: \(message)"
        }
    }
}

