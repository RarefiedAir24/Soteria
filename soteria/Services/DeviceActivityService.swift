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
    private let awsDataService = AWSDataService.shared
    @Published var useAWS: Bool = false // Toggle to enable/disable AWS sync (Premium feature)
    
    @Published var selectedApps: FamilyActivitySelection = FamilyActivitySelection() {
        didSet {
            // DISABLED: All synchronous operations in didSet to prevent blocking
            // Move everything to background tasks
            
            // Save app count in background (this is the critical blocking operation)
            // Use a significant delay to ensure this doesn't block startup
            Task.detached(priority: .background) { [weak self] in
                guard let self = self else { return }
                // Wait 5 seconds to ensure app is fully responsive before accessing blocking property
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                // Access count in background task to avoid blocking main thread
                let count = await MainActor.run {
                    self.selectedApps.applicationTokens.count
                }
                UserDefaults.standard.set(count, forKey: "cachedSelectedAppsCount")
                await MainActor.run {
                    self.cachedAppsCount = count
                }
                print("💾 [DeviceActivityService] Cached app count: \(count)")
            }
            
            // Save selection in background
            Task.detached(priority: .utility) { [weak self] in
                guard let self = self else { return }
                await MainActor.run {
                    self.saveSelection()
                }
            }
            
            // Update app names mapping in background
            Task.detached(priority: .utility) { [weak self] in
                guard let self = self else { return }
                await MainActor.run {
                    self.updateAppNamesMapping()
                }
            }
            
            // If monitoring is active, restart it to apply new app selection
            if isMonitoring {
                print("🔄 [DeviceActivityService] App selection changed - restarting monitoring to apply changes")
                Task {
                    // Stop current monitoring
                    center.stopMonitoring([activityName])
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
            // Save monitoring state when it changes
            // Make this non-blocking by doing it in background
            Task.detached(priority: .utility) { [weak self] in
                guard let self = self else { return }
                await MainActor.run {
                    self.saveMonitoringState()
                }
            }
        }
    }
    private let isMonitoringKey = "isMonitoringActive"
    @Published var pendingUnlock: Bool = false // Track if user wants to unlock
    
    private let activityName = DeviceActivityName("soteria.monitoring")
    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    
    // Reference to QuietHoursService to check if blocking should be active
    private lazy var quietHoursService = QuietHoursService.shared
    
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
        // Do absolutely nothing synchronously
        let initStart = Date()
        print("✅ [DeviceActivityService] Init started at \(initStart) (all work deferred)")
        
        // Load everything asynchronously in background with minimal delay
        // This ensures the UI is fully rendered before we do any work
        Task.detached(priority: .background) { [weak self, initStart] in
            guard let self = self else { return }
            
            let taskStart = Date()
            print("🟡 [DeviceActivityService] Background task started at \(taskStart)")
            
            // Minimal delay to ensure UI renders first - reduced from 2s to 0.5s
            let sleep1Start = Date()
            print("🟡 [DeviceActivityService] Starting 0.5s sleep at \(sleep1Start)")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            let sleep1End = Date()
            print("🟡 [DeviceActivityService] 0.5s sleep completed at \(sleep1End) (took \(sleep1End.timeIntervalSince(sleep1Start))s)")
            
            // Load critical data in separate background tasks - don't await MainActor.run
            // This prevents any blocking even if MainActor is busy
            let loadStart = Date()
            print("🟡 [DeviceActivityService] Starting critical data loading (truly non-blocking) at \(loadStart)")
            
            // Load cached app count in background (fast UserDefaults read)
            Task.detached(priority: .utility) { [weak self] in
                guard let self = self else { return }
                let cachedCount = UserDefaults.standard.integer(forKey: "cachedSelectedAppsCount")
                await MainActor.run {
                    self.cachedAppsCount = cachedCount
                }
                print("📂 [DeviceActivityService] Loaded cached app count: \(cachedCount)")
            }
            
            // Load monitoring state in background (fast UserDefaults read)
            Task.detached(priority: .utility) { [weak self] in
                guard let self = self else { return }
                await MainActor.run {
                    self.loadMonitoringState()
                }
            }
            
            // Load app names mapping in background (fast UserDefaults read)
            Task.detached(priority: .utility) { [weak self] in
                guard let self = self else { return }
                await MainActor.run {
                    self.loadAppNamesMapping()
                }
            }
            
            // Load selection in background (doesn't access blocking property)
            Task.detached(priority: .utility) { [weak self] in
                guard let self = self else { return }
                await MainActor.run {
                    self.loadSelection()
                }
            }
            
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
        let content = UNMutableNotificationContent()
        content.title = "📝 Log Your Purchase?"
        content.body = "You were shopping for \(Int(duration / 60)) minutes. Quick log to track your spending."
        content.userInfo = ["type": "purchase_log_prompt"]
        content.sound = .default
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "purchase_log_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [DeviceActivityService] Failed to send purchase log notification: \(error)")
            } else {
                print("✅ [DeviceActivityService] Purchase log notification sent")
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
                    await MainActor.run {
                        self.unblockEvents = awsData
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
                    await MainActor.run {
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
    
    // Load monitoring state
    private func loadMonitoringState() {
        // CRITICAL: Don't trigger didSet during initialization
        // The _isInitializing flag will prevent saveMonitoringState() from being called
        let monitoringState = UserDefaults.standard.bool(forKey: isMonitoringKey)
        isMonitoring = monitoringState
        print("📂 [DeviceActivityService] Loaded monitoring state: \(monitoringState)")
    }
    
    // Load selection from UserDefaults (if needed)
    private func loadSelection() {
        // FamilyActivitySelection is managed by the system
        // The selection persists automatically through the FamilyActivityPicker
        // However, we need to ensure it's not reset on app launch
        // The selection should be preserved by the system, but we verify it here
        
        // Load app names mapping
        loadAppNamesMapping()
        
        // DISABLED: Accessing selectedApps.applicationTokens.count can block for minutes
        // Don't access it during initialization - it will be loaded on demand
        print("📂 [DeviceActivityService] Loaded selection - apps count will be loaded on demand")
    }
    
    // Update app names mapping when apps are selected
    private func updateAppNamesMapping() {
        // Use cached count instead of accessing selectedApps.applicationTokens.count
        let currentCount = cachedAppsCount
        let previousCount = appNames.keys.max() ?? -1
        // Only update if the count changed
        if currentCount != previousCount + 1 {
            // Remove names for apps that are no longer selected
            let filteredNames = appNames.filter { $0.key < currentCount }
            if filteredNames.count != appNames.count {
                print("🔄 [DeviceActivityService] App count changed from \(previousCount + 1) to \(currentCount). Filtering app names.")
                appNames = filteredNames
                saveAppNamesMappingPrivate()
            }
        }
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
                await MainActor.run {
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
    func setAppName(_ name: String, forIndex index: Int) {
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
        print("🔄 [DeviceActivityService] startMonitoring() called")
        print("🔄 [DeviceActivityService] isMonitoring currently: \(isMonitoring)")
        // DISABLED: Accessing selectedApps.applicationTokens.count can block
        // Access it safely on MainActor
        let appsCount = await MainActor.run {
            self.selectedApps.applicationTokens.count
        }
        print("🔄 [DeviceActivityService] selectedApps count: \(appsCount)")
        
        guard appsCount > 0 else {
            print("❌ [DeviceActivityService] No apps selected for monitoring")
            await MainActor.run {
                isMonitoring = false
            }
            return
        }
        
        print("✅ [DeviceActivityService] \(appsCount) apps selected")
        print("✅ [DeviceActivityService] Apps will be monitored and events will fire when they open")
        
        // Stop any existing monitoring first
        if isMonitoring {
            print("🔄 [DeviceActivityService] Stopping existing monitoring...")
            center.stopMonitoring([activityName])
        }
        
        // Update the schedule based on current Quiet Hours
        await updateMonitoringSchedule()
        
        // Set state to true
        await MainActor.run {
            self.isMonitoring = true
            print("✅ [DeviceActivityService] isMonitoring set to true")
        }
        
        // Ensure blocking is applied if Quiet Hours are already active
        // This handles the case where Quiet Hours are active when monitoring starts (e.g., on app launch)
        if quietHoursService.isQuietModeActive {
            await MainActor.run {
                // Access selectedApps on MainActor to avoid blocking
                self.store.shield.applications = self.selectedApps.applicationTokens
                print("🔒 [DeviceActivityService] Shield set on monitoring start (Quiet Hours active)")
            }
        }
        
        print("✅ [DeviceActivityService] startMonitoring() completed")
    }
    
    // Update monitoring schedule based on Quiet Hours
    // Uses Quiet Hours schedule for tracking (respects local time)
    private func updateMonitoringSchedule() async {
        print("🔄 [DeviceActivityService] Updating monitoring schedule based on Quiet Hours...")
        
        // Access selectedApps on MainActor to avoid blocking
        let appsTokens = await MainActor.run {
            self.selectedApps.applicationTokens
        }
        
        // Create an event to detect when monitored apps are opened
        let eventName = DeviceActivityEvent.Name("soteria.moment")
        let event = DeviceActivityEvent(
            applications: appsTokens,
            threshold: DateComponents(second: 1)
        )
        
        // Get active Quiet Hours schedule
        let activeSchedule = quietHoursService.schedules.first { $0.isCurrentlyActive() }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        formatter.timeZone = TimeZone.current
        let localTimeString = formatter.string(from: Date())
        
        if let schedule = activeSchedule, schedule.isActive {
            // Create DeviceActivity schedule that matches Quiet Hours (uses local time)
            // DeviceActivitySchedule uses local time by default when you pass DateComponents
            let deviceSchedule = DeviceActivitySchedule(
                intervalStart: schedule.startTime,
                intervalEnd: schedule.endTime,
                repeats: true
            )
            
            print("🔒 [DeviceActivityService] ════════════════════════════════════════")
            print("🔒 [DeviceActivityService] Creating tracking schedule for Quiet Hours: \(schedule.name)")
            let startHour = schedule.startTime.hour ?? 0
            let startMin = schedule.startTime.minute ?? 0
            let endHour = schedule.endTime.hour ?? 0
            let endMin = schedule.endTime.minute ?? 0
            print("🔒 [DeviceActivityService] Schedule (local time): \(startHour):\(String(format: "%02d", startMin)) - \(endHour):\(String(format: "%02d", endMin))")
            print("🔒 [DeviceActivityService] Current local time: \(localTimeString)")
            print("🔒 [DeviceActivityService] Current UTC time: \(Date())")
            print("🔒 [DeviceActivityService] Activity name: \(self.activityName)")
            print("🔒 [DeviceActivityService] Event name: \(eventName)")
            print("🔒 [DeviceActivityService] Event threshold: 1 second")
            print("🔒 [DeviceActivityService] Apps in event: \(appsTokens.count)")
            print("🔒 [DeviceActivityService] ════════════════════════════════════════")
            
            do {
                try await MainActor.run {
                    try self.center.startMonitoring(self.activityName, during: deviceSchedule, events: [eventName: event])
                    // Set blocking - apps will be blocked during Quiet Hours
                    // IMPORTANT: Set shield.applications to ALL selected apps
                        self.store.shield.applications = appsTokens
                        print("🔒 [DeviceActivityService] Blocking enabled - apps will be BLOCKED from FOREGROUND during Quiet Hours")
                        print("🔒 [DeviceActivityService] Apps can run in background, but CANNOT come to focus/foreground")
                        print("🔒 [DeviceActivityService] Number of apps being blocked: \(appsTokens.count)")
                        print("🔒 [DeviceActivityService] Shield applications set: \(self.store.shield.applications?.count ?? 0) apps")
                        print("🔒 [DeviceActivityService] Extension will customize blocking screen with purchase intent question")
                }
                print("✅ [DeviceActivityService] Tracking schedule started successfully!")
                print("✅ [DeviceActivityService] Schedule created: \(schedule.startTime.hour ?? 0):\(String(format: "%02d", schedule.startTime.minute ?? 0)) - \(schedule.endTime.hour ?? 0):\(String(format: "%02d", schedule.endTime.minute ?? 0))")
                print("✅ [DeviceActivityService] Current local time: \(localTimeString)")
                print("✅ [DeviceActivityService] Extension should load when schedule becomes active")
                print("✅ [DeviceActivityService] Extension will receive intervalDidStart when schedule becomes active")
                print("✅ [DeviceActivityService] eventDidReachThreshold will fire when Amazon opens during Quiet Hours")
                print("🔒 [DeviceActivityService] Apps will be BLOCKED automatically during Quiet Hours (via DeviceActivity)")
                
                // Check if schedule is currently active
                let calendar = Calendar.current
                let now = Date()
                let currentHour = calendar.component(.hour, from: now)
                let currentMinute = calendar.component(.minute, from: now)
                let scheduleStartHour = schedule.startTime.hour ?? 0
                let scheduleStartMinute = schedule.startTime.minute ?? 0
                let scheduleEndHour = schedule.endTime.hour ?? 0
                let scheduleEndMinute = schedule.endTime.minute ?? 0
                
                let currentTimeMinutes = currentHour * 60 + currentMinute
                let startTimeMinutes = scheduleStartHour * 60 + scheduleStartMinute
                let endTimeMinutes = scheduleEndHour * 60 + scheduleEndMinute
                
                let isCurrentlyActive = currentTimeMinutes >= startTimeMinutes && currentTimeMinutes <= endTimeMinutes
                
                if isCurrentlyActive {
                    print("✅ [DeviceActivityService] Schedule is CURRENTLY ACTIVE - extension should load NOW")
                    print("✅ [DeviceActivityService] If you don't see extension logs, the extension may not be installed")
                } else {
                    print("⏳ [DeviceActivityService] Schedule is NOT currently active")
                    print("⏳ [DeviceActivityService] Extension will load when schedule becomes active at \(scheduleStartHour):\(String(format: "%02d", scheduleStartMinute))")
                }
            } catch {
                print("❌ [DeviceActivityService] Failed to start tracking schedule: \(error.localizedDescription)")
                print("❌ [DeviceActivityService] Error: \(error)")
            }
        } else {
            // No Quiet Hours active - use all-day schedule for tracking only (no blocking)
            let allDaySchedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59),
                repeats: true
            )
            
            print("📊 [DeviceActivityService] ════════════════════════════════════════")
            print("📊 [DeviceActivityService] No Quiet Hours active - using all-day schedule for tracking only")
            print("📊 [DeviceActivityService] Current local time: \(localTimeString)")
            print("📊 [DeviceActivityService] Current UTC time: \(Date())")
            print("📊 [DeviceActivityService] Activity name: \(self.activityName)")
            print("📊 [DeviceActivityService] Event name: \(eventName)")
            print("📊 [DeviceActivityService] Event threshold: 1 second")
            print("📊 [DeviceActivityService] Apps in event: \(appsTokens.count)")
            print("📊 [DeviceActivityService] ════════════════════════════════════════")
            
            do {
                try await MainActor.run {
                    try self.center.startMonitoring(self.activityName, during: allDaySchedule, events: [eventName: event])
                    // No blocking - just tracking
                }
                print("✅ [DeviceActivityService] All-day tracking schedule started - apps will NOT be blocked")
            } catch {
                print("❌ [DeviceActivityService] Failed to start tracking schedule: \(error.localizedDescription)")
                print("❌ [DeviceActivityService] Error: \(error)")
            }
        }
    }
    
    // Stop monitoring
    func stopMonitoring() {
        center.stopMonitoring([activityName])
        // Clear shield to unblock apps
        store.shield.applications = nil
        // Stopping monitoring automatically unblocks apps
        // Setting isMonitoring will trigger saveMonitoringState via didSet
        isMonitoring = false
        print("🛑 [DeviceActivityService] Stopped monitoring - apps are now unblocked")
        print("🛑 [DeviceActivityService] Cleared shield.applications")
    }
    
    // Update blocking status based on Quiet Hours
    func updateBlockingStatus() async {
        guard isMonitoring else {
            print("⚠️ [DeviceActivityService] Not monitoring - cannot update blocking status")
            // If monitoring isn't active but Quiet Hours are, we should still set the shield
            // This handles the case where user toggles monitoring off/on
            // DISABLED: Accessing selectedApps.applicationTokens can block
            // if quietHoursService.isQuietModeActive && !selectedApps.applicationTokens.isEmpty {
            //     await MainActor.run {
            //         self.store.shield.applications = self.selectedApps.applicationTokens
            //         print("🔒 [DeviceActivityService] Shield set even though monitoring is off (Quiet Hours active)")
            //     }
            // }
            return
        }
        
        // Restart monitoring with updated schedule based on Quiet Hours
        // This will automatically block/unblock apps based on the schedule
        await updateMonitoringSchedule()
        
        // Ensure shield is set if Quiet Hours are active
        if quietHoursService.isQuietModeActive {
            // Access selectedApps on MainActor to avoid blocking
            let appsTokens = await MainActor.run {
                self.selectedApps.applicationTokens
            }
            await MainActor.run {
                self.store.shield.applications = appsTokens
                print("🔒 [DeviceActivityService] Shield applications updated: \(self.store.shield.applications?.count ?? 0) apps")
                print("🔒 [DeviceActivityService] Apps will be blocked during Quiet Hours")
            }
        } else {
            await MainActor.run {
                self.store.shield.applications = nil
                print("🔓 [DeviceActivityService] Shield applications cleared (Quiet Hours inactive)")
            }
        }
        
        print("✅ [DeviceActivityService] Blocking status updated - Quiet Hours: \(quietHoursService.isQuietModeActive ? "ACTIVE (blocking)" : "INACTIVE (tracking only)")")
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
        
        // Check if during quiet hours
        let isQuietHoursActive = quietHoursService.isQuietModeActive
        let activeSchedule = quietHoursService.schedules.first { $0.isCurrentlyActive() }
        
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
            wasDuringQuietHours: isQuietHoursActive,
            quietHoursScheduleName: activeSchedule?.name,
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
        print("   - During Quiet Hours: \(isQuietHoursActive)")
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
        
        // Stop monitoring to unblock
        center.stopMonitoring([activityName])
        
        // Also clear shield applications to ensure apps are unblocked
        store.shield.applications = nil
        print("🔓 [DeviceActivityService] Cleared shield.applications - apps should now be unblocked")
        
        // Re-start monitoring after duration to re-block apps
        // This ensures apps don't stay unblocked indefinitely
        print("⏰ [DeviceActivityService] Setting timer to re-block apps in \(durationMinutes) minutes")
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(durationMinutes * 60)) {
            Task {
                print("⏰ [DeviceActivityService] Timer expired - checking if apps should be re-blocked")
                print("⏰ [DeviceActivityService] isMonitoring: \(self.isMonitoring)")
                print("⏰ [DeviceActivityService] Quiet Hours active: \(self.quietHoursService.isQuietModeActive)")
                
                if self.isMonitoring && self.quietHoursService.isQuietModeActive {
                    // Quiet Hours are still active - re-block apps
                    await self.updateMonitoringSchedule()
                    print("🔒 [DeviceActivityService] ✅ Apps RE-BLOCKED after \(durationMinutes) minutes")
                    print("🔒 [DeviceActivityService] Apps will be blocked again during Quiet Hours")
                    
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
        let content = UNMutableNotificationContent()
        content.title = "SOTERIA Moment"
        content.body = "You're about to open a shopping app. Take a moment to pause and think."
        content.sound = .default
        content.categoryIdentifier = "SOTERIA_MOMENT"
        content.userInfo = ["type": "soteria_moment"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
}

