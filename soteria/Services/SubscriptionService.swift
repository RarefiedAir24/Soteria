//
//  SubscriptionService.swift
//  soteria
//
//  Subscription management with StoreKit
//

import Foundation
import Combine
import StoreKit

enum SubscriptionTier {
    case free
    case premium
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }
}

class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Product IDs - Update these with your actual App Store Connect product IDs
    private let monthlyProductID = "com.soteria.premium.monthly"
    private let yearlyProductID = "com.soteria.premium.yearly"
    
    private var products: [Product] = []
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // Load from UserDefaults immediately (fast, synchronous)
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        subscriptionTier = isPremium ? .premium : .free
        
        // Defer heavy operations to avoid blocking UI
        Task { [weak self] in
            guard let self = self else { return }
            // Load subscription status from StoreKit (async)
            await self.updateSubscriptionStatus()
            
            // Listen for transaction updates
            self.updateListenerTask = self.listenForTransactions()
            
            // Load products
            await self.loadProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    @MainActor
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = [monthlyProductID, yearlyProductID]
            products = try await Product.products(for: productIDs)
            print("✅ [SubscriptionService] Loaded \(products.count) products")
        } catch {
            print("❌ [SubscriptionService] Failed to load products: \(error)")
            errorMessage = "Failed to load subscription options"
        }
    }
    
    // MARK: - Purchase
    
    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            return true
        case .userCancelled:
            return false
        case .pending:
            errorMessage = "Purchase is pending approval"
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    @MainActor
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ [SubscriptionService] Purchases restored")
        } catch {
            print("❌ [SubscriptionService] Failed to restore: \(error)")
            errorMessage = "Failed to restore purchases"
        }
    }
    
    // MARK: - Subscription Status
    
    @MainActor
    private func updateSubscriptionStatus() async {
        var isCurrentlyPremium = false
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == monthlyProductID || transaction.productID == yearlyProductID {
                    // Check if subscription is still valid
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            isCurrentlyPremium = true
                            print("✅ [SubscriptionService] Active premium subscription found")
                        }
                    } else {
                        // Non-consumable or lifetime subscription
                        isCurrentlyPremium = true
                    }
                }
            } catch {
                print("❌ [SubscriptionService] Failed to verify transaction: \(error)")
            }
        }
        
        subscriptionTier = isCurrentlyPremium ? .premium : .free
        isPremium = isCurrentlyPremium
        
        // Save status
        UserDefaults.standard.set(isPremium, forKey: "isPremium")
        
        print("📊 [SubscriptionService] Subscription status: \(subscriptionTier.displayName)")
    }
    
    // MARK: - Transaction Verification
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                } catch {
                    print("❌ [SubscriptionService] Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Product Access
    
    var monthlyProduct: Product? {
        products.first { $0.id == monthlyProductID }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == yearlyProductID }
    }
    
    var allProducts: [Product] {
        products
    }
}

enum SubscriptionError: Error {
    case failedVerification
    case productNotFound
}

