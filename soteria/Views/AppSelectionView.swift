//
//  AppSelectionView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI
import FamilyControls
import UIKit

// Simple wrapper that just returns the picker with background
// IMPORTANT: This view accesses selection.applicationTokens which can block
// It should only be created when the sheet is actually shown
struct FamilyActivityPickerWrapper: View {
    @Binding var selection: FamilyActivitySelection
    var maxApps: Int?
    @Binding var showLimitAlert: Bool
    
    @State private var isPickerReady = false
    
    var body: some View {
        Group {
            if isPickerReady {
                FamilyActivityPicker(selection: $selection)
                    .background(Color.mistGray)
            } else {
                // Placeholder while picker loads
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.mistGray)
            }
        }
        .task {
            // Defer FamilyActivityPicker creation to avoid blocking
            // Wait a bit to ensure view is fully rendered
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            isPickerReady = true
        }
    }
}

// Wrapper to make AppSelectionView truly lazy
struct LazyAppSelectionView: View {
    @Binding var selection: FamilyActivitySelection
    @Binding var isPresented: Bool
    var maxApps: Int? = nil
    
    var body: some View {
        AppSelectionView(selection: $selection, isPresented: $isPresented, maxApps: maxApps)
    }
}

struct AppSelectionView: View {
    @Binding var selection: FamilyActivitySelection
    @Binding var isPresented: Bool
    var maxApps: Int? = nil // Limit for free tier (1 app)
    @State private var showLimitAlert = false
    @State private var authorizationCenter = AuthorizationCenter.shared
    @State private var isAuthorized = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.mistGray
                .ignoresSafeArea(.all)
            
            // Main content
            VStack(spacing: 0) {
                // Spacer for header
                Color.clear
                    .frame(height: 60)
                
                if isAuthorized {
                    // App Selection - simple, no complex background manipulation
                    FamilyActivityPickerWrapper(selection: $selection, maxApps: maxApps, showLimitAlert: $showLimitAlert)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Text("Authorization Required")
                            .font(.headline)
                            .foregroundColor(Color.midnightSlate)
                        
                        Text("Please grant Screen Time permissions to select apps.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Request Authorization") {
                            requestAuthorization()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.reverBlue)
                        
                        // Debug info
                        Text("Status: \(authorizationCenter.authorizationStatus.rawValue)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            // Fixed Header overlay
            VStack(spacing: 0) {
                HStack {
                    Text("Select Apps to Monitor")
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundColor(Color.midnightSlate)
                    Spacer()
                    Button(action: {
                        // Immediately dismiss - let SwiftUI handle cleanup
                        isPresented = false
                    }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.reverBlue)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                
                // Note about system picker appearance
                if isAuthorized {
                    Text("Note: The app picker uses Apple's system interface")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.softGraphite)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .background(
                Color(red: 0.92, green: 0.97, blue: 0.94)
                    .ignoresSafeArea(edges: .top)
            )
            .zIndex(100)
        }
        .background(Color.mistGray.ignoresSafeArea())
        .onAppear {
            // Check authorization status
            checkAuthorization()
            // IMPORTANT: FamilyActivityPicker should automatically restore previous selection
            // when opened. The system manages this persistence.
            print("📂 [AppSelectionView] Picker opened - system should restore previous selection")
        }
        .task {
            // Check authorization status when view appears (async)
            checkAuthorization()
        }
        .onChange(of: selection) { oldValue, newValue in
            // Log when selection changes (picker should restore previous selection on open)
            print("🔄 [AppSelectionView] Selection changed")
            // The system should persist this automatically
            // Note: When picker opens, system restores selection, which triggers this onChange
            // The count will be refreshed by AppSelectionSheetContent.onChange handler
        }
        .alert("App Limit Reached", isPresented: $showLimitAlert) {
            Button("OK") { }
        } message: {
            Text("Free tier includes 1 app. Upgrade to Premium to monitor multiple apps.")
        }
    }
    
    private func checkAuthorization() {
        // Check authorization status with error handling
        // Note: This may log system warnings (like NSCocoaErrorDomain 4099) which are usually harmless
        let status = authorizationCenter.authorizationStatus
        let wasAuthorized = isAuthorized
        isAuthorized = status == .approved
        
        // Log status for debugging
        print("Family Controls authorization status: \(status.rawValue), isAuthorized: \(isAuthorized)")
        
        // If authorization just changed to approved, force UI update
        if isAuthorized && !wasAuthorized {
            print("Authorization granted! Updating UI...")
        }
    }
    
    private func requestAuthorization() {
        Task {
            do {
                print("Requesting Family Controls authorization...")
                try await authorizationCenter.requestAuthorization(for: .individual)
                print("Authorization request completed")
                await MainActor.run {
                    // Force check and update
                    checkAuthorization()
                    // Also trigger a view update
                    DispatchQueue.main.async {
                        self.checkAuthorization()
                    }
                }
            } catch {
                // Log error but don't show to user - system-level errors are common with Family Controls
                print("Family Controls authorization error: \(error.localizedDescription)")
                // Still check status in case authorization succeeded despite the error
                await MainActor.run {
                    checkAuthorization()
                }
            }
        }
    }
    
}

