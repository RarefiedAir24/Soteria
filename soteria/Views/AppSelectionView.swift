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
struct FamilyActivityPickerWrapper: View {
    @Binding var selection: FamilyActivitySelection
    
    var body: some View {
        FamilyActivityPicker(selection: $selection)
            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
    }
}

struct AppSelectionView: View {
    @Binding var selection: FamilyActivitySelection
    @Binding var isPresented: Bool
    @State private var authorizationCenter = AuthorizationCenter.shared
    @State private var isAuthorized = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color(red: 0.95, green: 0.95, blue: 0.95)
                .ignoresSafeArea(.all)
            
            // Main content
            VStack(spacing: 0) {
                // Spacer for header
                Color.clear
                    .frame(height: 60)
                
                if isAuthorized {
                    // App Selection - simple, no complex background manipulation
                    FamilyActivityPickerWrapper(selection: $selection)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Text("Authorization Required")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Please grant Screen Time permissions to select apps.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Request Authorization") {
                            requestAuthorization()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.1, green: 0.6, blue: 0.3))
                        
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
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
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
                                    .fill(Color(red: 0.1, green: 0.6, blue: 0.3))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                
                // Note about system picker appearance
                if isAuthorized {
                    Text("Note: The app picker uses Apple's system interface")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
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
        .background(Color(red: 0.95, green: 0.95, blue: 0.95).ignoresSafeArea())
        .onAppear {
            // Check authorization status
            checkAuthorization()
        }
        .task {
            // Check authorization status when view appears (async)
            checkAuthorization()
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

