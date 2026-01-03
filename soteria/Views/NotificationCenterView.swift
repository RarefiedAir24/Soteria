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
                    .foregroundColor(.reverBlue)
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
                
                // Clear badge when notifications are viewed
                clearBadge()
            }
        }
    }
    
    private func removeNotification(_ notification: UNNotification) {
        // Remove only the specific notification by its exact identifier
        let identifier = notification.request.identifier
        print("🗑️ [NotificationCenterView] Removing notification with identifier: \(identifier)")
        
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [identifier]
        )
        
        // Small delay to ensure iOS processes the removal before reloading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Reload notifications to refresh the list
            self.loadNotifications()
        }
    }
    
    private func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        deliveredNotifications = []
        clearBadge()
    }
    
    private func clearBadge() {
        // Clear badge using traditional method for better compatibility
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
            print("✅ [NotificationCenterView] Badge cleared")
        }
    }
}

struct NotificationRow: View {
    let notification: UNNotification
    let onRemove: () -> Void
    
    @State private var showRemoveConfirmation = false
    
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
            return .reverBlue
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
                
                Text(notificationBody)
                    .font(.system(size: 14))
                    .foregroundColor(.softGraphite)
                    .lineLimit(3)
                
                Text(formatDate(notificationDate))
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite.opacity(0.7))
            }
            
            Spacer()
            
            // Remove button
            Button(action: {
                showRemoveConfirmation = true
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.softGraphite.opacity(0.5))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationCenterView()
}

