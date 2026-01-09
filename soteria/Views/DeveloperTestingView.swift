//
//  DeveloperTestingView.swift
//  soteria
//
//  Developer testing utilities for loyalty system
//

import SwiftUI

struct DeveloperTestingView: View {
    @StateObject private var loyaltyService = LoyaltyPointsService.shared
    @StateObject private var sceneManager = SceneManager.shared
    @State private var pointsToAdd: String = "1000"
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Loyalty Points Section
                Section(header: Text("Loyalty Points Testing")) {
                    HStack {
                        Text("Current Points:")
                        Spacer()
                        Text("\(loyaltyService.totalPoints)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Lifetime Earned:")
                        Spacer()
                        Text("\(loyaltyService.lifetimePointsEarned)")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        TextField("Points to add", text: $pointsToAdd)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Add Points") {
                            if let points = Int(pointsToAdd) {
                                loyaltyService.addPointsManual(points, confidence: 1.0)
                                alertMessage = "Added \(points) loyalty points!"
                                showAlert = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button("Add 5,000 Points (Quick Test)") {
                        loyaltyService.addPointsManual(5000, confidence: 1.0)
                        alertMessage = "Added 5,000 points for testing!"
                        showAlert = true
                    }
                    .foregroundColor(.green)
                    
                    Button("Reset All Points") {
                        loyaltyService.resetAll()
                        alertMessage = "Reset all loyalty points and purchases!"
                        showAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                // MARK: - Purchased Items Section
                Section(header: Text("Purchased Items")) {
                    Text("Total Purchased: \(loyaltyService.purchasedItemIds.count)")
                        .font(.headline)
                    
                    if loyaltyService.purchasedItemIds.isEmpty {
                        Text("No items purchased yet")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(Array(loyaltyService.purchasedItemIds), id: \.self) { itemId in
                            if let item = SceneItem.catalog.first(where: { $0.id == itemId }) {
                                HStack {
                                    SceneItemIcon(item: item, tintColor: .blue)
                                    Text(item.name)
                                    Spacer()
                                    Text("\(item.pointCost) pts")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    Button("Unlock All Animals (Testing)") {
                        unlockAllAnimals()
                        alertMessage = "Unlocked all 16 animals for testing!"
                        showAlert = true
                    }
                    .foregroundColor(.orange)
                }
                
                // MARK: - Scene Items Section
                Section(header: Text("Scene Items")) {
                    Text("Placed on Scene: \(sceneManager.placedItems.count)")
                        .font(.headline)
                    
                    if sceneManager.placedItems.isEmpty {
                        Text("No items placed on scene")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(sceneManager.placedItems) { placement in
                            if let item = SceneItem.catalog.first(where: { $0.id == placement.itemId }) {
                                HStack {
                                    SceneItemIcon(item: item, tintColor: .green)
                                    Text(item.name)
                                    Spacer()
                                    Text(placement.isFlipped ? "← Flipped" : "→ Normal")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    if !sceneManager.placedItems.isEmpty {
                        Button("Clear All Scene Items") {
                            sceneManager.clearScene()
                            alertMessage = "Cleared all items from scene!"
                            showAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // MARK: - Quick Actions Section
                Section(header: Text("Quick Test Scenarios")) {
                    Button("Scenario 1: New User") {
                        loyaltyService.resetAll()
                        sceneManager.clearScene()
                        alertMessage = "Reset to new user state!"
                        showAlert = true
                    }
                    
                    Button("Scenario 2: Active User (1000 pts)") {
                        loyaltyService.resetAll()
                        sceneManager.clearScene()
                        loyaltyService.addPointsManual(1000, confidence: 1.0)
                        alertMessage = "Set up as active user with 1000 points!"
                        showAlert = true
                    }
                    
                    Button("Scenario 3: Power User (10000 pts + All Animals)") {
                        loyaltyService.resetAll()
                        sceneManager.clearScene()
                        loyaltyService.addPointsManual(10000, confidence: 1.0)
                        unlockAllAnimals()
                        alertMessage = "Set up as power user with 10000 points and all animals!"
                        showAlert = true
                    }
                }
                
                // MARK: - Icon Test Section
                Section(header: Text("Icon Rendering Test")) {
                    Text("All 16 Animals:")
                        .font(.headline)
                    
                    ForEach(SceneItem.catalog.filter { $0.category == .animal }) { item in
                        HStack {
                            SceneItemIcon(item: item, tintColor: .blue)
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.body)
                                Text("\(item.pointCost) pts • \(item.size.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(item.iconName)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("🔧 Developer Testing")
            .alert("Success", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func unlockAllAnimals() {
        let animalIds = SceneItem.catalog
            .filter { $0.category == .animal }
            .map { $0.id }
        
        // Add each animal as "purchased" directly to the set for testing
        for animalId in animalIds {
            if !loyaltyService.hasPurchased(itemId: animalId) {
                // Add to the set directly for testing (bypassing normal purchase flow)
                loyaltyService.purchasedItemIds.insert(animalId)
            }
        }
        
        // Force save by triggering a point change (add 0 to trigger save)
        loyaltyService.addPointsManual(0, confidence: 1.0)
    }
}

// MARK: - Preview
#Preview {
    DeveloperTestingView()
}

