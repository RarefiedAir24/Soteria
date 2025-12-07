//
//  PurchaseIntentPromptView.swift
//  soteria
//
//  Prompt user to categorize purchase intent when opening shopping apps
//
import SwiftUI
import FamilyControls
import UIKit

struct PurchaseIntentPromptView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var purchaseIntentService: PurchaseIntentService
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    
    @State private var purchaseType: PurchaseType? = nil
    @State private var selectedCategory: PlannedPurchaseCategory? = nil
    @State private var selectedMood: ImpulseMood? = nil
    @State private var moodNotes: String = ""
    @State private var showMoodNotes: Bool = false
    @State private var showConfirmation: String? = nil
    // Track which app index user selected (simpler than storing token)
    @State private var selectedAppIndex: Int? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                        
                        // First, ask which app they were trying to open
                        if selectedAppIndex == nil {
                            VStack(spacing: 20) {
                                Text("Which app were you trying to open?")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                // Show list of selected apps
                                let selectedApps = deviceActivityService.selectedApps
                                if selectedApps.applicationTokens.count == 1 {
                                    // Only one app - auto-select it
                                    Text("Opening \(selectedApps.applicationTokens.count) app")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .onAppear {
                                            selectedAppIndex = 0
                                        }
                                } else {
                                    // Multiple apps - let user select
                                    VStack(spacing: 12) {
                                        ForEach(Array(selectedApps.applicationTokens.enumerated()), id: \.element) { index, token in
                                            Button(action: {
                                                selectedAppIndex = index
                                            }) {
                                                HStack {
                                                    Image(systemName: "app.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(selectedAppIndex == index ? .white : Color(red: 0.1, green: 0.6, blue: 0.3))
                                                    
                                                    Text(deviceActivityService.getAppName(forIndex: index))
                                                        .font(.headline)
                                                        .foregroundColor(selectedAppIndex == index ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))
                                                    
                                                    Spacer()
                                                    
                                                    if selectedAppIndex == index {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(selectedAppIndex == index ? Color(red: 0.1, green: 0.6, blue: 0.3) : Color(red: 0.95, green: 0.95, blue: 0.95))
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 32)
                                }
                            }
                        }
                        // Then ask purchase type (only if app is selected)
                        else if selectedAppIndex != nil && purchaseType == nil {
                            Text("Is this a planned purchase or impulse?")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Purchase Type Selection
                            VStack(spacing: 16) {
                                HStack(spacing: 20) {
                                    // Planned Purchase Button
                                    Button(action: {
                                        purchaseType = .planned
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "calendar.circle.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                            Text("Planned")
                                                .font(.headline)
                                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 24)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                                        )
                                    }
                                    
                                    // Impulse Purchase Button
                                    Button(action: {
                                        purchaseType = .impulse
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "bolt.circle.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.orange)
                                            Text("Impulse")
                                                .font(.headline)
                                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 24)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 0.98, green: 0.95, blue: 0.95))
                                        )
                                    }
                                }
                                .padding(.horizontal, 32)
                            }
                        }
                        
                        // Planned Purchase - Category Selection
                        else if purchaseType == .planned {
                            VStack(spacing: 20) {
                                if selectedCategory == nil {
                                    Text("What category is this purchase?")
                                        .font(.headline)
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                        .multilineTextAlignment(.center)
                                    
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                        ForEach(PlannedPurchaseCategory.allCases, id: \.self) { category in
                                            Button(action: {
                                                print("✅ [PurchaseIntentPromptView] Category selected: \(category.displayName)")
                                                selectedCategory = category
                                            }) {
                                                VStack(spacing: 8) {
                                                    Image(systemName: category.icon)
                                                        .font(.system(size: 32))
                                                        .foregroundColor(selectedCategory == category ? .white : Color(red: 0.1, green: 0.6, blue: 0.3))
                                                    Text(category.displayName)
                                                        .font(.subheadline)
                                                        .foregroundColor(selectedCategory == category ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))
                                                        .multilineTextAlignment(.center)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 16)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(selectedCategory == category ? Color(red: 0.1, green: 0.6, blue: 0.3) : Color(red: 0.95, green: 0.95, blue: 0.95))
                                                )
                                            }
                                        }
                                    }
                                } else {
                                    // Category selected - show Continue button
                                    VStack(spacing: 20) {
                                        Text("Selected: \(selectedCategory?.displayName ?? "")")
                                            .font(.headline)
                                            .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                        
                                        Button(action: {
                                            print("✅ [PurchaseIntentPromptView] Continue button tapped for planned purchase")
                                            handleComplete()
                                        }) {
                                            Text("Continue")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.vertical, 14)
                                                .frame(maxWidth: .infinity)
                                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.1, green: 0.6, blue: 0.3)))
                                        }
                                        .padding(.horizontal, 32)
                                        
                                        Button(action: {
                                            selectedCategory = nil
                                        }) {
                                            Text("Change Category")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Impulse Purchase - Mood Selection
                        else if purchaseType == .impulse {
                            VStack(spacing: 20) {
                                if selectedMood == nil {
                                    Text("How are you feeling?")
                                        .font(.headline)
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                        .multilineTextAlignment(.center)
                                    
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                        ForEach(ImpulseMood.allCases, id: \.self) { mood in
                                            Button(action: {
                                                print("✅ [PurchaseIntentPromptView] Mood selected: \(mood.displayName)")
                                                selectedMood = mood
                                                if mood == .other {
                                                    showMoodNotes = true
                                                }
                                            }) {
                                                VStack(spacing: 8) {
                                                    Image(systemName: mood.icon)
                                                        .font(.system(size: 32))
                                                        .foregroundColor(selectedMood == mood ? .white : .orange)
                                                    Text(mood.displayName)
                                                        .font(.subheadline)
                                                        .foregroundColor(selectedMood == mood ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))
                                                        .multilineTextAlignment(.center)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 16)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(selectedMood == mood ? Color.orange : Color(red: 0.98, green: 0.95, blue: 0.95))
                                                )
                                            }
                                        }
                                    }
                                    
                                    // Free text field for mood notes (especially for "other")
                                    if showMoodNotes || selectedMood == .other {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Tell us more (optional)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            TextField("How are you feeling?", text: $moodNotes, axis: .vertical)
                                                .textFieldStyle(.plain)
                                                .padding(12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                                )
                                                .lineLimit(3...6)
                                        }
                                        .padding(.horizontal, 32)
                                    }
                                } else {
                                    // Mood selected - show Continue button
                                    VStack(spacing: 20) {
                                        Text("Selected: \(selectedMood?.displayName ?? "")")
                                            .font(.headline)
                                            .foregroundColor(.orange)
                                        
                                        // Free text field for mood notes (especially for "other")
                                        if showMoodNotes || selectedMood == .other {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Tell us more (optional)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                                TextField("How are you feeling?", text: $moodNotes, axis: .vertical)
                                                    .textFieldStyle(.plain)
                                                    .padding(12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                                    )
                                                    .lineLimit(3...6)
                                            }
                                            .padding(.horizontal, 32)
                                        }
                                        
                                        Button(action: {
                                            print("✅ [PurchaseIntentPromptView] Continue button tapped for impulse purchase")
                                            handleComplete()
                                        }) {
                                            Text("Continue")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.vertical, 14)
                                                .frame(maxWidth: .infinity)
                                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange))
                                        }
                                        .padding(.horizontal, 32)
                                        
                                        Button(action: {
                                            selectedMood = nil
                                            showMoodNotes = false
                                        }) {
                                            Text("Change Mood")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Show confirmation message after completing
                        if let confirmation = showConfirmation {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                
                                Text(confirmation)
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.vertical, 40)
                }
            }
            .navigationTitle("Purchase Intent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleComplete() {
        print("✅ [PurchaseIntentPromptView] handleComplete() called")
        print("   - Purchase type: \(purchaseType?.rawValue ?? "nil")")
        print("   - Category: \(selectedCategory?.rawValue ?? "nil")")
        print("   - Mood: \(selectedMood?.rawValue ?? "nil")")
        
        let intent = PurchaseIntent(
            purchaseType: purchaseType ?? .impulse,
            category: purchaseType == .planned ? selectedCategory : nil,
            impulseMood: purchaseType == .impulse ? selectedMood : nil,
            impulseMoodNotes: purchaseType == .impulse && !moodNotes.isEmpty ? moodNotes : nil
        )
        
        purchaseIntentService.recordIntent(intent)
        print("✅ [PurchaseIntentPromptView] Intent recorded")
        
        // Record dismissal time to prevent immediate re-prompt
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastPurchaseIntentPromptTime")
        
        // Store which app was selected for metrics (we already have the index)
        let appIndex = selectedAppIndex
        
        // Temporarily unblock apps so user can continue
        // Pass purchase intent data and app info for metrics tracking
        deviceActivityService.temporarilyUnblock(
            durationMinutes: 15,
            purchaseType: purchaseType?.rawValue,
            category: purchaseType == .planned ? selectedCategory?.rawValue : nil,
            mood: purchaseType == .impulse ? selectedMood?.rawValue : nil,
            appIndex: appIndex
        )
        print("✅ [PurchaseIntentPromptView] Apps unblocked (app index: \(appIndex ?? -1))")
        
        // Show confirmation message before dismissing
        // Note: We unblock all selected apps since we can't identify the specific app that was blocked
        let appCount = deviceActivityService.selectedApps.applicationTokens.count
        if appCount == 1 {
            showConfirmation = "App is unblocked for 15 minutes.\nYou can now open it."
        } else {
            showConfirmation = "All \(appCount) selected apps are unblocked for 15 minutes.\nYou can now open the app you want to use."
        }
        
        // Dismiss after showing confirmation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.dismiss()
        }
    }
}

#Preview {
    PurchaseIntentPromptView()
        .environmentObject(PurchaseIntentService.shared)
        .environmentObject(DeviceActivityService.shared)
}

