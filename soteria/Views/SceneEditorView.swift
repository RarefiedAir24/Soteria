//
//  SceneEditorView.swift
//  soteria
//
//  UI for managing money tree scene decorations
//

import SwiftUI

struct SceneEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sceneManager = SceneManager.shared
    @StateObject private var loyaltyService = LoyaltyPointsService.shared
    
    @State private var selectedCategory: SceneItem.ItemCategory = .animal
    @State private var showRemoveConfirmation = false
    @State private var itemToRemove: SceneItemPlacement?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.9, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Scene Info Header
                    sceneInfoHeader
                    
                    // Category Picker
                    categoryPicker
                    
                    // Owned Items Grid
                    ScrollView {
                        VStack(spacing: 16) {
                            // Placed Items Section
                            if !placedItemsInCategory.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("On Your Tree")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 16),
                                        GridItem(.flexible(), spacing: 16)
                                    ], spacing: 16) {
                                        ForEach(placedItemsInCategory, id: \.id) { placement in
                                            if let item = SceneItem.catalog.first(where: { $0.id == placement.itemId }) {
                                                PlacedItemCard(
                                                    item: item,
                                                    placement: placement,
                                                    onRemove: {
                                                        itemToRemove = placement
                                                        showRemoveConfirmation = true
                                                    }
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Available Items Section
                            if !availableItemsInCategory.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Available to Place")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 16),
                                        GridItem(.flexible(), spacing: 16)
                                    ], spacing: 16) {
                                        ForEach(availableItemsInCategory) { item in
                                            AvailableItemCard(
                                                item: item,
                                                onPlace: {
                                                    placeItem(item)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // No Items Message
                            if placedItemsInCategory.isEmpty && availableItemsInCategory.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    
                                    Text("No \(selectedCategory.rawValue.lowercased()) items")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Text("Visit the shop to get more!")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 40)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Edit Scene")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        showClearAllConfirmation()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Remove Item?", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    if let placement = itemToRemove {
                        sceneManager.removeItem(placement.id)
                    }
                }
            } message: {
                Text("This will remove the item from your scene, but you'll still own it.")
            }
        }
    }
    
    // MARK: - Components
    
    private var sceneInfoHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(sceneManager.visibleItemCount) / \(sceneManager.maxActiveItems)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Items on Scene")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(ownedItemCount)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Owned Items")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding()
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryButton(
                    title: "Animals",
                    icon: "hare.fill",
                    category: .animal,
                    isSelected: selectedCategory == .animal
                ) {
                    selectedCategory = .animal
                }
                
                CategoryButton(
                    title: "Decorations",
                    icon: "sparkles",
                    category: .decoration,
                    isSelected: selectedCategory == .decoration
                ) {
                    selectedCategory = .decoration
                }
                
                CategoryButton(
                    title: "Plants",
                    icon: "leaf.fill",
                    category: .plant,
                    isSelected: selectedCategory == .plant
                ) {
                    selectedCategory = .plant
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Helpers
    
    private var ownedItems: [SceneItem] {
        SceneItem.catalog.filter { loyaltyService.hasPurchased(itemId: $0.id) }
    }
    
    private var ownedItemCount: Int {
        ownedItems.count
    }
    
    private var placedItemsInCategory: [SceneItemPlacement] {
        sceneManager.placedItems.filter { placement in
            guard let item = SceneItem.catalog.first(where: { $0.id == placement.itemId }) else { return false }
            return item.category == selectedCategory
        }
    }
    
    private var availableItemsInCategory: [SceneItem] {
        ownedItems.filter { item in
            item.category == selectedCategory && !sceneManager.isPlaced(itemId: item.id)
        }
    }
    
    private func placeItem(_ item: SceneItem) {
        let suggestedPos = sceneManager.suggestedPosition(for: item)
        let success = sceneManager.placeItem(itemId: item.id, at: suggestedPos)
        
        if !success {
            // Show error (item limit reached or already placed)
            print("Failed to place item")
        }
    }
    
    private func showClearAllConfirmation() {
        let alert = UIAlertController(
            title: "Clear Scene?",
            message: "This will remove all items from your tree. You'll still own them and can add them back later.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { _ in
            sceneManager.clearScene()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

// MARK: - Item Cards

struct PlacedItemCard: View {
    let item: SceneItem
    let placement: SceneItemPlacement
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                // Display icon
                SceneItemIcon(item: item, tintColor: .green)
                
                // Remove button
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                        .background(Circle().fill(Color.white).padding(4))
                }
                .offset(x: 30, y: -30)
            }
            
            Text(item.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text("On Scene")
                .font(.system(size: 11))
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.green.opacity(0.15)))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

struct AvailableItemCard: View {
    let item: SceneItem
    let onPlace: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                // Display icon
                SceneItemIcon(item: item, tintColor: .blue)
            }
            
            Text(item.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Button(action: onPlace) {
                Text("Place")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.blue))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Preview
struct SceneEditorView_Previews: PreviewProvider {
    static var previews: some View {
        SceneEditorView()
    }
}

