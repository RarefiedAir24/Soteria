//
//  MainTabView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//  Updated: Custom tab bar implementation for lazy loading
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService  // Get from parent environment
    @State private var selectedTab = 0
    @State private var showMonthlyGoalPrompt = false
    
    init() {
        let initStart = Date()
        StartupDiagnostics.shared.log("🔍 [MainTabView] init() started")
        StartupDiagnostics.shared.logViewInit("MainTabView", startTime: initStart)
    }
    
    var body: some View {
        let bodyStart = Date()
        let _ = {
            StartupDiagnostics.shared.log("🔍 [MainTabView] body evaluation started (selectedTab: \(selectedTab))")
        }()
        
        // Restore tab bar with lazy loading
        let vstack = VStack(spacing: 0) {
            // Content area - only show selected tab
            Group {
                if selectedTab == 0 {
                    // Home Tab - create HomeViewWrapper immediately (app is loading fast now)
                    let homeWrapperStart = Date()
                    let homeWrapper = HomeViewWrapper()
                    let _ = {
                        let homeWrapperDuration = Date().timeIntervalSince(homeWrapperStart)
                        if homeWrapperDuration > 0.01 {
                            StartupDiagnostics.shared.log("⚠️ [MainTabView] HomeViewWrapper() creation took \(String(format: "%.3f", homeWrapperDuration))s")
                        } else {
                            StartupDiagnostics.shared.log("✅ [MainTabView] HomeViewWrapper() creation completed (fast)")
                        }
                    }()
                    homeWrapper
                        .onAppear {
                            StartupDiagnostics.shared.log("🔍 [MainTabView] HomeViewWrapper.onAppear")
                        }
                } else if selectedTab == 1 {
                    // Goals Tab - create immediately when tab is selected (non-blocking)
                    let goalsStart = Date()
                    let goalsService = GoalsService.shared
                    let _ = {
                        let goalsServiceDuration = Date().timeIntervalSince(goalsStart)
                        if goalsServiceDuration > 0.01 {
                            StartupDiagnostics.shared.log("⚠️ [MainTabView] GoalsService.shared access took \(String(format: "%.3f", goalsServiceDuration))s")
                        }
                    }()
                    
                    GoalsView()
                        .environmentObject(goalsService)
                        .environmentObject(authService)
                } else if selectedTab == 2 {
                    // Settings Tab - create immediately when tab is selected (non-blocking)
                    // CRITICAL: Access .shared services only when tab is actually selected
                    // This prevents service initialization during app startup
                    let subStart = Date()
                    let subscriptionService = SubscriptionService.shared
                    let _ = {
                        let subDuration = Date().timeIntervalSince(subStart)
                        if subDuration > 0.01 {
                            StartupDiagnostics.shared.log("⚠️ [MainTabView] SubscriptionService.shared access took \(String(format: "%.3f", subDuration))s")
                        }
                    }()
                    
                    NavigationStack {
                        SettingsView()
                            .environmentObject(subscriptionService)
                            .environmentObject(authService)
                            .id("settingsView")
                    }
                } else {
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar at bottom
            CustomTabBar(selectedTab: $selectedTab)
        }
        .onAppear {
            StartupDiagnostics.shared.log("🔍 [MainTabView] onAppear (selectedTab: \(selectedTab))")
        }
        
        let _ = {
            let bodyDuration = Date().timeIntervalSince(bodyStart)
            if bodyDuration > 0.01 {
                StartupDiagnostics.shared.log("⚠️ [MainTabView] body evaluation took \(String(format: "%.3f", bodyDuration))s")
            }
        }()
        
        return vstack
        .onChange(of: selectedTab) { oldValue, newValue in
            print("🟢 [MainTabView] Tab changed from \(oldValue) to \(newValue)")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToGoalsTab"))) { _ in
            print("✅ [MainTabView] Received NavigateToGoalsTab notification - switching to Goals tab")
            selectedTab = 1  // Goals tab is index 1
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToSettingsTab"))) { _ in
            print("✅ [MainTabView] Received NavigateToSettingsTab notification - switching to Settings tab")
            selectedTab = 2  // Settings tab is index 2
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowMonthlyGoalPrompt"))) { _ in
            print("✅ [MainTabView] Received ShowMonthlyGoalPrompt notification - showing monthly goal prompt")
            // Small delay to ensure any current sheets are dismissed first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showMonthlyGoalPrompt = true
            }
        }
        .sheet(isPresented: $showMonthlyGoalPrompt) {
            MonthlyGoalPromptView(
                onYes: {
                    // Navigate to Goals tab and show create goal view
                    selectedTab = 1  // Goals tab is index 1
                    // Post notification to show create goal view after a small delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ShowCreateGoal"),
                            object: nil
                        )
                    }
                },
                onNo: {
                    // User declined - just dismiss
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    MainTabView()
        // .environmentObject(AuthService())  // TEMPORARILY DISABLED
}

