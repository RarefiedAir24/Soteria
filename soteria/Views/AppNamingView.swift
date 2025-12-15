//
//  AppNamingView.swift
//  soteria
//
//  View to name selected apps for better tracking and metrics
//

import SwiftUI
import FamilyControls

struct AppNamingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    
    @State private var appNames: [Int: String] = [:]
    @State private var appsCount: Int = 0 // Cache to avoid blocking access
    
    // Computed property to check if all apps are named
    // Note: Naming is now optional (auto-named from backend), but we still validate for editing
    private var allAppsNamed: Bool {
        guard appsCount > 0 else { return true } // Allow saving even if no apps
        
        for index in 0..<appsCount {
            let name = appNames[index] ?? deviceActivityService.getAppName(forIndex: index)
            let trimmedName = name.trimmingCharacters(in: .whitespaces)
            
            // Allow saving if name is not empty (even if it's "App X" - backend will update it)
            if trimmedName.isEmpty {
                return false
            }
        }
        return true
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.reverBlue)
                        
                        Text("Name Your Apps")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.midnightSlate)
                        
                        Text("Apps are automatically named, but you can customize them here. Names are saved automatically and persist until you change or remove the app.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Use cached count to avoid blocking
                        ForEach(0..<appsCount, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("App \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    // Show "Auto-named" if name came from backend
                                let currentName = appNames[index] ?? deviceActivityService.getAppName(forIndex: index)
                                if currentName != "App \(index + 1)" && !currentName.isEmpty {
                                    Text("Auto-named")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                }
                                
                                TextField("Enter app name (e.g., Amazon, eBay)", text: Binding(
                                    get: { appNames[index] ?? deviceActivityService.getAppName(forIndex: index) },
                                    set: { appNames[index] = $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.words)
                            }
                            .padding(.horizontal, 32)
                        }
                        
                        Button(action: {
                            // App names are now read-only and managed by backend
                            // This view is display-only - names are auto-named from backend
                            print("💾 [AppNamingView] App names are read-only - managed by backend")
                            dismiss()
                        }) {
                            Text("Save Changes")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(allAppsNamed ? Color.reverBlue : Color.gray)
                                )
                        }
                        .disabled(!allAppsNamed)
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 40)
                }
            }
            .navigationTitle("Name Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // App names are now read-only and managed by backend
                        // This view is display-only - names are auto-named from backend
                        print("💾 [AppNamingView] App names are read-only - managed by backend")
                        dismiss()
                    }
                    .disabled(!allAppsNamed)
                }
            }
            .task {
                // Load apps count and names asynchronously to avoid blocking
                Task { @MainActor in
                    // Small delay to ensure view is rendered
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    let selectedApps = self.deviceActivityService.selectedApps
                    self.appsCount = selectedApps.applicationTokens.count
                    
                    // Load current app names
                    for index in 0..<self.appsCount {
                        let currentName = self.deviceActivityService.getAppName(forIndex: index)
                        if currentName != "App \(index + 1)" {
                            self.appNames[index] = currentName
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AppNamingView()
        .environmentObject(DeviceActivityService.shared)
}

