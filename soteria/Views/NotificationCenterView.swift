//
//  NotificationCenterView.swift
//  soteria
//
//  View to display and manage app notifications
//

import SwiftUI
import UserNotifications
import UIKit

struct NotificationCenterView: View {
    @State private var deliveredNotifications: [UNNotification] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cloudWhite
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if deliveredNotifications.isEmpty {
                    emptyStateView
                } else {
                    notificationList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        clearAllNotifications()
                    }
                    .foregroundColor(.softGraphite)
                    .disabled(deliveredNotifications.isEmpty)
                }
            }
        }
        .onAppear {
            loadNotifications()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
            
            Text("No Notifications")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.midnightSlate)
            
            Text("You're all caught up!")
                .font(.system(size: 14))
                .foregroundColor(.softGraphite)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(deliveredNotifications, id: \.request.identifier) { notification in
                    NotificationRow(notification: notification) {
                        removeNotification(notification)
                    }
                }
            }
            .padding()
        }
    }
    
    private func loadNotifications() {
        isLoading = true
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                // Filter out duplicate identifiers (iOS may return grouped notifications)
                var uniqueNotifications: [UNNotification] = []
                var seenIdentifiers: Set<String> = []
                
                for notification in notifications {
                    let identifier = notification.request.identifier
                    if !seenIdentifiers.contains(identifier) {
                        seenIdentifiers.insert(identifier)
                        uniqueNotifications.append(notification)
                    }
                }
                
                // Sort by date (most recent first)
                self.deliveredNotifications = uniqueNotifications.sorted { notif1, notif2 in
                    let date1 = notif1.date
                    let date2 = notif2.date
                    return date1 > date2
                }
                
                print("📬 [NotificationCenterView] Loaded \(self.deliveredNotifications.count) unique notifications (from \(notifications.count) total)")
                
                self.isLoading = false
                
                // DO NOT clear badge when opening - user must manually mark as read/delete
            }
        }
    }
    
    private func removeNotification(_ notification: UNNotification) {
        // Remove only the specific notification by its exact identifier
        let identifier = notification.request.identifier
        print("🗑️ [NotificationCenterView] Removing notification with identifier: \(identifier)")
        
        // Remove read status from UserDefaults
        UserDefaults.standard.removeObject(forKey: "notification_read_\(identifier)")
        
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [identifier]
        )
        
        // Update badge count after removal
        NotificationBadgeManager.shared.updateBadgeCount()
        
        // Small delay to ensure iOS processes the removal before reloading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Reload notifications to refresh the list
            self.loadNotifications()
        }
    }
    
    private func clearAllNotifications() {
        // Remove all read statuses from UserDefaults
        for notification in deliveredNotifications {
            let identifier = notification.request.identifier
            UserDefaults.standard.removeObject(forKey: "notification_read_\(identifier)")
        }
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        deliveredNotifications = []
        clearBadge()
    }
    
    private func clearBadge() {
        // Clear badge using NotificationBadgeManager
        NotificationBadgeManager.shared.clearBadge()
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: NSNotification.Name("NotificationCountUpdated"),
            object: 0
        )
    }
}

struct NotificationRow: View {
    let notification: UNNotification
    let onRemove: () -> Void
    
    @State private var showRemoveConfirmation = false
    @State private var isRead: Bool
    
    init(notification: UNNotification, onRemove: @escaping () -> Void) {
        self.notification = notification
        self.onRemove = onRemove
        // Check if notification is marked as read
        let identifier = notification.request.identifier
        _isRead = State(initialValue: UserDefaults.standard.bool(forKey: "notification_read_\(identifier)"))
    }
    
    private var notificationType: String {
        let userInfo = notification.request.content.userInfo
        return userInfo["type"] as? String ?? "unknown"
    }
    
    private var notificationTitle: String {
        notification.request.content.title
    }
    
    private var notificationBody: String {
        notification.request.content.body
    }
    
    private var notificationDate: Date {
        notification.date
    }
    
    private var iconName: String {
        switch notificationType {
        case "goal_progress":
            return "target"
        case "goal_milestone":
            return "star.fill"
        case "goal_achievement":
            return "trophy.fill"
        case "decision_window", "decision_window_reminder":
            return "clock.badge.questionmark"
        case "purchase_intent_prompt":
            return "cart.fill"
        case "purchase_log_prompt":
            return "list.bullet.rectangle"
        default:
            return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch notificationType {
        case "goal_progress":
            return .softGraphite
        case "goal_milestone":
            return .orange
        case "goal_achievement":
            return .yellow
        case "decision_window", "decision_window_reminder":
            return .purple
        case "purchase_intent_prompt":
            return .red
        case "purchase_log_prompt":
            return .blue
        default:
            return .gray
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notificationTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                    .opacity(isRead ? 0.6 : 1.0)
                
                Text(notificationBody)
                    .font(.system(size: 14))
                    .foregroundColor(.softGraphite)
                    .lineLimit(3)
                    .opacity(isRead ? 0.6 : 1.0)
                
                Text(formatDate(notificationDate))
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite.opacity(0.7))
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                // Mark as read/unread button
                Button(action: {
                    toggleReadStatus()
                }) {
                    Image(systemName: isRead ? "circle" : "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isRead ? .softGraphite.opacity(0.5) : .softGraphite)
                }
                
                // Remove button
                Button(action: {
                    showRemoveConfirmation = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.softGraphite.opacity(0.5))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isRead ? Color.white.opacity(0.5) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .confirmationDialog("Remove Notification", isPresented: $showRemoveConfirmation, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                onRemove()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Remove this notification?")
        }
    }
    
    private func toggleReadStatus() {
        let identifier = notification.request.identifier
        isRead.toggle()
        UserDefaults.standard.set(isRead, forKey: "notification_read_\(identifier)")
        
        // Update badge count when marking as read
        if isRead {
            NotificationBadgeManager.shared.updateBadgeCount()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationCenterView()
}

