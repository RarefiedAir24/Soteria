//
//  SceneManager.swift
//  soteria
//
//  Manages the placement and configuration of scene items on the money tree
//

import Foundation
import Combine
import CoreGraphics

@MainActor
class SceneManager: ObservableObject {
    static let shared = SceneManager()
    
    // MARK: - Published Properties
    @Published var placedItems: [SceneItemPlacement] = []
    
    // MARK: - Constants
    private let placedItemsKey = "scene_placed_items"
    let maxActiveItems = 15 // Limit to prevent clutter (public for UI display)
    
    // MARK: - Initialization
    private init() {
        loadPlacedItems()
    }
    
    // MARK: - Item Placement
    
    /// Place a new item on the scene
    /// - Parameters:
    ///   - itemId: The SceneItem ID
    ///   - position: Normalized position (0-1, 0-1)
    /// - Returns: True if placed successfully
    func placeItem(itemId: String, at position: SceneItemPlacement.PlacementPosition) -> Bool {
        // Check if item is already placed
        if placedItems.contains(where: { $0.itemId == itemId }) {
            print("⚠️ SceneManager: Item \(itemId) is already placed")
            return false
        }
        
        // Check item limit
        let visibleCount = placedItems.filter { $0.isVisible }.count
        if visibleCount >= maxActiveItems {
            print("⚠️ SceneManager: Maximum items reached (\(maxActiveItems))")
            return false
        }
        
        // Check if user owns the item
        guard LoyaltyPointsService.shared.hasPurchased(itemId: itemId) else {
            print("⚠️ SceneManager: User doesn't own item \(itemId)")
            return false
        }
        
        let placement = SceneItemPlacement(itemId: itemId, position: position)
        placedItems.append(placement)
        savePlacedItems()
        
        print("✅ SceneManager: Placed item \(itemId) at (\(position.x), \(position.y))")
        return true
    }
    
    /// Remove an item from the scene (but keep ownership)
    func removeItem(_ placementId: String) {
        placedItems.removeAll { $0.id == placementId }
        savePlacedItems()
        print("✅ SceneManager: Removed item placement \(placementId)")
    }
    
    /// Update item position (for drag & drop)
    func updateItemPosition(_ placementId: String, to position: SceneItemPlacement.PlacementPosition) {
        if let index = placedItems.firstIndex(where: { $0.id == placementId }) {
            placedItems[index].position = position
            savePlacedItems()
        }
    }
    
    /// Toggle item visibility
    func toggleItemVisibility(_ placementId: String) {
        if let index = placedItems.firstIndex(where: { $0.id == placementId }) {
            placedItems[index].isVisible.toggle()
            savePlacedItems()
            print("✅ SceneManager: Toggled visibility for \(placementId)")
        }
    }
    
    /// Toggle item horizontal flip (for left/right orientation)
    func toggleFlip(placementId: String) {
        if let index = placedItems.firstIndex(where: { $0.id == placementId }) {
            placedItems[index].isFlipped.toggle()
            savePlacedItems()
            print("✅ SceneManager: Flipped \(placementId) to \(placedItems[index].isFlipped ? "left" : "right")")
        }
    }
    
    /// Get item by SceneItem ID
    func getPlacement(for itemId: String) -> SceneItemPlacement? {
        return placedItems.first { $0.itemId == itemId }
    }
    
    /// Check if an item is placed on the scene
    func isPlaced(itemId: String) -> Bool {
        return placedItems.contains { $0.itemId == itemId }
    }
    
    /// Get number of visible items
    var visibleItemCount: Int {
        return placedItems.filter { $0.isVisible }.count
    }
    
    /// Get all visible placements
    var visiblePlacements: [SceneItemPlacement] {
        return placedItems.filter { $0.isVisible }
    }
    
    /// Clear all items from scene
    func clearScene() {
        placedItems.removeAll()
        savePlacedItems()
        print("✅ SceneManager: Cleared all items from scene")
    }
    
    // MARK: - Suggested Positions
    
    /// Get a suggested position for a new item based on its type
    func suggestedPosition(for item: SceneItem) -> SceneItemPlacement.PlacementPosition {
        switch item.position {
        case .ground:
            // Random position on ground (bottom 30%)
            return SceneItemPlacement.PlacementPosition(
                x: CGFloat.random(in: 0.2...0.8),
                y: CGFloat.random(in: 0.7...0.9)
            )
        case .sky:
            // Random position in sky (top 40%)
            return SceneItemPlacement.PlacementPosition(
                x: CGFloat.random(in: 0.1...0.9),
                y: CGFloat.random(in: 0.1...0.4)
            )
        case .tree:
            // Random position near tree center
            return SceneItemPlacement.PlacementPosition(
                x: CGFloat.random(in: 0.4...0.6),
                y: CGFloat.random(in: 0.4...0.6)
            )
        case .anywhere:
            // Random position anywhere
            return SceneItemPlacement.PlacementPosition(
                x: CGFloat.random(in: 0.2...0.8),
                y: CGFloat.random(in: 0.3...0.8)
            )
        }
    }
    
    // MARK: - Persistence
    
    private func loadPlacedItems() {
        if let data = UserDefaults.standard.data(forKey: placedItemsKey),
           let items = try? JSONDecoder().decode([SceneItemPlacement].self, from: data) {
            placedItems = items
            print("✅ SceneManager: Loaded \(items.count) placed items")
        }
    }
    
    private func savePlacedItems() {
        if let data = try? JSONEncoder().encode(placedItems) {
            UserDefaults.standard.set(data, forKey: placedItemsKey)
        }
        
        // Sync to AWS in background
        Task {
            await syncToAWS()
        }
    }
    
    // MARK: - AWS Cloud Sync
    
    func syncToAWS() async {
        let data = ScenePlacementData(placements: placedItems)
        
        do {
            try await AWSDataService.shared.syncData(data, dataType: .scenePlacements)
            print("✅ SceneManager: Synced \(placedItems.count) items to AWS")
        } catch {
            // Silently fail AWS sync - local UserDefaults is source of truth
            // This allows offline usage and development/testing without AWS access
            #if DEBUG
            print("⚠️ SceneManager: AWS sync unavailable (data saved locally)")
            #endif
        }
    }
    
    func loadFromAWS() async {
        // Only load from AWS if we have no local data
        guard placedItems.isEmpty else {
            print("ℹ️ SceneManager: Local data exists, skipping AWS load")
            return
        }
        
        do {
            let dataArray: [ScenePlacementData] = try await AWSDataService.shared.getData(dataType: .scenePlacements)
            
            guard let data = dataArray.first else {
                print("ℹ️ SceneManager: No scene data in AWS")
                return
            }
            
            await MainActor.run {
                self.placedItems = data.placements
                savePlacedItems()
                print("✅ SceneManager: Loaded \(placedItems.count) items from AWS")
            }
        } catch {
            print("ℹ️ SceneManager: No scene data in AWS or failed to load: \(error.localizedDescription)")
        }
    }
}

// MARK: - Scene Placement Data Model for AWS Sync
struct ScenePlacementData: Codable {
    let placements: [SceneItemPlacement]
}

