//
//  SettingsView.swift
//  rever
//
//  Settings with behavioral features
//

import SwiftUI
import FirebaseAuth
import UIKit
import FamilyControls
#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

// Separate view to ensure binding is only created when sheet is shown
struct AppSelectionSheetContent: View {
    @ObservedObject var deviceActivityService: DeviceActivityService
    @ObservedObject var subscriptionService: SubscriptionService
    @Binding var showAppSelection: Bool
    
    var body: some View {
        LazyAppSelectionView(
            selection: Binding(
                get: { deviceActivityService.selectedApps },
                set: { deviceActivityService.selectedApps = $0 }
            ),
            isPresented: $showAppSelection,
            maxApps: subscriptionService.isPremium ? nil : 1
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
    @State private var showAppNaming = false
    @State private var showAppManagement = false
    @State private var showMetrics = false
    @State private var showPaywall = false
    // Use cached count from DeviceActivityService instead of accessing selectedApps directly
    @State private var isViewReady = false  // Track if view is ready to observe changes
    @State private var isAppFullyLoaded = false  // Track if app initialization is complete
    @State private var cachedIsMonitoring = false  // Cache to avoid accessing @Published during view evaluation
    @State private var avatarImage: UIImage? = nil
    @State private var showProfileView = false
    
    var body: some View {
        let _ = {
            let timestamp = Date()
            print("🟢 [SettingsView] body evaluated at \(timestamp)")
        }()
        
        return ZStack(alignment: .top) {
            // Consistent background that extends to safe area
            Color(red: 0.95, green: 0.95, blue: 0.95)
                .ignoresSafeArea(.all, edges: .top)
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView {
                Color.clear
                    .frame(height: 60)
                
                VStack(spacing: 20) {
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
                                                        colors: [Color.themePrimaryDark, Color.themePrimaryLight],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                            
                                            if let user = authService.currentUser {
                                                Text(String((user.email?.components(separatedBy: "@").first ?? "U").prefix(1)).uppercased())
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
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                    
                                    if let user = authService.currentUser {
                                        Text(user.email ?? "Unknown")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                        
                                        Text("Manage account, banking & preferences")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                        
                        // Subscription Status
                        HStack {
                            Image(systemName: subscriptionService.isPremium ? "crown.fill" : "crown")
                                .font(.system(size: 20))
                                .foregroundColor(subscriptionService.isPremium ? Color.themePrimary : .gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subscriptionService.isPremium ? "Premium" : "Free")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
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
                                                .fill(Color.themePrimary)
                                        )
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Behavioral Features Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Behavioral Features")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        // Quiet Hours
                        SettingsRow(
                            icon: "moon.fill",
                            title: "Quiet Hours",
                            subtitle: quietHoursService.isQuietModeActive ? "Active" : "Inactive",
                            color: quietHoursService.isQuietModeActive ? Color.themePrimary : .gray
                        ) {
                            showQuietHours = true
                        }
                        
                        Divider()
                        
                        // Mood Check-In
                        SettingsRow(
                            icon: "heart.fill",
                            title: "Mood Check-In",
                            subtitle: "Track your mood",
                            color: Color.themePrimary
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
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // App Monitoring Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "app.badge.checkmark")
                                .font(.system(size: 24))
                                .foregroundColor(Color.themePrimary)
                            
                            Text("App Monitoring")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
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
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    
                                    if deviceActivityService.cachedAppsCount > 0 {
                                        Text("\(deviceActivityService.cachedAppsCount) app\(deviceActivityService.cachedAppsCount == 1 ? "" : "s") selected")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                    } else {
                                        Text("No apps selected")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                            )
                        }
                        
                        // Manage Apps button (only show if apps are selected)
                        if deviceActivityService.cachedAppsCount > 0 {
                            Button(action: {
                                showAppManagement = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Manage App Names")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                        
                                        Text("Rename or review selected apps")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                )
                            }
                        }
                        
                        // Metrics Dashboard button
                        Button(action: {
                            showMetrics = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View Metrics")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    
                                    Text("Unblock requests and app usage")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.themePrimary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                            )
                        }
                        
                        // Savings Settings button (temporarily disabled - Plaid lazy loading in progress)
                        /*
                        NavigationLink(destination: SavingsSettingsView()) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Savings Settings")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    
                                    Text("Connect accounts & manage savings")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.themePrimary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
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
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
                                if isStartingMonitoring {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color.themePrimary))
                                            .frame(width: 14, height: 14)
                                        Text("Starting monitoring...")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.themePrimary)
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
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                }
                            }
                            
                            Spacer()
                            
                            Group {
                                if isStartingMonitoring {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.themePrimary))
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
                                    .tint(Color.themePrimary)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                        )
                        .disabled(deviceActivityService.cachedAppsCount == 0 || isStartingMonitoring)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
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
            
            // Fixed Header
            VStack(spacing: 2) {
                Text("Settings")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
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
        .onDisappear {
                // After app selection, show naming screen if apps were selected
                // Defer this check to avoid blocking
                Task { @MainActor in
                    if deviceActivityService.cachedAppsCount > 0 {
                        // Check if any apps need naming (async to avoid blocking)
                        let needsNaming = (0..<deviceActivityService.cachedAppsCount).contains { index in
                            deviceActivityService.getAppName(forIndex: index) == "App \(index + 1)"
                        }
                        if needsNaming {
                            showAppNaming = true
                        }
                    }
                }
            }
        .sheet(isPresented: $showAppNaming) {
            AppNamingView()
                .environmentObject(deviceActivityService)
        }
        .sheet(isPresented: $showAppManagement) {
            AppManagementView()
                .environmentObject(deviceActivityService)
        }
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
            // Cache isMonitoring immediately to avoid accessing @Published during view evaluation
            cachedIsMonitoring = deviceActivityService.isMonitoring
            print("🟡 [SettingsView] Cached isMonitoring: \(cachedIsMonitoring)")
            
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
        .onChange(of: deviceActivityService.isMonitoring) { newValue in
            // Update cached value when it changes
            // Use the parameter instead of accessing the property again
            cachedIsMonitoring = newValue
            viewId = UUID()
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
        if let userId = authService.currentUser?.uid {
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
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
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
