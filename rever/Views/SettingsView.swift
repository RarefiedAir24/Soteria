//
//  SettingsView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI
import FirebaseAuth
import UIKit
import FamilyControls

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    @State private var showAppSelection = false
    @State private var viewId = UUID()
    @State private var showStartMonitoringConfirmation = false
    @State private var pendingToggleState = false
    @State private var isStartingMonitoring = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView {
                // Spacer for fixed header
                Color.clear
                    .frame(height: 60)
                
                VStack(spacing: 20) {
                    // Account Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Account")
                                    .font(.system(size: 14, weight: .medium, design: .default))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                
                                if let user = authService.currentUser {
                                    Text(user.email ?? "Unknown")
                                        .font(.system(size: 16, weight: .semibold, design: .default))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                }
                            }
                            
                            Spacer()
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
                                .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                            
                            Text("App Monitoring")
                                .font(.system(size: 18, weight: .semibold, design: .default))
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            Spacer()
                        }
                        
                        // Select Apps Button
                        Button(action: {
                            showAppSelection = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Select Apps to Monitor")
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    
                                    if !deviceActivityService.selectedApps.applicationTokens.isEmpty {
                                        Text("\(deviceActivityService.selectedApps.applicationTokens.count) app\(deviceActivityService.selectedApps.applicationTokens.count == 1 ? "" : "s") selected")
                                            .font(.system(size: 13, weight: .regular, design: .default))
                                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                    } else {
                                        Text("No apps selected")
                                            .font(.system(size: 13, weight: .regular, design: .default))
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
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // Monitoring Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Monitoring")
                                    .font(.system(size: 16, weight: .medium, design: .default))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
                                if isStartingMonitoring {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.1, green: 0.6, blue: 0.3)))
                                            .frame(width: 14, height: 14)
                                        Text("Starting monitoring...")
                                            .font(.system(size: 13, weight: .medium, design: .default))
                                            .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                    }
                                } else if deviceActivityService.isMonitoring {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.green)
                                        Text("Active")
                                            .font(.system(size: 13, weight: .regular, design: .default))
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    Text("Inactive")
                                        .font(.system(size: 13, weight: .regular, design: .default))
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                }
                            }
                            
                            Spacer()
                            
                            Group {
                                if isStartingMonitoring {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.1, green: 0.6, blue: 0.3)))
                                        .frame(width: 30, height: 30)
                                        .onAppear {
                                            print("ProgressView appeared - isStartingMonitoring: \(isStartingMonitoring)")
                                        }
                                } else {
                                    Toggle("", isOn: Binding(
                                        get: { deviceActivityService.isMonitoring },
                                        set: { newValue in
                                            if newValue {
                                                pendingToggleState = true
                                                showStartMonitoringConfirmation = true
                                            } else {
                                                deviceActivityService.stopMonitoring()
                                                viewId = UUID()
                                            }
                                        }
                                    ))
                                    .toggleStyle(.switch)
                                    .tint(Color(red: 0.1, green: 0.6, blue: 0.3))
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                        )
                        .disabled(deviceActivityService.selectedApps.applicationTokens.isEmpty || isStartingMonitoring)
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
                                .font(.system(size: 16, weight: .semibold, design: .default))
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
            
            // Fixed Header - matches Home style
            VStack(spacing: 2) {
                Text("Settings")
                    .font(.system(size: 24, weight: .semibold, design: .default))
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
        .sheet(isPresented: $showAppSelection) {
            AppSelectionView(
                selection: $deviceActivityService.selectedApps,
                isPresented: $showAppSelection
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: showAppSelection) { newValue in
            if !newValue {
                // Sheet was dismissed - refresh view immediately
                viewId = UUID()
            }
        }
        .onChange(of: deviceActivityService.selectedApps.applicationTokens.count) { count in
            // Refresh when app count changes
            print("App count changed to: \(count)")
            viewId = UUID()
        }
        .onChange(of: deviceActivityService.isMonitoring) { isMonitoring in
            // Refresh when monitoring state changes
            print("Monitoring state changed to: \(isMonitoring)")
            viewId = UUID()
        }
        .alert("Start Monitoring", isPresented: $showStartMonitoringConfirmation) {
            Button("Cancel", role: .cancel) {
                // Reset pending state - toggle will stay off
                pendingToggleState = false
            }
            Button("Start", role: .none) {
                // Set state immediately (we're already on main thread in alert handler)
                isStartingMonitoring = true
                pendingToggleState = false
                print("Setting isStartingMonitoring to true")
                
                // Start monitoring in background
                Task {
                    await deviceActivityService.startMonitoring()
                    // Hide loading and show final state
                    await MainActor.run {
                        print("Setting isStartingMonitoring to false")
                        self.isStartingMonitoring = false
                        self.viewId = UUID()
                    }
                }
            }
        } message: {
            Text("Rever will monitor \(deviceActivityService.selectedApps.applicationTokens.count) selected app\(deviceActivityService.selectedApps.applicationTokens.count == 1 ? "" : "s") and send you notifications when you open them. Continue?")
        }
        .onChange(of: isStartingMonitoring) { newValue in
            print("isStartingMonitoring changed to: \(newValue)")
            viewId = UUID()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
}

