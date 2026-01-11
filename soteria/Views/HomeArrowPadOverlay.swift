//
//  HomeArrowPadOverlay.swift
//  soteria
//
//  Arrow pad displayed below the tree scene when editing decorations
//

import SwiftUI

struct HomeArrowPadOverlay: View {
    @StateObject private var tutorialManager = DecorationEditTutorialManager.shared
    @StateObject private var sceneManager = SceneManager.shared
    @State private var showScrollHint: Bool = true
    
    var body: some View {
        Group {
            if let selectedId = tutorialManager.selectedItemId,
               !tutorialManager.showTutorial, // Only show after tutorial is dismissed
               let selectedPlacement = sceneManager.visiblePlacements.first(where: { $0.id == selectedId }) {
                
                VStack(spacing: 0) {
                    // Scroll hint (shows for 3 seconds)
                    if showScrollHint {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.reverBlue)
                            
                            Text("Scroll up to see decoration if needed")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.softGraphite)
                            
                            Image(systemName: "hand.draw.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.reverBlue.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.dreamMist)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            // Auto-hide after 4 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                withAnimation {
                                    showScrollHint = false
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .background(Color.softGraphite.opacity(0.3))
                    
                    ArrowPad(
                        onMove: { direction in
                            moveItem(selectedPlacement, by: direction.offset)
                        },
                        onDone: {
                            // Fully exit edit mode
                            withAnimation {
                                tutorialManager.exitEditMode()
                            }
                        },
                        onUndo: {
                            // Undo not implemented for retroactive editing yet
                        },
                        showUndo: false
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color.mistGray)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    // Reset scroll hint when arrow pad appears
                    showScrollHint = true
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: tutorialManager.selectedItemId)
    }
    
    private func moveItem(_ placement: SceneItemPlacement, by offset: CGPoint) {
        // Convert pixel offset to normalized offset (assuming ~375 width)
        let normalizedX = offset.x / 375.0
        let normalizedY = offset.y / 375.0
        
        // Calculate new position
        var newPosition = placement.position
        newPosition.x = max(0.1, min(0.9, newPosition.x + normalizedX))
        newPosition.y = max(0.1, min(0.9, newPosition.y + normalizedY))
        
        // Update position
        sceneManager.updateItemPosition(placement.id, to: newPosition)
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}
