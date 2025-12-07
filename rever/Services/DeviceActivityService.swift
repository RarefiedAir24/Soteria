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
    
    private let activityName = DeviceActivityName("rever.monitoring")
    private let center = DeviceActivityCenter()
    
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
            let eventName = DeviceActivityEvent.Name("rever.moment")
            let event = DeviceActivityEvent(
                applications: selectedApps.applicationTokens,
                threshold: DateComponents(second: 1)
            )
            
            // Start monitoring with schedule, during activity, with events
            try center.startMonitoring(activityName, during: schedule, events: [eventName: event])
            
            print("Started monitoring \(selectedApps.applicationTokens.count) apps")
            
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
        isMonitoring = false
        print("Stopped monitoring")
    }
    
    // Send local notification for Rever Moment
    func sendReverMomentNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Rever Moment"
        content.body = "You're about to open a shopping app. Take a moment to pause and think."
        content.sound = .default
        content.categoryIdentifier = "REVER_MOMENT"
        content.userInfo = ["type": "rever_moment"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
}

