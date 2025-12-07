import SwiftUI
import FirebaseCore
import UserNotifications

@main
struct ReverApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var savingsService = SavingsService()
    @StateObject private var deviceActivityService = DeviceActivityService.shared
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
                .sheet(isPresented: $showPauseView) {
                    PauseView()
                        .environmentObject(savingsService)
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
        
        // Request notification authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
}

// Notification delegate to handle taps
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var showPauseView: (() -> Void)?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if userInfo["type"] as? String == "rever_moment" {
            DispatchQueue.main.async {
                self.showPauseView?()
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
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
