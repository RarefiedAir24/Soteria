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
    @Published var isPremium: Bool = false {
        didSet {
            // CRITICAL: Keep UserDefaults in sync for extension access
            // The extension needs to check subscription status via UserDefaults
            UserDefaults.standard.set(isPremium, forKey: "isPremium")
        }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Product IDs - Must match Products.storekit configuration
    // Format: com.soteria.premium.monthly and com.soteria.premium.yearly
    private let monthlyProductID = "com.soteria.premium.monthly"
    private let yearlyProductID = "com.soteria.premium.yearly"
    
    private var products: [Product] = []
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // CRITICAL: Do ABSOLUTELY NOTHING in init() - not even UserDefaults reads
        // UserDefaults reads on MainActor during init() can block SwiftUI initialization
        // All initialization happens in startInitialization() which is called after UI is rendered
        
        // CRITICAL: Defer ALL work to 60+ seconds after startup to prevent blocking
        // This ensures the app is fully interactive before doing any work
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) { [weak self] in
            guard let self = self else { return }
            self.startInitialization()
        }
    }
    
    private var hasInitialized = false
    
    func startInitialization() {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        print("🔄 [SubscriptionService] Starting initialization (deferred)")
        
        // Load from UserDefaults (now safe, UI is rendered)
        let isTestAccount = UserDefaults.standard.bool(forKey: "isTestAccountPremium")
        if isTestAccount {
            isPremium = true
            subscriptionTier = .premium
            print("✅ [SubscriptionService] Test account premium status loaded from UserDefaults")
        } else {
            isPremium = UserDefaults.standard.bool(forKey: "isPremium")
            subscriptionTier = isPremium ? .premium : .free
        }
        
        // Defer heavy operations to avoid blocking UI during startup
        // Use Task.detached to ensure it doesn't block the main thread
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            // Small delay to ensure app startup completes first
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Load subscription status from StoreKit (async, non-blocking)
            await self.updateSubscriptionStatus()
            
            // Listen for transaction updates (background task)
            // CRITICAL: Use DispatchQueue instead of MainActor.run to avoid blocking
            // This prevents MainActor blocking during startup
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateListenerTask = self.listenForTransactions()
            }
            
            // DON'T load products here - they're loaded when PaywallView appears
            // This prevents unnecessary StoreKit calls during startup
            // await self.loadProducts()  // ❌ Removed - loaded in PaywallView.task instead
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    @MainActor
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let productIDs = [monthlyProductID, yearlyProductID]
            print("🟡 [SubscriptionService] Loading products: \(productIDs)")
            print("🟡 [SubscriptionService] Make sure scheme is configured to use Products.storekit!")
            print("🟡 [SubscriptionService] Edit Scheme → Run → Options → StoreKit Configuration")
            products = try await Product.products(for: productIDs)
            print("✅ [SubscriptionService] Loaded \(products.count) products")
            
            if products.isEmpty {
                errorMessage = "No subscription products found. Please check:\n1. Scheme is configured (Edit Scheme → Run → Options → StoreKit Configuration → Products.storekit)\n2. App is running in DEBUG mode\n3. Clean build folder (⇧⌘K) and rebuild"
                print("⚠️ [SubscriptionService] No products loaded - check product IDs: \(productIDs)")
                print("⚠️ [SubscriptionService] StoreKit Configuration file may not be active")
                print("⚠️ [SubscriptionService] Verify: Edit Scheme → Run → Options → StoreKit Configuration = Products.storekit")
            } else {
                // Clear any previous error
                errorMessage = nil
                print("✅ [SubscriptionService] Products loaded successfully from StoreKit Configuration!")
            }
        } catch {
            print("❌ [SubscriptionService] Failed to load products: \(error.localizedDescription)")
            print("❌ [SubscriptionService] Error details: \(error)")
            errorMessage = "Failed to load subscription options: \(error.localizedDescription)\n\nMake sure:\n1. Scheme uses Products.storekit (Edit Scheme → Run → Options)\n2. App is in DEBUG mode\n3. Clean build (⇧⌘K) and rebuild"
            products = [] // Clear products on error
        }
    }
    
    // MARK: - Purchase
    
    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // Record subscription for streak tracking BEFORE finishing transaction
            SubscriptionStreakService.shared.recordSubscription(
                productID: transaction.productID,
                transactionDate: transaction.purchaseDate
            )
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
    func updateSubscriptionStatus() async {
        // Check if this is a test account - preserve premium status for test accounts
        let isTestAccount = UserDefaults.standard.bool(forKey: "isTestAccountPremium")
        if isTestAccount {
            print("✅ [SubscriptionService] Test account detected - preserving premium status")
            isPremium = true
            subscriptionTier = .premium
            return
        }
        
        var isCurrentlyPremium = false
        var latestTransaction: (productID: String, purchaseDate: Date)? = nil
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == monthlyProductID || transaction.productID == yearlyProductID {
                    // Check if subscription is still valid
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            isCurrentlyPremium = true
                            // Track the latest transaction for streak calculation
                            if latestTransaction == nil || transaction.purchaseDate > latestTransaction!.purchaseDate {
                                latestTransaction = (transaction.productID, transaction.purchaseDate)
                            }
                            print("✅ [SubscriptionService] Active premium subscription found: \(transaction.productID)")
                        }
                    } else {
                        // Non-consumable or lifetime subscription
                        isCurrentlyPremium = true
                        if latestTransaction == nil || transaction.purchaseDate > latestTransaction!.purchaseDate {
                            latestTransaction = (transaction.productID, transaction.purchaseDate)
                        }
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
        
        // Update subscription streak with product ID and transaction date
        SubscriptionStreakService.shared.ensureDataLoaded()
        if isCurrentlyPremium, let transaction = latestTransaction {
            print("📊 [SubscriptionService] Recording subscription for streak: \(transaction.productID), date: \(transaction.purchaseDate)")
            SubscriptionStreakService.shared.recordSubscription(
                productID: transaction.productID,
                transactionDate: transaction.purchaseDate
            )
        } else if !isCurrentlyPremium {
            // No longer premium - streak stays but doesn't increment
            print("📊 [SubscriptionService] User is not premium - streak remains at \(SubscriptionStreakService.shared.currentStreak)")
        }
        
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
                    // Record subscription for streak tracking (handles renewals)
                    if transaction.productID == self.monthlyProductID || transaction.productID == self.yearlyProductID {
                        await MainActor.run {
                            SubscriptionStreakService.shared.recordSubscription(
                                productID: transaction.productID,
                                transactionDate: transaction.purchaseDate
                            )
                        }
                    }
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
    
    // MARK: - Testing/Development
    
    /// Manually set premium status for testing (only for specific test accounts)
    @MainActor
    func setPremiumForTesting(email: String) {
        // Only allow for specific test accounts
        let testAccounts = ["supergeek@me.com", "supergeek"]
        guard testAccounts.contains(email.lowercased()) else {
            print("⚠️ [SubscriptionService] Test account not authorized: \(email)")
            return
        }
        
        isPremium = true
        subscriptionTier = .premium
        UserDefaults.standard.set(true, forKey: "isPremium")
        UserDefaults.standard.set(true, forKey: "isTestAccountPremium") // Flag to preserve premium status
        print("✅ [SubscriptionService] Premium status manually set for testing account: \(email)")
        print("✅ [SubscriptionService] isPremium: \(isPremium), subscriptionTier: \(subscriptionTier.displayName)")
    }
}

enum SubscriptionError: Error {
    case failedVerification
    case productNotFound
}

