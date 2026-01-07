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
                        // Header with Soteria logo
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
                                
                                Image("AppLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
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
                                            .foregroundColor(.softGraphite)
                                        Text("See how each save moves you closer to your goals")
                                            .font(.system(size: 14))
                                            .foregroundColor(.midnightSlate)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.softGraphite)
                                        Text("Get AI-powered insights to optimize your savings")
                                            .font(.system(size: 14))
                                            .foregroundColor(.midnightSlate)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.softGraphite)
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
                            // Premium member info - show current subscription and upgrade option
                            VStack(spacing: 20) {
                                // Current Subscription Card
                                VStack(spacing: 16) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Current Plan")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.softGraphite)
                                            
                                            if let subscriptionType = subscriptionService.currentSubscriptionType {
                                                Text("Soteria Plus \(subscriptionType)")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.midnightSlate)
                                            } else {
                                                Text("Soteria Plus")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.midnightSlate)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Active badge
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 8, height: 8)
                                            Text("Active")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Text("You have access to all premium features")
                                        .font(.system(size: 14))
                                        .foregroundColor(.softGraphite)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                                )
                                
                                // Upgrade to Annual (if user has monthly)
                                if subscriptionService.canUpgradeToAnnual, let annualProduct = subscriptionService.yearlyProduct {
                                    VStack(spacing: 12) {
                                        HStack {
                                            Image(systemName: "arrow.up.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.softGraphite)
                                            Text("Upgrade to Annual")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.midnightSlate)
                                            Spacer()
                                        }
                                        
                                        Text("Save 33% and get all premium features for a full year")
                                            .font(.system(size: 14))
                                            .foregroundColor(.softGraphite)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Button(action: {
                                            purchaseProduct(annualProduct)
                                        }) {
                                            HStack {
                                                if isPurchasing {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                } else {
                                                    Text("Upgrade to Annual - \(annualProduct.displayPrice)")
                                                        .font(.system(size: 16, weight: .semibold))
                                                }
                                            }
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(
                                                LinearGradient(
                                                    colors: [Color.softGraphite, Color.midnightSlate],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .cornerRadius(12)
                                        }
                                        .disabled(isPurchasing)
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.softGraphite.opacity(0.05), Color.midnightSlate.opacity(0.05)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.softGraphite.opacity(0.2), lineWidth: 1.5)
                                            )
                                    )
                                }
                                
                                // Manage Subscription Button
                                Button(action: {
                                    showManageSubscriptions = true
                                }) {
                                    HStack {
                                        Image(systemName: "gearshape.fill")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Manage Subscription")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
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
                                        LinearGradient(
                                            colors: [Color.softGraphite, Color.midnightSlate],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
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
                                            LinearGradient(
                                                colors: [Color.softGraphite, Color.midnightSlate],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(8)
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
                            .foregroundColor(.softGraphite)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.softGraphite.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.softGraphite.opacity(0.3), lineWidth: 1)
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
                                .foregroundColor(.softGraphite)
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
                    // Wait a moment for subscription status to update
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    dismiss()
                    // Celebration will be shown automatically by SubscriptionService
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
                            colors: [Color.softGraphite.opacity(0.15), Color.midnightSlate.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.softGraphite, Color.midnightSlate],
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
                        .foregroundColor(Color.softGraphite)
                    
                    if product.id.contains("yearly") {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("Best Value")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.softGraphite)
                        .font(.system(size: 24))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                        LinearGradient(
                            colors: [Color.softGraphite.opacity(0.1), Color.midnightSlate.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : 
                        LinearGradient(
                            colors: [Color.white, Color.mistGray.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.softGraphite : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? Color.softGraphite.opacity(0.2) : Color.black.opacity(0.05), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
            )
        }
        .disabled(isPurchasing)
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionService.shared)
}

