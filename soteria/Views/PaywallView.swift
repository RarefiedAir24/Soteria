//
//  PaywallView.swift
//  soteria
//
//  Premium subscription paywall
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var selectedProduct: Product? = nil
    @State private var isPurchasing = false
    @State private var showManageSubscriptions = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color.mistGray, Color.cloudWhite],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header with gradient crown
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            
                            if subscriptionService.isPremium {
                                VStack(spacing: 8) {
                                    Text("Soteria Plus Member")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color.midnightSlate)
                                    
                                    // Subscription streak badge
                                    let _ = SubscriptionStreakService.shared.ensureDataLoaded()
                                    if SubscriptionStreakService.shared.currentStreak > 0 {
                                        HStack(spacing: 8) {
                                            Image(systemName: "flame.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(SubscriptionStreakService.shared.badgeGradient)
                                            Text("\(SubscriptionStreakService.shared.currentStreak) month streak • \(SubscriptionStreakService.shared.tierName)")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.softGraphite)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(SubscriptionStreakService.shared.badgeGradient.opacity(0.1))
                                        )
                                    }
                                    
                                    Text("Thank you for being a member")
                                        .font(.system(size: 16))
                                        .foregroundColor(.softGraphite)
                                }
                            } else {
                                Text("Unlock Soteria Plus")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color.midnightSlate)
                                
                                Text("Reach your goals faster with smarter savings and powerful insights")
                                    .font(.system(size: 16))
                                    .foregroundColor(.softGraphite)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                
                                // Value proposition - emphasize outcomes
                                VStack(spacing: 8) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.reverBlue)
                                        Text("See how each save moves you closer to your goals")
                                            .font(.system(size: 14))
                                            .foregroundColor(.midnightSlate)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.reverBlue)
                                        Text("Get AI-powered insights to optimize your savings")
                                            .font(.system(size: 14))
                                            .foregroundColor(.midnightSlate)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.reverBlue)
                                        Text("Track your progress with advanced analytics")
                                            .font(.system(size: 14))
                                            .foregroundColor(.midnightSlate)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding(.top, 12)
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Premium Features (Styled cards) - Only show for non-premium users
                        if !subscriptionService.isPremium {
                            VStack(alignment: .leading, spacing: 16) {
                                FeatureRow(
                                    icon: "clock.badge.questionmark",
                                    title: "Up to 3 Decision Windows per day",
                                    description: "Set multiple intentional moments to pause and save throughout your day"
                                )
                                
                                FeatureRow(
                                    icon: "brain.head.profile",
                                    title: "Smarter save suggestions",
                                    description: "AI-powered timing and amount recommendations based on your behavior"
                                )
                                
                                FeatureRow(
                                    icon: "target",
                                    title: "Goal Impact Intervention",
                                    description: "See how each save moves you closer to your goal with photos, impact calculations, and regret reminders"
                                )
                                
                                FeatureRow(
                                    icon: "chart.bar.fill",
                                    title: "Advanced Analytics",
                                    description: "Goal predictions, savings velocity tracking, and trend analysis"
                                )
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                            .padding(.horizontal, 24)
                        } else {
                            // Premium member info
                            VStack(spacing: 20) {
                                VStack(spacing: 12) {
                                    Text("You have access to all premium features")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.midnightSlate)
                                    
                                    Text("Manage or cancel your subscription anytime")
                                        .font(.system(size: 14))
                                        .foregroundColor(.softGraphite)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(24)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                )
                                
                                Button(action: {
                                    showManageSubscriptions = true
                                }) {
                                    HStack {
                                        Image(systemName: "gearshape.fill")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Manage or Cancel Subscription")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.reverBlue)
                                    )
                                }
                                
                                // Additional instructions for cancellation
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("How to cancel:")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.midnightSlate)
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("1.")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.reverBlue)
                                            Text("Tap 'Manage or Cancel Subscription' above")
                                                .font(.system(size: 13))
                                                .foregroundColor(.softGraphite)
                                        }
                                        
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("2.")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.reverBlue)
                                            Text("Select your Soteria Plus subscription")
                                                .font(.system(size: 13))
                                                .foregroundColor(.softGraphite)
                                        }
                                        
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("3.")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.reverBlue)
                                            Text("Tap 'Cancel Subscription'")
                                                .font(.system(size: 13))
                                                .foregroundColor(.softGraphite)
                                        }
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.reverBlue.opacity(0.05))
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Pricing Options (Only show for non-premium users)
                        if !subscriptionService.isPremium {
                            if subscriptionService.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading subscription options...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        } else if !subscriptionService.allProducts.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(subscriptionService.allProducts, id: \.id) { product in
                                    PricingCard(
                                        product: product,
                                        isSelected: selectedProduct?.id == product.id,
                                        isPurchasing: isPurchasing
                                    ) {
                                        selectedProduct = product
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Purchase Button
                            if let product = selectedProduct ?? subscriptionService.yearlyProduct ?? subscriptionService.monthlyProduct {
                                Button(action: {
                                    purchaseProduct(product)
                                }) {
                                    HStack {
                                        if isPurchasing {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("Start Premium")
                                                .font(.headline)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.reverBlue)
                                    )
                                    .foregroundColor(.white)
                                }
                                .disabled(isPurchasing)
                                .padding(.horizontal, 24)
                            }
                        } else {
                            // Products failed to load or not available
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                
                                Text("Subscription Options Unavailable")
                                    .font(.headline)
                                    .foregroundColor(.midnightSlate)
                                
                                if let errorMessage = subscriptionService.errorMessage {
                                    Text(errorMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text("Unable to load subscription options. Please try again later.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                
                                Button(action: {
                                    Task {
                                        await subscriptionService.loadProducts()
                                    }
                                }) {
                                    Text("Retry")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.reverBlue)
                                        )
                                }
                            }
                            .padding()
                        }
                        
                        // Restore Purchases - Styled button
                        Button(action: {
                            Task {
                                await subscriptionService.restorePurchases()
                                if subscriptionService.isPremium {
                                    dismiss()
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Restore Purchases")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.reverBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.reverBlue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.reverBlue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                }
            }
            }
            .navigationTitle(subscriptionService.isPremium ? "Manage Subscription" : "Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                // Add Manage Subscription button for premium users
                if subscriptionService.isPremium {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showManageSubscriptions = true
                        }) {
                            Text("Cancel")
                                .font(.system(size: 14))
                                .foregroundColor(.reverBlue)
                        }
                    }
                }
            }
            .task {
                await subscriptionService.loadProducts()
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        }
    }
    
    private func purchaseProduct(_ product: Product) {
        isPurchasing = true
        Task {
            do {
                let success = try await subscriptionService.purchase(product)
                if success {
                    dismiss()
                }
            } catch {
                print("❌ [PaywallView] Purchase failed: \(error)")
            }
            isPurchasing = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.reverBlue.opacity(0.15), Color.deepReverBlue.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.reverBlue, Color.deepReverBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.midnightSlate)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.softGraphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let isPurchasing: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundColor(Color.midnightSlate)
                    
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.reverBlue)
                    
                    if product.id.contains("yearly") {
                        Text("Best Value")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.reverBlue)
                        .font(.system(size: 24))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(red: 0.95, green: 0.98, blue: 0.95) : Color.mistGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.reverBlue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(isPurchasing)
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionService.shared)
}

