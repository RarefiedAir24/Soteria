//
//  HomeViewWrapper.swift
//  soteria
//
//  Lightweight wrapper to defer HomeView creation and reduce startup delay
//

import SwiftUI

/// Lightweight wrapper for HomeView with NavigationStack
struct HomeViewWrapper: View {
    var body: some View {
        // Use NavigationStack for iOS 16+, NavigationView for iOS 15
        if #available(iOS 16.0, *) {
            NavigationStack {
                HomeView()
                    .id("homeView") // Prevent unnecessary recreation
                    .navigationTitle("Soteria")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(Color.mistGray, for: .navigationBar)
            }
        } else {
            NavigationView {
                HomeView()
                    .id("homeView") // Prevent unnecessary recreation
                    .navigationTitle("Soteria")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

