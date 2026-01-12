//
//  RedemptionSuccessView.swift
//  soteria
//
//  Beautiful success screen for gift card redemption
//  Displays reward link with instant access
//

import SwiftUI

struct RedemptionSuccessView: View {
    let redemption: GiftCardRedemption
    let onDismiss: () -> Void
    @Environment(\.openURL) private var openURL
    
    @State private var linkCopied = false
    @State private var showConfetti = true
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.reverBlue, Color.deepReverBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Success animation
                ZStack {
                    // Pulsing circles
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showConfetti ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: showConfetti
                        )
                    
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    // Gift icon
                    Image(systemName: "gift.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .scaleEffect(showConfetti ? 1.1 : 1.0)
                        .animation(
                            Animation.spring(response: 0.6, dampingFraction: 0.7)
                                .repeatForever(autoreverses: true),
                            value: showConfetti
                        )
                }
                .padding(.top, 40)
                
                // Success message
                VStack(spacing: 12) {
                    Text("🎉 Success!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your $\(Int(redemption.amount)) \(redemption.brand) gift card is ready!")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        
                        Text("\(redemption.pointsSpent) points redeemed")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.vertical, 20)
                
                // Main CTA: Claim Gift Card
                if let rewardLink = redemption.redemptionLink,
                   let url = URL(string: rewardLink) {
                    
                    VStack(spacing: 16) {
                        // Primary button
                        Button(action: {
                            openURL(url)
                            
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 24))
                                
                                Text("Claim Your Gift Card")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.reverBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        
                        // Copy link button
                        Button(action: {
                            UIPasteboard.general.string = rewardLink
                            linkCopied = true
                            
                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            // Reset after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                linkCopied = false
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: linkCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.system(size: 14))
                                
                                Text(linkCopied ? "Link Copied!" : "Copy Link")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.white.opacity(linkCopied ? 0.3 : 0.2))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Info section
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Link saved to your redemption history")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("This gift card never expires")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.bottom, 20)
                
                // Done button
                Button(action: onDismiss) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Success haptic on appear
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Preview

#Preview {
    RedemptionSuccessView(
        redemption: GiftCardRedemption(
            id: "TEST123",
            userId: "user123",
            giftCardId: "amazon_5",
            brand: "Amazon",
            amount: 5.0,
            pointsSpent: 2500,
            redemptionDate: Date(),
            redemptionCode: nil,
            redemptionLink: "https://testflight.tremendous.com/rewards/payout/ob1wkdjn2--2racpbquz3lomwckyztju4vcpcf5qvja",
            status: .delivered,
            tremendousOrderId: "ORDER123"
        ),
        onDismiss: {}
    )
}
