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
    
    @Published var selectedApps: FamilyActivitySelection = FamilyActivitySelection() {
        didSet {
            // Save selection when it changes
            saveSelection()
            // Update app names mapping if needed
            updateAppNamesMapping()
            
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
    
    // Store app names by index (since we can't get names from ApplicationToken)
    // Key: app index (0-based), Value: user-provided name
    @Published var appNames: [Int: String] = [:]
    private let appNamesKey = "appNamesMapping"
    @Published var isMonitoring: Bool = false
    @Published var pendingUnlock: Bool = false // Track if user wants to unlock
    
    private let activityName = DeviceActivityName("soteria.monitoring")
    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    
    // Reference to QuietHoursService to check if blocking should be active
    private lazy var quietHoursService = QuietHoursService.shared
    
    // Track app usage patterns
    @Published var shoppingAttempts: [Date] = [] // When user tried to open shopping apps
    @Published var totalBlockedAttempts: Int = 0
    
    // Track unblock events for metrics
    struct UnblockEvent: Codable {
        let timestamp: Date
        let purchaseType: String? // "planned" or "impulse"
        let category: String? // For planned purchases
        let mood: String? // For impulse purchases
        let selectedAppsCount: Int // How many apps were unblocked
        let appIndex: Int? // Which app was selected (0-based index)
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
        // Defer notification authorization to avoid blocking init
        DispatchQueue.main.async { [weak self] in
            self?.requestNotificationAuthorization()
        }
        loadSelection()
        startSessionMonitoring()
        print("✅ [DeviceActivityService] Initialized")
    }
    
    deinit {
        sessionCheckTimer?.invalidate()
    }
    
    // Start monitoring for shopping session end
    private func startSessionMonitoring() {
        print("🔄 [DeviceActivityService] Starting session monitoring timer (checks every 30 seconds)")
        // Check every 30 seconds if there's an active shopping session that has ended
        sessionCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkForSessionEnd()
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
        // FamilyActivitySelection can't be directly encoded, but the tokens are preserved
        // The selection is managed by the system, so we just need to ensure state updates
        print("Selected apps count: \(selectedApps.applicationTokens.count)")
        
        // Save app token count for extension to know how many apps to block
        UserDefaults.standard.set(selectedApps.applicationTokens.count, forKey: "selectedAppsCount")
    }
    
    // Save unblock events for metrics
    private func saveUnblockEvents() {
        if let encoded = try? JSONEncoder().encode(unblockEvents) {
            UserDefaults.standard.set(encoded, forKey: "unblockEvents")
        }
    }
    
    // Load unblock events
    private func loadUnblockEvents() {
        if let data = UserDefaults.standard.data(forKey: "unblockEvents"),
           let decoded = try? JSONDecoder().decode([UnblockEvent].self, from: data) {
            unblockEvents = decoded
        }
    }
    
    // Get metrics about unblocks
    func getUnblockMetrics() -> (totalUnblocks: Int, plannedUnblocks: Int, impulseUnblocks: Int, mostCommonCategory: String?, mostCommonMood: String?, mostRequestedAppIndex: Int?, mostRequestedAppName: String?) {
        let total = unblockEvents.count
        let planned = unblockEvents.filter { $0.purchaseType == "planned" }.count
        let impulse = unblockEvents.filter { $0.purchaseType == "impulse" }.count
        
        // Find most common category
        let categories = unblockEvents.compactMap { $0.category }
        let categoryCounts = Dictionary(grouping: categories, by: { $0 }).mapValues { $0.count }
        let mostCommonCategory = categoryCounts.max(by: { $0.value < $1.value })?.key
        
        // Find most common mood
        let moods = unblockEvents.compactMap { $0.mood }
        let moodCounts = Dictionary(grouping: moods, by: { $0 }).mapValues { $0.count }
        let mostCommonMood = moodCounts.max(by: { $0.value < $1.value })?.key
        
        // Find most requested app (by index)
        let appIndices = unblockEvents.compactMap { $0.appIndex }
        let appIndexCounts = Dictionary(grouping: appIndices, by: { $0 }).mapValues { $0.count }
        let mostRequestedAppIndex = appIndexCounts.max(by: { $0.value < $1.value })?.key
        
        // Get app name for most requested app
        let mostRequestedAppName = mostRequestedAppIndex.map { getAppName(forIndex: $0) }
        
        return (total, planned, impulse, mostCommonCategory, mostCommonMood, mostRequestedAppIndex, mostRequestedAppName)
    }
    
    // Load selection from UserDefaults (if needed)
    private func loadSelection() {
        // FamilyActivitySelection is managed by the system
        // The selection persists automatically through the FamilyActivityPicker
        
        // Load app names mapping
        loadAppNamesMapping()
    }
    
    // Update app names mapping when apps are selected
    private func updateAppNamesMapping() {
        let currentCount = selectedApps.applicationTokens.count
        // Remove names for apps that are no longer selected
        appNames = appNames.filter { $0.key < currentCount }
        saveAppNamesMapping()
    }
    
    // Save app names mapping
    private func saveAppNamesMapping() {
        if let encoded = try? JSONEncoder().encode(appNames) {
            UserDefaults.standard.set(encoded, forKey: appNamesKey)
        }
    }
    
    // Load app names mapping
    private func loadAppNamesMapping() {
        if let data = UserDefaults.standard.data(forKey: appNamesKey),
           let decoded = try? JSONDecoder().decode([Int: String].self, from: data) {
            appNames = decoded
        }
    }
    
    // Set app name for a specific index
    func setAppName(_ name: String, forIndex index: Int) {
        appNames[index] = name
        saveAppNamesMapping()
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
        print("🔄 [DeviceActivityService] selectedApps count: \(selectedApps.applicationTokens.count)")
        
        guard !selectedApps.applicationTokens.isEmpty else {
            print("❌ [DeviceActivityService] No apps selected for monitoring")
            await MainActor.run {
                isMonitoring = false
            }
            return
        }
        
        print("✅ [DeviceActivityService] \(selectedApps.applicationTokens.count) apps selected")
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
        
        print("✅ [DeviceActivityService] startMonitoring() completed")
    }
    
    // Update monitoring schedule based on Quiet Hours
    // Uses Quiet Hours schedule for tracking (respects local time)
    private func updateMonitoringSchedule() async {
        print("🔄 [DeviceActivityService] Updating monitoring schedule based on Quiet Hours...")
        
        // Create an event to detect when monitored apps are opened
        let eventName = DeviceActivityEvent.Name("soteria.moment")
        let event = DeviceActivityEvent(
            applications: selectedApps.applicationTokens,
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
            print("🔒 [DeviceActivityService] Apps in event: \(selectedApps.applicationTokens.count)")
            print("🔒 [DeviceActivityService] ════════════════════════════════════════")
            
            do {
                try await MainActor.run {
                    try self.center.startMonitoring(self.activityName, during: deviceSchedule, events: [eventName: event])
                    // Set blocking - apps will be blocked during Quiet Hours
                    // IMPORTANT: Set shield.applications to ALL selected apps
                    self.store.shield.applications = self.selectedApps.applicationTokens
                    print("🔒 [DeviceActivityService] Blocking enabled - apps will be blocked during Quiet Hours")
                    print("🔒 [DeviceActivityService] Number of apps being blocked: \(self.selectedApps.applicationTokens.count)")
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
            print("📊 [DeviceActivityService] Apps in event: \(selectedApps.applicationTokens.count)")
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
        isMonitoring = false
        print("🛑 [DeviceActivityService] Stopped monitoring - apps are now unblocked")
        print("🛑 [DeviceActivityService] Cleared shield.applications")
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
        
        // Ensure shield is set if Quiet Hours are active
        if quietHoursService.isQuietModeActive {
            await MainActor.run {
                self.store.shield.applications = self.selectedApps.applicationTokens
                print("🔒 [DeviceActivityService] Shield applications updated: \(self.store.shield.applications?.count ?? 0) apps")
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
    func temporarilyUnblock(durationMinutes: Int = 15, purchaseType: String? = nil, category: String? = nil, mood: String? = nil, appIndex: Int? = nil) {
        // Stop monitoring temporarily to allow apps to open
        // This will unblock apps for the specified duration
        pendingUnlock = true
        print("🔓 [DeviceActivityService] Temporarily unblocking apps for \(durationMinutes) minutes")
        
        // Track unblock event for metrics
        let unblockEvent = UnblockEvent(
            timestamp: Date(),
            purchaseType: purchaseType,
            category: category,
            mood: mood,
            selectedAppsCount: selectedApps.applicationTokens.count,
            appIndex: appIndex
        )
        unblockEvents.append(unblockEvent)
        saveUnblockEvents()
        print("📊 [DeviceActivityService] Tracked unblock event: \(unblockEvent)")
        if let appIndex = appIndex {
            print("📊 [DeviceActivityService] App index: \(appIndex) (out of \(selectedApps.applicationTokens.count) apps)")
        }
        
        // Stop monitoring to unblock
        center.stopMonitoring([activityName])
        
        // Also clear shield applications to ensure apps are unblocked
        store.shield.applications = nil
        print("🔓 [DeviceActivityService] Cleared shield.applications - apps should now be unblocked")
        
        // Re-start monitoring after duration if Quiet Hours are still active
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(durationMinutes * 60)) {
            Task {
                if self.isMonitoring && self.quietHoursService.isQuietModeActive {
                    await self.updateMonitoringSchedule()
                    print("🔒 [DeviceActivityService] Re-blocked apps after \(durationMinutes) minutes")
                }
                await MainActor.run {
                    self.pendingUnlock = false
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

