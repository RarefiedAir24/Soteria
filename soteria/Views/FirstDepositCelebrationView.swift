//
//  FirstDepositCelebrationView.swift
//  soteria
//
//  Big congratulations graphic when user makes their first deposit
//

import SwiftUI

struct FirstDepositCelebrationView: View {
    let depositAmount: Double
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var showBalloons = false
    @State private var confettiOffset: CGFloat = 0
    @State private var balloonOffset: CGFloat = 0
    @State private var treeScale: CGFloat = 0.5
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: depositAmount)) ?? "$\(String(format: "%.2f", depositAmount))"
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.reverBlueLight.opacity(0.2),
                    Color.reverBlueDark.opacity(0.15),
                    Color.dreamMist.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Big Tree Icon
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.reverBlue.opacity(0.3),
                                    Color.reverBlue.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .blur(radius: 20)
                    
                    // Tree icon
                    Image(systemName: "tree.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.reverBlueLight, Color.reverBlueDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(treeScale)
                        .shadow(color: Color.reverBlue.opacity(0.5), radius: 20, x: 0, y: 10)
                }
                .padding(.bottom, 40)
                
                // Congratulations Text
                VStack(spacing: 16) {
                    Text("🎉 Congratulations! 🎉")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.midnightSlate)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 30)
                    
                    Text("You've planted your first seed!")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.softGraphite)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 30)
                    
                    // Deposit Amount
                    VStack(spacing: 8) {
                        Text("First Deposit")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.softGraphite)
                        
                        Text(formattedAmount)
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.reverBlue)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cloudWhite)
                            .shadow(color: Color.reverBlue.opacity(0.2), radius: 15, x: 0, y: 8)
                    )
                    .opacity(showContent ? 1.0 : 0.0)
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    
                    Text("Your money tree is starting to grow! 🌳")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.softGraphite)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.bottom, 60)
                
                Spacer()
                
                // Dismiss Button
                Button(action: {
                    onDismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Continue Growing")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.reverBlueLight, Color.reverBlueDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.reverBlue.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .opacity(showContent ? 1.0 : 0.0)
                .scaleEffect(showContent ? 1.0 : 0.9)
            }
            
            // Confetti particles
            if showConfetti {
                GeometryReader { geometry in
                    ForEach(0..<80, id: \.self) { index in
                        FirstDepositConfettiView(
                            index: index,
                            screenWidth: geometry.size.width,
                            screenHeight: geometry.size.height,
                            offset: confettiOffset
                        )
                    }
                }
            }
            
            // Balloon particles
            if showBalloons {
                GeometryReader { geometry in
                    ForEach(0..<12, id: \.self) { index in
                        FirstDepositBalloonView(
                            index: index,
                            screenWidth: geometry.size.width,
                            screenHeight: geometry.size.height,
                            offset: balloonOffset
                        )
                    }
                }
            }
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private func startCelebration() {
        // Animate tree icon
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            treeScale = 1.0
        }
        
        // Show content with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
        
        // Start confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showConfetti = true
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                confettiOffset = 1000
            }
        }
        
        // Start balloons
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            showBalloons = true
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                balloonOffset = -1000
            }
        }
    }
}

// MARK: - Confetti View (Reused from GoalCompletionCelebrationView)
struct FirstDepositConfettiView: View {
    let index: Int
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let offset: CGFloat
    
    private var colors: [Color] {
        [Color.reverBlue, Color.reverBlueLight, Color.reverBlueDark, Color.green, Color.yellow, Color.orange, Color.pink]
    }
    
    private var xPosition: CGFloat {
        let seed = Double(index) * 137.5
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
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(rotation))
            .position(
                x: xPosition,
                y: -50 + offset + CGFloat(index) * 15
            )
    }
}

// MARK: - Balloon View (Reused from GoalCompletionCelebrationView)
struct FirstDepositBalloonView: View {
    let index: Int
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let offset: CGFloat
    
    private var colors: [Color] {
        [Color.red, Color.blue, Color.green, Color.yellow, Color.pink, Color.orange, Color.purple]
    }
    
    private var xPosition: CGFloat {
        let seed = Double(index) * 137.5
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
                .frame(width: 50, height: 60)
                .overlay(
                    Ellipse()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            // String
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 1, height: 40)
        }
        .position(
            x: xPosition,
            y: screenHeight + 50 + offset - CGFloat(index) * 80
        )
    }
}

#Preview {
    FirstDepositCelebrationView(
        depositAmount: 50.0,
        onDismiss: {}
    )
}

