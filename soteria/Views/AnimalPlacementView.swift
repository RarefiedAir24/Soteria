//
//  AnimalPlacementView.swift
//  soteria
//
//  Enhanced Money Tree scene with arrow pad and tutorial support for placing animals
//

import SwiftUI

struct AnimalPlacementView: View {
    let item: SceneItem
    let totalSaved: Double
    let activeGoal: SavingsGoal?
    let allGoals: [SavingsGoal]
    let onComplete: () -> Void
    let showTutorial: Bool
    
    @StateObject private var sceneManager = SceneManager.shared
    @State private var selectedPlacement: SceneItemPlacement?
    @State private var positionHistory: [SceneItemPlacement.PlacementPosition] = []
    @State private var tutorialRef: InteractivePlacementTutorial?
    @State private var arrowTapCount = 0
    @AppStorage("placement_tutorial_completed") private var tutorialCompleted = false
    
    var body: some View {
        ZStack {
            // Background and tree
            VStack(spacing: 0) {
                // Money Tree Scene
                GeometryReader { geometry in
                    MoneyTreeView(
                        totalSaved: totalSaved,
                        activeGoal: activeGoal,
                        allGoals: allGoals,
                        onGoalLeafTapped: nil,
                        isEditMode: true // Enable edit mode for placement
                    )
                    .overlay(
                        // Newly placed item (if not yet confirmed)
                        newAnimalOverlay(geometry: geometry)
                    )
                }
            }
            
            // Arrow pad at bottom
            VStack {
                Spacer()
                
                ArrowPad(
                    onMove: { direction in
                        moveAnimal(by: direction.offset)
                        
                        // Notify tutorial
                        if showTutorial && !tutorialCompleted {
                            arrowTapCount += 1
                            if arrowTapCount >= 3 {
                                // Tutorial will auto-advance
                            }
                        }
                    },
                    onDone: {
                        confirmPlacement()
                    },
                    onUndo: {
                        undoLastMove()
                    },
                    showUndo: !positionHistory.isEmpty
                )
            }
            
            // Tutorial overlay (if first time)
            if showTutorial && !tutorialCompleted {
                InteractivePlacementTutorial(
                    item: item,
                    onComplete: {
                        // Tutorial complete, confirm placement and exit
                        confirmPlacement()
                    }
                )
            }
        }
        .onAppear {
            setupInitialPlacement()
        }
    }
    
    @ViewBuilder
    private func newAnimalOverlay(geometry: GeometryProxy) -> some View {
        if let placement = selectedPlacement,
           let catalogItem = SceneItem.catalog.first(where: { $0.id == placement.itemId }) {
            
            let absoluteX = (placement.position.x * geometry.size.width) - (geometry.size.width / 2)
            let absoluteY = (placement.position.y * geometry.size.height) - (geometry.size.height / 2)
            
            SceneItemIcon(item: catalogItem, tintColor: .reverBlue)
                .scaleEffect(1.2) // Slightly larger while placing
                .position(
                    x: geometry.size.width / 2 + absoluteX,
                    y: geometry.size.height / 2 + absoluteY
                )
                .overlay(
                    // Selection indicator
                    Circle()
                        .stroke(Color.reverBlue, lineWidth: 3)
                        .frame(width: catalogItem.fontSizeForIcon + 20, height: catalogItem.fontSizeForIcon + 20)
                        .position(
                            x: geometry.size.width / 2 + absoluteX,
                            y: geometry.size.height / 2 + absoluteY
                        )
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Calculate new normalized position from drag
                            let newX = (value.location.x) / geometry.size.width
                            let newY = (value.location.y) / geometry.size.height
                            
                            updateAnimalPosition(to: SceneItemPlacement.PlacementPosition(x: newX, y: newY))
                            
                            // Notify tutorial that animal was dragged
                            if showTutorial && !tutorialCompleted && arrowTapCount == 0 {
                                // First drag completed
                            }
                        }
                )
        }
    }
    
    private func setupInitialPlacement() {
        // Create initial placement at center-bottom (ground level)
        let initialPosition = SceneItemPlacement.PlacementPosition(
            x: 0.5, // Center horizontally
            y: 0.75 // Near bottom (ground level)
        )
        
        selectedPlacement = SceneItemPlacement(
            itemId: item.id,
            position: initialPosition,
            isFlipped: false
        )
        
        // Save initial position to history
        positionHistory.append(initialPosition)
    }
    
    private func updateAnimalPosition(to position: SceneItemPlacement.PlacementPosition) {
        guard var placement = selectedPlacement else { return }
        
        // Save current position to history before updating
        positionHistory.append(placement.position)
        
        // Limit history to last 10 moves
        if positionHistory.count > 10 {
            positionHistory.removeFirst()
        }
        
        // Update position
        placement.position = position
        selectedPlacement = placement
    }
    
    private func moveAnimal(by offset: CGPoint) {
        guard var placement = selectedPlacement else { return }
        
        // Save current position to history
        positionHistory.append(placement.position)
        
        // Limit history
        if positionHistory.count > 10 {
            positionHistory.removeFirst()
        }
        
        // Convert pixel offset to normalized offset (assuming ~375 width)
        let normalizedX = offset.x / 375.0
        let normalizedY = offset.y / 375.0
        
        // Update position
        var newPosition = placement.position
        newPosition.x = max(0.1, min(0.9, newPosition.x + normalizedX))
        newPosition.y = max(0.1, min(0.9, newPosition.y + normalizedY))
        
        placement.position = newPosition
        selectedPlacement = placement
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func undoLastMove() {
        guard var placement = selectedPlacement,
              positionHistory.count > 1 else { return }
        
        // Remove current position
        positionHistory.removeLast()
        
        // Restore previous position
        if let previousPosition = positionHistory.last {
            placement.position = previousPosition
            selectedPlacement = placement
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func confirmPlacement() {
        guard let placement = selectedPlacement else { return }
        
        // Place item using SceneManager
        let success = sceneManager.placeItem(itemId: placement.itemId, at: placement.position)
        
        if success {
            print("✅ [AnimalPlacement] Successfully placed \(placement.itemId)")
            
            // Haptic feedback
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            
            // Complete flow
            onComplete()
        } else {
            print("❌ [AnimalPlacement] Failed to place \(placement.itemId)")
        }
    }
}

#Preview {
    AnimalPlacementView(
        item: SceneItem.catalog.first(where: { $0.id == "cat" })!,
        totalSaved: 150.0,
        activeGoal: nil,
        allGoals: [],
        onComplete: {},
        showTutorial: true
    )
}
