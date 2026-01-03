//
//  HomeViewWrapper.swift
//  soteria
//
//  Lightweight wrapper to defer HomeView creation and reduce startup delay
//

import SwiftUI

/// Lightweight wrapper for HomeView with NavigationStack
struct HomeViewWrapper: View {
    @EnvironmentObject var authService: AuthService
    
    init() {
        let initStart = Date()
        StartupDiagnostics.shared.log("🔍 [HomeViewWrapper] init() started")
        StartupDiagnostics.shared.logViewInit("HomeViewWrapper", startTime: initStart)
    }
    
    var body: some View {
        let _ = {
            StartupDiagnostics.shared.log("🔍 [HomeViewWrapper] body evaluation started")
        }()
        
        // Use NavigationStack for iOS 16+, NavigationView for iOS 15
        let homeViewStart = Date()
        let subscriptionService = SubscriptionService.shared
        let homeView = HomeView()
            .environmentObject(subscriptionService)
            .environmentObject(authService)
        let _ = {
            let homeViewDuration = Date().timeIntervalSince(homeViewStart)
            if homeViewDuration > 0.01 {
                StartupDiagnostics.shared.log("⚠️ [HomeViewWrapper] HomeView() creation took \(String(format: "%.3f", homeViewDuration))s")
            }
        }()
        
        let navStart = Date()
        
        // Use NavigationStack for iOS 16+, NavigationView for iOS 15
        let navigationView: AnyView = {
            if #available(iOS 16.0, *) {
                AnyView(
                    NavigationStack {
                        homeView
                            .id("homeView") // Prevent unnecessary recreation
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbarBackground(.hidden, for: .navigationBar) // Hide navigation bar to show custom header
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    // Empty toolbar to maintain layout
                                    Color.clear
                                        .frame(width: 0, height: 0)
                                }
                            }
                    }
                )
            } else {
                AnyView(
                    NavigationView {
                        homeView
                            .id("homeView") // Prevent unnecessary recreation
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarHidden(true) // Hide navigation bar to show custom header
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                )
            }
        }()
        
        let _ = {
            let navDuration = Date().timeIntervalSince(navStart)
            if navDuration > 0.1 {
                StartupDiagnostics.shared.log("⚠️ [HomeViewWrapper] NavigationStack/NavigationView creation took \(String(format: "%.3f", navDuration))s")
            } else {
                StartupDiagnostics.shared.log("✅ [HomeViewWrapper] NavigationStack/NavigationView creation completed (fast)")
            }
        }()
        
        return navigationView
    }
}

