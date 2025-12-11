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
    
    @State private var editingIndex: Int? = nil
    @State private var editingName: String = ""
    @State private var showDeleteConfirmation: Int? = nil
    @State private var appsCount: Int = 0 // Cache to avoid blocking access
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.98, green: 0.98, blue: 0.98)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "app.badge.checkmark")
                                .font(.system(size: 60))
                                .foregroundColor(Color.themePrimary)
                            
                            Text("Manage Apps")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            Text("\(appsCount) app\(appsCount == 1 ? "" : "s") selected")
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
                                            .foregroundColor(Color.themePrimary)
                                        
                                        if editingIndex == index {
                                            // Editing mode
                                            TextField("App name", text: $editingName)
                                                .textFieldStyle(.roundedBorder)
                                                .autocapitalization(.words)
                                                .onSubmit {
                                                    saveName(for: index)
                                                }
                                            
                                            Button(action: {
                                                saveName(for: index)
                                            }) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                    .font(.system(size: 24))
                                            }
                                            
                                            Button(action: {
                                                cancelEditing()
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.system(size: 24))
                                            }
                                        } else {
                                            // Display mode
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(deviceActivityService.getAppName(forIndex: index))
                                                    .font(.headline)
                                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                                
                                                Text("App \(index + 1)")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                startEditing(index: index)
                                            }) {
                                                Image(systemName: "pencil.circle.fill")
                                                    .foregroundColor(Color.themePrimary)
                                                    .font(.system(size: 24))
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                    )
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            showDeleteConfirmation = index
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Manage Apps")
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
            .alert("Remove App", isPresented: Binding(
                get: { showDeleteConfirmation != nil },
                set: { if !$0 { showDeleteConfirmation = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    showDeleteConfirmation = nil
                }
                Button("Remove", role: .destructive) {
                    if let index = showDeleteConfirmation {
                        removeAppName(at: index)
                        showDeleteConfirmation = nil
                    }
                }
            } message: {
                if let index = showDeleteConfirmation {
                    let appName = deviceActivityService.getAppName(forIndex: index)
                    Text("Remove '\(appName)' from monitoring? This will stop blocking and tracking for this app. You can add it back in Settings.")
                }
            }
        }
    }
    
    private func startEditing(index: Int) {
        editingIndex = index
        editingName = deviceActivityService.getAppName(forIndex: index)
    }
    
    private func saveName(for index: Int) {
        if !editingName.trimmingCharacters(in: .whitespaces).isEmpty {
            deviceActivityService.setAppName(editingName.trimmingCharacters(in: .whitespaces), forIndex: index)
        }
        cancelEditing()
    }
    
    private func cancelEditing() {
        editingIndex = nil
        editingName = ""
    }
    
    private func removeAppName(at index: Int) {
        let appName = deviceActivityService.getAppName(forIndex: index)
        
        // Access selectedApps asynchronously to avoid blocking
        Task { @MainActor in
            let selectedApps = self.deviceActivityService.selectedApps
            
            // Get the token at this index
            let tokensArray = Array(selectedApps.applicationTokens)
            guard index < tokensArray.count else {
                print("❌ [AppManagementView] Invalid index \(index)")
                return
            }
            
            // Create new selection without this token
            var newSelection = FamilyActivitySelection()
            for (idx, token) in tokensArray.enumerated() {
                if idx != index {
                    newSelection.applicationTokens.insert(token)
                }
            }
            
            // Update the selection (this will trigger didSet and restart monitoring if needed)
            self.deviceActivityService.selectedApps = newSelection
        
            // Remove the app name and shift remaining names
            var newAppNames: [Int: String] = [:]
            for (oldIndex, name) in self.deviceActivityService.appNames {
                if oldIndex < index {
                    // Keep names before the removed index
                    newAppNames[oldIndex] = name
                } else if oldIndex > index {
                    // Shift names after the removed index down by 1
                    newAppNames[oldIndex - 1] = name
                }
                // Skip the removed index
            }
            self.deviceActivityService.appNames = newAppNames
            self.deviceActivityService.saveAppNamesMapping()
            
            // Update cached count
            self.appsCount = newSelection.applicationTokens.count
            
            print("🗑️ [AppManagementView] Removed app '\(appName)' (index \(index)) from monitoring")
        }
    }
}

#Preview {
    AppManagementView()
        .environmentObject(DeviceActivityService.shared)
}

