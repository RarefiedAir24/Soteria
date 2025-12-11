//
//  PremiumFeatureGate.swift
//  soteria
//
//  Utility for gating premium features
//

import SwiftUI

struct PremiumFeatureGate<Content: View>: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    let featureName: String
    let content: () -> Content
    let premiumContent: () -> Content
    
    var body: some View {
        if subscriptionService.isPremium {
            premiumContent()
        } else {
            content()
        }
    }
}

// View modifier for premium features
struct PremiumLock: ViewModifier {
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Binding var showPaywall: Bool
    let featureName: String
    
    func body(content: Content) -> some View {
        Group {
            if subscriptionService.isPremium {
                content
            } else {
                ZStack {
                    content
                        .blur(radius: 2)
                        .disabled(true)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("Premium Feature")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            showPaywall = true
                        }) {
                            Text("Upgrade to Premium")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.themePrimary)
                                )
                        }
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                }
            }
        }
    }
}

extension View {
    func premiumLocked(showPaywall: Binding<Bool>, featureName: String = "This feature") -> some View {
        modifier(PremiumLock(showPaywall: showPaywall, featureName: featureName))
    }
}

