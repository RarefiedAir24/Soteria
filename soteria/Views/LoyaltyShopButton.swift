//
//  LoyaltyShopButton.swift
//  soteria
//
//  Floating action button for accessing the loyalty shop
//

import SwiftUI

struct LoyaltyShopButton: View {
    @Binding var showShop: Bool
    @StateObject private var loyaltyService = LoyaltyPointsService.shared
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: {
            showShop = true
        }) {
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0),  // Gold
                                Color(red: 1.0, green: 0.71, blue: 0.0)   // Darker gold
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                
                // Pulsing ring for new points
                if loyaltyService.totalPoints > 0 {
                    Circle()
                        .stroke(
                            Color.yellow.opacity(0.6),
                            lineWidth: 3
                        )
                        .frame(width: isPulsing ? 74 : 64, height: isPulsing ? 74 : 64)
                        .opacity(isPulsing ? 0 : 1)
                        .animation(
                            Animation.easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                }
                
                VStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    if loyaltyService.totalPoints > 0 {
                        Text("\(loyaltyService.totalPoints)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.3))
                            )
                    }
                }
            }
        }
        .onAppear {
            isPulsing = true
        }
    }
}

