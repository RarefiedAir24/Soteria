import SwiftUI
import UserNotifications

// CRITICAL: Don't access ANY singletons at file level - they block MainActor
// Even accessing StartupDiagnostics.shared at file level can cause blocking

@main
struct SoteriaApp: App {
    // CRITICAL: Don't create AuthService at all - create it lazily when needed
    // Even creating StateObject can block MainActor
    @State private var authService: AuthService? = nil
    
    @State private var showPauseView = false
    @State private var showPurchaseLogPrompt = false
    @State private var showPurchaseIntentPrompt = false
    @State private var showPaywall = false

    init() {
        // CRITICAL: Do ABSOLUTELY NOTHING - don't even create AuthService
        // AuthService will be created only when user tries to sign in
        
        // Initialize Unit API token (safe to do here - just setting a string)
        UnitService.shared.setAPIToken("v2.public.eyJyb2xlIjoiYWRtaW4iLCJyb2xlcyI6WyJhZG1pbiJdLCJ1c2VySWQiOiI0Njk0MiIsInN1YiI6InN1cGVyZ2Vla0BtZS5jb20iLCJleHAiOiIyMDI2LTEyLTI1VDIwOjIwOjI4LjE0OFoiLCJqdGkiOiI1NjIzMjEiLCJvcmdJZCI6Ijg1OTkiLCJzY29wZSI6ImFwcGxpY2F0aW9ucyBhcHBsaWNhdGlvbnMtd3JpdGUgY3VzdG9tZXJzIGN1c3RvbWVycy13cml0ZSBjdXN0b21lci10YWdzLXdyaXRlIGN1c3RvbWVyLXRva2VuLXdyaXRlIGFjY291bnRzIGFjY291bnRzLXdyaXRlIGNhcmRzIGNhcmRzLXNlbnNpdGl2ZSB0cmFuc2FjdGlvbnMgYXV0aG9yaXphdGlvbnMgc3RhdGVtZW50cyBwYXltZW50cyBwYXltZW50cy13cml0ZSBwYXltZW50cy13cml0ZS1jb3VudGVycGFydHkgcGF5bWVudHMtd3JpdGUtbGlua2VkLWFjY291bnQgYWNoLXBheW1lbnRzLXdyaXRlIHdpcmUtcGF5bWVudHMtd3JpdGUgcmVwYXltZW50cyBwYXltZW50cy13cml0ZS1hY2gtZGViaXQgY291bnRlcnBhcnRpZXMgYmF0Y2gtcmVsZWFzZXMgYmF0Y2gtcmVsZWFzZXMtd3JpdGUgbGlua2VkLWFjY291bnRzIHdlYmhvb2tzIHdlYmhvb2tzLXdyaXRlIGV2ZW50cyBldmVudHMtd3JpdGUgYXV0aG9yaXphdGlvbi1yZXF1ZXN0cyBhdXRob3JpemF0aW9uLXJlcXVlc3RzLXdyaXRlIGNhc2gtZGVwb3NpdHMgY2FzaC1kZXBvc2l0cy13cml0ZSBjaGVjay1kZXBvc2l0cyBjaGVjay1kZXBvc2l0cy13cml0ZSByZWNlaXZlZC1wYXltZW50cyBkaXNwdXRlcyBjaGFyZ2ViYWNrcyByZXdhcmRzIGNoZWNrLXBheW1lbnRzIGNyZWRpdC1kZWNpc2lvbnMgbGVuZGluZy1wcm9ncmFtcyBjYXJkLWZyYXVkLWNhc2VzIGNyZWRpdC1hcHBsaWNhdGlvbnMgdGF4IHRheC13cml0ZSBmb3JtcyBmb3Jtcy1zZW5zaXRpdmUgd2lyZS1kcmF3ZG93bnMiLCJvcmciOiJTb3RlcmlhIiwic291cmNlSXAiOiIiLCJ1c2VyVHlwZSI6Im9yZyIsImlzVW5pdFBpbG90IjpmYWxzZSwiaXNQYXJlbnRPcmciOmZhbHNlfWTAKjltvgvOm3Yubjuzj8ubIjo7jYvMnEPCxDaYRzb9uh-05JLBxvU0rsPFHp8ee51Cnk-me54S0jAfh2HpggM")
    }
    
    private func getAuthService() -> AuthService {
        if authService == nil {
            authService = AuthService()
        }
        return authService!
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
        if #available(iOS 15.0, *) {
            let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
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
            RootView(showPauseView: $showPauseView, showPaywall: $showPaywall, getAuthService: getAuthService)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    // Handle deep links for goal invitations
                    if url.scheme == "soteria" {
                        handleDeepLink(url: url)
                    }
                }
        }
    }
    
    private func handleDeepLink(url: URL) {
        // Parse: soteria://goal/{goalId}/invite/{invitationId}
        guard url.host == "goal" else { return }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        if pathComponents.count >= 2 && pathComponents[1] == "invite" {
            let goalId = pathComponents[0]
            let invitationId = pathComponents.count >= 3 ? pathComponents[2] : ""
            
            // Store invitation info for when user signs in
            UserDefaults.standard.set(goalId, forKey: "pending_goal_invitation_goal_id")
            UserDefaults.standard.set(invitationId, forKey: "pending_goal_invitation_id")
            UserDefaults.standard.set(true, forKey: "has_pending_goal_invitation")
            
            print("✅ [SoteriaApp] Deep link received - goal: \(goalId), invitation: \(invitationId)")
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
        
        // Track that app was opened from notification
        let notificationType = userInfo["type"] as? String ?? "unknown"
        UserDefaults.standard.set(true, forKey: "openedFromNotification")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "notificationTapTime")
        UserDefaults.standard.set(notificationType, forKey: "lastNotificationType")
        if let appName = userInfo["appName"] as? String {
            UserDefaults.standard.set(appName, forKey: "lastNotificationAppName")
        }
        print("✅ [App] Tracked notification tap - type: \(notificationType)")
        
        if userInfo["type"] as? String == "soteria_moment" {
            print("✅ [App] SOTERIA Moment notification detected - opening PauseView")
            // CRITICAL: Only record shopping attempt for premium subscribers
            // Quiet hours and purchase intent are premium features
            if SubscriptionService.shared.isPremium {
                DeviceActivityService.shared.recordShoppingAttempt()
            }
            DispatchQueue.main.async {
                self.showPauseView?()
            }
        } else if userInfo["type"] as? String == "purchase_log_prompt" {
            print("✅ [App] Purchase log prompt notification detected - opening PurchaseLogPromptView")
            DispatchQueue.main.async {
                self.showPurchaseLogPrompt?()
            }
        } else if userInfo["type"] as? String == "purchase_intent_prompt" {
            // CRITICAL: Purchase intent prompts are premium features - check subscription first
            let isPremium = SubscriptionService.shared.isPremium
            guard isPremium else {
                print("⏭️ [App] Purchase intent prompt is a premium feature - user is not subscribed")
                return
            }
            
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
                print("✅ [App] Purchase intent prompt notification detected - will show PurchaseIntentPromptView")
                // Post notification instead of calling closure directly - more reliable
                DispatchQueue.main.async {
                    print("✅ [App] Posting ShowPurchaseIntentPrompt notification")
                    NotificationCenter.default.post(name: NSNotification.Name("ShowPurchaseIntentPrompt"), object: nil)
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

// Helper to check if app was opened from notification
struct NotificationOpenTracker {
    /// Check if app was opened from a notification tap (deprecated - use check() instead)
    /// Returns: (wasOpenedFromNotification: Bool, notificationType: String?, appName: String?, tapTime: Date?)
    static func checkAndClear() -> (Bool, String?, String?, Date?) {
        // Just call check() - clearing is now handled separately
        return check()
    }
    
    /// Check if app was opened from notification without clearing the flag (for multiple checks)
    static func check() -> (Bool, String?, String?, Date?) {
        let wasOpened = UserDefaults.standard.bool(forKey: "openedFromNotification")
        
        if wasOpened {
            let notificationType = UserDefaults.standard.string(forKey: "lastNotificationType")
            let appName = UserDefaults.standard.string(forKey: "lastNotificationAppName")
            let tapTimeInterval = UserDefaults.standard.double(forKey: "notificationTapTime")
            let tapTime = tapTimeInterval > 0 ? Date(timeIntervalSince1970: tapTimeInterval) : nil
            
            print("✅ [NotificationOpenTracker] Check (no clear) - type: \(notificationType ?? "unknown"), app: \(appName ?? "none")")
            
            return (true, notificationType, appName, tapTime)
        }
        
        return (false, nil, nil, nil)
    }
    
    /// Clear the notification flag (call after prompt is shown)
    static func clear() {
        UserDefaults.standard.set(false, forKey: "openedFromNotification")
        UserDefaults.standard.removeObject(forKey: "notificationTapTime")
        UserDefaults.standard.removeObject(forKey: "lastNotificationType")
        UserDefaults.standard.removeObject(forKey: "lastNotificationAppName")
        print("✅ [NotificationOpenTracker] Cleared notification flag")
    }
}

struct RootView: View {
    // CRITICAL: Don't use @EnvironmentObject - it blocks MainActor
    // Get authService only when needed
    let getAuthService: () -> AuthService
    @Binding var showPauseView: Bool
    @Binding var showPaywall: Bool
    @State private var isAppReady = false // Start as false to show splash screen
    @State private var authService: AuthService? = nil // Lazy: Only create when needed
    @State private var isAuthenticated = false // Track auth state locally
    @State private var authCheckTimer: Timer? = nil // Timer for periodic auth checks
    @State private var showGoalInvitation = false
    @State private var pendingInvitationGoalId: String? = nil
    @State private var pendingInvitationId: String? = nil
    
    init(showPauseView: Binding<Bool>, showPaywall: Binding<Bool>, getAuthService: @escaping () -> AuthService) {
        // CRITICAL: Do ABSOLUTELY NOTHING - no logging, no work
        self._showPauseView = showPauseView
        self._showPaywall = showPaywall
        self.getAuthService = getAuthService
    }

    var body: some View {
        // Show splash screen first, then auth or main app
        Group {
            if !isAppReady {
                SplashScreenView()
                    .onAppear {
                        // Set ready after a delay to show splash (1.5 seconds to see the logo)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isAppReady = true
                        }
                    }
            } else {
                // Check authentication status
                if isAuthenticated, let authService = authService {
                    // User is authenticated - show main app (onboarding or main tabs)
                    OnboardingSurveyWrapper()
                        .environmentObject(authService)
                } else {
                    // User is not authenticated - show sign-in
                    AuthView_Simplified(getAuthService: getAuthService)
                        .onAppear {
                            // Check for pending goal invitation
                            if UserDefaults.standard.bool(forKey: "has_pending_goal_invitation") {
                                pendingInvitationGoalId = UserDefaults.standard.string(forKey: "pending_goal_invitation_goal_id")
                                pendingInvitationId = UserDefaults.standard.string(forKey: "pending_goal_invitation_id")
                            }
                        }
                        .onChange(of: isAuthenticated) { oldValue, newValue in
                            // When user signs in, check if they have a pending invitation
                            if newValue && UserDefaults.standard.bool(forKey: "has_pending_goal_invitation") {
                                pendingInvitationGoalId = UserDefaults.standard.string(forKey: "pending_goal_invitation_goal_id")
                                pendingInvitationId = UserDefaults.standard.string(forKey: "pending_goal_invitation_id")
                                showGoalInvitation = true
                            }
                        }
                        .onAppear {
                            // Check auth state when view appears (non-blocking)
                            checkAuthState()
                            
                            // Also check periodically in case auth state changes
                            // Store timer in state so we can invalidate it later
                            authCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                                // Stop checking once authenticated
                                if isAuthenticated {
                                    timer.invalidate()
                                    authCheckTimer = nil
                                    return
                                }
                                checkAuthState()
                            }
                        }
                        .onDisappear {
                            // Clean up timer when view disappears
                            authCheckTimer?.invalidate()
                            authCheckTimer = nil
                        }
                        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidSignIn"))) { _ in
                            // Listen for sign-in success notification - check immediately
                            if authService == nil {
                                authService = getAuthService()
                            }
                            // Check auth state immediately (sign-in just completed)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let authService = self.authService {
                                    self.isAuthenticated = authService.isAuthenticated
                                    print("✅ [RootView] Auth state updated after sign-in: \(authService.isAuthenticated)")
                                }
                            }
                        }
                }
            }
        }
    }
    
    private func checkAuthState() {
        // Lazy: Only create AuthService when checking auth state
        if authService == nil {
            authService = getAuthService()
        }
        
        // Check auth state immediately (non-blocking)
        if let authService = authService {
            isAuthenticated = authService.isAuthenticated
        }
    }
    
           // Check if we should show purchase intent prompt
           // CRITICAL: COMPLETELY DISABLED - Accessing services blocks MainActor for 60+ seconds
           // This function will be re-enabled only when explicitly needed (e.g., after app blocking)
           private func checkForPurchaseIntentPrompt() {
               // COMPLETELY DISABLED - Do nothing to prevent MainActor blocking
               print("⏭️ [RootView] checkForPurchaseIntentPrompt() - DISABLED to prevent MainActor blocking")
               return
               
               // DISABLED CODE - All code below is unreachable due to early return above
               /*
               // Guard: Don't check during app launch (first 3 seconds) to prevent startup blocking
               let funcStart = Date()
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
               
               // CRITICAL: DISABLED - Accessing services blocks MainActor for 60+ seconds
               // Even accessing .shared triggers initialization that can block
               // This check will be re-enabled only when user explicitly needs it (e.g., after app blocking)
               print("⏭️ [RootView] checkForPurchaseIntentPrompt - DISABLED to prevent MainActor blocking")
               return
               
               // DISABLED CODE - Re-enable only when needed
               /*
               DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                   
                   let asyncStart = Date()
                   print("🔍 [RootView] checkForPurchaseIntentPrompt - Async task started at \(asyncStart)")
                   
                   // Access services on MainActor (they're already MainActor-isolated)
                   let quietHoursService = QuietHoursService.shared
                   let deviceActivityService = DeviceActivityService.shared
                   
                   // Fallback: Check if user likely saw blocking screen
                   // This handles cases where:
                   // 1. Extension didn't fire (common issue)
                   // 2. Schedule was active when blocking happened but isn't active now
                   // 3. User returns to Soteria after seeing restricted screen
                   
                   let now = Date().timeIntervalSince1970
                   let lastPromptTime = UserDefaults.standard.double(forKey: "lastPurchaseIntentPromptTime")
                   let timeSinceLastPrompt = now - lastPromptTime
                   
                   // Check if any schedule is enabled (not just currently active)
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
                       // Use NotificationCenter to update view state from async closure
                       NotificationCenter.default.post(name: NSNotification.Name("ShowPurchaseIntentPrompt"), object: nil)
                   } else {
                       if !cachedIsMonitoring {
                           print("⏭️ [RootView] Monitoring is off")
                       } else if !hasEnabledSchedule {
                           print("⏭️ [RootView] No enabled schedules")
                       } else {
                           print("⏭️ [RootView] Cooldown active (\(Int(timeSinceLastPrompt))s)")
                       }
                   }
                   
                   let asyncEnd = Date()
                   print("🔍 [RootView] checkForPurchaseIntentPrompt - Async task completed (took \(asyncEnd.timeIntervalSince(asyncStart))s)")
                   print("🔍 [RootView] ════════════════════════════════════════")
               }
               */
               
               let funcEnd = Date()
               print("🔍 [RootView] checkForPurchaseIntentPrompt - Function returned immediately (took \(funcEnd.timeIntervalSince(funcStart))s)")
               */
           }
           
           // DISABLED: All purchase intent and shopping session checks deferred
           // These will be re-enabled when needed, after app is fully loaded
           private func checkForRecentShoppingSession() {
               // Deferred - not needed for minimal splash/sign-in flow
           }
}

// CRITICAL: Conditional sheet modifier to prevent eager evaluation during startup
// Only applies sheets when shouldApply is true - prevents any evaluation when false
// Renamed from ConditionalSheetModifier to avoid conflict with SettingsView's modifier
// DISABLED: RootViewSheetModifier - all sheets deferred until needed
// struct RootViewSheetModifier: ViewModifier {
//     ... disabled to prevent MainActor blocking
// }

// Wrapper to observe onboarding survey completion
struct OnboardingSurveyWrapper: View {
    // CRITICAL: Use @StateObject with lazy initialization to prevent blocking
    // This ensures the service is only created when the view is actually displayed
    @StateObject private var surveyService = OnboardingSurveyService.shared
    @EnvironmentObject var authService: AuthService
    @State private var showUnitAccountBanner = false
    
    var body: some View {
        Group {
            if !surveyService.hasCompletedSurvey {
                OnboardingSurveyView()
                    .id("onboarding-survey")
                    .onAppear {
                        // Check if we should show Unit account banner after onboarding
                        checkForUnitAccountPrompt()
                    }
            } else {
                let mainTabStart = Date()
                let mainTabView = MainTabView()
                let _ = {
                    let mainTabDuration = Date().timeIntervalSince(mainTabStart)
                    if mainTabDuration > 0.01 {
                        StartupDiagnostics.shared.log("⚠️ [RootView] MainTabView() creation took \(String(format: "%.3f", mainTabDuration))s")
                    } else {
                        StartupDiagnostics.shared.log("✅ [RootView] MainTabView() creation completed (fast)")
                    }
                }()
                mainTabView
                    .id("main-tab-view")
                    .sheet(isPresented: $showUnitAccountBanner) {
                        UnitAccountCreationBanner(onDismiss: {
                            showUnitAccountBanner = false
                        })
                        .environmentObject(authService)
                    }
                    .onAppear {
                        // Show Unit account banner if needed (after onboarding completes)
                        checkForUnitAccountPrompt()
                    }
            }
        }
    }
    
    private func checkForUnitAccountPrompt() {
        // Only show if:
        // 1. User just signed up (not returning user)
        // 2. Haven't shown the prompt before
        // 3. Haven't created a Unit account yet
        
        let isNewSignUp = UserDefaults.standard.bool(forKey: "is_new_signup")
        let hasShownPrompt = UserDefaults.standard.bool(forKey: "unit_account_creation_prompt_shown")
        let hasUnitAccount = UserDefaults.standard.bool(forKey: "unit_account_created")
        
        if isNewSignUp && !hasShownPrompt && !hasUnitAccount {
            // Small delay to ensure smooth transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showUnitAccountBanner = true
            }
        }
    }
}

