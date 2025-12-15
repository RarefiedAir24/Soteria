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
    
    init() {
        let timestamp = Date()
        print("🔍 [MainTabView] init() called at \(timestamp)")
    }
    
    var body: some View {
        let _ = {
            let timestamp = Date()
            print("🟢 [MainTabView] body evaluation started at \(timestamp), selectedTab: \(selectedTab)")
        }()
        
        // Restore tab bar with lazy loading
        return VStack(spacing: 0) {
            // Content area - only show selected tab
            Group {
                if selectedTab == 0 {
                    // Home Tab - create HomeViewWrapper immediately (app is loading fast now)
                    HomeViewWrapper()
                        .onAppear {
                            print("🔍 [MainTabView] HomeViewWrapper.onAppear")
                        }
                } else if selectedTab == 1 {
                    // Goals Tab - create immediately when tab is selected (non-blocking)
                    GoalsView()
                        .environmentObject(GoalsService.shared)
                        .environmentObject(authService)
                } else if selectedTab == 2 {
                    // Settings Tab - create immediately when tab is selected (non-blocking)
                    SettingsView()
                        .environmentObject(DeviceActivityService.shared)
                        .environmentObject(QuietHoursService.shared)
                        .environmentObject(SubscriptionService.shared)
                        .environmentObject(authService)
                        .id("settingsView")
                } else {
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar at bottom
            CustomTabBar(selectedTab: $selectedTab)
        }
        .onAppear {
            let timestamp = Date()
            print("🟢 [MainTabView] onAppear at \(timestamp), selectedTab: \(selectedTab)")
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            print("🟢 [MainTabView] Tab changed from \(oldValue) to \(newValue)")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToGoalsTab"))) { _ in
            print("✅ [MainTabView] Received NavigateToGoalsTab notification - switching to Goals tab")
            selectedTab = 1  // Goals tab is index 1
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    MainTabView()
        // .environmentObject(AuthService())  // TEMPORARILY DISABLED
}

