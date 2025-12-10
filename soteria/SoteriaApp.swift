import SwiftUI
import FirebaseCore
import UserNotifications

@main
struct SoteriaApp: App {
    // Re-enabling services one by one to find the crash
    // Start with simple services (no external dependencies)
    @StateObject private var authService = AuthService()
    @StateObject private var savingsService = SavingsService()
    @StateObject private var goalsService = GoalsService.shared
    @StateObject private var moodService = MoodTrackingService.shared
    @StateObject private var streakService = StreakService.shared
    // Services with Firebase (re-enabling since Firebase is working)
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var regretService = RegretLoggingService.shared
    @StateObject private var regretRiskEngine = RegretRiskEngine.shared
    // Services with DeviceActivity (re-enabling - should be fine)
    @StateObject private var quietHoursService = QuietHoursService.shared
    @StateObject private var deviceActivityService = DeviceActivityService.shared
    @StateObject private var purchaseIntentService = PurchaseIntentService.shared
    // Plaid (keeping disabled - was causing crash)
    // @StateObject private var plaidService = PlaidService.shared
    @State private var showPauseView = false
    @State private var showPurchaseLogPrompt = false
    @State private var showPurchaseIntentPrompt = false
    @State private var showPaywall = false

    init() {
        let startTime = Date()
        print("✅ [App] Starting initialization at \(startTime)...")
        print("🟡 [App] About to initialize services...")
        
        // Log each service initialization
        print("🟡 [App] Services will initialize as @StateObject properties")
        print("🟡 [App] Note: @StateObject properties initialize BEFORE init() runs")
        
        // Configure consistent navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
        
        // Also configure UITabBar appearance for consistency
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Re-enable Firebase - app is working now
        // Debug: List all plist files in bundle
        let plistFiles = Bundle.main.paths(forResourcesOfType: "plist", inDirectory: nil)
        print("🔍 [App] Plist files in bundle: \(plistFiles)")
        
        // Configure Firebase - check if already configured first
        // FirebaseApp.configure() can crash if GoogleService-Info.plist is missing/invalid
        if FirebaseApp.app() == nil {
            // Check if GoogleService-Info.plist exists in bundle
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               FileManager.default.fileExists(atPath: path) {
                print("✅ [App] Found GoogleService-Info.plist at: \(path)")
                // FirebaseApp.configure() doesn't throw, but may abort if plist is invalid
                // We can't catch that, but at least we verified the file exists
                print("🔍 [App] About to call FirebaseApp.configure()...")
                let firebaseStart = Date()
                FirebaseApp.configure()
                let firebaseTime = Date().timeIntervalSince(firebaseStart)
                print("✅ [App] Firebase configured (took \(firebaseTime) seconds)")
            } else {
                print("⚠️ [App] GoogleService-Info.plist not found in bundle")
                print("⚠️ [App] Available resources: \(Bundle.main.paths(forResourcesOfType: nil, inDirectory: nil).prefix(10))")
                print("⚠️ [App] Skipping Firebase configuration - app may not have auth")
                // Don't call configure() if file doesn't exist - it will crash
            }
        } else {
            print("✅ [App] Firebase already configured")
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        print("✅ [App] SoteriaApp init completed (total: \(totalTime) seconds)")
        print("🟡 [App] Services should have initialized by now - check their logs above")
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
            // Testing with basic services enabled
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
                .environmentObject(subscriptionService)
                .environmentObject(streakService)
                // .environmentObject(plaidService)  // Keeping disabled - was causing crash
                // Set consistent status bar style
                .preferredColorScheme(.light)
                .statusBar(hidden: false)
            // .sheet(isPresented: $showPaywall) {
            //     PaywallView()
            //         .environmentObject(subscriptionService)
            // }
            // .task {
            //     // Initialize premium status for QuietHoursService
            //     QuietHoursService.shared.updatePremiumStatus(subscriptionService.isPremium)
            //     let appearTime = Date()
            //     print("📱 [SoteriaApp] WindowGroup appeared at \(appearTime)")
            //     setupNotifications()
            //     
            //     // Check if we should show purchase intent prompt immediately on app launch
            //     if UserDefaults.standard.bool(forKey: "shouldShowPurchaseIntentPrompt") {
            //         print("✅ [SoteriaApp] shouldShowPurchaseIntentPrompt is true on app launch - showing prompt")
            //         UserDefaults.standard.set(false, forKey: "shouldShowPurchaseIntentPrompt")
            //         try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            //         showPurchaseIntentPrompt = true
            //     }
            // }
            // .onChange(of: subscriptionService.isPremium) { oldValue, newValue in
            //     // Update QuietHoursService when premium status changes
            //     QuietHoursService.shared.updatePremiumStatus(newValue)
            // }
            // .sheet(isPresented: $showPauseView) {
            //         PauseView()
            //             .environmentObject(savingsService)
            //             .environmentObject(deviceActivityService)
            //             .environmentObject(goalsService)
            //             .environmentObject(regretService)
            //             .environmentObject(moodService)
            //             .environmentObject(purchaseIntentService)
            //             .environmentObject(streakService)
            //             .environmentObject(plaidService)
            //     }
            //     .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPauseView"))) { _ in
            //         showPauseView = true
            //     }
            //     .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPurchaseLogPrompt"))) { _ in
            //         showPurchaseLogPrompt = true
            //     }
            //     .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPurchaseIntentPrompt"))) { _ in
            //         showPurchaseIntentPrompt = true
            //     }
            //     .sheet(isPresented: $showPurchaseLogPrompt) {
            //         PurchaseLogPromptView()
            //             .environmentObject(deviceActivityService)
            //             .environmentObject(purchaseIntentService)
            //             .environmentObject(savingsService)
            //             .environmentObject(goalsService)
            //             .environmentObject(regretService)
            //             .environmentObject(moodService)
            //     }
            //     .onOpenURL { url in
            //         // Handle URL schemes
            //         if url.scheme == "soteria" {
            //             if url.host == "pause" {
            //                 print("✅ [App] Opened via URL scheme: \(url)")
            //                 showPauseView = true
            //             } else if url.host == "purchase-intent" {
            //                 print("✅ [App] Opened via URL scheme: \(url)")
            //                 showPurchaseIntentPrompt = true
            //             }
            //         }
            //     }
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

// Minimal test view to isolate crash
struct TestMinimalView: View {
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            VStack {
                Text("✅ App is Running!")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("If you see this, the crash is in service initialization")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
        .onAppear {
            print("✅ [TestMinimalView] Rendered successfully!")
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
    @State private var isAppReady = false  // Track if app initialization is complete

    var body: some View {
        let _ = {
            let timestamp = Date()
            print("🟢 [RootView] body evaluated at \(timestamp), isAuthenticated: \(authService.isAuthenticated)")
        }()
        
        return Group {
            if authService.isAuthenticated {
                // CRITICAL: Only create MainTabView after app is ready
                // This prevents TabView from evaluating all its children during startup
                if isAppReady {
                    MainTabView()
                } else {
                    // Show a simple placeholder while app initializes
                    Color(red: 0.98, green: 0.98, blue: 0.98)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                        )
                }
            } else {
                AuthView()
            }
        }
        .onAppear {
            let timestamp = Date()
            print("🟢 [RootView] onAppear at \(timestamp), isAuthenticated: \(authService.isAuthenticated)")
        }
        .task {
            let taskStart = Date()
            print("🟢 [RootView] .task started at \(taskStart), isAuthenticated: \(authService.isAuthenticated)")
            
            // Wait for app initialization to complete before showing MainTabView
            // This prevents TabView from evaluating all its children during startup
            if authService.isAuthenticated {
                print("🟡 [RootView] Waiting for app initialization...")
                // Wait a bit to ensure all services are initialized
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                await MainActor.run {
                    isAppReady = true
                    print("🟢 [RootView] App is ready - MainTabView will be created")
                }
            }
            
            // DISABLE these checks on app launch - they're blocking the main thread
            // They can run later when user interacts with the app
            // Task.detached(priority: .background) {
            //     try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            //     await MainActor.run {
            //         checkForRecentShoppingSession()
            //         checkForPurchaseIntentPrompt()
            //     }
            // }
            let taskEnd = Date()
            print("🟢 [RootView] .task completed at \(taskEnd) (took \(taskEnd.timeIntervalSince(taskStart))s)")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // DISABLED: These checks block the main thread
            // They can be re-enabled later if needed, but must be truly async
        }
               .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                   // DISABLED: These checks block the main thread
                   // They can be re-enabled later if needed, but must be truly async
               }
               .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                   // App is going to background - end any active usage sessions
                   // Note: This is a fallback - we primarily track via DeviceActivity events
                   print("📱 [RootView] App will resign active")
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
            // REMOVED: dictionaryRepresentation() is VERY slow and blocks main thread
            // Don't enumerate all UserDefaults keys - it's expensive
        }
        print("🔍 [RootView] ════════════════════════════════════════")
    }
}
