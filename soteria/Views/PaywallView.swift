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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.reverBlue)
                            
                            Text("Unlock Premium")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color.midnightSlate)
                            
                            Text("Get deeper insights and advanced protection")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Premium Features
                        VStack(alignment: .leading, spacing: 20) {
                            FeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Advanced Analytics",
                                description: "Historical patterns, trend analysis, and predictive insights"
                            )
                            
                            FeatureRow(
                                icon: "cloud.fill",
                                title: "Cloud Sync",
                                description: "Backup your data and access from multiple devices"
                            )
                            
                            FeatureRow(
                                icon: "brain.head.profile",
                                title: "Smart Auto-Protection",
                                description: "Automatically activate protection based on your behavior patterns (no input needed)"
                            )
                            
                            FeatureRow(
                                icon: "app.badge.checkmark",
                                title: "Multiple Apps",
                                description: "Monitor and protect multiple apps (free: 1 app limit)"
                            )
                            
                            FeatureRow(
                                icon: "pencil",
                                title: "Edit Quiet Hours",
                                description: "Edit and customize your protection schedules (free: view only)"
                            )
                            
                            FeatureRow(
                                icon: "square.and.arrow.up",
                                title: "Export Data",
                                description: "Download your behavioral insights as reports"
                            )
                            
                            FeatureRow(
                                icon: "bell.badge.fill",
                                title: "Smart Alerts",
                                description: "Predictive risk alerts and personalized recommendations"
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Pricing Options
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
                        
                        // Restore Purchases
                        Button(action: {
                            Task {
                                await subscriptionService.restorePurchases()
                                if subscriptionService.isPremium {
                                    dismiss()
                                }
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await subscriptionService.loadProducts()
            }
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
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color.reverBlue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.midnightSlate)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
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

