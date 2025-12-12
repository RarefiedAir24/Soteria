//
//  MainTabView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//  Updated: Custom tab bar implementation for lazy loading
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var shouldCreateGoalsView = false  // Lazy load GoalsView
    @State private var shouldCreateSettingsView = false  // Lazy load SettingsView
    
    var body: some View {
        let _ = {
            let timestamp = Date()
            print("🟢 [MainTabView] body evaluated at \(timestamp), selectedTab: \(selectedTab)")
        }()
        
        return VStack(spacing: 0) {
            // Only create the selected view - this is the key optimization!
            Group {
                switch selectedTab {
                case 0:
                    // HomeView is always created (it's the default tab)
                    NavigationView {
                        HomeView()
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    
                case 1:
                    // GoalsView is only created when user selects Goals tab
                    NavigationView {
                        if shouldCreateGoalsView {
                            GoalsView()
                        } else {
                            // Placeholder while we prepare to create the view
                            Color.mistGray
                                .ignoresSafeArea()
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(1.2)
                                )
                        }
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .onAppear {
                        // Create GoalsView when tab appears
                        if !shouldCreateGoalsView {
                            Task {
                                // Small delay to ensure smooth transition
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                await MainActor.run {
                                    shouldCreateGoalsView = true
                                    print("🟢 [MainTabView] GoalsView will now be created")
                                }
                            }
                        }
                    }
                    
                case 2:
                    // SettingsView is only created when user selects Settings tab
                    NavigationView {
                        if shouldCreateSettingsView {
                            SettingsView()
                        } else {
                            // Placeholder while we prepare to create the view
                            Color.mistGray
                                .ignoresSafeArea()
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(1.2)
                                )
                        }
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .onAppear {
                        // Create SettingsView when tab appears
                        if !shouldCreateSettingsView {
                            Task {
                                // Small delay to ensure smooth transition
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                await MainActor.run {
                                    shouldCreateSettingsView = true
                                    print("🟢 [MainTabView] SettingsView will now be created")
                                }
                            }
                        }
                    }
                    
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom tab bar at bottom
            CustomTabBar(selectedTab: $selectedTab)
        }
        // Set consistent navigation bar appearance for all tabs
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.mistGray, for: .navigationBar)
        // Set consistent status bar style
        .preferredColorScheme(.light)
        .onAppear {
            let timestamp = Date()
            print("🟢 [MainTabView] onAppear at \(timestamp), selectedTab: \(selectedTab)")
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            print("🟢 [MainTabView] Tab changed from \(oldValue) to \(newValue)")
        }
        .task {
            let startTime = Date()
            print("🟢 [MainTabView] .task started at \(startTime)")
            let endTime = Date()
            print("🟢 [MainTabView] .task completed at \(endTime) (took \(endTime.timeIntervalSince(startTime))s)")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
}

