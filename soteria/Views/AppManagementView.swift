//
//  AppManagementView.swift
//  soteria
//
//  View to manage app names and view app list
//

import SwiftUI
import FamilyControls

// ApplicationToken is already Hashable in FamilyControls, no extension needed

struct AppManagementView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    
    // Editing removed - app names are read-only (managed by backend)
    // App removal removed - users should manage apps via Settings → Select Apps
    @State private var appsCount: Int = 0 // Cache to avoid blocking access
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cloudWhite
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "app.badge.checkmark")
                                .font(.system(size: 60))
                                .foregroundColor(Color.reverBlue)
                            
                            Text("Selected Apps")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color.midnightSlate)
                            
                            Text("\(appsCount) app\(appsCount == 1 ? "" : "s") selected • Names managed automatically")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        // App list
                        if appsCount == 0 {
                            VStack(spacing: 16) {
                                Image(systemName: "app.badge")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("No apps selected")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Text("Go to Settings to select apps to monitor")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                // Use cached count to avoid blocking
                                ForEach(0..<appsCount, id: \.self) { index in
                                    HStack {
                                        Image(systemName: "app.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color.reverBlue)
                                        
                                        // Display mode only (read-only)
                                        // App names are managed by backend - no editing allowed
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(deviceActivityService.getAppName(forIndex: index))
                                                .font(.headline)
                                                .foregroundColor(Color.midnightSlate)
                                            
                                            Text("App \(index + 1)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            Text("Auto-named by backend")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                    )
                                    // Swipe-to-delete removed - app removal should be done via Settings → Select Apps
                                    // This keeps app management centralized and prevents name mapping conflicts
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Selected Apps")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Load apps count asynchronously to avoid blocking
                Task { @MainActor in
                    // Small delay to ensure view is rendered
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    self.appsCount = self.deviceActivityService.selectedApps.applicationTokens.count
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            // App removal removed - users should manage apps via Settings → Select Apps
            // This prevents conflicts with backend name mapping
        }
    }
    
    // Editing functions removed - app names are read-only (managed by backend)
    
    // App removal function removed - users should manage apps via Settings → Select Apps
    // This prevents conflicts with backend name mapping
}

#Preview {
    AppManagementView()
        .environmentObject(DeviceActivityService.shared)
}

