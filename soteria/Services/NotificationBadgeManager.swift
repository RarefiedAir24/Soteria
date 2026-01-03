//
//  NotificationBadgeManager.swift
//  soteria
//
//  Manages notification badge count and app icon badge
//

import Foundation
import UserNotifications
import UIKit

class NotificationBadgeManager {
    static let shared = NotificationBadgeManager()
    
    private init() {}
    
    // MARK: - Update Badge Count
    
    /// Update badge count from delivered notifications (only unread ones)
    func updateBadgeCount() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            // Get list of unread notification identifiers
            let unreadIdentifiers = UserDefaults.standard.stringArray(forKey: "unreadNotificationIdentifiers") ?? []
            
            // Count notifications that are both delivered AND in the unread list
            let unreadCount = notifications.filter { notification in
                unreadIdentifiers.contains(notification.request.identifier)
            }.count
            
            DispatchQueue.main.async {
                // Set badge on main thread
                UIApplication.shared.applicationIconBadgeNumber = unreadCount
                print("🔔 [NotificationBadgeManager] Updated badge count: \(unreadCount) unread (from \(notifications.count) total delivered, \(unreadIdentifiers.count) in unread list), set app icon badge to: \(unreadCount)")
                
                // Post notification for UI updates
                NotificationCenter.default.post(
                    name: NSNotification.Name("NotificationCountUpdated"),
                    object: unreadCount
                )
            }
        }
    }
    
    /// Set app icon badge number
    func setAppIconBadge(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
            print("🔔 [NotificationBadgeManager] App icon badge set to: \(count)")
        }
    }
    
    /// Clear app icon badge
    func clearBadge() {
        setAppIconBadge(0)
    }
    
    /// Mark a notification as unread
    func markNotificationAsUnread(identifier: String) {
        // Store the identifier in UserDefaults to track unread notifications
        var unreadIdentifiers = UserDefaults.standard.stringArray(forKey: "unreadNotificationIdentifiers") ?? []
        if !unreadIdentifiers.contains(identifier) {
            unreadIdentifiers.append(identifier)
            UserDefaults.standard.set(unreadIdentifiers, forKey: "unreadNotificationIdentifiers")
            print("🔔 [NotificationBadgeManager] Marked notification as unread: \(identifier)")
        }
    }
    
    /// Mark a notification as read
    func markNotificationAsRead(identifier: String) {
        var unreadIdentifiers = UserDefaults.standard.stringArray(forKey: "unreadNotificationIdentifiers") ?? []
        if let index = unreadIdentifiers.firstIndex(of: identifier) {
            unreadIdentifiers.remove(at: index)
            UserDefaults.standard.set(unreadIdentifiers, forKey: "unreadNotificationIdentifiers")
            updateBadgeCount()
            print("🔔 [NotificationBadgeManager] Marked notification as read: \(identifier)")
        }
    }
    
    /// Get current notification count
    func getNotificationCount(completion: @escaping (Int) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                completion(notifications.count)
            }
        }
    }
    
    // MARK: - Notification Observers
    
    /// Sync unread status - mark any delivered notifications as unread if they haven't been marked as read
    func syncUnreadStatus() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            var unreadIdentifiers = UserDefaults.standard.stringArray(forKey: "unreadNotificationIdentifiers") ?? []
            var updated = false
            
            // Mark any delivered notifications as unread if they're not already marked as read
            for notification in notifications {
                let identifier = notification.request.identifier
                // Only mark decision window notifications and other app notifications as unread
                // Skip system notifications
                if (notification.request.content.userInfo["type"] as? String != nil) &&
                   !unreadIdentifiers.contains(identifier) {
                    unreadIdentifiers.append(identifier)
                    updated = true
                }
            }
            
            if updated {
                UserDefaults.standard.set(unreadIdentifiers, forKey: "unreadNotificationIdentifiers")
                print("🔔 [NotificationBadgeManager] Synced unread status - marked \(unreadIdentifiers.count) notifications as unread")
            }
            
            DispatchQueue.main.async {
                self.updateBadgeCount()
            }
        }
    }
    
    /// Start observing notification changes
    func startObserving() {
        // Update badge when app becomes active
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Sync unread status first, then update badge
            self?.syncUnreadStatus()
        }
        
        // Update badge when notifications are delivered
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NotificationDelivered"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateBadgeCount()
        }
    }
    
    /// Stop observing
    func stopObserving() {
        NotificationCenter.default.removeObserver(self)
    }
}

