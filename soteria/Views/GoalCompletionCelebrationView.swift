//
//  GoalCompletionCelebrationView.swift
//  soteria
//
//  Celebration view with confetti and balloons when a goal is completed
//

import SwiftUI

struct GoalCompletionCelebrationView: View {
    let goal: SavingsGoal
    let onDismiss: () -> Void
    
    @State private var showConfetti = false
    @State private var showBalloons = false
    @State private var confettiOffset: CGFloat = 0
    @State private var balloonOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.reverBlueLight.opacity(0.1), Color.reverBlueDark.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Celebration Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.reverBlueLight, Color.reverBlueDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.reverBlue.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                .scaleEffect(showConfetti ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)
                
                // Congratulations Text
                VStack(spacing: 12) {
                    Text("🎉 Congratulations! 🎉")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.midnightSlate)
                        .multilineTextAlignment(.center)
                    
                    Text("You've reached your goal!")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.softGraphite)
                        .multilineTextAlignment(.center)
                    
                    Text(goal.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.reverBlue)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Goal Amount
                    VStack(spacing: 4) {
                        Text("$\(String(format: "%.2f", goal.completedAmount ?? goal.currentAmount))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.reverBlue)
                        
                        Text("Saved!")
                            .font(.system(size: 16))
                            .foregroundColor(.softGraphite)
                    }
                    .padding(.top, 8)
                }
                .opacity(showConfetti ? 1.0 : 0.0)
                .offset(y: showConfetti ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: showConfetti)
                
                Spacer()
                
                // Dismiss Button
                Button(action: {
                    onDismiss()
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.reverBlueLight, Color.reverBlueDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.reverBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .opacity(showConfetti ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(0.8), value: showConfetti)
            }
            
            // Confetti particles
            GeometryReader { geometry in
                ForEach(0..<50, id: \.self) { index in
                    ConfettiView(
                        index: index,
                        screenWidth: geometry.size.width,
                        screenHeight: geometry.size.height,
                        offset: confettiOffset
                    )
                }
            }
            
            // Balloon particles
            GeometryReader { geometry in
                ForEach(0..<8, id: \.self) { index in
                    BalloonView(
                        index: index,
                        screenWidth: geometry.size.width,
                        screenHeight: geometry.size.height,
                        offset: balloonOffset
                    )
                }
            }
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private func startCelebration() {
        // Start confetti animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            showConfetti = true
        }
        
        // Animate confetti falling
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            confettiOffset = 1000
        }
        
        // Animate balloons rising
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            balloonOffset = -1000
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    let index: Int
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let offset: CGFloat
    
    private var colors: [Color] {
        [Color.reverBlue, Color.reverBlueLight, Color.reverBlueDark, Color.green, Color.yellow, Color.orange]
    }
    
    private var xPosition: CGFloat {
        // Use index to create pseudo-random but consistent positions
        let seed = Double(index) * 137.5 // Golden angle for distribution
        return CGFloat(seed.truncatingRemainder(dividingBy: Double(screenWidth)))
    }
    
    private var color: Color {
        colors[index % colors.count]
    }
    
    private var rotation: Double {
        Double(index) * 45.0 + Double(offset) * 0.5
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .position(
                x: xPosition,
                y: -50 + offset + CGFloat(index) * 20
            )
    }
}

// MARK: - Balloon View

struct BalloonView: View {
    let index: Int
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let offset: CGFloat
    
    private var colors: [Color] {
        [Color.red, Color.blue, Color.green, Color.yellow, Color.pink, Color.orange]
    }
    
    private var xPosition: CGFloat {
        // Use index to create pseudo-random but consistent positions
        let seed = Double(index) * 137.5 // Golden angle for distribution
        return CGFloat(seed.truncatingRemainder(dividingBy: Double(screenWidth - 100))) + 50
    }
    
    private var color: Color {
        colors[index % colors.count]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Balloon
            Ellipse()
                .fill(color)
                .frame(width: 40, height: 50)
                .overlay(
                    Ellipse()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            // String
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 1, height: 30)
        }
        .position(
            x: xPosition,
            y: screenHeight + 50 + offset - CGFloat(index) * 100
        )
    }
}

#Preview {
    GoalCompletionCelebrationView(
        goal: SavingsGoal(
            id: "test",
            name: "Trip to Hawaii",
            targetAmount: 2000,
            currentAmount: 2000,
            category: .trip
        ),
        onDismiss: {}
    )
}

