//
//  ArrowPad.swift
//  soteria
//
//  Arrow pad control for precise animal placement
//

import SwiftUI

struct ArrowPad: View {
    let onMove: (Direction) -> Void
    let onDone: () -> Void
    let onUndo: () -> Void
    let showUndo: Bool
    
    @State private var pressing: Direction? = nil
    @State private var pulseScale: CGFloat = 1.0
    
    enum Direction {
        case up, down, left, right
        
        var offset: CGPoint {
            switch self {
            case .up: return CGPoint(x: 0, y: -10)
            case .down: return CGPoint(x: 0, y: 10)
            case .left: return CGPoint(x: -10, y: 0)
            case .right: return CGPoint(x: 10, y: 0)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Undo button
            if showUndo {
                Button(action: onUndo) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14))
                        Text("Undo")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            
            // Arrow pad with darker background
            VStack(spacing: 8) {
                // Up
                ArrowButton(direction: .up, pressing: $pressing, onPress: onMove)
                
                HStack(spacing: 8) {
                    // Left
                    ArrowButton(direction: .left, pressing: $pressing, onPress: onMove)
                    
                    // Center indicator
                    Circle()
                        .fill(Color.reverBlue.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "scope")
                                .font(.system(size: 22))
                                .foregroundColor(.reverBlue)
                        )
                    
                    // Right
                    ArrowButton(direction: .right, pressing: $pressing, onPress: onMove)
                }
                
                // Down
                ArrowButton(direction: .down, pressing: $pressing, onPress: onMove)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.midnightSlate)
                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: -3)
            )
            
            // Helper text
            Text("Tap arrows to move 10px")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.3))
                )
            
            // Done button - BIG and PROMINENT
            Button(action: onDone) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                    Text("Done - Lock Position")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .green.opacity(0.6), radius: 15, x: 0, y: 5)
                )
            }
            .scaleEffect(pulseScale)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .onAppear {
            // Pulse animation for Done button
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
        }
    }
}

struct ArrowButton: View {
    let direction: ArrowPad.Direction
    @Binding var pressing: ArrowPad.Direction?
    let onPress: (ArrowPad.Direction) -> Void
    
    @State private var isPressed = false
    
    private var iconName: String {
        switch direction {
        case .up: return "chevron.up"
        case .down: return "chevron.down"
        case .left: return "chevron.left"
        case .right: return "chevron.right"
        }
    }
    
    var body: some View {
        Button(action: {
            onPress(direction)
            triggerHaptic()
        }) {
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(isPressed ? .midnightSlate : .white)
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isPressed ? Color.white : Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(isPressed ? 0 : 0.4), lineWidth: 2)
                        )
                )
                .shadow(color: isPressed ? .white.opacity(0.5) : .clear, radius: 8, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        pressing = direction
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    pressing = nil
                }
        )
    }
    
    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

#Preview {
    ZStack {
        Color.mistGray.ignoresSafeArea()
        
        VStack {
            Spacer()
            ArrowPad(
                onMove: { direction in
                    print("Move: \(direction)")
                },
                onDone: {
                    print("Done")
                },
                onUndo: {
                    print("Undo")
                },
                showUndo: true
            )
        }
    }
}
