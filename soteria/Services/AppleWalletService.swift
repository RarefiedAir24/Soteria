//
//  AppleWalletService.swift
//  soteria
//
//  Handles Apple Wallet integration for premium member cards
//

import Foundation
import PassKit

class AppleWalletService {
    static let shared = AppleWalletService()
    
    private init() {}
    
    // API Gateway URL (same as other services)
    #if DEBUG
    #if targetEnvironment(simulator)
    private let apiGatewayURL = "http://localhost:8000"
    #else
    private let apiGatewayURL = "http://10.0.0.52:8000"
    #endif
    #else
    private let apiGatewayURL = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod"
    #endif
    
    private lazy var cognitoService = CognitoAuthService.shared
    
    /// Checks if Apple Wallet is available on the device
    var isWalletAvailable: Bool {
        PKAddPassesViewController.canAddPasses()
    }
    
    /// Downloads and creates a pass for the premium member card from the backend
    /// - Parameters:
    ///   - userId: The user's unique ID
    ///   - cardType: The card type (gold, platinum, black)
    /// - Returns: A PKPass if successful, throws error otherwise
    func downloadMemberCardPass(
        userId: String,
        cardType: String
    ) async throws -> PKPass {
        // Get authentication token
        guard let idToken = try await cognitoService.getIDToken() else {
            throw AppleWalletError.notAuthenticated
        }
        
        // Construct API endpoint
        var urlComponents = URLComponents(string: "\(apiGatewayURL)/soteria/apple-wallet/pass")!
        urlComponents.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "card_type", value: cardType)
        ]
        
        guard let url = urlComponents.url else {
            throw AppleWalletError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.apple.pkpass", forHTTPHeaderField: "Accept")
        
        print("📥 [AppleWalletService] Requesting pass from: \(url.absoluteString)")
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppleWalletError.invalidResponse
        }
        
        // Check for errors
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [AppleWalletService] Server error: \(httpResponse.statusCode) - \(errorMessage)")
            
            if httpResponse.statusCode == 404 {
                throw AppleWalletError.endpointNotAvailable("Apple Wallet pass endpoint not found. Backend setup required.")
            } else if httpResponse.statusCode == 500 {
                throw AppleWalletError.backendError("Backend error: \(errorMessage)")
            } else {
                throw AppleWalletError.serverError(httpResponse.statusCode, errorMessage)
            }
        }
        
        // Check content type
        guard let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
              contentType.contains("application/vnd.apple.pkpass") else {
            throw AppleWalletError.invalidContentType
        }
        
        // Create PKPass from data
        do {
            let pass = try PKPass(data: data)
            print("✅ [AppleWalletService] Pass downloaded successfully")
            return pass
        } catch {
            print("❌ [AppleWalletService] Failed to create PKPass: \(error)")
            throw AppleWalletError.invalidPassData(error.localizedDescription)
        }
    }
    
    /// Presents the add pass view controller
    /// - Parameters:
    ///   - pass: The PKPass to add
    ///   - viewController: The presenting view controller
    func addPassToWallet(_ pass: PKPass, from viewController: UIViewController) {
        let addPassVC = PKAddPassesViewController(pass: pass)
        viewController.present(addPassVC!, animated: true)
    }
}

// MARK: - Apple Wallet Errors

enum AppleWalletError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case invalidContentType
    case invalidPassData(String)
    case endpointNotAvailable(String)
    case backendError(String)
    case serverError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to add a card to Apple Wallet."
        case .invalidURL:
            return "Invalid API endpoint URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .invalidContentType:
            return "Server returned invalid content type. Expected Apple Wallet pass file."
        case .invalidPassData(let message):
            return "Failed to create Apple Wallet pass: \(message)"
        case .endpointNotAvailable(let message):
            return message
        case .backendError(let message):
            return "Backend error: \(message)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        }
    }
}

