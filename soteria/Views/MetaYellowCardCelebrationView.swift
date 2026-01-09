//
//  MetaYellowCardCelebrationView.swift
//  soteria
//
//  Celebration view for first 100 TestFlight signups - Meta Yellow Card unlock
//

import SwiftUI

// Helper functions for safe screen bounds access
private func getScreenWidth() -> CGFloat {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        return window.bounds.width
    }
    return UIScreen.main.bounds.width
}

private func getScreenHeight() -> CGFloat {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        return window.bounds.height
    }
    return UIScreen.main.bounds.height
}

struct MetaYellowCardCelebrationView: View {
    @Binding var isPresented: Bool
    
    @State private var showConfetti = false
    @State private var showBalloons = false
    @State private var balloonOffsets: [CGSize] = []
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Celebration content
            VStack(spacing: 30) {
                // Balloons
                if showBalloons {
                    HStack(spacing: 40) {
                        ForEach(0..<5, id: \.self) { index in
                            MetaYellowBalloonView(color: balloonColors[index % balloonColors.count])
                                .offset(balloonOffsets[safe: index] ?? .zero)
                                .animation(
                                    .spring(response: 1.5, dampingFraction: 0.6)
                                    .delay(Double(index) * 0.1),
                                    value: showBalloons
                                )
                        }
                    }
                    .frame(height: 120)
                }
                
                // Congratulations Banner
                VStack(spacing: 16) {
                    // Yellow card icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.95, blue: 0.4),
                                        Color(red: 0.98, green: 0.90, blue: 0.35),
                                        Color(red: 0.95, green: 0.85, blue: 0.30)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: Color(red: 0.9, green: 0.8, blue: 0.3).opacity(0.6), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Congratulations!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("You're one of the first 100 TestFlight users!")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Text("You've been upgraded to the Meta Yellow Card")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.2, blue: 0.25),
                                    Color(red: 0.15, green: 0.15, blue: 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 15)
                )
                
                // Get Started Button
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.95, blue: 0.4),
                                Color(red: 0.98, green: 0.90, blue: 0.35)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color(red: 0.9, green: 0.8, blue: 0.3).opacity(0.5), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 40)
            }
            .padding(20)
            
            // Confetti
            if showConfetti {
                MetaYellowConfettiView()
            }
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private func startCelebration() {
        // Initialize balloon offsets
        balloonOffsets = (0..<5).map { _ in
            CGSize(width: 0, height: 300)
        }
        
        // Animate balloons rising
        withAnimation(.spring(response: 1.5, dampingFraction: 0.6)) {
            showBalloons = true
            balloonOffsets = (0..<5).map { index in
                CGSize(width: CGFloat.random(in: -20...20), height: -200)
            }
        }
        
        // Start confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showConfetti = true
            }
        }
    }
    
    private func dismiss() {
        withAnimation {
            isPresented = false
        }
    }
    
    private let balloonColors: [Color] = [
        Color(red: 1.0, green: 0.95, blue: 0.4),  // Bright yellow
        Color(red: 0.98, green: 0.90, blue: 0.35), // Medium yellow
        Color(red: 0.95, green: 0.85, blue: 0.30),  // Deeper yellow
        Color(red: 1.0, green: 0.98, blue: 0.5),    // Light yellow
        Color(red: 0.92, green: 0.88, blue: 0.4)   // Golden yellow
    ]
}

// MARK: - Balloon View
struct MetaYellowBalloonView: View {
    let color: Color
    @State private var isFloating = false
    
    var body: some View {
        ZStack {
            // Balloon
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 70)
                .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
            
            // Highlight
            Ellipse()
                .fill(Color.white.opacity(0.3))
                .frame(width: 20, height: 25)
                .offset(x: -8, y: -15)
            
            // String
            Path { path in
                path.move(to: CGPoint(x: 0, y: 35))
                path.addLine(to: CGPoint(x: 0, y: 80))
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
        }
        .offset(y: isFloating ? -5 : 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
    }
}

// MARK: - Confetti View
struct MetaYellowConfettiView: View {
    @State private var confettiPieces: [MetaYellowConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                MetaYellowConfettiPieceView(piece: piece)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        confettiPieces = (0..<50).map { _ in
            MetaYellowConfettiPiece(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...getScreenWidth()),
                    y: -20
                ),
                color: [
                    Color(red: 1.0, green: 0.95, blue: 0.4),
                    Color(red: 0.98, green: 0.90, blue: 0.35),
                    Color(red: 0.95, green: 0.85, blue: 0.30),
                    Color.white
                ].randomElement() ?? Color.yellow,
                rotation: Double.random(in: 0...360),
                velocity: CGSize(
                    width: CGFloat.random(in: -50...50),
                    height: CGFloat.random(in: 100...300)
                )
            )
        }
    }
}

struct MetaYellowConfettiPiece: Identifiable {
    let id: UUID
    var position: CGPoint
    let color: Color
    var rotation: Double
    var velocity: CGSize
}

struct MetaYellowConfettiPieceView: View {
    let piece: MetaYellowConfettiPiece
    @State private var currentPosition: CGPoint
    @State private var currentRotation: Double
    
    init(piece: MetaYellowConfettiPiece) {
        self.piece = piece
        _currentPosition = State(initialValue: piece.position)
        _currentRotation = State(initialValue: piece.rotation)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(currentRotation))
            .position(currentPosition)
            .onAppear {
                withAnimation(.linear(duration: Double.random(in: 2...4))) {
                    currentPosition = CGPoint(
                        x: piece.position.x + piece.velocity.width,
                        y: getScreenHeight() + 100
                    )
                    currentRotation = piece.rotation + 360
                }
            }
    }
}

