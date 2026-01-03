//
//  DeviceActivityService.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import Foundation
import Combine
import DeviceActivity
import FamilyControls
import ManagedSettings
import UserNotifications
import UIKit

class DeviceActivityService: ObservableObject {
    static let shared = DeviceActivityService()
    
    // AWS Data Service for cloud sync
    // CRITICAL: Make lazy to prevent initialization chain during startup
    private var awsDataService: AWSDataService {
        AWSDataService.shared
    }
    @Published var useAWS: Bool = false // Toggle to enable/disable AWS sync (Premium feature)
    
    // CRITICAL: Flag to prevent didSet from running during initialization
    private var isInitializing = true
    
    @Published var selectedApps: FamilyActivitySelection = FamilyActivitySelection() {
        didSet {
            // CRITICAL: Skip ALL operations during initialization to prevent blocking
            // The didSet itself runs synchronously on MainActor, so even creating tasks can block
            guard !isInitializing else {
                print("⏭️ [DeviceActivityService] Skipping selectedApps.didSet during initialization")
                return
            }
            
            // CRITICAL: Defer ALL operations to 60+ seconds after startup to prevent blocking
            // Accessing applicationTokens.count is a 20+ second blocker
            // Never access it during app startup
            
            // CRITICAL: Never access applicationTokens.count - it blocks for 20+ seconds
            // Instead, we'll rely on the cached count that's updated when the picker closes
            // This prevents the 60-second deferred operation from blocking MainActor
            print("⏭️ [DeviceActivityService] Skipping app count update - will use cached count instead")
            
            // CRITICAL: Disable all deferred operations in didSet to prevent MainActor blocking
            // These operations will be called manually when needed (e.g., when picker closes)
            // This prevents the 60-second deferred tasks from blocking MainActor
            print("⏭️ [DeviceActivityService] Skipping deferred operations in didSet to prevent blocking")
            
            // Auto-name apps from backend (token hash mapping)
            // DISABLED: This accesses selectedApps.applicationTokens which is blocking
            // Move to on-demand or much later (after app is fully loaded)
            // Task.detached(priority: .utility) { [weak self] in
            //     guard let self = self else { return }
            //     // Wait much longer to ensure app is fully loaded
            //     try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            //     await self.autoNameAppsFromBackend()
            // }
            print("🟡 [DeviceActivityService] Deferring autoNameAppsFromBackend() - will run on-demand or much later")
            
            // If monitoring is active, restart it to apply new app selection
            if isMonitoring {
                print("🔄 [DeviceActivityService] App selection changed - restarting monitoring to apply changes")
                Task {
                    // Stop current monitoring
                    // Stop all interval activities plus the main activity
                    var activitiesToStop: [DeviceActivityName] = [activityName]
                    activitiesToStop.append(contentsOf: intervalActivityNames)
                    center.stopMonitoring(activitiesToStop)
                    intervalActivityNames.removeAll()
                    // Small delay to ensure cleanup
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    // Restart monitoring with new selection
                    await startMonitoring()
                }
            }
        }
    }
    
    // Cached app count - loaded from UserDefaults to avoid blocking
    @Published var cachedAppsCount: Int = 0
    private let cachedAppsCountKey = "cachedSelectedAppsCount"
    
    // Store app names by index (since we can't get names from ApplicationToken)
    // Key: app index (0-based), Value: user-provided name
    @Published var appNames: [Int: String] = [:]
    private let appNamesKey = "appNamesMapping"
    @Published var isMonitoring: Bool = false {
        didSet {
            // Skip saving during state loading to prevent blocking startup
            guard !isLoadingState else { return }
            
            // Save monitoring state when it changes
            // CRITICAL: Use DispatchQueue instead of MainActor.run to avoid blocking
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.saveMonitoringState()
            }
        }
    }
    private let isMonitoringKey = "isMonitoringActive"
    @Published var pendingUnlock: Bool = false // Track if user wants to unlock
    
    private let activityName = DeviceActivityName("soteria.monitoring")
    private let center = DeviceActivityCenter()
    // Note: store is not used when blocking is disabled (notifications only)
    // private let store = ManagedSettingsStore()
    
    // Track 2-minute interval activity names for cleanup
    private var intervalActivityNames: [DeviceActivityName] = []
    
    // Track app usage patterns
    @Published var shoppingAttempts: [Date] = [] // When user tried to open shopping apps
    @Published var totalBlockedAttempts: Int = 0
    
    // Track app usage time
    struct AppUsageSession: Codable, Identifiable {
        var id: String
        var appIndex: Int
        var appName: String
        var startTime: Date
        var endTime: Date?
        var duration: TimeInterval {
            let end = endTime ?? Date()
            return end.timeIntervalSince(startTime)
        }
        var isActive: Bool {
            return endTime == nil
        }
    }
    @Published var appUsageSessions: [AppUsageSession] = []
    @Published var activeSessions: [Int: AppUsageSession] = [:] // appIndex -> session
    private let appUsageSessionsKey = "appUsageSessions"
    private var usageSessionTimers: [Int: Timer] = [:] // appIndex -> timer
    private var inactivityTimers: [Int: Timer] = [:] // appIndex -> inactivity timer
    private let maxSessionDuration: TimeInterval = 30 * 60 // 30 minutes max session
    private let inactivityThreshold: TimeInterval = 3 * 60 // 3 minutes of inactivity = app backgrounded
    
    // Track unblock events for metrics and behavioral analysis
    nonisolated struct UnblockEvent: Codable, Identifiable {
        let id: String // Unique identifier
        let timestamp: Date
        let purchaseType: String? // "planned" or "impulse"
        let category: String? // For planned purchases (gift_shopping, necessity, etc.)
        let mood: String? // For impulse purchases (lonely, bored, stressed, etc.)
        let moodNotes: String? // Free text notes for mood (especially "other")
        let selectedAppsCount: Int // How many apps were unblocked
        let appIndex: Int? // Which app was selected (0-based index)
        let appName: String? // App name (for easier analysis)
        let durationMinutes: Int // How long apps were unblocked
        let wasDuringQuietHours: Bool // Was this during active quiet hours?
        let quietHoursScheduleName: String? // Which quiet hours schedule was active
        let timeOfDay: Int // Hour of day (0-23)
        let dayOfWeek: Int // Day of week (1=Sunday, 7=Saturday)
        let timeSinceLastUnblock: TimeInterval? // Seconds since last unblock (if any)
        let unblockCountToday: Int // How many times unblocked today
        let unblockCountThisWeek: Int // How many times unblocked this week
        let wasAppUsed: Bool? // Did user actually open/use the app after unblock? (tracked separately)
        let appUsageDuration: TimeInterval? // How long was app used after unblock? (in seconds)
        
        // Computed properties for analysis
        var hourOfDay: Int {
            let calendar = Calendar.current
            return calendar.component(.hour, from: timestamp)
        }
        
        var dayName: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: timestamp)
        }
        
        var timeOfDayCategory: String {
            let hour = hourOfDay
            switch hour {
            case 0..<6: return "Night (12am-6am)"
            case 6..<12: return "Morning (6am-12pm)"
            case 12..<18: return "Afternoon (12pm-6pm)"
            case 18..<24: return "Evening (6pm-12am)"
            default: return "Unknown"
            }
        }
        
        init(id: String = UUID().uuidString,
             timestamp: Date = Date(),
             purchaseType: String? = nil,
             category: String? = nil,
             mood: String? = nil,
             moodNotes: String? = nil,
             selectedAppsCount: Int,
             appIndex: Int? = nil,
             appName: String? = nil,
             durationMinutes: Int = 15,
             wasDuringQuietHours: Bool = false,
             quietHoursScheduleName: String? = nil,
             timeSinceLastUnblock: TimeInterval? = nil,
             unblockCountToday: Int = 1,
             unblockCountThisWeek: Int = 1,
             wasAppUsed: Bool? = nil,
             appUsageDuration: TimeInterval? = nil) {
            self.id = id
            self.timestamp = timestamp
            self.purchaseType = purchaseType
            self.category = category
            self.mood = mood
            self.moodNotes = moodNotes
            self.selectedAppsCount = selectedAppsCount
            self.appIndex = appIndex
            self.appName = appName
            self.durationMinutes = durationMinutes
            self.wasDuringQuietHours = wasDuringQuietHours
            self.quietHoursScheduleName = quietHoursScheduleName
            let calendar = Calendar.current
            self.timeOfDay = calendar.component(.hour, from: timestamp)
            self.dayOfWeek = calendar.component(.weekday, from: timestamp)
            self.timeSinceLastUnblock = timeSinceLastUnblock
            self.unblockCountToday = unblockCountToday
            self.unblockCountThisWeek = unblockCountThisWeek
            self.wasAppUsed = wasAppUsed
            self.appUsageDuration = appUsageDuration
        }
    }
    @Published var unblockEvents: [UnblockEvent] = []
    
    // Track shopping sessions for automatic purchase detection
    struct ShoppingSession: Codable {
        let appName: String
        let startTime: Date
        var endTime: Date?
        var duration: TimeInterval {
            let end = endTime ?? Date()
            return end.timeIntervalSince(startTime)
        }
        var likelyPurchase: Bool {
            // If session > 2 minutes, likely made a purchase
            return duration > 120
        }
    }
    
    @Published var activeShoppingSessions: [String: ShoppingSession] = [:] // appName -> session
    @Published var recentShoppingSessions: [ShoppingSession] = [] // Sessions that need logging prompts
    
    private var sessionCheckTimer: Timer?
    
    private init() {
        // CRITICAL: Set flag to prevent didSet from running during initialization
        isInitializing = true
        
        // Do absolutely nothing synchronously
        let initStart = Date()
        print("✅ [DeviceActivityService] Init started at \(initStart) (all work deferred)")
        
        // STREAMLINED: Do absolutely nothing on startup - truly lazy loading
        // Data will be loaded on-demand when user opens Settings/App Management
        // This eliminates unnecessary background tasks on app launch
        
        // CRITICAL: Keep isInitializing true indefinitely to prevent didSet from ever running
        // The didSet operations (especially accessing applicationTokens.count) block MainActor for 20+ seconds
        // We'll handle app count updates manually when the picker closes, not in didSet
        // This prevents any blocking operations from running automatically
        print("✅ [DeviceActivityService] Initialization complete - didSet will remain disabled to prevent blocking")
        /*
        // OLD CODE - Removed to streamline startup
        Task.detached(priority: .background) { [weak self, initStart] in
            guard let self = self else { return }
            
            let taskStart = Date()
            print("🟡 [DeviceActivityService] Background task started at \(taskStart)")
            
            // CRITICAL: Wait for app to be fully loaded (5 seconds) before doing ANY MainActor work
            // Root cause: MainActor operations during view creation block SwiftUI updates
            // Solution: Defer ALL service operations until app is fully loaded and responsive
            let sleep1Start = Date()
            print("🟡 [DeviceActivityService] Starting 5s sleep to wait for app to fully load at \(sleep1Start)")
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds - wait for app to fully load
            let sleep1End = Date()
            print("🟡 [DeviceActivityService] 5s sleep completed at \(sleep1End) (took \(sleep1End.timeIntervalSince(sleep1Start))s)")
            
            // Load critical data in separate background tasks - don't await MainActor.run
            // This prevents any blocking even if MainActor is busy
            let loadStart = Date()
            print("🟡 [DeviceActivityService] Starting critical data loading (truly non-blocking) at \(loadStart)")
            
            // CRITICAL: Batch ALL MainActor updates into a single operation to prevent queueing
            // Root cause: Multiple await MainActor.run calls queue up and block MainActor
            // Solution: Single Task with @MainActor and .utility priority
            // This allows view updates (which run at .userInitiated) to take precedence
            Task(priority: .utility) { @MainActor [weak self] in
                guard let self = self else { return }
                // Read UserDefaults in background first (fast, non-blocking)
                let cachedCount = UserDefaults.standard.integer(forKey: "cachedSelectedAppsCount")
                
                // Batch all @Published property updates together - single MainActor operation
                self.cachedAppsCount = cachedCount
                print("📂 [DeviceActivityService] Loaded cached app count: \(cachedCount)")
                
                self.loadMonitoringState()
                self.loadSelection() // This calls loadAppNamesMapping() internally (which has its own Task.detached)
            }
            
            // Note: loadAppNamesMapping() is called by loadSelection() and handles its own async work
            // No need to call it separately
            
            let loadEnd = Date()
            print("🟡 [DeviceActivityService] Critical data loading tasks started at \(loadEnd) (took \(loadEnd.timeIntervalSince(loadStart))s) - tasks running in background")
            
            // No additional delay - operations are already in background tasks
            // Removed the extra 1-second sleep to speed up startup
            
            // Load heavy data in background (JSON decoding can be slow)
            // DISABLED: Defer loadUnblockEvents() significantly to prevent blocking
            // Even though it starts a background task, calling it can still cause issues
            // Load it much later or on-demand
            print("🟡 [DeviceActivityService] Deferring loadUnblockEvents() - will load later")
            // self.loadUnblockEvents() // DISABLED to prevent blocking
            
            // Load app usage sessions in background (JSON decoding can block)
            // DISABLED: Defer significantly to prevent blocking
            print("🟡 [DeviceActivityService] Deferring loadAppUsageSessions() - will load later")
            /*
            Task.detached(priority: .background) { [weak self] in
                guard let self = self else { return }
                // Additional delay for this heavy operation
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await MainActor.run {
                    self.loadAppUsageSessions()
                }
            }
            */
            
            // Background tasks - DISABLED to prevent blocking
            // Defer all of these significantly or load on-demand
            print("🟡 [DeviceActivityService] Deferring startSessionMonitoring() - will start later")
            print("🟡 [DeviceActivityService] Deferring endAllActiveSessions() - will run later")
            /*
            // Background tasks - move off main thread with delay
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            // startSessionMonitoring() needs to be on MainActor for Timer
            await MainActor.run {
                self.startSessionMonitoring()
            }
            
            // End active sessions in background (can do I/O) - with delay
            Task.detached(priority: .background) { [weak self] in
                guard let self = self else { return }
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run {
                    self.endAllActiveSessions()
                }
            }
            */
            
            // DISABLED: Don't restore monitoring automatically on startup
            // This was causing 3-minute freezes. User can manually start monitoring.
            print("⚠️ [DeviceActivityService] Auto-restore monitoring disabled - user must manually start")
            
            // DISABLED: Accessing selectedApps.applicationTokens.count can block
            // Just log basic info without accessing the property
            let initEnd = Date()
            let totalInitTime = initEnd.timeIntervalSince(initStart)
            print("✅ [DeviceActivityService] Initialized at \(initEnd) (total: \(totalInitTime)s)")
            // Access isMonitoring directly since we're already in a Task.detached
            // Don't use MainActor.run here - it can cause concurrency issues
            let isMonitoringValue = await MainActor.run {
                self.isMonitoring
            }
            print("✅ [DeviceActivityService] isMonitoring: \(isMonitoringValue)")
            // Skip accessing selectedApps.applicationTokens.count - it can block for minutes
            print("✅ [DeviceActivityService] Initialization complete - apps count will be loaded on demand")
        }
        */
        let initEnd = Date()
        print("✅ [DeviceActivityService] Initialized at \(initEnd) (total: \(initEnd.timeIntervalSince(initStart))s)")
    }
    
    // Track if monitoring state has been loaded to avoid redundant loads
    private var hasLoadedMonitoringState = false
    
    // Load data on-demand (lazy loading)
    // Call this when user actually opens Settings or App Management view
    func ensureDataLoaded() {
        // Always ensure monitoring state is loaded (it's critical for the toggle to work)
        // Only skip if we've already loaded it in this session
        let needsLoad = cachedAppsCount == 0 || !hasLoadedMonitoringState
        
        guard needsLoad else { 
            print("📂 [DeviceActivityService] Data already loaded - skipping")
            return 
        }
        
        Task(priority: .utility) { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Load app count if needed
            if self.cachedAppsCount == 0 {
                let cachedCount = UserDefaults.standard.integer(forKey: "cachedSelectedAppsCount")
                self.cachedAppsCount = cachedCount
                print("📂 [DeviceActivityService] Loaded cached app count: \(cachedCount)")
            }
            
            // Always load monitoring state to ensure it's up to date
            if !self.hasLoadedMonitoringState {
                self.loadMonitoringState()
                self.hasLoadedMonitoringState = true
            }
            
            // Load selection (app names, etc.)
            self.loadSelection()
        }
    }
    
    /// Update the cached app count from the current selection
    /// Call this when the picker closes to ensure count is saved immediately
    /// This runs off MainActor to avoid blocking
    func refreshAppCount() {
        // CRITICAL: Never access applicationTokens.count - it blocks MainActor for 20+ seconds
        // Instead, we'll rely on the cached count that's updated when the picker closes
        // This function is now a no-op to prevent blocking
        print("⏭️ [DeviceActivityService] refreshAppCount() called - skipping to prevent blocking")
        print("⏭️ [DeviceActivityService] Using cached count: \(cachedAppsCount)")
        // The cached count should be updated when the picker closes via the selection callback
        // No need to access applicationTokens.count which blocks for 20+ seconds
    }
    
    deinit {
        sessionCheckTimer?.invalidate()
        // Invalidate all usage session timers
        for timer in usageSessionTimers.values {
            timer.invalidate()
        }
        usageSessionTimers.removeAll()
        // Invalidate all inactivity timers
        for timer in inactivityTimers.values {
            timer.invalidate()
        }
        inactivityTimers.removeAll()
    }
    
    // Start monitoring for shopping session end and app foreground detection
    private func startSessionMonitoring() {
        print("🔄 [DeviceActivityService] Starting session monitoring timer (checks every 30 seconds)")
        // Check every 30 seconds if there's an active shopping session that has ended
        // Also check if shopping app came to foreground
        sessionCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkForSessionEnd()
            // Also check if shopping app came to foreground
            self?.checkForAppForeground()
        }
    }
    
    // Check if a shopping app came to foreground (detected by extension)
    private func checkForAppForeground() {
        if UserDefaults.standard.bool(forKey: "shoppingAppOpened") {
            // Shopping app was opened - check which app index it might be
            // Since we can't determine exact app, we'll check all active sessions
            // and reset their inactivity timers (app is active)
            let openedTime = UserDefaults.standard.double(forKey: "shoppingAppOpenedTime")
            let timeSinceOpened = Date().timeIntervalSince1970 - openedTime
            
            // Only process if opened recently (within last 10 seconds)
            if timeSinceOpened < 10 {
                print("📱 [DeviceActivityService] Shopping app came to foreground - resetting inactivity timers")
                // Reset inactivity timers for all active sessions
                for appIndex in activeSessions.keys {
                    resetInactivityTimer(appIndex: appIndex)
                }
            }
            
            // Clear the flag
            UserDefaults.standard.set(false, forKey: "shoppingAppOpened")
        }
    }
    
    // Check if shopping session has ended and prompt to log
    // Made public so it can be called from app lifecycle
    func checkForSessionEnd() {
        print("🔄 [DeviceActivityService] ════════════════════════════════════════")
        print("🔄 [DeviceActivityService] Checking for shopping session end...")
        
        // First, check if there's ANY data in UserDefaults
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let relevantKeys = Array(allKeys).filter { $0.contains("shopping") || $0.contains("session") || $0.contains("active") }
        print("📋 [DeviceActivityService] Relevant UserDefaults keys: \(relevantKeys)")
        
        if let sessionData = UserDefaults.standard.dictionary(forKey: "activeShoppingSession"),
           let startTime = sessionData["startTime"] as? TimeInterval {
            let sessionStart = Date(timeIntervalSince1970: startTime)
            let duration = Date().timeIntervalSince(sessionStart)
            
            print("📱 [DeviceActivityService] ✅ FOUND active session:")
            print("   Start time: \(sessionStart)")
            print("   Duration: \(Int(duration)) seconds (\(Int(duration / 60)) minutes)")
            print("   Full session data: \(sessionData)")
            
            // If session was > 2 minutes, likely made a purchase
            if duration > 120 {
                print("✅ [DeviceActivityService] Session > 2 min - SENDING PROMPT NOTIFICATION")
                sendPurchaseLogNotification(duration: duration)
                // Clear the session
                UserDefaults.standard.removeObject(forKey: "activeShoppingSession")
                print("✅ [DeviceActivityService] Cleared session from UserDefaults")
            } else {
                print("⏳ [DeviceActivityService] Session still active, duration: \(Int(duration))s (need > 120s)")
            }
        } else {
            print("📭 [DeviceActivityService] ❌ No active shopping session found in UserDefaults")
            // Try to read the key directly to see what's there
            if let rawValue = UserDefaults.standard.object(forKey: "activeShoppingSession") {
                print("⚠️ [DeviceActivityService] Key exists but wrong type: \(type(of: rawValue))")
            } else {
                print("⚠️ [DeviceActivityService] Key 'activeShoppingSession' does not exist")
            }
        }
        print("🔄 [DeviceActivityService] ════════════════════════════════════════")
    }
    
    // Send notification to prompt purchase logging
    private func sendPurchaseLogNotification(duration: TimeInterval) {
        // REMOVED: Canceling pending notifications - this callback can block MainActor
        // Notifications with nil trigger are immediate, so duplicates are unlikely
        
        let content = UNMutableNotificationContent()
        content.title = "📝 Log Your Purchase?"
        content.body = "You were shopping for \(Int(duration / 60)) minutes. Quick log to track your spending."
        content.userInfo = ["type": "purchase_log_prompt"]
        content.sound = .default
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // FIXED: Use nil trigger for immediate delivery instead of time interval trigger
        let identifier = "purchase_log_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [DeviceActivityService] Failed to send purchase log notification: \(error)")
                // Fallback: If nil trigger fails, try with minimal delay
                print("🔄 [DeviceActivityService] Attempting fallback with minimal delay trigger...")
                let fallbackTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let fallbackRequest = UNNotificationRequest(identifier: identifier, content: content, trigger: fallbackTrigger)
                UNUserNotificationCenter.current().add(fallbackRequest) { fallbackError in
                    if let fallbackError = fallbackError {
                        print("❌ [DeviceActivityService] Fallback also failed: \(fallbackError)")
                    } else {
                        print("✅ [DeviceActivityService] Fallback purchase log notification sent")
                        // Update badge when notification is added
                        NotificationBadgeManager.shared.updateBadgeCount()
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NotificationDelivered"),
                            object: nil
                        )
                    }
                }
            } else {
                print("✅ [DeviceActivityService] Purchase log notification sent immediately")
                // Update badge when notification is added
                NotificationBadgeManager.shared.updateBadgeCount()
                NotificationCenter.default.post(
                    name: NSNotification.Name("NotificationDelivered"),
                    object: nil
                )
            }
        }
    }
    
    // Save selection to UserDefaults
    private func saveSelection() {
        // DISABLED: Don't access selectedApps.applicationTokens.count here
        // It's already cached in cachedAppsCount
        // Just save the cached count
        UserDefaults.standard.set(cachedAppsCount, forKey: "selectedAppsCount")
        print("Selected apps count (cached): \(cachedAppsCount)")
    }
    
    // Save unblock events for metrics
    private func saveUnblockEvents() {
        // Save to UserDefaults in background (JSON encoding can block)
        let events = unblockEvents
        Task.detached(priority: .utility) {
            if let encoded = try? JSONEncoder().encode(events) {
                UserDefaults.standard.set(encoded, forKey: "unblockEvents")
            }
        }
        
        // Sync to AWS if enabled
        if useAWS {
            Task {
                do {
                    try await awsDataService.batchSync(unblockEvents, dataType: .unblockEvents)
                    print("✅ [DeviceActivityService] Unblock events synced to AWS")
                } catch {
                    print("⚠️ [DeviceActivityService] Failed to sync unblock events to AWS: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Load unblock events - make JSON decoding async to avoid blocking
    private func loadUnblockEvents() {
        // DISABLED: Skip AWS during initialization to prevent 3-minute freezes
        // AWS calls will timeout if API Gateway isn't configured, causing app to freeze
        // User can enable AWS sync later if needed
        /*
        // Try AWS first if enabled (with timeout to prevent freezes)
        if useAWS {
            Task.detached(priority: .background) {
                do {
                    // AWS calls disabled to prevent freezes
                    // let awsData: [UnblockEvent] = try await self.awsDataService.getData(dataType: .unblockEvents)
                    // CRITICAL: Use DispatchQueue instead of MainActor.run to avoid blocking
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        // self.unblockEvents = awsData
                    }
                    // Save to UserDefaults in background
                    Task.detached(priority: .utility) {
                        if let encoded = try? JSONEncoder().encode(awsData) {
                            UserDefaults.standard.set(encoded, forKey: "unblockEvents")
                        }
                    }
                    print("✅ [DeviceActivityService] Unblock events loaded from AWS")
                    return
                } catch {
                    print("⚠️ [DeviceActivityService] Failed to load unblock events from AWS (timeout or error): \(error.localizedDescription)")
                    // Fall through to UserDefaults immediately
                }
            }
        }
        */
        
        // Load from UserDefaults only - decode JSON in background (can be slow with large arrays)
        Task.detached(priority: .background) {
            if let data = UserDefaults.standard.data(forKey: "unblockEvents") {
                // Decode in background thread
                if let decoded = try? JSONDecoder().decode([UnblockEvent].self, from: data) {
                    // CRITICAL: Use DispatchQueue instead of MainActor.run to avoid blocking
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.unblockEvents = decoded
                    }
                }
            }
        }
    }
    
    // Get comprehensive metrics about unblocks
    func getUnblockMetrics() -> (totalUnblocks: Int, plannedUnblocks: Int, impulseUnblocks: Int, mostCommonCategory: String?, mostCommonMood: String?, mostRequestedAppIndex: Int?, mostRequestedAppName: String?) {
        // OPTIMIZED: Single pass through unblockEvents instead of multiple iterations
        // This prevents blocking when the array is large
        let startTime = Date()
        let events = unblockEvents
        let total = events.count
        
        // Single pass to collect all data
        var planned = 0
        var impulse = 0
        var categoryCounts: [String: Int] = [:]
        var moodCounts: [String: Int] = [:]
        var appIndexCounts: [Int: Int] = [:]
        
        for event in events {
            // Count purchase types
            if event.purchaseType == "planned" {
                planned += 1
            } else if event.purchaseType == "impulse" {
                impulse += 1
            }
            
            // Count categories
            if let category = event.category {
                categoryCounts[category, default: 0] += 1
            }
            
            // Count moods
            if let mood = event.mood {
                moodCounts[mood, default: 0] += 1
            }
            
            // Count app indices
            if let appIndex = event.appIndex {
                appIndexCounts[appIndex, default: 0] += 1
            }
        }
        
        // Find most common
        let mostCommonCategory = categoryCounts.max(by: { $0.value < $1.value })?.key
        let mostCommonMood = moodCounts.max(by: { $0.value < $1.value })?.key
        let mostRequestedAppIndex = appIndexCounts.max(by: { $0.value < $1.value })?.key
        
        // Get app name for most requested app
        let mostRequestedAppName = mostRequestedAppIndex.map { getAppName(forIndex: $0) }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        if duration > 0.1 {
            print("⚠️ [DeviceActivityService] getUnblockMetrics() took \(duration)s (processed \(total) events)")
        }
        
        return (total, planned, impulse, mostCommonCategory, mostCommonMood, mostRequestedAppIndex, mostRequestedAppName)
    }
    
    // Get recent unblock events within a time window (for behavioral auto-activation)
    func getRecentUnblockEvents(hours: Int) -> [UnblockEvent] {
        let cutoff = Date().addingTimeInterval(-Double(hours) * 60 * 60)
        return unblockEvents.filter { $0.timestamp >= cutoff }
    }
    
    // Get detailed behavioral patterns (with optional date range filter)
    func getBehavioralPatterns(from startDate: Date? = nil, to endDate: Date? = nil) -> BehavioralPatterns {
        // Filter events by date range if provided
        let events: [UnblockEvent]
        if let start = startDate, let end = endDate {
            events = unblockEvents.filter { $0.timestamp >= start && $0.timestamp <= end }
        } else {
            events = unblockEvents
        }
        
        if events.count > 1000 {
            print("⚠️ [DeviceActivityService] getBehavioralPatterns() processing \(events.count) events (may be slow)")
        }
        
        // Time of day patterns
        let timeOfDayCounts = Dictionary(grouping: events, by: { $0.timeOfDayCategory }).mapValues { $0.count }
        let mostCommonTimeOfDay = timeOfDayCounts.max(by: { $0.value < $1.value })?.key
        
        // Day of week patterns
        let dayOfWeekCounts = Dictionary(grouping: events, by: { $0.dayName }).mapValues { $0.count }
        let mostCommonDayOfWeek = dayOfWeekCounts.max(by: { $0.value < $1.value })?.key
        
        // Quiet hours patterns
        let duringQuietHours = events.filter { $0.wasDuringQuietHours }.count
        let quietHoursPercentage = events.isEmpty ? 0.0 : Double(duringQuietHours) / Double(events.count) * 100.0
        
        // App usage patterns
        let appsUsed = events.filter { $0.wasAppUsed == true }.count
        let appsNotUsed = events.filter { $0.wasAppUsed == false || $0.wasAppUsed == nil }.count
        let usageRate = events.isEmpty ? 0.0 : Double(appsUsed) / Double(events.count) * 100.0
        
        // Average time between unblocks
        let timeBetweenUnblocks = events.compactMap { $0.timeSinceLastUnblock }
        let avgTimeBetween = timeBetweenUnblocks.isEmpty ? nil : timeBetweenUnblocks.reduce(0, +) / Double(timeBetweenUnblocks.count)
        
        // Average app usage duration
        let usageDurations = events.compactMap { $0.appUsageDuration }
        let avgUsageDuration = usageDurations.isEmpty ? nil : usageDurations.reduce(0, +) / Double(usageDurations.count)
        
        // Frequency patterns
        let avgUnblocksPerDay = events.isEmpty ? 0.0 : {
            let days = Set(events.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
            return days > 0 ? Double(events.count) / Double(days) : 0.0
        }()
        
        // Category breakdown (for planned purchases)
        let plannedEvents = events.filter { $0.purchaseType == "planned" }
        let categories = plannedEvents.compactMap { $0.category }
        let categoryBreakdown = Dictionary(grouping: categories, by: { $0 }).mapValues { $0.count }
        
        // Mood breakdown (for impulse purchases)
        let impulseEvents = events.filter { $0.purchaseType == "impulse" }
        let moods = impulseEvents.compactMap { $0.mood }
        let moodBreakdown = Dictionary(grouping: moods, by: { $0 }).mapValues { $0.count }
        
        // Time of day breakdown
        let timeOfDayBreakdown = Dictionary(grouping: events, by: { $0.timeOfDayCategory }).mapValues { $0.count }
        
        // Day of week breakdown
        let dayOfWeekBreakdown = Dictionary(grouping: events, by: { $0.dayName }).mapValues { $0.count }
        
        return BehavioralPatterns(
            mostCommonTimeOfDay: mostCommonTimeOfDay,
            mostCommonDayOfWeek: mostCommonDayOfWeek,
            quietHoursPercentage: quietHoursPercentage,
            appsUsedCount: appsUsed,
            appsNotUsedCount: appsNotUsed,
            usageRate: usageRate,
            avgTimeBetweenUnblocks: avgTimeBetween,
            avgUsageDuration: avgUsageDuration,
            avgUnblocksPerDay: avgUnblocksPerDay,
            categoryBreakdown: categoryBreakdown,
            moodBreakdown: moodBreakdown,
            timeOfDayBreakdown: timeOfDayBreakdown,
            dayOfWeekBreakdown: dayOfWeekBreakdown
        )
    }
    
    // Behavioral patterns structure
    struct BehavioralPatterns {
        let mostCommonTimeOfDay: String?
        let mostCommonDayOfWeek: String?
        let quietHoursPercentage: Double
        let appsUsedCount: Int
        let appsNotUsedCount: Int
        let usageRate: Double // Percentage of unblocks where app was actually used
        let avgTimeBetweenUnblocks: TimeInterval? // Average seconds between unblocks
        let avgUsageDuration: TimeInterval? // Average seconds app was used
        let avgUnblocksPerDay: Double
        let categoryBreakdown: [String: Int] // Category -> count for planned purchases
        let moodBreakdown: [String: Int] // Mood -> count for impulse purchases
        let timeOfDayBreakdown: [String: Int] // Time category -> count
        let dayOfWeekBreakdown: [String: Int] // Day name -> count
    }
    
    // Get category breakdown for planned purchases
    func getCategoryBreakdown(from startDate: Date? = nil, to endDate: Date? = nil) -> [String: Int] {
        let events: [UnblockEvent]
        if let start = startDate, let end = endDate {
            events = unblockEvents.filter { $0.timestamp >= start && $0.timestamp <= end }
        } else {
            events = unblockEvents
        }
        
        let plannedEvents = events.filter { $0.purchaseType == "planned" }
        let categories = plannedEvents.compactMap { $0.category }
        return Dictionary(grouping: categories, by: { $0 }).mapValues { $0.count }
    }
    
    // Get mood breakdown for impulse purchases
    func getMoodBreakdown(from startDate: Date? = nil, to endDate: Date? = nil) -> [String: Int] {
        let events: [UnblockEvent]
        if let start = startDate, let end = endDate {
            events = unblockEvents.filter { $0.timestamp >= start && $0.timestamp <= end }
        } else {
            events = unblockEvents
        }
        
        let impulseEvents = events.filter { $0.purchaseType == "impulse" }
        let moods = impulseEvents.compactMap { $0.mood }
        return Dictionary(grouping: moods, by: { $0 }).mapValues { $0.count }
    }
    
    // Save monitoring state
    private func saveMonitoringState() {
        UserDefaults.standard.set(isMonitoring, forKey: isMonitoringKey)
        print("💾 [DeviceActivityService] Saved monitoring state: \(isMonitoring)")
    }
    
    // Track if we're loading state to prevent didSet from saving
    private var isLoadingState = false
    
    // Load monitoring state
    private func loadMonitoringState() {
        // CRITICAL: Prevent didSet from saving during load to avoid blocking
        isLoadingState = true
        let monitoringState = UserDefaults.standard.bool(forKey: isMonitoringKey)
        isMonitoring = monitoringState
        isLoadingState = false
        print("📂 [DeviceActivityService] Loaded monitoring state: \(monitoringState)")
        
        // DISABLED: Auto-start monitoring on app launch
        // This was causing startup delays. Monitoring will be started manually when user toggles it on
        // or when they navigate to Settings/Quiet Hours views
    }
    
    // Load selection from UserDefaults (if needed)
    // PERSISTENCE: Selected apps (FamilyActivitySelection) persist across app restarts and signout/signin
    // The system automatically manages persistence - selection is device-level, not user-specific
    private func loadSelection() {
        // FamilyActivitySelection is managed by the system
        // The selection persists automatically through the FamilyActivityPicker
        // However, we need to ensure it's not reset on app launch
        // The selection should be preserved by the system, but we verify it here
        
        // Load app names mapping
        loadAppNamesMapping()
        
        // IMPORTANT: FamilyActivitySelection is restored automatically by the system
        // when the FamilyActivityPicker is opened. We don't need to manually restore it.
        // The picker will show the previous selection when opened.
        // However, we need to ensure the cached count is updated when selection changes.
        // PERSISTENCE: Selection persists across signout/signin (device-level, system-managed)
        
        // Load cached count from UserDefaults (fast, non-blocking)
        let cachedCount = UserDefaults.standard.integer(forKey: "cachedSelectedAppsCount")
        cachedAppsCount = cachedCount
        
        // NOTE: We don't check actual count here because accessing selectedApps.applicationTokens.count
        // can block for minutes during initialization. The mismatch will be detected when:
        // 1. User opens the picker (refreshAppCount() is called)
        // 2. User tries to start monitoring (startMonitoring() checks count)
        
        print("📂 [DeviceActivityService] Loaded selection - apps count will be loaded on demand")
        print("📂 [DeviceActivityService] Cached count from UserDefaults: \(cachedCount)")
        print("📂 [DeviceActivityService] Note: FamilyActivitySelection is restored by system when picker opens")
        print("📂 [DeviceActivityService] PERSISTENCE: Selected apps persist across app restarts and signout/signin")
        print("📂 [DeviceActivityService] Mismatch detection: Will check when picker opens or monitoring starts")
    }
    
    // Update app names mapping when apps are selected
    // This ensures names persist correctly when apps are added/removed
    private func updateAppNamesMapping() {
        // Use cached count instead of accessing selectedApps.applicationTokens.count
        let currentCount = cachedAppsCount
        let previousCount = appNames.keys.max() ?? -1
        
        if currentCount == 0 {
            // All apps removed - clear all names
            if !appNames.isEmpty {
                print("🔄 [DeviceActivityService] All apps removed - clearing all app names")
                appNames = [:]
                saveAppNamesMappingPrivate()
            }
        } else if currentCount < previousCount + 1 {
            // Apps were removed - keep names for remaining indices
            // Note: When an app is removed via AppManagementView, names are already shifted
            // This handles cases where selection changes outside of AppManagementView
            let filteredNames = appNames.filter { $0.key < currentCount }
            if filteredNames.count != appNames.count {
                print("🔄 [DeviceActivityService] App count decreased from \(previousCount + 1) to \(currentCount). Filtering app names.")
                appNames = filteredNames
                saveAppNamesMappingPrivate()
            }
        } else if currentCount > previousCount + 1 {
            // New apps added - existing names are preserved
            // New apps will have default names until user names them
            print("🔄 [DeviceActivityService] App count increased from \(previousCount + 1) to \(currentCount). Existing names preserved.")
            // Names for new indices will be set when user names them
        }
        // If count is same, names are unchanged (user might have reordered, but we can't detect that)
    }
    
    // Save app names mapping (private version - public version also exists)
    private func saveAppNamesMappingPrivate() {
        // Save to UserDefaults (always, synchronous, immediate)
        if let encoded = try? JSONEncoder().encode(appNames) {
            UserDefaults.standard.set(encoded, forKey: appNamesKey)
            print("💾 [DeviceActivityService] App names saved to UserDefaults: \(appNames)")
        } else {
            print("❌ [DeviceActivityService] Failed to encode app names for saving. Current appNames: \(appNames)")
        }
        
        // Sync to AWS if enabled (async, optional)
        if useAWS {
            Task {
                do {
                    try await awsDataService.syncData(appNames, dataType: .appNames)
                    print("✅ [DeviceActivityService] App names synced to AWS")
                } catch {
                    print("⚠️ [DeviceActivityService] Failed to sync app names to AWS: \(error.localizedDescription)")
                    // Continue with UserDefaults - AWS sync is optional
                }
            }
        }
    }
    
    // Load app names mapping
    private func loadAppNamesMapping() {
        // Load from UserDefaults - decode JSON in background to avoid blocking
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            if let data = UserDefaults.standard.data(forKey: self.appNamesKey),
               let decoded = try? JSONDecoder().decode([Int: String].self, from: data) {
                // CRITICAL: Use DispatchQueue instead of MainActor.run to avoid blocking
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.appNames = decoded
                    print("✅ [DeviceActivityService] App names loaded from UserDefaults: \(self.appNames)")
                }
            }
        }
        
        // DISABLED: Skip AWS during initialization to prevent 3-minute freezes
        // AWS calls will timeout if API Gateway isn't configured, causing app to freeze
        /*
        // Then try AWS if enabled (async, will update if different)
        if useAWS {
            Task {
                do {
                    let loadedNames = try await awsDataService.getAppNames()
                    await MainActor.run {
                        // Merge AWS data with local (AWS takes precedence)
                        for (key, value) in loadedNames {
                            self.appNames[key] = value
                        }
                        // Also save merged data to UserDefaults as cache
                        if let encoded = try? JSONEncoder().encode(self.appNames) {
                            UserDefaults.standard.set(encoded, forKey: self.appNamesKey)
                        }
                        print("✅ [DeviceActivityService] App names synced from AWS: \(loadedNames)")
                    }
                } catch {
                    print("⚠️ [DeviceActivityService] Failed to load app names from AWS: \(error.localizedDescription)")
                    // Continue with UserDefaults - AWS sync is optional
                }
            }
        }
        */
    }
    
    // Set app name for a specific index
    // NOTE: This is now only used internally by backend auto-naming
    // User editing is disabled to prevent conflicts with backend mapping
    private func setAppName(_ name: String, forIndex index: Int) {
        appNames[index] = name
        saveAppNamesMappingPrivate() // Use private version that handles AWS sync
        print("💾 [DeviceActivityService] Saved app name '\(name)' for index \(index) - will persist permanently")
    }
    
    
    // Save app names mapping (public so AppManagementView can call it)
    func saveAppNamesMapping() {
        saveAppNamesMappingPrivate() // Use private version that handles AWS sync
    }
    
    // Get app name for a specific index
    func getAppName(forIndex index: Int) -> String {
        return appNames[index] ?? "App \(index + 1)"
    }
    
    // Auto-name apps from backend using token hash mapping
    // NOTE: This function accesses selectedApps.applicationTokens which is BLOCKING
    // Only call this after app is fully loaded and responsive (30+ seconds after startup)
    private func autoNameAppsFromBackend() async {
        print("🔍 [DeviceActivityService] Starting auto-naming from backend...")
        
        // CRITICAL: Access selectedApps.applicationTokens in a truly detached task
        // CRITICAL: Never access applicationTokens - it blocks MainActor for 20+ seconds
        // This function is disabled to prevent blocking
        // App naming will be handled manually when the picker closes
        print("⏭️ [DeviceActivityService] autoNameAppsFromBackend() - DISABLED to prevent MainActor blocking")
        return
        
        // DISABLED CODE - Never access applicationTokens
        // This function is completely disabled to prevent MainActor blocking
        /*
        let tokens: [ApplicationToken] = await Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return [] }
            return await MainActor.run {
                Array(self.selectedApps.applicationTokens)
            }
        }.value
        
        guard !tokens.isEmpty else {
            print("⚠️ [DeviceActivityService] No apps selected, skipping auto-naming")
            return
        }
        
        // Generate token hashes
        var tokenHashes: [String] = []
        var tokenToIndex: [String: Int] = [:]
        
        for (index, token) in tokens.enumerated() {
            // Use token's hashValue as identifier
            // Note: ApplicationToken is Hashable, so we can use hashValue
            let hash = String(token.hashValue)
            tokenHashes.append(hash)
            tokenToIndex[hash] = index
            print("🔍 [DeviceActivityService] Token \(index) hash: \(hash)")
        }
        
        // Call backend to get app names
        do {
            let appNameMapping = try await awsDataService.getAppNamesFromTokens(tokenHashes: tokenHashes)
            print("✅ [DeviceActivityService] Backend returned \(appNameMapping.count) app name(s)")
            
            // Update app names from backend response
            await MainActor.run {
                var updated = false
                for (hash, appName) in appNameMapping {
                    if let index = tokenToIndex[hash] {
                        // Always update from backend (backend is source of truth)
                        // This ensures backend mapping takes precedence over any local changes
                        self.setAppName(appName, forIndex: index)
                        updated = true
                        print("✅ [DeviceActivityService] Auto-named app \(index): \(appName) (from backend)")
                    }
                }
                
                if updated {
                    self.saveAppNamesMappingPrivate()
                    print("💾 [DeviceActivityService] Saved auto-named apps")
                }
            }
        } catch {
            print("⚠️ [DeviceActivityService] Failed to get app names from backend: \(error.localizedDescription)")
            print("⚠️ [DeviceActivityService] Will use generic names as fallback")
            
            // Fallback: Assign generic names for apps that don't have names
            await MainActor.run {
                var updated = false
                for index in 0..<tokens.count {
                    if self.appNames[index] == nil || self.appNames[index] == "App \(index + 1)" {
                        let genericName = tokens.count == 1 ? "Shopping App" : "App \(index + 1)"
                        self.appNames[index] = genericName
                        updated = true
                    }
                }
                
                if updated {
                    self.saveAppNamesMappingPrivate()
                    print("💾 [DeviceActivityService] Saved generic fallback names")
                }
            }
        }
        */
    }
    
    // Request notification permission
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    // Start monitoring selected apps
    func startMonitoring() async {
        print("🔄 [DeviceActivityService] ════════════════════════════════════════")
        print("🔄 [DeviceActivityService] startMonitoring() CALLED")
        print("🔄 [DeviceActivityService] isMonitoring currently: \(isMonitoring)")
        print("🔄 [DeviceActivityService] Current time: \(Date())")
        
        // CRITICAL: Monitoring is a premium feature - check subscription first
        // Simple property reads are fast - using MainActor.run is acceptable here
        let isPremium = await MainActor.run {
            SubscriptionService.shared.isPremium
        }
        
        guard isPremium else {
            print("❌ [DeviceActivityService] Monitoring is a premium feature - user is not subscribed")
            // CRITICAL: Use DispatchQueue instead of MainActor.run to avoid blocking
            DispatchQueue.main.async { [weak self] in
                self?.isMonitoring = false
            }
            return
        }
        
        // CRITICAL: Use cached count instead of accessing applicationTokens.count
        // Accessing applicationTokens.count blocks MainActor for 20+ seconds
        // The cached count is updated when the picker closes, so it should be accurate
        let appsCount = await MainActor.run {
            self.cachedAppsCount
        }
        
        print("🔄 [DeviceActivityService] Apps count (cached): \(appsCount)")
        
        guard appsCount > 0 else {
            print("❌ [DeviceActivityService] No apps selected for monitoring - ABORTING")
            // CRITICAL: Use DispatchQueue instead of MainActor.run to avoid blocking
            DispatchQueue.main.async { [weak self] in
                self?.isMonitoring = false
            }
            return
        }
        
        print("✅ [DeviceActivityService] \(appsCount) apps selected - proceeding with monitoring setup")
        
        // Stop any existing monitoring first
        if isMonitoring {
            print("🔄 [DeviceActivityService] Stopping existing monitoring...")
            // Stop all interval activities plus the main activity
            var activitiesToStop: [DeviceActivityName] = [activityName]
            activitiesToStop.append(contentsOf: intervalActivityNames)
            center.stopMonitoring(activitiesToStop)
            intervalActivityNames.removeAll()
        }
        
        // Update the schedule based on current Quiet Hours
        await updateMonitoringSchedule()
        
        // Set state to true
        // CRITICAL: Use DispatchQueue instead of MainActor.run to avoid blocking
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isMonitoring = true
            print("✅ [DeviceActivityService] isMonitoring set to true")
        }
        
        // Ensure blocking is applied if Quiet Hours are already active
        // NO BLOCKING - Using notifications instead
        // Clear shield to prevent Screen Time conflicts
        // Note: Blocking is disabled - store is not available
        // await MainActor.run {
        //     self.store.shield.applications = nil
        //     print("🔔 [DeviceActivityService] Shield cleared - using notifications instead of blocking")
        // }
        
        print("✅ [DeviceActivityService] startMonitoring() completed")
    }
    
    // MARK: - Adaptive Interval Schedule Creation
    
    /// Breaks a time range into interval schedules with adaptive sizing
    /// DeviceActivity requires minimum 15-minute intervals
    /// iOS limits the number of schedules (~20), so we use adaptive intervals:
    /// - Short schedules (< 2 hours): 15-minute intervals
    /// - Medium schedules (2-6 hours): 30-minute intervals
    /// - Long schedules (> 6 hours): 1-hour intervals
    /// CRITICAL: For overnight schedules, intervals that span midnight must be split into same-day intervals
    /// - Parameters:
    ///   - startTime: Start time of the schedule (DateComponents with hour and minute)
    ///   - endTime: End time of the schedule (DateComponents with hour and minute)
    /// - Returns: Array of DeviceActivitySchedule objects with adaptive interval sizes
    private func createFifteenMinuteIntervalSchedules(
        startTime: DateComponents,
        endTime: DateComponents
    ) -> [DeviceActivitySchedule] {
        // Convert start and end times to minutes since midnight
        let startHour = startTime.hour ?? 0
        let startMin = startTime.minute ?? 0
        let endHour = endTime.hour ?? 0
        let endMin = endTime.minute ?? 0
        
        let startTotalMinutes = startHour * 60 + startMin
        let endTotalMinutes = endHour * 60 + endMin
        
        // Calculate total duration (handle overnight schedules)
        var totalDurationMinutes: Int
        let isOvernight = endTotalMinutes <= startTotalMinutes
        if isOvernight {
            // Overnight: from start to midnight + from midnight to end
            totalDurationMinutes = (24 * 60 - startTotalMinutes) + endTotalMinutes
        } else {
            totalDurationMinutes = endTotalMinutes - startTotalMinutes
        }
        
        // Adaptive interval sizing to stay within iOS limits (~20 schedules)
        // Use larger intervals for longer schedules to avoid exceeding the limit
        let maximumIntervals = 20
        let minimumIntervalMinutes = 15
        
        // Calculate optimal interval size to stay within limit
        // This ensures we create at most 20 intervals
        let calculatedIntervalMinutes = max(minimumIntervalMinutes, (totalDurationMinutes + maximumIntervals - 1) / maximumIntervals)
        
        // Round to nearest standard interval (15, 30, or 60 minutes)
        // Prefer shorter intervals when possible, but respect the 20-interval limit
        let intervalMinutes: Int
        if calculatedIntervalMinutes <= 15 {
            intervalMinutes = 15
        } else if calculatedIntervalMinutes <= 30 {
            intervalMinutes = 30
        } else {
            // For very long schedules, we need 60-minute intervals to stay within limit
            intervalMinutes = 60
        }
        
        var schedules: [DeviceActivitySchedule] = []
        
        if isOvernight {
            // Overnight schedule: Split into two parts (same-day and next-day)
            // Part 1: From start time to midnight (23:59)
            var currentStartMinutes = startTotalMinutes
            let midnightMinutes = 24 * 60 - 1 // 23:59 (last minute of day)
            
            while currentStartMinutes < midnightMinutes {
                let intervalEndMinutes = min(currentStartMinutes + intervalMinutes, midnightMinutes)
                let intervalDuration = intervalEndMinutes - currentStartMinutes
                
                guard intervalDuration >= minimumIntervalMinutes else {
                    break
                }
                
                let intervalStartHour = currentStartMinutes / 60
                let intervalStartMin = currentStartMinutes % 60
                let intervalEndHour = intervalEndMinutes / 60
                let intervalEndMin = intervalEndMinutes % 60
                
                let intervalStart = DateComponents(hour: intervalStartHour, minute: intervalStartMin)
                let intervalEnd = DateComponents(hour: intervalEndHour, minute: intervalEndMin)
                
                let schedule = DeviceActivitySchedule(
                    intervalStart: intervalStart,
                    intervalEnd: intervalEnd,
                    repeats: true
                )
                
                schedules.append(schedule)
                currentStartMinutes += intervalMinutes
            }
            
            // Part 2: From midnight (00:00) to end time
            currentStartMinutes = 0
            while currentStartMinutes < endTotalMinutes {
                let intervalEndMinutes = min(currentStartMinutes + intervalMinutes, endTotalMinutes)
                let intervalDuration = intervalEndMinutes - currentStartMinutes
                
                guard intervalDuration >= minimumIntervalMinutes else {
                    break
                }
                
                let intervalStartHour = currentStartMinutes / 60
                let intervalStartMin = currentStartMinutes % 60
                let intervalEndHour = intervalEndMinutes / 60
                let intervalEndMin = intervalEndMinutes % 60
                
                let intervalStart = DateComponents(hour: intervalStartHour, minute: intervalStartMin)
                let intervalEnd = DateComponents(hour: intervalEndHour, minute: intervalEndMin)
                
                let schedule = DeviceActivitySchedule(
                    intervalStart: intervalStart,
                    intervalEnd: intervalEnd,
                    repeats: true
                )
                
                schedules.append(schedule)
                currentStartMinutes += intervalMinutes
            }
        } else {
            // Same-day schedule: Create intervals normally
            var currentStartMinutes = startTotalMinutes
            
            while currentStartMinutes < endTotalMinutes {
                let intervalEndMinutes = min(currentStartMinutes + intervalMinutes, endTotalMinutes)
                let intervalDuration = intervalEndMinutes - currentStartMinutes
                
                guard intervalDuration >= minimumIntervalMinutes else {
                    break
                }
                
                let intervalStartHour = currentStartMinutes / 60
                let intervalStartMin = currentStartMinutes % 60
                let intervalEndHour = intervalEndMinutes / 60
                let intervalEndMin = intervalEndMinutes % 60
                
                let intervalStart = DateComponents(hour: intervalStartHour, minute: intervalStartMin)
                let intervalEnd = DateComponents(hour: intervalEndHour, minute: intervalEndMin)
                
                let schedule = DeviceActivitySchedule(
                    intervalStart: intervalStart,
                    intervalEnd: intervalEnd,
                    repeats: true
                )
                
                schedules.append(schedule)
                currentStartMinutes += intervalMinutes
            }
        }
        
        let intervalDescription = intervalMinutes == 15 ? "15-minute" : intervalMinutes == 30 ? "30-minute" : "1-hour"
        print("📅 [DeviceActivityService] Created \(schedules.count) x \(intervalDescription) intervals from \(startHour):\(String(format: "%02d", startMin)) to \(endHour):\(String(format: "%02d", endMin)) (overnight: \(isOvernight), duration: \(totalDurationMinutes) min)")
        
        return schedules
    }
    
    // Update monitoring schedule
    // NOTE: Quiet Hours functionality removed - now monitors all apps
    private func updateMonitoringSchedule() async {
        print("🔄 [DeviceActivityService] ════════════════════════════════════════")
        print("🔄 [DeviceActivityService] updateMonitoringSchedule() CALLED")
        print("🔄 [DeviceActivityService] Updating monitoring schedule (all apps)...")
        
        // Get cached app count (fast, non-blocking)
        let cachedCount = await MainActor.run {
            self.cachedAppsCount
        }
        
        // Monitor all apps (based on cached count)
        let appIndicesToMonitor = Array(0..<cachedCount)
        print("📱 [DeviceActivityService] Monitoring all \(cachedCount) apps")
        
        guard !appIndicesToMonitor.isEmpty else {
            print("❌ [DeviceActivityService] No apps to monitor - cannot create events")
            return
        }
        
        // CRITICAL: Access applicationTokens on MainActor to avoid blocking
        // We'll create events asynchronously and then update the schedule
        print("🔄 [DeviceActivityService] Accessing applicationTokens to create events...")
        
        // Access tokens on MainActor - this ensures we're on the correct thread for FamilyActivitySelection access
        // NOTE: This access might be slow (20+ seconds) but it's necessary for events
        let events = await MainActor.run {
            // Access selectedApps - this might be slow but we're already on MainActor
            let apps = self.selectedApps
            
            // Convert to array for indexed access
            let appsTokensArray = Array(apps.applicationTokens)
            print("📱 [DeviceActivityService] Accessed \(appsTokensArray.count) application tokens")
            
            var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
            
            for index in appIndicesToMonitor {
                guard index < appsTokensArray.count else {
                    print("⚠️ [DeviceActivityService] App index \(index) out of bounds (max: \(appsTokensArray.count - 1))")
                    continue
                }
                
                let appToken = appsTokensArray[index]
                let eventName = DeviceActivityEvent.Name("soteria.moment.\(index)")
                
                // Create event with 1-second threshold to fire immediately when app opens
                let event = DeviceActivityEvent(
                    applications: [appToken],
                    threshold: DateComponents(second: 1)
                )
                events[eventName] = event
                print("📱 [DeviceActivityService] Created event '\(eventName.rawValue)' for app index \(index)")
            }
            
            print("📱 [DeviceActivityService] Created \(events.count) separate events (one per app)")
            return events
        }
        
        guard !events.isEmpty else {
            print("❌ [DeviceActivityService] No events created - cannot start monitoring")
            print("❌ [DeviceActivityService] App indices to monitor: \(appIndicesToMonitor)")
            print("❌ [DeviceActivityService] Cached count: \(cachedCount)")
            return
        }
        
        print("✅ [DeviceActivityService] Successfully created \(events.count) events for monitoring")
        for (eventName, _) in events {
            print("   - Event: \(eventName.rawValue)")
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        formatter.timeZone = TimeZone.current
        let localTimeString = formatter.string(from: Date())
        
        // NOTE: Quiet Hours removed - use all-day schedule for tracking only (no blocking)
        // Use all-day schedule with adaptive intervals for tracking
        let allDayStart = DateComponents(hour: 0, minute: 0)
        let allDayEnd = DateComponents(hour: 23, minute: 59)
        let allDayIntervalSchedules = createFifteenMinuteIntervalSchedules(
            startTime: allDayStart,
            endTime: allDayEnd
        )
        
        print("📊 [DeviceActivityService] ════════════════════════════════════════")
        print("📊 [DeviceActivityService] Using all-day schedule with adaptive intervals for tracking")
        print("📊 [DeviceActivityService] Split into \(allDayIntervalSchedules.count) intervals")
        print("📊 [DeviceActivityService] Current local time: \(localTimeString)")
        print("📊 [DeviceActivityService] Activity name: \(self.activityName)")
        print("📊 [DeviceActivityService] Event threshold: 1 second")
        print("📊 [DeviceActivityService] Apps being monitored: \(appIndicesToMonitor.count)")
        print("📊 [DeviceActivityService] Total events created: \(events.count)")
        print("📊 [DeviceActivityService] ════════════════════════════════════════")
        
        // Capture events for the closure
        let capturedEvents = events
        await MainActor.run {
            print("🔄 [DeviceActivityService] Starting all-day monitoring with \(capturedEvents.count) events")
            
            // Stop any existing monitoring first (including old interval activities)
            var activitiesToStop: [DeviceActivityName] = [self.activityName]
            activitiesToStop.append(contentsOf: self.intervalActivityNames)
            self.center.stopMonitoring(activitiesToStop)
            self.intervalActivityNames.removeAll()
            
            // Start monitoring with all interval schedules
            var successCount = 0
            var failureCount = 0
            for (index, intervalSchedule) in allDayIntervalSchedules.enumerated() {
                // Create unique activity name for each interval
                let intervalActivityName = DeviceActivityName("\(self.activityName.rawValue).interval\(index)")
                
                do {
                    self.intervalActivityNames.append(intervalActivityName)
                    try self.center.startMonitoring(intervalActivityName, during: intervalSchedule, events: capturedEvents)
                    successCount += 1
                    let startHour = intervalSchedule.intervalStart.hour ?? 0
                    let startMin = intervalSchedule.intervalStart.minute ?? 0
                    let endHour = intervalSchedule.intervalEnd.hour ?? 0
                    let endMin = intervalSchedule.intervalEnd.minute ?? 0
                    print("✅ [DeviceActivityService] Registered interval \(index + 1)/\(allDayIntervalSchedules.count): \(startHour):\(String(format: "%02d", startMin)) - \(endHour):\(String(format: "%02d", endMin))")
                } catch {
                    failureCount += 1
                    print("❌ [DeviceActivityService] Failed to register interval \(index + 1): \(error.localizedDescription)")
                }
            }
            
            print("📊 [DeviceActivityService] Interval registration summary: \(successCount) succeeded, \(failureCount) failed out of \(allDayIntervalSchedules.count) total")
            print("🔔 [DeviceActivityService] Monitoring enabled - notifications will be sent (no blocking)")
        }
        
        // OLD QUIET HOURS CODE REMOVED - replaced with simple all-day monitoring above
    }
    
    // Stop monitoring
    func stopMonitoring() {
        // Stop all interval activities plus the main activity
        var activitiesToStop: [DeviceActivityName] = [activityName]
        activitiesToStop.append(contentsOf: intervalActivityNames)
        center.stopMonitoring(activitiesToStop)
        intervalActivityNames.removeAll()
        
        // Clear shield (already nil, but ensure it's cleared)
        // Note: Blocking is disabled - store is not available
        // store.shield.applications = nil
        // Stopping monitoring stops notifications
        // Setting isMonitoring will trigger saveMonitoringState via didSet
        isMonitoring = false
        print("🛑 [DeviceActivityService] Stopped monitoring - notifications will no longer be sent")
        print("🛑 [DeviceActivityService] Stopped \(activitiesToStop.count) activity/activities")
        // print("🛑 [DeviceActivityService] Shield cleared")
    }
    
    // Check if there are existing Screen Time restrictions (from Apple Settings or other apps)
    // Returns true if restrictions exist that weren't set by Soteria
    // NOTE: This method is not used when blocking is disabled (notifications only)
    private func hasExistingRestrictions() -> Bool {
        // Blocking is disabled - always return false
        // This method is kept for potential future use but not actively used
        return false
    }
    
    // Update blocking status based on Quiet Hours
    func updateBlockingStatus() async {
        guard isMonitoring else {
            print("⚠️ [DeviceActivityService] Not monitoring - cannot update blocking status")
            return
        }
        
        // Restart monitoring with updated schedule based on Quiet Hours
        // This will automatically block/unblock apps based on the schedule
        await updateMonitoringSchedule()
        
        // NO BLOCKING - Using notifications instead
        // Blocking code has been removed to prevent startup delays
        // Notifications will be sent via DeviceActivity events
        
        print("✅ [DeviceActivityService] Blocking status updated - monitoring restarted (notifications only)")
    }
    
    // Note: Blocking is now handled automatically by DeviceActivity schedules
    // When Quiet Hours are active, the schedule matches Quiet Hours and DeviceActivity blocks apps
    // When Quiet Hours are inactive, the schedule is all-day and DeviceActivity only tracks (doesn't block)
    
    // Temporarily unblock apps (when user chooses "Continue Shopping" or answers prompt)
    func temporarilyUnblock(durationMinutes: Int = 15, purchaseType: String? = nil, category: String? = nil, mood: String? = nil, moodNotes: String? = nil, appIndex: Int? = nil) {
        // Stop monitoring temporarily to allow apps to open
        // This will unblock apps for the specified duration
        pendingUnlock = true
        print("🔓 [DeviceActivityService] Temporarily unblocking apps for \(durationMinutes) minutes")
        
        // Calculate behavioral metrics
        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? todayStart
        
        // Count unblocks today and this week
        let unblockCountToday = unblockEvents.filter { $0.timestamp >= todayStart }.count + 1
        let unblockCountThisWeek = unblockEvents.filter { $0.timestamp >= weekStart }.count + 1
        
        // Time since last unblock
        let timeSinceLastUnblock = unblockEvents.last.map { now.timeIntervalSince($0.timestamp) }
        
        // NOTE: Quiet Hours removed - no longer checking quiet hours status
        
        // Get app name if available
        let appName = appIndex.map { getAppName(forIndex: $0) }
        
        // Track unblock event for metrics with comprehensive data
        let unblockEvent = UnblockEvent(
            timestamp: now,
            purchaseType: purchaseType,
            category: category,
            mood: mood,
            moodNotes: moodNotes,
            selectedAppsCount: selectedApps.applicationTokens.count,
            appIndex: appIndex,
            appName: appName,
            durationMinutes: durationMinutes,
            wasDuringQuietHours: false, // Quiet Hours removed
            quietHoursScheduleName: nil, // Quiet Hours removed
            timeSinceLastUnblock: timeSinceLastUnblock,
            unblockCountToday: unblockCountToday,
            unblockCountThisWeek: unblockCountThisWeek,
            wasAppUsed: nil, // Will be updated when app usage is tracked
            appUsageDuration: nil // Will be updated when app usage ends
        )
        unblockEvents.append(unblockEvent)
        saveUnblockEvents()
        print("📊 [DeviceActivityService] Tracked unblock event with behavioral data:")
        print("   - Time: \(unblockEvent.timeOfDayCategory) (\(unblockEvent.dayName))")
        print("   - Type: \(purchaseType ?? "unknown")")
        print("   - App: \(appName ?? "unknown") (index: \(appIndex ?? -1))")
        print("   - During Quiet Hours: false (Quiet Hours removed)")
        print("   - Unblocks today: \(unblockCountToday), this week: \(unblockCountThisWeek)")
        if let timeSince = timeSinceLastUnblock {
            print("   - Time since last unblock: \(Int(timeSince / 60)) minutes")
        }
        
        if let appIndex = appIndex {
            print("📊 [DeviceActivityService] App index: \(appIndex) (out of \(selectedApps.applicationTokens.count) apps)")
            
            // Start tracking app usage for this app
            startAppUsageSession(appIndex: appIndex)
            
            // Update unblock event when app usage ends
            // This will be done in endAppUsageSession
        }
        
        // Stop monitoring (notifications will stop)
        // Stop all interval activities plus the main activity
        var activitiesToStop: [DeviceActivityName] = [activityName]
        activitiesToStop.append(contentsOf: intervalActivityNames)
        center.stopMonitoring(activitiesToStop)
        intervalActivityNames.removeAll()
        
        // Clear shield (already nil, but ensure it's cleared)
        // Note: Blocking is disabled - store is not available
        // store.shield.applications = nil
        print("🔓 [DeviceActivityService] Monitoring stopped - notifications will no longer be sent")
        
        // Re-start monitoring after duration to re-block apps
        // This ensures apps don't stay unblocked indefinitely
        print("⏰ [DeviceActivityService] Setting timer to re-block apps in \(durationMinutes) minutes")
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(durationMinutes * 60)) {
            Task {
                print("⏰ [DeviceActivityService] Timer expired - checking if apps should be re-blocked")
                print("⏰ [DeviceActivityService] isMonitoring: \(self.isMonitoring)")
                
                if self.isMonitoring {
                    // Re-start monitoring
                    await self.updateMonitoringSchedule()
                    print("🔒 [DeviceActivityService] ✅ Monitoring restarted after \(durationMinutes) minutes")
                    
                    // End any active usage sessions when blocking resumes
                    // This handles the case where user was using app and blocking resumed
                    for appIndex in self.activeSessions.keys {
                        self.endAppUsageSession(appIndex: appIndex)
                        print("📱 [DeviceActivityService] Ended usage session for app \(appIndex) due to re-blocking")
                    }
                } else {
                    // Quiet Hours ended or monitoring was stopped - apps stay unblocked
                    print("🔓 [DeviceActivityService] Apps remain unblocked (Quiet Hours inactive or monitoring stopped)")
                }
                
                await MainActor.run {
                    self.pendingUnlock = false
                    print("✅ [DeviceActivityService] pendingUnlock set to false")
                }
            }
        }
    }
    
    // Record shopping attempt (called from extension)
    func recordShoppingAttempt() {
        shoppingAttempts.append(Date())
        totalBlockedAttempts += 1
        print("📊 [DeviceActivityService] Recorded shopping attempt. Total: \(totalBlockedAttempts)")
    }
    
    // Start tracking app usage (when app comes to FOREGROUND/FOCUS)
    // Note: We only track foreground time, not background time
    // Blocking prevents apps from coming to foreground, not from running in background
    func startAppUsageSession(appIndex: Int) {
        let appName = getAppName(forIndex: appIndex)
        
        // If there's already an active session, this means the app came back to foreground
        // Reset the inactivity timer instead of creating a new session
        if activeSessions[appIndex] != nil {
            print("📱 [DeviceActivityService] App \(appIndex) (\(appName)) came back to FOREGROUND - resetting inactivity timer")
            // Reset inactivity timer - app is in focus again
            resetInactivityTimer(appIndex: appIndex)
            return
        }
        
        // New session - app came to FOREGROUND/FOCUS
        let session = AppUsageSession(
            id: UUID().uuidString,
            appIndex: appIndex,
            appName: appName,
            startTime: Date()
        )
        activeSessions[appIndex] = session
        appUsageSessions.append(session)
        saveAppUsageSessions()
        print("📱 [DeviceActivityService] Started FOREGROUND usage session for app \(appIndex) (\(appName))")
        print("📱 [DeviceActivityService] Tracking only FOREGROUND time - background time is NOT counted")
        
        // Set a timer to automatically end the session after max duration
        let maxTimer = Timer.scheduledTimer(withTimeInterval: maxSessionDuration, repeats: false) { [weak self] _ in
            print("⏰ [DeviceActivityService] Max session duration reached for app \(appIndex) - ending session")
            self?.endAppUsageSession(appIndex: appIndex)
        }
        usageSessionTimers[appIndex] = maxTimer
        
        // Set inactivity timer - if app goes to BACKGROUND (not in focus), end session after threshold
        resetInactivityTimer(appIndex: appIndex)
    }
    
    // Reset inactivity timer (app is in FOREGROUND/FOCUS)
    // If app goes to background (not in focus), timer will expire and session ends
    private func resetInactivityTimer(appIndex: Int) {
        // Cancel existing inactivity timer
        inactivityTimers[appIndex]?.invalidate()
        
        // Start new inactivity timer
        // If app goes to BACKGROUND (swiped away, not in focus), timer expires
        let inactivityTimer = Timer.scheduledTimer(withTimeInterval: inactivityThreshold, repeats: false) { [weak self] _ in
            print("⏰ [DeviceActivityService] Inactivity threshold reached for app \(appIndex) - app went to BACKGROUND (not in focus), ending session")
            print("⏰ [DeviceActivityService] Only FOREGROUND time was tracked - background time is NOT counted")
            self?.endAppUsageSession(appIndex: appIndex)
        }
        inactivityTimers[appIndex] = inactivityTimer
    }
    
    // End tracking app usage (when app goes to BACKGROUND or is closed)
    // Only FOREGROUND time is tracked - background time is NOT counted
    func endAppUsageSession(appIndex: Int) {
        if let session = activeSessions[appIndex] {
            var endedSession = session
            endedSession.endTime = Date()
            let usageDuration = endedSession.duration
            
            // Update in array
            if let index = appUsageSessions.firstIndex(where: { $0.id == session.id }) {
                appUsageSessions[index] = endedSession
            }
            activeSessions.removeValue(forKey: appIndex)
            
            // Invalidate and remove timers
            usageSessionTimers[appIndex]?.invalidate()
            usageSessionTimers.removeValue(forKey: appIndex)
            inactivityTimers[appIndex]?.invalidate()
            inactivityTimers.removeValue(forKey: appIndex)
            
            // Update the most recent unblock event to reflect app usage
            // Find the most recent unblock event for this app that hasn't been updated yet
            if let mostRecentIndex = unblockEvents.lastIndex(where: { $0.appIndex == appIndex && $0.wasAppUsed == nil }) {
                let updatedEvent = unblockEvents[mostRecentIndex]
                // Create a new event with updated usage data
                let updatedUnblockEvent = UnblockEvent(
                    id: updatedEvent.id,
                    timestamp: updatedEvent.timestamp,
                    purchaseType: updatedEvent.purchaseType,
                    category: updatedEvent.category,
                    mood: updatedEvent.mood,
                    moodNotes: updatedEvent.moodNotes,
                    selectedAppsCount: updatedEvent.selectedAppsCount,
                    appIndex: updatedEvent.appIndex,
                    appName: updatedEvent.appName,
                    durationMinutes: updatedEvent.durationMinutes,
                    wasDuringQuietHours: updatedEvent.wasDuringQuietHours,
                    quietHoursScheduleName: updatedEvent.quietHoursScheduleName,
                    timeSinceLastUnblock: updatedEvent.timeSinceLastUnblock,
                    unblockCountToday: updatedEvent.unblockCountToday,
                    unblockCountThisWeek: updatedEvent.unblockCountThisWeek,
                    wasAppUsed: true, // App was actually used
                    appUsageDuration: usageDuration // How long it was used
                )
                unblockEvents[mostRecentIndex] = updatedUnblockEvent
                saveUnblockEvents()
                print("📊 [DeviceActivityService] Updated unblock event: app was used for \(Int(usageDuration))s")
            }
            
            saveAppUsageSessions()
            let durationMinutes = Int(usageDuration / 60)
            let durationSeconds = Int(usageDuration) % 60
            print("📱 [DeviceActivityService] Ended FOREGROUND usage session for app \(appIndex) (\(session.appName))")
            print("📱 [DeviceActivityService] FOREGROUND time tracked: \(durationMinutes)m \(durationSeconds)s (background time NOT counted)")
        }
    }
    
    // Save app usage sessions
    private func saveAppUsageSessions() {
        // Only save completed sessions (not active ones)
        let completedSessions = appUsageSessions.filter { $0.endTime != nil }
        
        // Save to UserDefaults in background (JSON encoding can block)
        let key = appUsageSessionsKey
        Task.detached(priority: .utility) {
            if let encoded = try? JSONEncoder().encode(completedSessions) {
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
        
        // Sync to AWS if enabled
        if useAWS {
            Task {
                do {
                    try await awsDataService.batchSync(completedSessions, dataType: .appUsage)
                    print("✅ [DeviceActivityService] App usage sessions synced to AWS")
                } catch {
                    print("⚠️ [DeviceActivityService] Failed to sync app usage sessions to AWS: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Load app usage sessions
    private func loadAppUsageSessions() {
        // DISABLED: Skip AWS during initialization to prevent 3-minute freezes
        // AWS calls will timeout if API Gateway isn't configured, causing app to freeze
        /*
        // Try AWS first if enabled
        if useAWS {
            Task {
                do {
                    let awsData: [AppUsageSession] = try await awsDataService.getData(dataType: .appUsage)
                    await MainActor.run {
                        self.appUsageSessions = awsData
                        // Also save to UserDefaults as cache
                        if let encoded = try? JSONEncoder().encode(awsData) {
                            UserDefaults.standard.set(encoded, forKey: self.appUsageSessionsKey)
                        }
                    }
                    print("✅ [DeviceActivityService] App usage sessions loaded from AWS")
                    return
                } catch {
                    print("⚠️ [DeviceActivityService] Failed to load app usage sessions from AWS: \(error.localizedDescription)")
                    // Fall through to UserDefaults
                }
            }
        }
        */
        
        // Load from UserDefaults - decode JSON in background to avoid blocking
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            if let data = UserDefaults.standard.data(forKey: self.appUsageSessionsKey),
               let decoded = try? JSONDecoder().decode([AppUsageSession].self, from: data) {
                await MainActor.run {
                    self.appUsageSessions = decoded
                }
            }
        }
    }
    
    // Get app usage statistics
    func getAppUsageStats() -> [Int: (totalTime: TimeInterval, sessionCount: Int, appName: String)] {
        var stats: [Int: (totalTime: TimeInterval, sessionCount: Int, appName: String)] = [:]
        
        for session in appUsageSessions {
            let existing = stats[session.appIndex] ?? (0, 0, session.appName)
            stats[session.appIndex] = (
                totalTime: existing.totalTime + session.duration,
                sessionCount: existing.sessionCount + 1,
                appName: session.appName
            )
        }
        
        return stats
    }
    
    // Get app usage for a specific date range
    func getAppUsage(from startDate: Date, to endDate: Date) -> [Int: (totalTime: TimeInterval, sessionCount: Int, appName: String)] {
        let filteredSessions = appUsageSessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= startDate && endTime <= endDate
        }
        
        var stats: [Int: (totalTime: TimeInterval, sessionCount: Int, appName: String)] = [:]
        
        for session in filteredSessions {
            let existing = stats[session.appIndex] ?? (0, 0, session.appName)
            stats[session.appIndex] = (
                totalTime: existing.totalTime + session.duration,
                sessionCount: existing.sessionCount + 1,
                appName: session.appName
            )
        }
        
        return stats
    }
    
    // End all active sessions (called on app launch to clean up)
    private func endAllActiveSessions() {
        for (appIndex, session) in activeSessions {
            // End session with current time
            var endedSession = session
            endedSession.endTime = Date()
            // Update in array
            if let index = appUsageSessions.firstIndex(where: { $0.id == session.id }) {
                appUsageSessions[index] = endedSession
            }
            print("📱 [DeviceActivityService] Ended stale session for app \(appIndex) (\(session.appName)) - Duration: \(Int(endedSession.duration))s")
        }
        activeSessions.removeAll()
        saveAppUsageSessions()
    }
    
    // End active session when app becomes active (user likely closed shopping app)
    func checkAndEndActiveSessions() {
        // If SOTERIA becomes active and there are active sessions, end them
        // This assumes the user closed the shopping app
        if !activeSessions.isEmpty {
            print("📱 [DeviceActivityService] SOTERIA became active - ending \(activeSessions.count) active session(s)")
            endAllActiveSessions()
        }
    }
    
    // Get shopping pattern insights
    func getShoppingPatterns() -> (peakHour: Int?, attemptsToday: Int, attemptsThisWeek: Int) {
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        let attemptsToday = shoppingAttempts.filter { $0 >= today }.count
        let attemptsThisWeek = shoppingAttempts.filter { $0 >= weekAgo }.count
        
        // Find peak hour
        let hourCounts = Dictionary(grouping: shoppingAttempts, by: { calendar.component(.hour, from: $0) })
        let peakHour = hourCounts.max(by: { $0.value.count < $1.value.count })?.key
        
        return (peakHour, attemptsToday, attemptsThisWeek)
    }
    
    // Send local notification for SOTERIA Moment
    func sendSoteriaMomentNotification() {
        // REMOVED: Canceling pending notifications - this callback can block MainActor
        // Notifications with nil trigger are immediate, so duplicates are unlikely
        
        let content = UNMutableNotificationContent()
        content.title = "SOTERIA Moment"
        content.body = "You're about to open a shopping app. Take a moment to pause and think."
        content.sound = .default
        content.categoryIdentifier = "SOTERIA_MOMENT"
        content.userInfo = ["type": "soteria_moment"]
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // FIXED: Use nil trigger for immediate delivery instead of time interval trigger
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [DeviceActivityService] Failed to send notification: \(error)")
                // Fallback: If nil trigger fails, try with minimal delay
                print("🔄 [DeviceActivityService] Attempting fallback with minimal delay trigger...")
                let fallbackTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let fallbackRequest = UNNotificationRequest(identifier: identifier, content: content, trigger: fallbackTrigger)
                UNUserNotificationCenter.current().add(fallbackRequest) { fallbackError in
                    if let fallbackError = fallbackError {
                        print("❌ [DeviceActivityService] Fallback also failed: \(fallbackError)")
                    } else {
                        print("✅ [DeviceActivityService] Fallback SOTERIA moment notification sent")
                    }
                }
            } else {
                print("✅ [DeviceActivityService] SOTERIA moment notification sent immediately")
            }
        }
    }
}

