//
//  SettingsView.swift
//  rever
//
//  Settings with behavioral features
//

import SwiftUI
import FirebaseAuth
import UIKit
import FamilyControls

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    @EnvironmentObject var quietHoursService: QuietHoursService
    @State private var showAppSelection = false
    @State private var viewId = UUID()
    @State private var showStartMonitoringConfirmation = false
    @State private var pendingToggleState = false
    @State private var isStartingMonitoring = false
    @State private var showQuietHours = false
    @State private var showMoodCheckIn = false
    @State private var showRegretLog = false
    @State private var showAppNaming = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView {
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
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                
                                if let user = authService.currentUser {
                                    Text(user.email ?? "Unknown")
                                        .font(.system(size: 16, weight: .semibold))
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
                    
                    // Behavioral Features Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Behavioral Features")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        // Quiet Hours
                        SettingsRow(
                            icon: "moon.fill",
                            title: "Quiet Hours",
                            subtitle: quietHoursService.isQuietModeActive ? "Active" : "Inactive",
                            color: quietHoursService.isQuietModeActive ? Color(red: 0.1, green: 0.6, blue: 0.3) : .gray
                        ) {
                            showQuietHours = true
                        }
                        
                        Divider()
                        
                        // Mood Check-In
                        SettingsRow(
                            icon: "heart.fill",
                            title: "Mood Check-In",
                            subtitle: "Track your mood",
                            color: Color(red: 0.1, green: 0.6, blue: 0.3)
                        ) {
                            showMoodCheckIn = true
                        }
                        
                        Divider()
                        
                        // Regret Log
                        SettingsRow(
                            icon: "exclamationmark.triangle.fill",
                            title: "Regret Log",
                            subtitle: "View regret purchases",
                            color: .orange
                        ) {
                            showRegretLog = true
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
                                .font(.system(size: 18, weight: .semibold))
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
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    
                                    if !deviceActivityService.selectedApps.applicationTokens.isEmpty {
                                        Text("\(deviceActivityService.selectedApps.applicationTokens.count) app\(deviceActivityService.selectedApps.applicationTokens.count == 1 ? "" : "s") selected")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                    } else {
                                        Text("No apps selected")
                                            .font(.system(size: 13))
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
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
                                if isStartingMonitoring {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.1, green: 0.6, blue: 0.3)))
                                            .frame(width: 14, height: 14)
                                        Text("Starting monitoring...")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                    }
                                } else if deviceActivityService.isMonitoring {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.green)
                                        Text("Active")
                                            .font(.system(size: 13))
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    Text("Inactive")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                }
                            }
                            
                            Spacer()
                            
                            Group {
                                if isStartingMonitoring {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.1, green: 0.6, blue: 0.3)))
                                        .frame(width: 30, height: 30)
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
                                .font(.system(size: 16, weight: .semibold))
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
            
            // Fixed Header
            VStack(spacing: 2) {
                Text("Settings")
                    .font(.system(size: 24, weight: .semibold))
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
            .onDisappear {
                // After app selection, show naming screen if apps were selected
                if !deviceActivityService.selectedApps.applicationTokens.isEmpty {
                    // Check if any apps need naming
                    let needsNaming = (0..<deviceActivityService.selectedApps.applicationTokens.count).contains { index in
                        deviceActivityService.getAppName(forIndex: index) == "App \(index + 1)"
                    }
                    if needsNaming {
                        showAppNaming = true
                    }
                }
            }
        }
        .sheet(isPresented: $showAppNaming) {
            AppNamingView()
                .environmentObject(deviceActivityService)
        }
        .fullScreenCover(isPresented: $showQuietHours) {
            NavigationView {
                QuietHoursView()
                    .environmentObject(quietHoursService)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showQuietHours = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showMoodCheckIn) {
            NavigationView {
                MoodCheckInView()
                    .environmentObject(MoodTrackingService.shared)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showMoodCheckIn = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showRegretLog) {
            NavigationView {
                RegretLogView()
                    .environmentObject(RegretLoggingService.shared)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showRegretLog = false
                            }
                        }
                    }
            }
        }
        .onChange(of: showAppSelection) {
            if !showAppSelection {
                viewId = UUID()
            }
        }
        .onChange(of: deviceActivityService.selectedApps.applicationTokens.count) {
            viewId = UUID()
        }
        .onChange(of: deviceActivityService.isMonitoring) {
            viewId = UUID()
        }
        .alert("Start Monitoring", isPresented: $showStartMonitoringConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingToggleState = false
            }
            Button("Start", role: .none) {
                isStartingMonitoring = true
                pendingToggleState = false
                viewId = UUID()
                
                Task {
                    print("🔄 [SettingsView] Starting monitoring...")
                    do {
                        // Add timeout to prevent infinite hanging
                        try await withTimeout(seconds: 10) {
                            await deviceActivityService.startMonitoring()
                        }
                        print("✅ [SettingsView] Monitoring started successfully")
                        await MainActor.run {
                            self.isStartingMonitoring = false
                            self.viewId = UUID()
                            self.showStartMonitoringConfirmation = false
                        }
                    } catch {
                        print("❌ [SettingsView] Error or timeout starting monitoring: \(error)")
                        await MainActor.run {
                            self.isStartingMonitoring = false
                            self.viewId = UUID()
                            self.showStartMonitoringConfirmation = false
                        }
                    }
                }
            }
        } message: {
            Text("SOTERIA will monitor \(deviceActivityService.selectedApps.applicationTokens.count) selected app\(deviceActivityService.selectedApps.applicationTokens.count == 1 ? "" : "s") and send you notifications when you open them. Continue?")
        }
        .onChange(of: isStartingMonitoring) {
            viewId = UUID()
        }
    }
}

// Helper function to add timeout to async operations
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
            )
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
        .environmentObject(DeviceActivityService.shared)
        .environmentObject(QuietHoursService.shared)
}
