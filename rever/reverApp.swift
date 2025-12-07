import SwiftUI
import FirebaseCore
import UserNotifications

@main
struct SoteriaApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var savingsService = SavingsService()
    @StateObject private var deviceActivityService = DeviceActivityService.shared
    @StateObject private var goalsService = GoalsService.shared
    @StateObject private var quietHoursService = QuietHoursService.shared
    @StateObject private var moodService = MoodTrackingService.shared
    @StateObject private var regretRiskEngine = RegretRiskEngine.shared
    @StateObject private var regretService = RegretLoggingService.shared
    @State private var showPauseView = false

    init() {
        FirebaseApp.configure()
        setupNotifications()
    }

    var body: some Scene {
        WindowGroup {
            RootView(showPauseView: $showPauseView)
                .environmentObject(authService)
                .environmentObject(savingsService)
                .environmentObject(deviceActivityService)
                .environmentObject(goalsService)
                .environmentObject(quietHoursService)
                .environmentObject(moodService)
                .environmentObject(regretRiskEngine)
                .environmentObject(regretService)
                .sheet(isPresented: $showPauseView) {
                    PauseView()
                        .environmentObject(savingsService)
                        .environmentObject(deviceActivityService)
                        .environmentObject(goalsService)
                        .environmentObject(regretService)
                        .environmentObject(moodService)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPauseView"))) { _ in
                    showPauseView = true
                }
        }
    }
    
    private func setupNotifications() {
        let delegate = NotificationDelegate()
        delegate.showPauseView = {
            // Post notification to trigger pause view
            NotificationCenter.default.post(name: NSNotification.Name("ShowPauseView"), object: nil)
        }
        UNUserNotificationCenter.current().delegate = delegate
        
        // Request notification authorization with time-sensitive option
        if #available(iOS 15.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .timeSensitive]) { granted, error in
                if let error = error {
                    print("❌ [App] Notification authorization error: \(error)")
                } else {
                    print("✅ [App] Notification authorization granted: \(granted)")
                }
            }
        } else {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("❌ [App] Notification authorization error: \(error)")
                } else {
                    print("✅ [App] Notification authorization granted: \(granted)")
                }
            }
        }
    }
}

// Notification delegate to handle taps
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var showPauseView: (() -> Void)?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        print("📱 [App] Notification tapped - userInfo: \(userInfo)")
        
        if userInfo["type"] as? String == "soteria_moment" {
            print("✅ [App] SOTERIA Moment notification detected - opening PauseView")
            // Record shopping attempt
            DeviceActivityService.shared.recordShoppingAttempt()
            DispatchQueue.main.async {
                self.showPauseView?()
            }
        } else {
            print("⚠️ [App] Unknown notification type: \(userInfo["type"] ?? "nil")")
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        let identifier = notification.request.identifier
        print("📱 [App] Notification received in foreground!")
        print("📱 [App] Identifier: \(identifier)")
        print("📱 [App] Title: \(notification.request.content.title)")
        print("📱 [App] Body: \(notification.request.content.body)")
        print("📱 [App] UserInfo: \(userInfo)")
        print("📱 [App] Trigger: \(notification.request.trigger?.description ?? "nil")")
        
        // Check if this is a SOTERIA Moment notification
        if userInfo["type"] as? String == "soteria_moment" {
            print("✅ [App] SOTERIA Moment notification detected in foreground - showing banner")
            // Show notification even when app is in foreground
            // Use .list for iOS 15+ compatibility
            if #available(iOS 15.0, *) {
                completionHandler([.banner, .list, .sound, .badge])
            } else {
                completionHandler([.alert, .sound, .badge])
            }
        } else {
            print("⚠️ [App] Unknown notification type in foreground")
            if #available(iOS 15.0, *) {
                completionHandler([.banner, .list, .sound, .badge])
            } else {
                completionHandler([.alert, .sound, .badge])
            }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var showPauseView: Bool

    var body: some View {
        Group {
            if authService.isAuthenticated {
                // User is signed in → main app
                MainTabView()
            } else {
                // User is signed out → auth flow
                AuthView()
            }
        }
    }
}
