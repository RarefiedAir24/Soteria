//
//  InteractivePlacementTutorial.swift
//  soteria
//
//  Step-by-step tutorial for placing newly unlocked animals
//

import SwiftUI

struct InteractivePlacementTutorial: View {
    let item: SceneItem
    let onComplete: () -> Void
    
    @State private var tutorialStep: TutorialStep = .welcome
    @State private var hasPlacedAnimal = false
    @State private var arrowTapsCount = 0
    @AppStorage("placement_tutorial_completed") private var tutorialCompleted = false
    
    enum TutorialStep {
        case welcome
        case dragToPosition
        case fineTuneWithArrows
        case confirmPlacement
        case futureReference
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(tutorialStep == .welcome || tutorialStep == .futureReference ? 0.85 : 0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissal by tapping overlay
                }
            
            // Tutorial card
            VStack {
                if tutorialStep == .welcome || tutorialStep == .futureReference {
                    Spacer()
                    tutorialCard
                        .padding(24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    Spacer()
                } else {
                    // Top-aligned for other steps
                    Spacer()
                        .frame(height: 100)
                    
                    tutorialCard
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
            }
        }
        .animation(.spring(response: 0.4), value: tutorialStep)
    }
    
    @ViewBuilder
    private var tutorialCard: some View {
        switch tutorialStep {
        case .welcome:
            TutorialCard(
                icon: "hand.wave.fill",
                iconColor: .yellow,
                title: "Let's Place Your \(item.name)!",
                description: "Your \(item.name.lowercased()) is ready to join your Money Tree scene. Let me show you how to position it perfectly!",
                buttonText: "Let's Go!",
                buttonAction: {
                    withAnimation {
                        tutorialStep = .dragToPosition
                    }
                }
            )
            
        case .dragToPosition:
            TutorialCard(
                icon: "hand.draw",
                iconColor: .blue,
                title: "Drag to Position",
                description: "Tap and drag your \(item.name.lowercased()) to place it on the ground. Don't worry about being exact - we'll fine-tune in the next step!",
                showSkip: false
            )
            
        case .fineTuneWithArrows:
            TutorialCard(
                icon: "arrow.up.and.down.and.arrow.left.and.right",
                iconColor: .purple,
                title: "Fine-Tune with Arrows",
                description: "Tap the arrow buttons below to move your \(item.name.lowercased()) exactly where you want it. Each tap moves it 10 pixels!",
                showSkip: false,
                hint: "Try tapping the arrows a few times"
            )
            
        case .confirmPlacement:
            TutorialCard(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                title: "Perfect! Tap Done",
                description: "Your \(item.name.lowercased()) is positioned perfectly. Tap the 'Done' button below to confirm its placement.",
                showSkip: false
            )
            
        case .futureReference:
            TutorialCard(
                icon: "lightbulb.fill",
                iconColor: .orange,
                title: "Tips for Later",
                description: """
                To reposition any animal:
                
                1️⃣ Long press (0.5 sec) to select it
                2️⃣ Drag or use arrows to move it
                3️⃣ Tap "Done" to confirm
                
                Quick tap to flip orientation! ↔️
                
                You can rearrange your scene anytime!
                """,
                buttonText: "Got it!",
                buttonAction: {
                    tutorialCompleted = true
                    onComplete()
                }
            )
        }
    }
    
    // Public methods to be called by MoneyTreeView
    func onAnimalDragged() {
        guard tutorialStep == .dragToPosition else { return }
        hasPlacedAnimal = true
        
        // Auto-advance to arrow step after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                tutorialStep = .fineTuneWithArrows
            }
        }
    }
    
    func onArrowTapped() {
        guard tutorialStep == .fineTuneWithArrows else { return }
        arrowTapsCount += 1
        
        // After 3 arrow taps, advance to confirm step
        if arrowTapsCount >= 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    tutorialStep = .confirmPlacement
                }
            }
        }
    }
    
    func onDonePressed() {
        guard tutorialStep == .confirmPlacement else { return }
        withAnimation {
            tutorialStep = .futureReference
        }
    }
}

// MARK: - Tutorial Card Component
struct TutorialCard: View {
    let icon: String
    var iconColor: Color = .reverBlue
    let title: String
    let description: String
    var buttonText: String? = nil
    var buttonAction: (() -> Void)? = nil
    var showSkip: Bool = false
    var hint: String? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.midnightSlate)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.softGraphite)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let hint = hint {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                        Text(hint)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            
            // Button
            if let buttonText = buttonText, let action = buttonAction {
                Button(action: action) {
                    Text(buttonText)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.reverBlueLight, Color.reverBlueDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .reverBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cloudWhite)
                .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 10)
        )
    }
}

#Preview {
    InteractivePlacementTutorial(
        item: SceneItem.catalog.first(where: { $0.id == "cat" })!,
        onComplete: {}
    )
}
