//
//  UnlockFlowCoordinator.swift
//  soteria
//
//  Coordinates the unlock-to-placement flow for newly unlocked animals
//

import Foundation
import SwiftUI
import Combine

class UnlockFlowCoordinator: ObservableObject {
    static let shared = UnlockFlowCoordinator()
    
    @Published var currentFlow: UnlockFlow?
    
    enum UnlockFlow: Identifiable {
        case celebration(SceneItem, bonusPoints: Int)
        case placementTutorial(SceneItem)
        case completed
        
        var id: String {
            switch self {
            case .celebration(let item, _): return "celebration_\(item.id)"
            case .placementTutorial(let item): return "tutorial_\(item.id)"
            case .completed: return "completed"
            }
        }
    }
    
    private init() {}
    
    /// Start the unlock flow for a newly unlocked item
    func startUnlockFlow(for item: SceneItem, bonusPoints: Int) {
        DispatchQueue.main.async {
            self.currentFlow = .celebration(item, bonusPoints: bonusPoints)
        }
    }
    
    /// Move to placement tutorial
    func showPlacementTutorial(for item: SceneItem) {
        DispatchQueue.main.async {
            self.currentFlow = .placementTutorial(item)
        }
    }
    
    /// Complete the flow
    func completePlacement() {
        DispatchQueue.main.async {
            self.currentFlow = .completed
            
            // Clear after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.currentFlow = nil
            }
        }
    }
    
    /// Cancel the flow
    func cancelFlow() {
        DispatchQueue.main.async {
            self.currentFlow = nil
        }
    }
}
