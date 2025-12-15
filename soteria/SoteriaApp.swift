import SwiftUI
import UserNotifications

// Import MainActorMonitor for startup diagnostics
let mainActorMonitor = MainActorMonitor.shared

@main
struct SoteriaApp: App {
    @StateObject private var authService = AuthService()
    @State private var showPauseView = false
    @State private var showPurchaseLogPrompt = false
    @State private var showPurchaseIntentPrompt = false
    @State private var showPaywall = false

    init() {
        let initStart = Date()
        MainActorMonitor.shared.logOperation("SoteriaApp.init() started")
        print("🔍 [SoteriaApp] init() started")
        
        // CRITICAL: UI appearance config was taking 18.856s even when async
        // Move to a background task with significant delay to avoid blocking startup
        // The UI will work fine with default appearance until this applies
        // Don't await - fire and forget
        _ = Task.detached(priority: .utility) {
            // Wait 5 seconds to ensure app is fully loaded and interactive
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            
            await MainActor.run {
                let beforeAppearance = Date()
                MainActorMonitor.shared.logOperation("SoteriaApp: UI appearance config (deferred)")
                
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(Color.mistGray)
                appearance.shadowColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithOpaqueBackground()
                tabBarAppearance.backgroundColor = UIColor(Color.mistGray)
                UITabBar.appearance().standardAppearance = tabBarAppearance
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                
                let appearanceDuration = Date().timeIntervalSince(beforeAppearance)
                MainActorMonitor.shared.logOperation("SoteriaApp: UI appearance config completed", duration: appearanceDuration)
                if appearanceDuration > 0.1 {
                    print("⚠️ [SoteriaApp] UI appearance config took \(String(format: "%.3f", appearanceDuration))s (SLOW)")
                }
            }
        }
        
        let initDuration = Date().timeIntervalSince(initStart)
        MainActorMonitor.shared.logOperation("SoteriaApp.init() completed", duration: initDuration)
        print("✅ [SoteriaApp] init() completed (took \(String(format: "%.3f", initDuration))s)")
    }
    
    private func setupNotifications() {
        let delegate = NotificationDelegate()
        delegate.showPauseView = {
            NotificationCenter.default.post(name: NSNotification.Name("ShowPauseView"), object: nil)
        }
        delegate.showPurchaseLogPrompt = {
            NotificationCenter.default.post(name: NSNotification.Name("ShowPurchaseLogPrompt"), object: nil)
        }
        delegate.showPurchaseIntentPrompt = {
            NotificationCenter.default.post(name: NSNotification.Name("ShowPurchaseIntentPrompt"), object: nil)
        }
        UNUserNotificationCenter.current().delegate = delegate
        
        // Request notification authorization
        let beforeAuth = Date()
        MainActorMonitor.shared.logOperation("SoteriaApp: Requesting notification authorization")
        if #available(iOS 15.0, *) {
            let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
                let authDuration = Date().timeIntervalSince(beforeAuth)
                MainActorMonitor.shared.logOperation("SoteriaApp: Notification authorization callback (on MainActor)", duration: authDuration)
                if let error = error {
                    print("❌ [App] Notification authorization error: \(error)")
                } else {
                    print("✅ [App] Notification authorization granted: \(granted) (took \(String(format: "%.3f", authDuration))s)")
                }
            }
        } else {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                let authDuration = Date().timeIntervalSince(beforeAuth)
                MainActorMonitor.shared.logOperation("SoteriaApp: Notification authorization callback (on MainActor)", duration: authDuration)
                if let error = error {
                    print("❌ [App] Notification authorization error: \(error)")
                } else {
                    print("✅ [App] Notification authorization granted: \(granted) (took \(String(format: "%.3f", authDuration))s)")
                }
            }
        }
    }
    
    // TEMPORARILY DISABLED: setupNotifications - requires UserNotifications framework
    /*
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
        
        // Request notification authorization with time-sensitive support
        // Time-sensitive notifications can show as banners even when in another app
        // The entitlement is already configured in entitlements file
        if #available(iOS 15.0, *) {
            // Note: Time-sensitive notifications are enabled via entitlement
            // No need to include .timeSensitive in the authorization request
            let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
                if let error = error {
                    print("❌ [App] Notification authorization error: \(error)")
                } else {
                    print("✅ [App] Notification authorization granted: \(granted)")
                    if granted {
                        print("✅ [App] Time-sensitive notifications enabled - banners will show in-app")
                    }
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
    */

    var body: some Scene {
        WindowGroup {
            RootView(showPauseView: $showPauseView)
                .environmentObject(authService)
                .preferredColorScheme(.light)
                .task {
                    // CRITICAL: Move notification setup completely off MainActor
                    // Task.sleep in .task runs on MainActor and gets delayed when MainActor is blocked
                    // Solution: Use Task.detached for the entire operation
                    MainActorMonitor.shared.logOperation("SoteriaApp: Starting notification setup task")
                    
                    await Task.detached(priority: .utility) {
                        // Wait off MainActor - this won't be delayed
                        let beforeSleep = Date()
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        let sleepDuration = Date().timeIntervalSince(beforeSleep)
                        await MainActor.run {
                            MainActorMonitor.shared.logOperation("SoteriaApp: Notification setup sleep completed", duration: sleepDuration)
                        }
                        if sleepDuration > 1.1 {
                            print("⚠️ [SoteriaApp] Notification sleep delayed by \(String(format: "%.2f", sleepDuration - 1.0))s")
                        }
                        
                        // Setup notifications - this calls MainActor operations but doesn't block the wait
                        let beforeSetup = Date()
                        await MainActor.run {
                            setupNotifications()
                        }
                        let setupDuration = Date().timeIntervalSince(beforeSetup)
                        await MainActor.run {
                            MainActorMonitor.shared.logOperation("SoteriaApp: setupNotifications() completed", duration: setupDuration)
                        }
                    }.value
                }
                .sheet(isPresented: $showPauseView) {
                    PauseView()
                }
                .sheet(isPresented: $showPurchaseLogPrompt) {
                    PurchaseLogPromptView()
                }
                .sheet(isPresented: $showPurchaseIntentPrompt) {
                    PurchaseIntentPromptView()
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
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
                .onOpenURL { url in
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
            //     .task {
            //         // Setup notifications asynchronously - don't block UI
            //         setupNotifications()
            //     }
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
            // Check if user has no active goal - navigate to Goals tab instead
            if userInfo["noActiveGoal"] as? Bool == true {
                print("✅ [App] Purchase intent prompt notification detected - no active goal, navigating to Goals tab")
                // Post notification to navigate to Goals tab
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToGoalsTab"), object: nil)
                    // Also post notification to show create goal view
                    NotificationCenter.default.post(name: NSNotification.Name("ShowCreateGoal"), object: nil)
                }
            } else {
                print("✅ [App] Purchase intent prompt notification detected - opening PurchaseIntentPromptView")
                DispatchQueue.main.async {
                    self.showPurchaseIntentPrompt?()
                }
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
            // Check if user has no active goal - navigate to Goals tab instead
            if userInfo["noActiveGoal"] as? Bool == true {
                print("✅ [App] Purchase intent prompt notification detected in foreground - no active goal, navigating to Goals tab")
                // Post notification to navigate to Goals tab
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToGoalsTab"), object: nil)
                    // Also post notification to show create goal view
                    NotificationCenter.default.post(name: NSNotification.Name("ShowCreateGoal"), object: nil)
                }
            } else {
                print("✅ [App] Purchase intent prompt notification detected in foreground - opening PurchaseIntentPromptView")
                DispatchQueue.main.async {
                    self.showPurchaseIntentPrompt?()
                }
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
    @Binding var showPauseView: Bool
    @State private var showPurchaseLogPrompt = false
    @State private var showPurchaseIntentPrompt = false
    // Show splash screen until all startup work is complete
    @State private var isAppReady = false // Start with splash screen
    
    init(showPauseView: Binding<Bool>) {
        let initStart = Date()
        MainActorMonitor.shared.logOperation("RootView.init() called")
        self._showPauseView = showPauseView
        let initDuration = Date().timeIntervalSince(initStart)
        MainActorMonitor.shared.logOperation("RootView.init() completed", duration: initDuration)
        print("🔍 [RootView] init() called (took \(String(format: "%.3f", initDuration))s)")
    }

    var body: some View {
        let _ = {
            let bodyStart = Date()
            MainActorMonitor.shared.logOperation("RootView.body evaluation")
            print("🟢 [RootView] body evaluated - isAppReady: \(isAppReady), isAuthenticated: \(authService.isAuthenticated), isCheckingAuth: \(authService.isCheckingAuth)")
            let bodyDuration = Date().timeIntervalSince(bodyStart)
            if bodyDuration > 0.01 {
                MainActorMonitor.shared.logOperation("RootView.body evaluation (SLOW)", duration: bodyDuration)
                print("⚠️ [RootView] Body evaluation took \(String(format: "%.3f", bodyDuration))s")
            }
        }()
        
        // CRITICAL: Show splash screen while app is initializing OR auth is being verified
        // This prevents showing sign-in screen while background auth verification is happening
        Group {
            if !isAppReady || authService.isCheckingAuth {
                SplashScreenView()
                    .id("splash-screen")
            } else if authService.isAuthenticated {
                MainTabView()
                    .id("main-tab-view")
            } else {
                AuthView()
                    .id("auth-view")
            }
        }
        // Prevent view recreation by using stable identity
        .animation(nil, value: isAppReady) // No animation to prevent blocking
        .animation(nil, value: authService.isCheckingAuth) // No animation to prevent blocking
        .onAppear {
            let startTime = Date()
            MainActorMonitor.shared.logOperation("RootView.onAppear called")
            print("🟢 [RootView] onAppear - setting app ready immediately")
            
            // CRITICAL: Set state immediately in onAppear (synchronous on MainActor)
            // Don't wait - if MainActor is blocked, waiting won't help
            // The UI will become interactive when MainActor frees up
            // Small async delay just for splash screen branding
            let beforeAsync = Date()
            MainActorMonitor.shared.logOperation("RootView: Scheduling asyncAfter(0.3s)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let asyncStart = Date()
                MainActorMonitor.shared.logOperation("RootView: asyncAfter block executing")
                print("🟢 [RootView] asyncAfter block started (queued for \(String(format: "%.3f", asyncStart.timeIntervalSince(beforeAsync)))s)")
                
                let beforeSet = Date()
                isAppReady = true
                let afterSet = Date()
                let setDuration = afterSet.timeIntervalSince(beforeSet)
                
                MainActorMonitor.shared.logOperation("RootView: isAppReady = true", duration: setDuration)
                
                let totalTime = Date().timeIntervalSince(startTime)
                print("✅ [RootView] App is ready (total: \(String(format: "%.2f", totalTime))s)")
                print("✅ [RootView] Setting isAppReady took \(String(format: "%.3f", setDuration))s")
                print("✅ [RootView] isAppReady: \(isAppReady), isAuthenticated: \(authService.isAuthenticated), isCheckingAuth: \(authService.isCheckingAuth)")
                
                // Print summary after a delay to capture all operations
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    MainActorMonitor.shared.printSummary()
                }
            }
        }
        // STREAMLINED: Removed purchase intent checks from foreground/active notifications
        // Purchase intent checks now only happen on-demand when app blocking actually occurs
        // This eliminates 2 unnecessary background tasks on every app launch
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
           // SAFE: Only reads UserDefaults and cached values (fast, non-blocking)
           // CRITICAL: This function must NEVER block - all property access is async
           private func checkForPurchaseIntentPrompt() {
               let funcStart = Date()
               print("🔍 [RootView] checkForPurchaseIntentPrompt() called at \(funcStart)")
               // Note: Thread.isMainThread is not available in async contexts in Swift 6
               // This function is called from MainActor context, so it's on the main thread
               print("🔍 [RootView] checkForPurchaseIntentPrompt - Running on MainActor (main thread)")
               print("🔍 [RootView] checkForPurchaseIntentPrompt - Task priority: \(Task.currentPriority.rawValue)")
               
               // Guard: Don't check during app launch (first 3 seconds) to prevent startup blocking
               let guardStart = Date()
               let appLaunchTime = UserDefaults.standard.double(forKey: "appLaunchTime")
               let guardTime = Date().timeIntervalSince(guardStart)
               if guardTime > 0.01 {
                   print("⚠️ [RootView] WARNING: UserDefaults read took \(guardTime)s (should be < 0.01s)")
               }
               
               if appLaunchTime > 0 {
                   let timeSinceLaunch = Date().timeIntervalSince1970 - appLaunchTime
                   if timeSinceLaunch < 3.0 {
                       print("⏭️ [RootView] Skipping purchase intent check - app still launching (\(Int(timeSinceLaunch))s)")
                       print("🔍 [RootView] checkForPurchaseIntentPrompt - Returned early (took \(Date().timeIntervalSince(funcStart))s)")
                       return
                   }
               }
               
               print("🔍 [RootView] Checking for purchase intent prompt...")
               
               // Fast check: UserDefaults read (synchronous but instant)
               let userDefaultsStart = Date()
               let shouldShow = UserDefaults.standard.bool(forKey: "shouldShowPurchaseIntentPrompt")
               let userDefaultsTime = Date().timeIntervalSince(userDefaultsStart)
               if userDefaultsTime > 0.01 {
                   print("⚠️ [RootView] WARNING: UserDefaults.bool read took \(userDefaultsTime)s (should be < 0.01s)")
               }
               
               if shouldShow {
                   print("✅ [RootView] shouldShowPurchaseIntentPrompt is true - showing prompt (intercepted before app launch)")
                   UserDefaults.standard.set(false, forKey: "shouldShowPurchaseIntentPrompt")
                   // Show immediately when app becomes active
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                       self.showPurchaseIntentPrompt = true
                       print("✅ [RootView] showPurchaseIntentPrompt set to: \(self.showPurchaseIntentPrompt)")
                   }
                   print("🔍 [RootView] ════════════════════════════════════════")
                   print("🔍 [RootView] checkForPurchaseIntentPrompt - Returned early (took \(Date().timeIntervalSince(funcStart))s)")
                   return
               }
               
               // CRITICAL: All property access must be in a detached task to avoid blocking
               // This ensures the function returns immediately and doesn't block MainActor
               // CRITICAL: Access services INSIDE the detached task to prevent initialization chain during startup
               let beforeDetached = Date()
               print("🔍 [RootView] checkForPurchaseIntentPrompt - Starting detached task at \(beforeDetached)")
               print("🔍 [RootView] checkForPurchaseIntentPrompt - Time before detached task: \(beforeDetached.timeIntervalSince(funcStart))s")
               
               Task.detached(priority: .utility) {
                   // CRITICAL: Access services INSIDE detached task to prevent blocking MainActor
                   // Accessing .shared triggers service init(), which can create an initialization chain
                   // Use MainActor.run to access MainActor-isolated properties
                   let quietHoursService = await MainActor.run {
                       QuietHoursService.shared
                   }
                   let deviceActivityService = await MainActor.run {
                       DeviceActivityService.shared
                   }
                   let detachedStart = Date()
                   print("🔍 [RootView] checkForPurchaseIntentPrompt - Detached task started at \(detachedStart)")
                   // Note: Thread.isMainThread is not available in async contexts in Swift 6
                   // This is a detached task, so it runs on a background thread
                   print("🔍 [RootView] checkForPurchaseIntentPrompt - Detached task running on background thread")
                   print("🔍 [RootView] checkForPurchaseIntentPrompt - Detached task priority: \(Task.currentPriority.rawValue)")
                   
                   // Fallback: Check if user likely saw blocking screen
                   // This handles cases where:
                   // 1. Extension didn't fire (common issue)
                   // 2. Schedule was active when blocking happened but isn't active now
                   // 3. User returns to Soteria after seeing restricted screen
                   
                   let now = Date().timeIntervalSince1970
                   let lastPromptTime = UserDefaults.standard.double(forKey: "lastPurchaseIntentPromptTime")
                   let timeSinceLastPrompt = now - lastPromptTime
                   
                   // CRITICAL: Access @Published properties on MainActor, but don't block
                   let beforeMainActor = Date()
                   print("🔍 [RootView] checkForPurchaseIntentPrompt - About to access @Published properties on MainActor at \(beforeMainActor)")
                   print("🔍 [RootView] checkForPurchaseIntentPrompt - Time before MainActor.run: \(beforeMainActor.timeIntervalSince(detachedStart))s")
                   
                   await MainActor.run {
                       let mainActorStart = Date()
                       print("🔍 [RootView] checkForPurchaseIntentPrompt - Inside MainActor.run at \(mainActorStart)")
                       print("🔍 [RootView] checkForPurchaseIntentPrompt - Time to enter MainActor.run: \(mainActorStart.timeIntervalSince(beforeMainActor))s")
                       // Note: Thread.isMainThread is not available in async contexts in Swift 6
                       // MainActor.run ensures we're on the main thread
                       print("🔍 [RootView] checkForPurchaseIntentPrompt - Running on MainActor (main thread)")
                       
                       // Check if any schedule is enabled (not just currently active)
                       // CRITICAL: Access schedules - they should be loaded by now (30s delay)
                       let schedulesStart = Date()
                       let schedules = quietHoursService.schedules
                       let schedulesTime = Date().timeIntervalSince(schedulesStart)
                       if schedulesTime > 0.1 {
                           print("⚠️ [RootView] WARNING: Accessing quietHoursService.schedules took \(schedulesTime)s (should be < 0.1s)")
                       }
                       let hasEnabledSchedule = schedules.contains { $0.isActive }
                       
                       // CRITICAL: Cache isQuietModeActive and isMonitoring to avoid blocking access
                       let isQuietModeActiveStart = Date()
                       let isQuietModeActive = quietHoursService.isQuietModeActive
                       let isQuietModeActiveTime = Date().timeIntervalSince(isQuietModeActiveStart)
                       if isQuietModeActiveTime > 0.1 {
                           print("⚠️ [RootView] WARNING: Accessing quietHoursService.isQuietModeActive took \(isQuietModeActiveTime)s (should be < 0.1s)")
                       }
                       
                       let isMonitoringStart = Date()
                       let cachedIsMonitoring = deviceActivityService.isMonitoring
                       let isMonitoringTime = Date().timeIntervalSince(isMonitoringStart)
                       if isMonitoringTime > 0.1 {
                           print("⚠️ [RootView] WARNING: Accessing deviceActivityService.isMonitoring took \(isMonitoringTime)s (should be < 0.1s)")
                       }
                       
                       print("🔍 [RootView] Checking fallback prompt conditions:")
                       print("   - Quiet Hours currently active: \(isQuietModeActive)")
                       print("   - Has enabled schedule: \(hasEnabledSchedule)")
                       print("   - Monitoring on: \(cachedIsMonitoring)")
                       print("   - Time since last prompt: \(Int(timeSinceLastPrompt))s")
                       print("🔍 [RootView] Property access times:")
                       print("   - schedules: \(schedulesTime)s")
                       print("   - isQuietModeActive: \(isQuietModeActiveTime)s")
                       print("   - isMonitoring: \(isMonitoringTime)s")
                       
                       // Show prompt if:
                       // 1. Monitoring is on (apps are being blocked)
                       // 2. At least one schedule is enabled (user has Quiet Hours set up)
                       // 3. Cooldown has expired
                       if cachedIsMonitoring && hasEnabledSchedule && timeSinceLastPrompt > 10.0 {
                           print("✅ [RootView] Showing fallback prompt (monitoring + enabled schedule)")
                           print("✅ [RootView] Setting showPurchaseIntentPrompt = true")
                           UserDefaults.standard.set(now, forKey: "lastPurchaseIntentPromptTime")
                           // Use NotificationCenter to update view state from detached task
                           NotificationCenter.default.post(name: NSNotification.Name("ShowPurchaseIntentPrompt"), object: nil)
                           print("✅ [RootView] Posted ShowPurchaseIntentPrompt notification")
                       } else {
                           if !cachedIsMonitoring {
                               print("⏭️ [RootView] Monitoring is off")
                           } else if !hasEnabledSchedule {
                               print("⏭️ [RootView] No enabled schedules")
                           } else {
                               print("⏭️ [RootView] Cooldown active (\(Int(timeSinceLastPrompt))s)")
                           }
                       }
                       
                       let mainActorEnd = Date()
                       print("🔍 [RootView] checkForPurchaseIntentPrompt - MainActor.run completed (took \(mainActorEnd.timeIntervalSince(mainActorStart))s)")
                       print("🔍 [RootView] ════════════════════════════════════════")
                   }
                   
                   let detachedEnd = Date()
                   print("🔍 [RootView] checkForPurchaseIntentPrompt - Detached task completed (total: \(detachedEnd.timeIntervalSince(detachedStart))s)")
               }
               
               let funcEnd = Date()
               print("🔍 [RootView] checkForPurchaseIntentPrompt - Function returned immediately (took \(funcEnd.timeIntervalSince(funcStart))s)")
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

