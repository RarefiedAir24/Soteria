//
//  MainTabViewWrapper.swift
//  soteria
//
//  Lightweight wrapper to defer MainTabView creation
//

import SwiftUI

/// Lightweight wrapper that defers MainTabView creation
/// This prevents blocking during view initialization
struct MainTabViewWrapper: View {
    @State private var shouldCreateMainTabView = false
    
    var body: some View {
        let _ = {
            let timestamp = Date()
            print("🔍 [MainTabViewWrapper] body evaluated at \(timestamp), shouldCreate: \(shouldCreateMainTabView)")
        }()
        
        Group {
            if shouldCreateMainTabView {
                let _ = {
                    let timestamp = Date()
                    print("🔍 [MainTabViewWrapper] About to create MainTabView() at \(timestamp)")
                }()
                MainTabView()
                    .onAppear {
                        let timestamp = Date()
                        print("🔍 [MainTabViewWrapper] MainTabView.onAppear at \(timestamp)")
                    }
            } else {
                // Minimal placeholder - show background immediately
                Color.mistGray
                    .ignoresSafeArea()
                    .onAppear {
                        let timestamp = Date()
                        print("🔍 [MainTabViewWrapper] Placeholder.onAppear at \(timestamp)")
                    }
            }
        }
        .onAppear {
            let timestamp = Date()
            print("🔍 [MainTabViewWrapper] onAppear at \(timestamp)")
            // Create MainTabView immediately - it was working before
            let beforeCreate = Date()
            print("🔍 [MainTabViewWrapper] About to set shouldCreateMainTabView = true at \(beforeCreate)")
            shouldCreateMainTabView = true
            let afterCreate = Date()
            print("🟢 [MainTabViewWrapper] shouldCreateMainTabView set to true (took \(afterCreate.timeIntervalSince(beforeCreate))s)")
        }
    }
}

