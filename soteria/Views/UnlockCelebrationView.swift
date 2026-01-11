//
//  UnlockCelebrationView.swift
//  soteria
//
//  Celebration screen shown when user unlocks a new animal
//

import SwiftUI

struct UnlockCelebrationView: View {
    let item: SceneItem
    let bonusPoints: Int
    let onContinue: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    @State private var titleScale: CGFloat = 0.5
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Dark overlay with gradient
            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.midnightSlate.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Confetti background
            UnlockConfettiView()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Achievement banner
                Text("🎉 Achievement Unlocked!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(titleScale)
                
                // Animal icon with glow ring
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    // Rotating ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange, Color.yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(rotation))
                    
                    // Animal icon
                    SceneItemIcon(item: item, tintColor: .white)
                        .frame(width: 100, height: 100)
                        .scaleEffect(scale)
                }
                .frame(height: 200)
                
                if showContent {
                    // Item details
                    VStack(spacing: 12) {
                        Text("You unlocked:")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(item.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(item.description)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    
                    // Bonus points
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                        Text("+\(bonusPoints) Bonus Points!")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .transition(.scale.combined(with: .opacity))
                    
                    // Continue button
                    Button(action: onContinue) {
                        HStack(spacing: 12) {
                            Text("Place on Your Tree")
                                .font(.system(size: 18, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: 280)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.5), radius: 12, x: 0, y: 4)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding(32)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Title animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            titleScale = 1.0
        }
        
        // Icon scale animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            scale = 1.0
        }
        
        // Rotation animation
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Content fade-in
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            showContent = true
        }
        
        // Haptic feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
}

// MARK: - Confetti Effect
struct UnlockConfettiView: View {
    @State private var confettiPieces: [UnlockConfettiPiece] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: 10, height: 10)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(piece.position)
                        .opacity(piece.opacity)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        
        for _ in 0..<50 {
            let piece = UnlockConfettiPiece(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                ),
                color: colors.randomElement() ?? .yellow,
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            confettiPieces.append(piece)
            
            // Animate falling
            withAnimation(.linear(duration: Double.random(in: 2...4))) {
                if let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                    confettiPieces[index].position.y = size.height + 20
                    confettiPieces[index].rotation += 720
                    confettiPieces[index].opacity = 0.0
                }
            }
        }
    }
}

struct UnlockConfettiPiece: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    var rotation: Double
    var opacity: Double
}

#Preview {
    UnlockCelebrationView(
        item: SceneItem.catalog.first!,
        bonusPoints: 2500,
        onContinue: {}
    )
}
