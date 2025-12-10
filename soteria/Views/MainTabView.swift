//
//  MainTabView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var shouldCreateSettingsView = false  // Control when SettingsView is created
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationView {
                GoalsView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            .tag(1)
            
            // CRITICAL: Only create SettingsView when shouldCreateSettingsView is true
            // This prevents SwiftUI from evaluating SettingsView during app startup
            NavigationView {
                Group {
                    if shouldCreateSettingsView {
                        SettingsView()
                    } else {
                        // Placeholder - SwiftUI won't render this
                        Color.clear
                            .frame(width: 0, height: 0)
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        // Set consistent toolbar appearance to prevent color changes when switching tabs
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color(red: 0.95, green: 0.95, blue: 0.95), for: .tabBar)
        // Also set consistent navigation bar appearance for all tabs
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(red: 0.95, green: 0.95, blue: 0.95), for: .navigationBar)
        // Set consistent status bar style
        .preferredColorScheme(.light)
        .onChange(of: selectedTab) { newValue in
            // When Settings tab is selected, wait a moment before creating the view
            // This gives the app time to finish any initialization
            if newValue == 2 && !shouldCreateSettingsView {
                Task {
                    // Small delay to ensure app is fully initialized
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await MainActor.run {
                        shouldCreateSettingsView = true
                        print("🟢 [MainTabView] SettingsView will now be created")
                    }
                }
            }
        }
        .onAppear {
            let timestamp = Date()
            print("🟢 [MainTabView] onAppear at \(timestamp)")
        }
        .task {
            let startTime = Date()
            print("🟢 [MainTabView] .task started at \(startTime)")
            // DISABLED: Removed sleep to prevent blocking
            // The sleep itself shouldn't block, but if something else is blocking the main thread,
            // the await will wait indefinitely. Just return immediately.
            let endTime = Date()
            print("🟢 [MainTabView] .task completed at \(endTime) (took \(endTime.timeIntervalSince(startTime))s)")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
}

