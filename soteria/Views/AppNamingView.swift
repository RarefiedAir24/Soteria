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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                        
                        Text("Name Your Apps")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Give each app a name so we can track which one you use most during Quiet Hours")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        let selectedApps = deviceActivityService.selectedApps
                        ForEach(Array(selectedApps.applicationTokens.enumerated()), id: \.element) { index, _ in
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
                            for (index, name) in appNames {
                                if !name.isEmpty {
                                    deviceActivityService.setAppName(name, forIndex: index)
                                }
                            }
                            dismiss()
                        }) {
                            Text("Save Names")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.1, green: 0.6, blue: 0.3)))
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
                        for (index, name) in appNames {
                            if !name.isEmpty {
                                deviceActivityService.setAppName(name, forIndex: index)
                            }
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load current app names
                let selectedApps = deviceActivityService.selectedApps
                for index in 0..<selectedApps.applicationTokens.count {
                    let currentName = deviceActivityService.getAppName(forIndex: index)
                    if currentName != "App \(index + 1)" {
                        appNames[index] = currentName
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

