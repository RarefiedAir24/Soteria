//
//  SettingsView.swift
//  rever
//
//  Settings with behavioral features
//

import SwiftUI
// TEMPORARILY DISABLED: Firebase imports - testing if they're causing crash
// import FirebaseAuth
import UIKit
import FamilyControls
// #if canImport(FirebaseStorage)
// import FirebaseStorage
// #endif

// Separate view to ensure binding is only created when sheet is shown
struct AppSelectionSheetContent: View {
    @ObservedObject var deviceActivityService: DeviceActivityService
    @ObservedObject var subscriptionService: SubscriptionService
    @Binding var showAppSelection: Bool
    
    var body: some View {
        LazyAppSelectionView(
            selection: Binding(
                get: { deviceActivityService.selectedApps },
                set: { newValue in
                    // FIXED: Ensure selection is saved when picker closes
                    // FamilyActivityPicker should restore previous selection automatically,
                    // but we need to ensure it's properly saved
                    print("🔄 [AppSelectionSheetContent] Selection changed - saving")
                    deviceActivityService.selectedApps = newValue
                }
            ),
            isPresented: $showAppSelection,
            maxApps: subscriptionService.isPremium ? nil : 1
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onChange(of: showAppSelection) { oldValue, newValue in
            // When picker closes, ensure selection is persisted
            if !newValue {
                print("🔄 [AppSelectionSheetContent] Picker closed - selection should be persisted by system")
                // The system should persist FamilyActivitySelection automatically,
                // but we ensure the count is cached
                deviceActivityService.ensureDataLoaded()
            }
        }
    }
}

// MARK: - Lazy Profile View Wrapper

struct LazyProfileView: View {
    var body: some View {
        // ProfileView is pushed onto the existing NavigationView stack from MainTabView
        // It already has .navigationTitle("Profile") set, so it should work correctly
        ProfileView()
            .navigationBarBackButtonHidden(false)
    }
}

// View modifier to conditionally apply sheet only when app is loaded
// CRITICAL: This prevents SwiftUI from evaluating the binding during startup
struct ConditionalSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let isAppFullyLoaded: Bool
    @ObservedObject var deviceActivityService: DeviceActivityService
    @ObservedObject var subscriptionService: SubscriptionService
    
    func body(content: Content) -> some View {
        // CRITICAL: Only apply sheet modifier when app is fully loaded
        // This prevents SwiftUI from evaluating the binding during startup
        if isAppFullyLoaded {
            content
                .sheet(isPresented: $isPresented) {
                    AppSelectionSheetContent(
                        deviceActivityService: deviceActivityService,
                        subscriptionService: subscriptionService,
                        showAppSelection: $isPresented
                    )
                }
        } else {
            content
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    @EnvironmentObject var quietHoursService: QuietHoursService
    @EnvironmentObject var subscriptionService: SubscriptionService
    // @EnvironmentObject var plaidService: PlaidService  // Temporarily disabled - Plaid removed
    @State private var showAppSelection = false
    @State private var viewId = UUID()
    @State private var showStartMonitoringConfirmation = false
    @State private var pendingToggleState = false
    @State private var isStartingMonitoring = false
    @State private var showQuietHours = false
    @State private var showMoodCheckIn = false
    @State private var showRegretLog = false
    // App naming is now fully automatic via backend - no user editing needed
    // Removed: showAppNaming, showAppManagement (no longer needed)
    @State private var showMetrics = false
    @State private var showPaywall = false
    // Use cached count from DeviceActivityService instead of accessing selectedApps directly
    @State private var isViewReady = false  // Track if view is ready to observe changes
    @State private var isAppFullyLoaded = false  // Track if app initialization is complete
    @State private var cachedIsMonitoring = false  // Cache to avoid accessing @Published during view evaluation
    @State private var avatarImage: UIImage? = nil
    @State private var showProfileView = false
    
    // Computed property to check if any schedule is enabled (toggle ON)
    private var hasActiveQuietHoursSchedule: Bool {
        quietHoursService.schedules.contains { $0.isActive }
    }
    
    // Extract ScrollView content to help compiler type-check
    private var scrollContent: some View {
        ScrollView {
                Color.clear
                    .frame(height: 60)
                
                VStack(spacing: .spacingCard) {
                    // Account & Subscription Card
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: {
                            print("🔵 [SettingsView] Account button tapped - setting showProfileView = true")
                            showProfileView = true
                            print("🔵 [SettingsView] showProfileView is now: \(showProfileView)")
                        }) {
                            HStack(spacing: 12) {
                                // Avatar - wrapped in Group to prevent re-evaluation from affecting navigation
                                Group {
                                    if let avatarImage = avatarImage {
                                        Image(uiImage: avatarImage)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        // Default avatar
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.deepReverBlue, Color.reverBlue],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                            
                                            if let user = authService.currentUser, let email = user.email {
                                                Text(String((email.components(separatedBy: "@").first ?? "U").prefix(1)).uppercased())
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Account")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color.softGraphite)
                                    
                                    if let user = authService.currentUser {
                                        Text(user.email ?? "Unknown User")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.midnightSlate)
                                        
                                        Text("Manage account, banking & preferences")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.softGraphite)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.softGraphite)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                        
                        // Subscription Status
                        HStack {
                            Image(systemName: subscriptionService.isPremium ? "crown.fill" : "crown")
                                .font(.system(size: 20))
                                .foregroundColor(subscriptionService.isPremium ? Color.reverBlue : .softGraphite)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subscriptionService.isPremium ? "Premium" : "Free")
                                    .reverBody()
                                    .fontWeight(.semibold)
                                    .foregroundColor(.midnightSlate)
                                
                                if !subscriptionService.isPremium {
                                    Text("Upgrade for advanced features")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            if !subscriptionService.isPremium {
                                Button(action: {
                                    showPaywall = true
                                }) {
                                    Text("Upgrade")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.reverBlue)
                                        )
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .reverCard()
                    .padding(.horizontal, .spacingCard)
                    
                    // Behavioral Features Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Behavioral Features")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.midnightSlate)
                        
                        // Quiet Hours
                        SettingsRow(
                            icon: "moon.fill",
                            title: "Quiet Hours",
                            subtitle: hasActiveQuietHoursSchedule ? "Active" : "Inactive",
                            color: hasActiveQuietHoursSchedule ? Color.reverBlue : .gray
                        ) {
                            showQuietHours = true
                        }
                        
                        Divider()
                        
                        // Mood Check-In
                        SettingsRow(
                            icon: "heart.fill",
                            title: "Mood Check-In",
                            subtitle: "Track your mood",
                            color: Color.reverBlue
                        ) {
                            showMoodCheckIn = true
                        }
                        
                        Divider()
                        
                        // Regret Log
                        SettingsRow(
                            icon: "exclamationmark.triangle.fill",
                            title: "Regret Log",
                            subtitle: "View regret purchases",
                            color: .orange
                        ) {
                            showRegretLog = true
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .reverCard()
                    .padding(.horizontal, .spacingCard)
                    
                    // App Monitoring Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "app.badge.checkmark")
                                .font(.system(size: 24))
                                .foregroundColor(Color.reverBlue)
                            
                            Text("App Monitoring")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.midnightSlate)
                            
                            Spacer()
                        }
                        
                        // Select Apps Button
                        Button(action: {
                            // Free tier: Limit to 1 app
                            if !subscriptionService.isPremium && deviceActivityService.cachedAppsCount >= 1 {
                                showPaywall = true
                            } else {
                                showAppSelection = true
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Select Apps to Monitor")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.midnightSlate)
                                    
                                    if deviceActivityService.cachedAppsCount > 0 {
                                        Text("\(deviceActivityService.cachedAppsCount) app\(deviceActivityService.cachedAppsCount == 1 ? "" : "s") selected")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.softGraphite)
                                    } else {
                                        Text("No apps selected")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.softGraphite)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.softGraphite)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.mistGray)
                            )
                        }
                        
                        // App names are auto-managed by backend - no user editing needed
                        
                        // Metrics Dashboard button
                        Button(action: {
                            showMetrics = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View Metrics")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.midnightSlate)
                                    
                                    Text("Unblock requests and app usage")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.softGraphite)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.reverBlue)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.softGraphite)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.mistGray)
                            )
                        }
                        
                        // Savings Settings button (temporarily disabled - Plaid lazy loading in progress)
                        /*
                        NavigationLink(destination: SavingsSettingsView()) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Savings Settings")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.midnightSlate)
                                    
                                    Text("Connect accounts & manage savings")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.softGraphite)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.reverBlue)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.softGraphite)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.mistGray)
                            )
                        }
                        */
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // Monitoring Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Monitoring")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.midnightSlate)
                                
                                if isStartingMonitoring {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color.reverBlue))
                                            .frame(width: 14, height: 14)
                                        Text("Starting monitoring...")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.reverBlue)
                                    }
                                } else if cachedIsMonitoring {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.green)
                                        Text("Active")
                                            .font(.system(size: 13))
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    Text("Inactive")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.softGraphite)
                                }
                            }
                            
                            Spacer()
                            
                            Group {
                                if isStartingMonitoring {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.reverBlue))
                                        .frame(width: 30, height: 30)
                                } else {
                                    Toggle("", isOn: Binding(
                                        get: { cachedIsMonitoring },
                                        set: { newValue in
                                            if newValue {
                                                pendingToggleState = true
                                                showStartMonitoringConfirmation = true
                                            } else {
                                                // Stop monitoring asynchronously to avoid blocking
                                                Task { @MainActor in
                                                    deviceActivityService.stopMonitoring()
                                                    viewId = UUID()
                                                }
                                            }
                                        }
                                    ))
                                    .toggleStyle(.switch)
                                    .tint(Color.reverBlue)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mistGray)
                        )
                        // FIXED: Only disable if no apps selected OR if monitoring is starting
                        // Note: User must select apps via "Select Apps to Monitor" button first
                        // Quiet Hours app selection is separate from monitoring app selection
                        .disabled(deviceActivityService.cachedAppsCount == 0 || isStartingMonitoring)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .reverCard()
                    .padding(.horizontal, .spacingCard)
                    
                    // Sign Out Button
                    Button(action: {
                        try? authService.signOut()
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
        }
    }
    
    var body: some View {
        let _ = {
            let timestamp = Date()
            print("🟢 [SettingsView] body evaluated at \(timestamp)")
        }()
        
        return ZStack(alignment: .top) {
            // REVER background
            Color.mistGray
                .ignoresSafeArea(.all, edges: .top)
            Color.cloudWhite
                .ignoresSafeArea()
            
            scrollContent
            
            // Fixed Header
            VStack(spacing: 2) {
                Text("Settings")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color.midnightSlate)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Color(red: 0.92, green: 0.97, blue: 0.94)
                    .ignoresSafeArea(edges: .top)
            )
            .zIndex(100)
        }
        // CRITICAL: Conditionally apply sheet modifier to prevent SwiftUI from evaluating binding during startup
        .modifier(ConditionalSheetModifier(
            isPresented: $showAppSelection,
            isAppFullyLoaded: isAppFullyLoaded,
            deviceActivityService: deviceActivityService,
            subscriptionService: subscriptionService
        ))
        // App naming is fully automatic via backend - no user editing sheets needed
        .sheet(isPresented: $showMetrics) {
            MetricsDashboardView()
                .environmentObject(deviceActivityService)
                .environmentObject(subscriptionService)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .fullScreenCover(isPresented: $showQuietHours) {
            NavigationView {
                QuietHoursView()
                    .environmentObject(quietHoursService)
                    .environmentObject(subscriptionService)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showQuietHours = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showMoodCheckIn) {
            NavigationView {
                MoodCheckInView()
                    .environmentObject(MoodTrackingService.shared)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showMoodCheckIn = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showRegretLog) {
            NavigationView {
                RegretLogView()
                    .environmentObject(RegretLoggingService.shared)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showRegretLog = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showProfileView) {
            NavigationView {
                LazyProfileView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                print("🔵 [SettingsView] Done button tapped - setting showProfileView = false")
                                showProfileView = false
                            }
                        }
                    }
            }
            .onAppear {
                print("🔵 [SettingsView] Profile sheet appeared")
            }
        }
        .onChange(of: showProfileView) { oldValue, newValue in
            print("🔵 [SettingsView] showProfileView changed from \(oldValue) to \(newValue)")
        }
        .onChange(of: showAppSelection) {
            if !showAppSelection {
                viewId = UUID()
                // When app selection sheet closes, cached count is already updated by didSet
                // Just refresh the view
                viewId = UUID()
            }
        }
        .onAppear {
            let timestamp = Date()
            print("🟢 [SettingsView] onAppear at \(timestamp)")
        }
        .task {
            let taskStartTime = Date()
            print("🟢 [SettingsView] .task started at \(taskStartTime)")
            
            // CRITICAL: Defer data loading to avoid blocking app startup
            // SettingsView might be created during startup even if not visible
            // Wait 5 seconds before loading to ensure app is fully launched
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            
            // CRITICAL FIX: Ensure DeviceActivityService data is loaded (monitoring state, app count, etc.)
            // This fixes the issue where monitoring toggle doesn't work because data isn't loaded
            // DeviceActivityService.init() does nothing to prevent startup delays
            deviceActivityService.ensureDataLoaded()
            
            // Wait a moment for data to load, then cache isMonitoring
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            cachedIsMonitoring = deviceActivityService.isMonitoring
            print("🟡 [SettingsView] Cached isMonitoring: \(cachedIsMonitoring)")
            
            // OPTION 1 FIX: Load schedules on-demand when SettingsView appears
            // This fixes the issue where schedules weren't loading on app launch
            // (QuietHoursService.init() does nothing to prevent startup delays)
            // SettingsView displays "Active/Inactive" status which requires schedules to be loaded
            quietHoursService.ensureSchedulesLoaded()
            
            // Load avatar (only once)
            loadAvatar()
            
            // Mark view as ready immediately - no need to wait
            isViewReady = true
            
            // Wait for app to be fully loaded before enabling sheet
            // This prevents SwiftUI from evaluating the binding during startup
            // Use a longer delay to ensure everything is loaded
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            isAppFullyLoaded = true
            print("🟡 [SettingsView] App fully loaded - sheet is now available")
            let taskEndTime = Date()
            print("🟢 [SettingsView] .task completed at \(taskEndTime) (total: \(taskEndTime.timeIntervalSince(taskStartTime))s)")
        }
        // REMOVED: onChange observation of .applicationTokens.count
        // This was causing 2-minute lockup because SwiftUI evaluates the property
        // when setting up the observation, and that evaluation blocks.
        // Instead, we update the count in .task and when selection actually changes
        // (which happens when showAppSelection closes)
        .onChange(of: deviceActivityService.isMonitoring) { oldValue, newValue in
            // Update cached value when it changes
            // Use the parameter instead of accessing the property again
            print("🔄 [SettingsView] isMonitoring changed from \(oldValue) to \(newValue)")
            cachedIsMonitoring = newValue
            viewId = UUID()
        }
        .onChange(of: cachedIsMonitoring) { oldValue, newValue in
            print("🔄 [SettingsView] cachedIsMonitoring changed from \(oldValue) to \(newValue)")
        }
        .alert("Start Monitoring", isPresented: $showStartMonitoringConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingToggleState = false
            }
            Button("Start", role: .none) {
                isStartingMonitoring = true
                pendingToggleState = false
                viewId = UUID()
                
                Task {
                    print("🔄 [SettingsView] Starting monitoring...")
                    do {
                        // Add timeout to prevent infinite hanging
                        try await withTimeout(seconds: 10) {
                            await deviceActivityService.startMonitoring()
                        }
                        print("✅ [SettingsView] Monitoring started successfully")
                        await MainActor.run {
                            self.isStartingMonitoring = false
                            self.viewId = UUID()
                            self.showStartMonitoringConfirmation = false
                        }
                    } catch {
                        print("❌ [SettingsView] Error or timeout starting monitoring: \(error)")
                        await MainActor.run {
                            self.isStartingMonitoring = false
                            self.viewId = UUID()
                            self.showStartMonitoringConfirmation = false
                        }
                    }
                }
            }
        } message: {
            Text("SOTERIA will monitor \(deviceActivityService.cachedAppsCount) selected app\(deviceActivityService.cachedAppsCount == 1 ? "" : "s") and send you notifications when you open them. Continue?")
        }
        .onChange(of: isStartingMonitoring) {
            viewId = UUID()
        }
    }
    
    private func loadAvatar() {
        // First try to load from UserDefaults (fast, local cache)
        if let data = UserDefaults.standard.data(forKey: "user_avatar"),
           let image = UIImage(data: data) {
            avatarImage = image
        }
        
        // Then try to load from Firebase Storage (async, for cross-device sync)
        #if canImport(FirebaseStorage)
        if let userId = authService.currentUser?.userId {
            Task {
                let storageRef = Storage.storage().reference().child("avatars/\(userId).jpg")
                
                do {
                    let data = try await storageRef.data(maxSize: 5 * 1024 * 1024) // 5MB max
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            avatarImage = image
                            // Update UserDefaults cache
                            if let imageData = image.jpegData(compressionQuality: 0.8) {
                                UserDefaults.standard.set(imageData, forKey: "user_avatar")
                            }
                        }
                        print("✅ [SettingsView] Avatar loaded from Firebase Storage")
                    }
                } catch {
                    // Avatar doesn't exist in Firebase Storage yet, or error loading
                    // This is fine - UserDefaults might have it, or user hasn't uploaded one
                    print("ℹ️ [SettingsView] Avatar not found in Firebase Storage (this is OK)")
                }
            }
        }
        #endif
    }
}

// Helper function to add timeout to async operations
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.midnightSlate)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color.softGraphite)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.softGraphite)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mistGray)
            )
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
        .environmentObject(DeviceActivityService.shared)
        .environmentObject(QuietHoursService.shared)
}
