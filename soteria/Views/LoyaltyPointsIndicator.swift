//
//  LoyaltyPointsIndicator.swift
//  soteria
//
//  Real-time points indicator with animation
//

import SwiftUI

struct LoyaltyPointsIndicator: View {
    @StateObject private var loyaltyService = LoyaltyPointsService.shared
    @State private var previousPoints: Int = 0
    @State private var pointsChange: Int = 0
    @State private var showChangeAnimation = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            ZStack {
                // Main points display
                Text("\(loyaltyService.totalPoints)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                
                // Change indicator (floats up)
                if showChangeAnimation {
                    Text(pointsChange > 0 ? "+\(pointsChange)" : "\(pointsChange)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(pointsChange > 0 ? .green : .red)
                        .offset(y: showChangeAnimation ? -30 : 0)
                        .opacity(showChangeAnimation ? 0 : 1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onChange(of: loyaltyService.totalPoints) { oldValue, newValue in
            // Animate point changes
            let change = newValue - oldValue
            if change != 0 {
                pointsChange = change
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showChangeAnimation = true
                }
                
                // Reset animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showChangeAnimation = false
                }
            }
            previousPoints = newValue
        }
        .onAppear {
            previousPoints = loyaltyService.totalPoints
        }
    }
}

// MARK: - Preview
struct LoyaltyPointsIndicator_Previews: PreviewProvider {
    static var previews: some View {
        LoyaltyPointsIndicator()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

