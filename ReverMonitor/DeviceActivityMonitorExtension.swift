//
//  DeviceActivityMonitorExtension.swift
//  ReverMonitor
//
//  Created by Frank Schioppa on 12/6/25.
//

import DeviceActivity
import UserNotifications

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // When monitoring starts, send notification immediately
        // This happens when a monitored app is opened
        sendReverMomentNotification()
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Monitoring ended
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // Event threshold reached - send notification
        sendReverMomentNotification()
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
    }
    
    // Send notification when monitored app is opened
    private func sendReverMomentNotification() {
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
