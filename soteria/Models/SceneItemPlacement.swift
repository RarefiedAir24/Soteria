//
//  SceneItemPlacement.swift
//  soteria
//
//  Tracks the placement and configuration of scene items on the money tree
//

import Foundation
import CoreGraphics

struct SceneItemPlacement: Codable, Identifiable {
    let id: String // Unique placement ID
    let itemId: String // Reference to SceneItem.id
    var position: PlacementPosition
    var isVisible: Bool
    var isFlipped: Bool // Horizontal flip for left/right orientation
    let placedDate: Date
    
    struct PlacementPosition: Codable {
        var x: CGFloat // Normalized position (0-1) relative to scene width
        var y: CGFloat // Normalized position (0-1) relative to scene height
        
        init(x: CGFloat, y: CGFloat) {
            // Clamp to valid range
            self.x = max(0, min(1, x))
            self.y = max(0, min(1, y))
        }
    }
    
    init(itemId: String, position: PlacementPosition, isFlipped: Bool = false) {
        self.id = UUID().uuidString
        self.itemId = itemId
        self.position = position
        self.isVisible = true
        self.isFlipped = isFlipped
        self.placedDate = Date()
    }
}

