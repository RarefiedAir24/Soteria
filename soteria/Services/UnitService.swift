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
        print("✅ [UnitService] API token set")
    }
    
    /// Check if API token is configured
    var isConfigured: Bool {
        return apiToken != nil
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
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw UnitError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
    
    /// Create a customer in Unit
    /// - Parameters:
    ///   - firstName: Customer's first name
    ///   - lastName: Customer's last name
    ///   - email: Customer's email
    ///   - ssn: Social Security Number (required for KYC)
    ///   - dateOfBirth: Date of birth (required for KYC)
    ///   - address: Physical address (required for KYC)
    /// - Returns: Customer ID
    func createCustomer(
        firstName: String,
        lastName: String,
        email: String,
        ssn: String,
        dateOfBirth: Date,
        address: UnitAddress
    ) async throws -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let body: [String: Any] = [
            "data": [
                "type": "customer",
                "attributes": [
                    "fullName": [
                        "first": firstName,
                        "last": lastName
                    ],
                    "email": email,
                    "ssn": ssn,
                    "dateOfBirth": dateFormatter.string(from: dateOfBirth),
                    "address": [
                        "street": address.street,
                        "city": address.city,
                        "state": address.state,
                        "postalCode": address.postalCode,
                        "country": address.country
                    ]
                ]
            ]
        ]
        
        let (data, response) = try await makeRequest(
            endpoint: "/customers",
            method: "POST",
            body: body
        )
        
        guard response.statusCode == 201 else {
            throw UnitError.apiError("Failed to create customer: \(response.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let customerId = json?["data"] as? [String: Any],
              let id = customerId["id"] as? String else {
            throw UnitError.invalidResponse
        }
        
        print("✅ [UnitService] Customer created: \(id)")
        return id
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

