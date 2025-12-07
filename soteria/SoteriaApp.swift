import SwiftUI
import FirebaseCore
import UserNotifications

@main
struct SoteriaApp: App {
    // Re-enable all services now that basic rendering works
    @StateObject private var authService = AuthService()
    @StateObject private var savingsService = SavingsService()
    @StateObject private var goalsService = GoalsService.shared
    @StateObject private var moodService = MoodTrackingService.shared
    @StateObject private var regretService = RegretLoggingService.shared
    @StateObject private var regretRiskEngine = RegretRiskEngine.shared
    @StateObject private var quietHoursService = QuietHoursService.shared
    @StateObject private var deviceActivityService = DeviceActivityService.shared
    @StateObject private var purchaseIntentService = PurchaseIntentService.shared
    @State private var showPauseView = false
    @State private var showPurchaseLogPrompt = false
    @State private var showPurchaseIntentPrompt = false

    init() {
        let startTime = Date()
        print("✅ [App] Starting initialization at \(startTime)...")
        
        // Configure Firebase immediately but on main thread
        // This is the recommended approach - Firebase needs main thread
        FirebaseApp.configure()
        let firebaseTime = Date().timeIntervalSince(startTime)
        print("✅ [App] Firebase configured (took \(firebaseTime) seconds)")
        
        let totalTime = Date().timeIntervalSince(startTime)
        print("✅ [App] SoteriaApp init completed (total: \(totalTime) seconds)")
    }
    
    private func setupNotifications() {
        let delegate = NotificationDelegate()
        delegate.showPauseView = {
            // Post notification to trigger pause view
            NotificationCenter.default.post(name: NSNotification.Name("ShowPauseView"), object: nil)
        }
        delegate.showPurchaseLogPrompt = {
            // Post notification to trigger purchase log prompt
            NotificationCenter.default.post(name: NSNotification.Name("ShowPurchaseLogPrompt"), object: nil)
        }
        delegate.showPurchaseIntentPrompt = {
            // Post notification to trigger purchase intent prompt
            NotificationCenter.default.post(name: NSNotification.Name("ShowPurchaseIntentPrompt"), object: nil)
        }
        UNUserNotificationCenter.current().delegate = delegate
        
        // Request notification authorization
        // Note: timeSensitive is deprecated - use time-sensitive entitlement instead
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ [App] Notification authorization error: \(error)")
            } else {
                print("✅ [App] Notification authorization granted: \(granted)")
            }
        }
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
                .environmentObject(purchaseIntentService)
                .onAppear {
                    let appearTime = Date()
                    print("📱 [SoteriaApp] WindowGroup appeared at \(appearTime)")
                    setupNotifications()
                    
                    // Check if we should show purchase intent prompt immediately on app launch
                    if UserDefaults.standard.bool(forKey: "shouldShowPurchaseIntentPrompt") {
                        print("✅ [SoteriaApp] shouldShowPurchaseIntentPrompt is true on app launch - showing prompt")
                        UserDefaults.standard.set(false, forKey: "shouldShowPurchaseIntentPrompt")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showPurchaseIntentPrompt = true
                        }
                    }
                }
                .sheet(isPresented: $showPauseView) {
                    PauseView()
                        .environmentObject(savingsService)
                        .environmentObject(deviceActivityService)
                        .environmentObject(goalsService)
                        .environmentObject(regretService)
                        .environmentObject(moodService)
                        .environmentObject(purchaseIntentService)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPauseView"))) { _ in
                    showPauseView = true
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPurchaseLogPrompt"))) { _ in
                    showPurchaseLogPrompt = true
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPurchaseIntentPrompt"))) { _ in
                    showPurchaseIntentPrompt = true
                }
                .sheet(isPresented: $showPurchaseLogPrompt) {
                    PurchaseLogPromptView()
                        .environmentObject(deviceActivityService)
                        .environmentObject(purchaseIntentService)
                        .environmentObject(savingsService)
                        .environmentObject(goalsService)
                        .environmentObject(regretService)
                        .environmentObject(moodService)
                }
                .onOpenURL { url in
                    // Handle URL schemes
                    if url.scheme == "soteria" {
                        if url.host == "pause" {
                            print("✅ [App] Opened via URL scheme: \(url)")
                            showPauseView = true
                        } else if url.host == "purchase-intent" {
                            print("✅ [App] Opened via URL scheme: \(url)")
                            showPurchaseIntentPrompt = true
                        }
                    }
                }
        }
    }
}

// Temporary test view to see if anything renders
struct TestView: View {
    var body: some View {
        // Ultra-simple view - just a solid color
        Color.red
            .ignoresSafeArea()
            .onAppear {
                print("✅ [TestView] Rendered successfully at \(Date())")
            }
    }
}

// Notification delegate to handle taps
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var showPauseView: (() -> Void)?
    var showPurchaseLogPrompt: (() -> Void)?
    var showPurchaseIntentPrompt: (() -> Void)?
    
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
        } else if userInfo["type"] as? String == "purchase_log_prompt" {
            print("✅ [App] Purchase log prompt notification detected - opening PurchaseLogPromptView")
            DispatchQueue.main.async {
                self.showPurchaseLogPrompt?()
            }
        } else if userInfo["type"] as? String == "purchase_intent_prompt" {
            print("✅ [App] Purchase intent prompt notification detected - opening PurchaseIntentPromptView")
            DispatchQueue.main.async {
                self.showPurchaseIntentPrompt?()
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
        
        // Check notification type
        if userInfo["type"] as? String == "soteria_moment" {
            print("✅ [App] SOTERIA Moment notification detected in foreground - showing banner")
            if #available(iOS 15.0, *) {
                completionHandler([.banner, .list, .sound, .badge])
            } else {
                completionHandler([.alert, .sound, .badge])
            }
        } else if userInfo["type"] as? String == "purchase_log_prompt" {
            print("✅ [App] Purchase log prompt notification detected in foreground - showing banner and opening view")
            // Show notification AND trigger the view
            DispatchQueue.main.async {
                self.showPurchaseLogPrompt?()
            }
            if #available(iOS 15.0, *) {
                completionHandler([.banner, .list, .sound, .badge])
            } else {
                completionHandler([.alert, .sound, .badge])
            }
        } else if userInfo["type"] as? String == "purchase_intent_prompt" {
            print("✅ [App] Purchase intent prompt notification detected in foreground - opening PurchaseIntentPromptView")
            DispatchQueue.main.async {
                self.showPurchaseIntentPrompt?()
            }
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
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    @EnvironmentObject var quietHoursService: QuietHoursService
    @Binding var showPauseView: Bool
    @State private var showPurchaseLogPrompt = false
    @State private var showPurchaseIntentPrompt = false

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
        .onAppear {
            print("📱 [RootView] Appeared - isAuthenticated: \(authService.isAuthenticated)")
            // Check for recent shopping sessions when app opens
            checkForRecentShoppingSession()
            
            // Also check for purchase intent prompt on appear
            checkForPurchaseIntentPrompt()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Check when app comes to foreground
            print("📱 [RootView] App entering foreground - checking for shopping sessions")
            checkForRecentShoppingSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Also check when app becomes active (more reliable)
            print("📱 [RootView] App did become active - checking for shopping sessions")
            checkForRecentShoppingSession()
            // Also trigger DeviceActivityService check
            deviceActivityService.checkForSessionEnd()
            
            // Check for purchase intent prompt
            checkForPurchaseIntentPrompt()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenSOTERIA"))) { notification in
            print("✅ [RootView] Received OpenSOTERIA notification")
            if let urlString = notification.userInfo?["url"] as? String,
               let url = URL(string: urlString) {
                // Handle URL to open purchase intent prompt
                if url.host == "purchase-intent" {
                    showPurchaseIntentPrompt = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPurchaseIntentPrompt"))) { _ in
            showPurchaseIntentPrompt = true
        }
        .sheet(isPresented: $showPurchaseIntentPrompt) {
            // Environment objects are passed from parent WindowGroup
            PurchaseIntentPromptView()
        }
        .sheet(isPresented: $showPurchaseLogPrompt) {
            // Show purchase logging prompt if user recently used shopping apps
            // Note: Environment objects are passed from parent WindowGroup
            PurchaseLogPromptView()
        }
    }
    
           // Check if we should show purchase intent prompt
           private func checkForPurchaseIntentPrompt() {
               print("🔍 [RootView] ════════════════════════════════════════")
               print("🔍 [RootView] Checking for purchase intent prompt...")
               
               // Check if we should show purchase intent prompt (intercepted before app launch)
               if UserDefaults.standard.bool(forKey: "shouldShowPurchaseIntentPrompt") {
                   print("✅ [RootView] shouldShowPurchaseIntentPrompt is true - showing prompt (intercepted before app launch)")
                   UserDefaults.standard.set(false, forKey: "shouldShowPurchaseIntentPrompt")
                   // Show immediately when app becomes active
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                       self.showPurchaseIntentPrompt = true
                       print("✅ [RootView] showPurchaseIntentPrompt set to: \(self.showPurchaseIntentPrompt)")
                   }
               } else {
                   // Fallback: If Quiet Hours are active and monitoring is on, 
                   // show prompt when user opens SOTERIA (they likely saw blocking screen)
                   let now = Date().timeIntervalSince1970
                   let lastPromptTime = UserDefaults.standard.double(forKey: "lastPurchaseIntentPromptTime")
                   let timeSinceLastPrompt = now - lastPromptTime
                   
                   print("🔍 [RootView] Checking fallback prompt conditions:")
                   print("   - Quiet Hours active: \(quietHoursService.isQuietModeActive)")
                   print("   - Monitoring on: \(deviceActivityService.isMonitoring)")
                   print("   - Time since last prompt: \(Int(timeSinceLastPrompt))s")
                   
                   if quietHoursService.isQuietModeActive && deviceActivityService.isMonitoring {
                       // Only show if we haven't shown a prompt in the last 10 seconds (avoid spam)
                       // Reduced from 30s for testing
                       if timeSinceLastPrompt > 10.0 {
                           print("✅ [RootView] SOTERIA activated during Quiet Hours with monitoring - showing prompt")
                           print("✅ [RootView] Setting showPurchaseIntentPrompt = true")
                           UserDefaults.standard.set(now, forKey: "lastPurchaseIntentPromptTime")
                           DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                               self.showPurchaseIntentPrompt = true
                               print("✅ [RootView] showPurchaseIntentPrompt set to: \(self.showPurchaseIntentPrompt)")
                           }
                       } else {
                           print("⏭️ [RootView] Skipping prompt - shown \(Int(timeSinceLastPrompt))s ago (cooldown: 10s)")
                       }
                   } else {
                       print("⏭️ [RootView] Fallback conditions not met:")
                       print("   - Quiet Hours active: \(quietHoursService.isQuietModeActive)")
                       print("   - Monitoring on: \(deviceActivityService.isMonitoring)")
                   }
               }
               print("🔍 [RootView] ════════════════════════════════════════")
           }
           
           // Check if user recently used shopping apps and prompt to log purchase
           private func checkForRecentShoppingSession() {
        print("🔍 [RootView] ════════════════════════════════════════")
        print("🔍 [RootView] Checking for recent shopping session...")
        print("🔍 [RootView] showPurchaseLogPrompt currently: \(showPurchaseLogPrompt)")
        
        // Check UserDefaults for active shopping session
        if let sessionData = UserDefaults.standard.dictionary(forKey: "activeShoppingSession"),
           let startTime = sessionData["startTime"] as? TimeInterval {
            let sessionStart = Date(timeIntervalSince1970: startTime)
            let duration = Date().timeIntervalSince(sessionStart)
            
            print("📱 [RootView] ✅ FOUND shopping session:")
            print("   Start: \(sessionStart)")
            print("   Duration: \(Int(duration)) seconds (\(Int(duration / 60)) minutes)")
            print("   Full session data: \(sessionData)")
            
            // If session was > 2 minutes, likely made a purchase
            if duration > 120 {
                print("✅ [RootView] Session > 2 minutes - PROMPTING TO LOG PURCHASE")
                print("✅ [RootView] Setting showPurchaseLogPrompt = true")
                // Show prompt immediately
                DispatchQueue.main.async {
                    self.showPurchaseLogPrompt = true
                    print("✅ [RootView] showPurchaseLogPrompt set to: \(self.showPurchaseLogPrompt)")
                }
                // Clear the session
                UserDefaults.standard.removeObject(forKey: "activeShoppingSession")
                print("✅ [RootView] Cleared session from UserDefaults")
            } else {
                print("⏳ [RootView] Session too short: \(Int(duration))s (need > 120s)")
            }
        } else {
            print("📭 [RootView] ❌ No shopping session found in UserDefaults")
            // Debug: Print all UserDefaults keys
            let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
            let relevantKeys = Array(allKeys).filter { $0.contains("shopping") || $0.contains("session") || $0.contains("active") }
            print("📋 [RootView] Relevant UserDefaults keys: \(relevantKeys)")
            print("📋 [RootView] Total UserDefaults keys: \(allKeys.count)")
        }
        print("🔍 [RootView] ════════════════════════════════════════")
    }
}
