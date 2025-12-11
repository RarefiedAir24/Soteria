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
                        
                        Text("Give each app a name so we can track which one you use most during Quiet Hours")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Use cached count to avoid blocking
                        ForEach(0..<appsCount, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("App \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
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
                            // Save all app names
                            print("💾 [AppNamingView] Save Names button - saving: \(appNames)")
                            for (index, name) in appNames {
                                if !name.isEmpty {
                                    print("💾 [AppNamingView] Saving '\(name)' for index \(index)")
                                    deviceActivityService.setAppName(name, forIndex: index)
                                }
                            }
                            // Force save one more time to ensure all names are persisted
                            deviceActivityService.saveAppNamesMapping()
                            print("💾 [AppNamingView] Done saving. Final appNames: \(deviceActivityService.appNames)")
                            dismiss()
                        }) {
                            Text("Save Names")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.reverBlue))
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 40)
                }
            }
            .navigationTitle("Name Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Save all app names
                        print("💾 [AppNamingView] Saving app names: \(appNames)")
                        for (index, name) in appNames {
                            if !name.isEmpty {
                                print("💾 [AppNamingView] Saving '\(name)' for index \(index)")
                                deviceActivityService.setAppName(name, forIndex: index)
                            }
                        }
                        // Force save one more time to ensure all names are persisted
                        deviceActivityService.saveAppNamesMapping()
                        print("💾 [AppNamingView] Done saving. Final appNames: \(deviceActivityService.appNames)")
                        dismiss()
                    }
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

