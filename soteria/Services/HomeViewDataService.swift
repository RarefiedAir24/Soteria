//
//  HomeViewDataService.swift
//  soteria
//
//  Aggregated service for HomeView to reduce environment object count
//  This service wraps access to multiple services, reducing from 11 to 1 environment object
//

import Foundation
import Combine
// TEMPORARILY DISABLED: Firebase import - testing if it's causing crash
// import FirebaseAuth

/// Aggregated service that provides all data HomeView needs
/// This reduces HomeView from 11 @EnvironmentObject properties to just 1
class HomeViewDataService: ObservableObject {
    static let shared = HomeViewDataService()
    
    // Lazy access to underlying services (only accessed when needed)
    // Note: These are accessed via computed properties to ensure lazy initialization
    private var moodService: MoodTrackingService { MoodTrackingService.shared }
    private var streakService: StreakService { StreakService.shared }
    private var regretService: RegretLoggingService { RegretLoggingService.shared }
    private var regretRiskEngine: RegretRiskEngine { RegretRiskEngine.shared }
    private var goalsService: GoalsService { GoalsService.shared }
    private var quietHoursService: QuietHoursService { QuietHoursService.shared }
    private var deviceActivityService: DeviceActivityService { DeviceActivityService.shared }
    private var subscriptionService: SubscriptionService { SubscriptionService.shared }
    private var purchaseIntentService: PurchaseIntentService { PurchaseIntentService.shared }
    // AuthService is not a singleton, so we access Firebase Auth directly
    // This is safe since AuthService also uses FirebaseAuth.currentUser internally
    
    private var savingsService: SavingsService { SavingsService.shared }
    
    // Published properties that HomeView needs (cached for performance)
    @Published var cachedRisk: RegretRiskAssessment? = nil
    @Published var cachedTotalSaved: Double = 0.0
    @Published var cachedIsQuietModeActive: Bool = false
    @Published var cachedActiveGoal: SavingsGoal? = nil
    @Published var cachedCurrentStreak: Int = 0
    @Published var cachedSoteriaMomentsCount: Int = 0
    @Published var cachedLastSavedAmount: Double? = nil
    @Published var cachedCurrentActiveSchedule: QuietHoursSchedule? = nil
    @Published var cachedStreakEmoji: String = "🔥"
    @Published var cachedCurrentMood: MoodLevel? = nil
    @Published var cachedRecentRegretCount: Int = 0
    @Published var cachedUserEmail: String = "there"
    @Published var cachedUserName: String = "User"
    @Published var recentIntents: [PurchaseIntent] = []
    @Published var totalIntentsCount: Int = 0
    
    private init() {
        let initStart = Date()
        print("✅ [HomeViewDataService] Init started at \(initStart) (truly lazy - no work on startup)")
        // Do absolutely nothing on startup - all data loaded on-demand
        let initEnd = Date()
        print("✅ [HomeViewDataService] Initialized at \(initEnd) (total: \(initEnd.timeIntervalSince(initStart))s)")
        
        // Defer all work to background task with delay
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            // Wait 30 seconds to ensure app is fully loaded and responsive
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            await MainActor.run {
                self.refreshAllData()
                print("✅ [HomeViewDataService] Data refreshed")
            }
        }
    }
    
    // Refresh all cached data (call on-demand)
    func refreshAllData() {
        // Access underlying services and cache their values
        cachedRisk = regretRiskEngine.currentRisk
        cachedTotalSaved = savingsService.totalSaved
        cachedIsQuietModeActive = quietHoursService.isQuietModeActive
        cachedActiveGoal = goalsService.activeGoal
        cachedCurrentStreak = streakService.currentStreak
        cachedSoteriaMomentsCount = savingsService.soteriaMomentsCount
        cachedLastSavedAmount = savingsService.lastSavedAmount
        cachedCurrentActiveSchedule = quietHoursService.currentActiveSchedule
        cachedStreakEmoji = streakService.streakEmoji
        cachedCurrentMood = moodService.currentMood
        cachedRecentRegretCount = regretService.recentRegretCount
        // TEMPORARILY DISABLED: Firebase Auth access - testing if it's causing crash
        // CRITICAL: Access Firebase Auth asynchronously to prevent blocking
        // Don't access Auth.auth().currentUser synchronously - it can block MainActor
        // Task.detached(priority: .userInitiated) { [weak self] in
        //     guard let self = self else { return }
        //     // Access Firebase Auth in background thread (it's thread-safe)
        //     let firebaseUser = Auth.auth().currentUser
        //     let email = firebaseUser?.email?.components(separatedBy: "@").first ?? "there"
        //     let name = firebaseUser?.displayName ?? email
        //     
        //     // Update cached values on MainActor (non-blocking)
        //     await MainActor.run {
        //         self.cachedUserEmail = email
        //         self.cachedUserName = name
        //     }
        // }
        
        // Set default values when Firebase is disabled
        cachedUserEmail = "there"
        cachedUserName = "User"
        
        // CRITICAL: Don't load purchase intent data here - it's loaded lazily when needed
        // This prevents blocking during initial data refresh
        // Purchase intent data will be loaded on-demand when recentInteractionsCard appears
    }
    
    // Load purchase intent data on-demand (lazy loading)
    // This prevents blocking during initial data refresh
    func refreshPurchaseIntentData() {
        // Ensure data is loaded first
        purchaseIntentService.ensureDataLoaded()
        
        // Cache purchase intent data
        totalIntentsCount = purchaseIntentService.purchaseIntents.count
        recentIntents = Array(purchaseIntentService.purchaseIntents.sorted { $0.date > $1.date }.prefix(3))
    }
    
    // Expose underlying services for direct access when needed
    var mood: MoodTrackingService { moodService }
    var streak: StreakService { streakService }
    var regret: RegretLoggingService { regretService }
    var risk: RegretRiskEngine { regretRiskEngine }
    var savings: SavingsService { savingsService }
    var goals: GoalsService { goalsService }
    var quietHours: QuietHoursService { quietHoursService }
    var deviceActivity: DeviceActivityService { deviceActivityService }
    var subscription: SubscriptionService { subscriptionService }
    var purchaseIntent: PurchaseIntentService { purchaseIntentService }
    // Note: AuthService is not exposed here since it's not a singleton
    // Access Firebase Auth directly via Auth.auth() if needed
}

