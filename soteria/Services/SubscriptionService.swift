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
    @Published var currentSubscriptionProductID: String? = nil // Track which subscription user has (monthly or yearly)
    @Published var showCelebration: Bool = false // Show celebration when subscription is activated
    @Published var celebrationSubscriptionType: String? = nil // Type of subscription to celebrate
    
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
        
        let wasPremiumBefore = isPremium
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ [SubscriptionService] Purchases restored")
            
            // Show celebration if user just restored a subscription (wasn't premium before)
            if !wasPremiumBefore && isPremium, let productID = currentSubscriptionProductID {
                let subscriptionType = productID.contains("yearly") ? "Annual" : "Monthly"
                celebrationSubscriptionType = subscriptionType
                showCelebration = true
            }
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
                    // CRITICAL: Strict expiration check - subscription must be active NOW
                    if let expirationDate = transaction.expirationDate {
                        let now = Date()
                        if expirationDate > now {
                            isCurrentlyPremium = true
                            // Track the latest transaction for streak calculation
                            if latestTransaction == nil || transaction.purchaseDate > latestTransaction!.purchaseDate {
                                latestTransaction = (transaction.productID, transaction.purchaseDate)
                            }
                            print("✅ [SubscriptionService] Active premium subscription found: \(transaction.productID), expires: \(expirationDate)")
                        } else {
                            // Subscription has expired
                            print("🔒 [SubscriptionService] Subscription EXPIRED: \(transaction.productID), expired: \(expirationDate), now: \(now)")
                        }
                    } else {
                        // Non-consumable or lifetime subscription (shouldn't happen for subscriptions, but handle it)
                        isCurrentlyPremium = true
                        if latestTransaction == nil || transaction.purchaseDate > latestTransaction!.purchaseDate {
                            latestTransaction = (transaction.productID, transaction.purchaseDate)
                        }
                        print("✅ [SubscriptionService] Non-expiring subscription found: \(transaction.productID)")
                    }
                }
            } catch {
                print("❌ [SubscriptionService] Failed to verify transaction: \(error)")
            }
        }
        
        // CRITICAL: Strict enforcement - update status immediately
        let previousStatus = isPremium
        subscriptionTier = isCurrentlyPremium ? .premium : .free
        isPremium = isCurrentlyPremium
        
        // Track current subscription product ID
        if isCurrentlyPremium, let transaction = latestTransaction {
            currentSubscriptionProductID = transaction.productID
        } else {
            currentSubscriptionProductID = nil
        }
        
        // Log status changes for monitoring
        if previousStatus != isCurrentlyPremium {
            if isCurrentlyPremium {
                print("✅ [SubscriptionService] SUBSCRIPTION ACTIVATED - User upgraded to premium")
                // Show celebration for new subscription activation (only if wasn't premium before)
                // This prevents showing celebration on app launch for existing subscribers
                if !previousStatus, let transaction = latestTransaction {
                    let subscriptionType = transaction.productID.contains("yearly") ? "Annual" : "Monthly"
                    celebrationSubscriptionType = subscriptionType
                    // Small delay to ensure UI is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.showCelebration = true
                    }
                }
            } else {
                print("🔒 [SubscriptionService] SUBSCRIPTION EXPIRED - User downgraded to free")
                print("🔒 [SubscriptionService] Premium features and card access REVOKED")
            }
        }
        
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
            print("🔒 [SubscriptionService] Premium card and features are DISABLED")
        }
        
        print("📊 [SubscriptionService] Subscription status: \(subscriptionTier.displayName) (verified: \(isCurrentlyPremium))")
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
    
    // Check if user can upgrade (has monthly, can upgrade to annual)
    var canUpgradeToAnnual: Bool {
        guard isPremium, let currentID = currentSubscriptionProductID else { return false }
        return currentID == monthlyProductID
    }
    
    // Get current subscription type
    var currentSubscriptionType: String? {
        guard let productID = currentSubscriptionProductID else { return nil }
        if productID == monthlyProductID {
            return "Monthly"
        } else if productID == yearlyProductID {
            return "Annual"
        }
        return nil
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

