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

class DeviceActivityService: ObservableObject {
    static let shared = DeviceActivityService()
    
    @Published var selectedApps: FamilyActivitySelection = FamilyActivitySelection() {
        didSet {
            // Save selection when it changes
            saveSelection()
        }
    }
    @Published var isMonitoring: Bool = false
    @Published var pendingUnlock: Bool = false // Track if user wants to unlock
    
    private let activityName = DeviceActivityName("soteria.monitoring")
    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    
    // Track app usage patterns
    @Published var shoppingAttempts: [Date] = [] // When user tried to open shopping apps
    @Published var totalBlockedAttempts: Int = 0
    
    private init() {
        requestNotificationAuthorization()
        loadSelection()
    }
    
    // Save selection to UserDefaults
    private func saveSelection() {
        // FamilyActivitySelection can't be directly encoded, but the tokens are preserved
        // The selection is managed by the system, so we just need to ensure state updates
        print("Selected apps count: \(selectedApps.applicationTokens.count)")
    }
    
    // Load selection from UserDefaults (if needed)
    private func loadSelection() {
        // FamilyActivitySelection is managed by the system
        // The selection persists automatically through the FamilyActivityPicker
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
        guard !selectedApps.applicationTokens.isEmpty else {
            print("No apps selected for monitoring")
            await MainActor.run {
                isMonitoring = false
            }
            return
        }
        
        // Stop any existing monitoring first
        if isMonitoring {
            center.stopMonitoring([activityName])
        }
        
        // Create a schedule that runs all day
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        do {
            // Create an event to detect when monitored apps are opened
            let eventName = DeviceActivityEvent.Name("soteria.moment")
            let event = DeviceActivityEvent(
                applications: selectedApps.applicationTokens,
                threshold: DateComponents(second: 1)
            )
            
            // Start monitoring with schedule, during activity, with events
            try center.startMonitoring(activityName, during: schedule, events: [eventName: event])
            
            // Block the selected apps using ManagedSettings
            // This will prevent them from opening and show a blocking screen
            store.application.blockedApplications = selectedApps.applicationTokens
            
            print("✅ [DeviceActivityService] Started monitoring \(selectedApps.applicationTokens.count) apps")
            print("✅ [DeviceActivityService] Blocked \(selectedApps.applicationTokens.count) apps using ManagedSettings")
            print("✅ [DeviceActivityService] Activity name: \(activityName)")
            print("✅ [DeviceActivityService] Event name: \(eventName)")
            print("✅ [DeviceActivityService] Threshold: 1 second")
            print("✅ [DeviceActivityService] Schedule: All day (00:00 - 23:59)")
            
            // Set state to true on success
            await MainActor.run {
                self.isMonitoring = true
            }
        } catch {
            print("Failed to start monitoring: \(error.localizedDescription)")
            print("Error details: \(error)")
            
            // Revert state on error
            await MainActor.run {
                self.isMonitoring = false
            }
        }
    }
    
    // Stop monitoring
    func stopMonitoring() {
        center.stopMonitoring([activityName])
        // Unblock apps when monitoring stops
        store.application.blockedApplications = nil
        isMonitoring = false
        print("🛑 [DeviceActivityService] Stopped monitoring and unblocked apps")
    }
    
    // Temporarily unblock apps (when user chooses "Continue Shopping")
    func temporarilyUnblock(durationMinutes: Int = 15) {
        store.application.blockedApplications = nil
        pendingUnlock = true
        print("🔓 [DeviceActivityService] Temporarily unblocked apps for \(durationMinutes) minutes")
        
        // Re-block after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(durationMinutes * 60)) {
            if self.isMonitoring {
                self.store.application.blockedApplications = self.selectedApps.applicationTokens
                self.pendingUnlock = false
                print("🔒 [DeviceActivityService] Re-blocked apps after \(durationMinutes) minutes")
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

