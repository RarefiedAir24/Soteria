//
//  AchievementUnlockOfferView.swift
//  soteria
//
//  Shows optional unlock offer when user completes a goal or milestone
//

import SwiftUI

struct AchievementUnlockOfferView: View {
    let pendingUnlock: AchievementsService.PendingUnlock
    @Binding var isPresented: Bool
    @ObservedObject private var achievementsService = AchievementsService.shared
    @State private var showCelebration = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section: Unlock preview
                unlockPreviewSection
                
                // Bottom section: Buttons
                actionButtonsSection
            }
            .frame(maxWidth: 350)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            
            if showCelebration {
                AchievementCelebrationView(
                    itemName: pendingUnlock.itemName,
                    bonusPoints: pendingUnlock.bonusPoints,
                    isPresented: $showCelebration
                )
            }
        }
    }
    
    private var unlockPreviewSection: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text("🎁 OPTIONAL UNLOCK")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)
                    .tracking(1)
                
                Text("Want to celebrate?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.midnightSlate)
            }
            .padding(.top, 32)
            
            // Item preview
            if let item = pendingUnlock.item {
                VStack(spacing: 12) {
                    // Icon
                    SceneItemIcon(item: item, tintColor: .reverBlue)
                        .frame(width: 80, height: 80)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.reverBlue.opacity(0.1))
                        )
                    
                    // Name
                    Text(item.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    // Description
                    Text(item.description)
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // Bonus points highlight
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                    Text("+\(pendingUnlock.bonusPoints) Bonus Points")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.reverBlue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                Text("This decoration will appear on your tree!")
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Divider()
            
            // Unlock button
            Button(action: {
                withAnimation {
                    if achievementsService.unlockItem(pendingUnlock.itemId) {
                        // Show celebration
                        showCelebration = true
                        
                        // Haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        // Dismiss after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            isPresented = false
                        }
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Yes, Unlock It!")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.reverBlue, Color.reverBlue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            // Decline button
            Button(action: {
                withAnimation {
                    achievementsService.declineUnlock(pendingUnlock.itemId)
                    isPresented = false
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle")
                    Text("No Thanks, Just Give Me the Points")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Celebration View

struct AchievementCelebrationView: View {
    let itemName: String
    let bonusPoints: Int
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Confetti animation
                Text("🎉")
                    .font(.system(size: 80))
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                VStack(spacing: 12) {
                    Text("Unlocked!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(itemName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                        Text("+\(bonusPoints) Points")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }
                .scaleEffect(scale)
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}
