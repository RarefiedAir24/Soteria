//
//  SubscriptionCelebrationView.swift
//  soteria
//
//  Celebration view for subscription activation
//

import SwiftUI

// Helper function for safe screen bounds access
private func getScreenWidth() -> CGFloat {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        return window.bounds.width
    }
    return UIScreen.main.bounds.width
}

struct SubscriptionCelebrationView: View {
    @Binding var isPresented: Bool
    let subscriptionType: String // "Monthly" or "Annual"
    
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
                            SubscriptionBalloonView(color: balloonColors[index % balloonColors.count])
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
                    // Crown icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), radius: 15, x: 0, y: 5)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(showConfetti ? 1.0 : 0.3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)
                    
                    // Congratulations text
                    VStack(spacing: 8) {
                        Text("Congratulations!")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("Welcome to Soteria Plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.softGraphite)
                        
                        Text("\(subscriptionType) Plan Activated")
                            .font(.system(size: 16))
                            .foregroundColor(.softGraphite)
                    }
                    .opacity(showConfetti ? 1.0 : 0.0)
                    .offset(y: showConfetti ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showConfetti)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 40)
                
                // Continue button
                Button(action: {
                    dismiss()
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.softGraphite, Color.midnightSlate],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .opacity(showConfetti ? 1.0 : 0.0)
                .offset(y: showConfetti ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: showConfetti)
            }
            
            // Confetti overlay
            if showConfetti {
                SubscriptionConfettiView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private let balloonColors: [Color] = [
        .red, .blue, .green, .orange, .purple
    ]
    
    private func startCelebration() {
        // Initialize balloon offsets (start from bottom)
        balloonOffsets = (0..<5).map { _ in
            CGSize(width: CGFloat.random(in: -50...50), height: 300)
        }
        
        // Animate balloons rising
        withAnimation(.spring(response: 1.5, dampingFraction: 0.6)) {
            showBalloons = true
            balloonOffsets = (0..<5).map { index in
                CGSize(
                    width: CGFloat.random(in: -30...30),
                    height: CGFloat.random(in: -20...20)
                )
            }
        }
        
        // Show confetti and banner
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
}

// MARK: - Subscription Balloon View

struct SubscriptionBalloonView: View {
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // Balloon
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 65)
                .overlay(
                    Ellipse()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            // String
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 40)
        }
    }
}

// MARK: - Subscription Confetti View

struct SubscriptionConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    SubscriptionConfettiPieceView(
                        piece: piece,
                        screenHeight: geometry.size.height,
                        screenWidth: geometry.size.width
                    )
                }
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    private func createConfetti() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        let shapes: [ConfettiShape] = [.circle, .square, .triangle]
        let screenWidth = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.width ?? UIScreen.main.bounds.width
        
        confettiPieces = (0..<60).map { _ in
            ConfettiPiece(
                id: UUID(),
                color: colors.randomElement()!,
                shape: shapes.randomElement()!,
                startX: CGFloat.random(in: 0...screenWidth),
                velocityX: CGFloat.random(in: -100...100),
                duration: Double.random(in: 2.0...4.0),
                rotationSpeed: Double.random(in: -360...360)
            )
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    let color: Color
    let shape: ConfettiShape
    let startX: CGFloat
    let velocityX: CGFloat
    let duration: Double
    let rotationSpeed: Double
}

enum ConfettiShape {
    case circle, square, triangle
}

struct SubscriptionConfettiPieceView: View {
    let piece: ConfettiPiece
    let screenHeight: CGFloat
    let screenWidth: CGFloat
    
    @State private var offsetY: CGFloat = -50
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        Group {
            switch piece.shape {
            case .circle:
                Circle()
                    .fill(piece.color)
                    .frame(width: 10, height: 10)
            case .square:
                Rectangle()
                    .fill(piece.color)
                    .frame(width: 10, height: 10)
            case .triangle:
                Triangle()
                    .fill(piece.color)
                    .frame(width: 10, height: 10)
            }
        }
        .offset(x: offsetX, y: offsetY)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            animatePiece()
        }
    }
    
    private func animatePiece() {
        let endY = screenHeight + 100
        let endX = piece.velocityX * CGFloat(piece.duration)
        let totalRotation = piece.rotationSpeed * piece.duration
        
        withAnimation(.linear(duration: piece.duration).repeatForever(autoreverses: false)) {
            offsetY = endY
            offsetX = endX
            rotation = totalRotation
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    SubscriptionCelebrationView(isPresented: .constant(true), subscriptionType: "Annual")
}

