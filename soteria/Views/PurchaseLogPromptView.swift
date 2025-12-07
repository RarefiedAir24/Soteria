//
//  PurchaseLogPromptView.swift
//  soteria
//
//  Automatic prompt to log purchases after shopping app usage
//

import SwiftUI

struct PurchaseLogPromptView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    @EnvironmentObject var regretService: RegretLoggingService
    @EnvironmentObject var purchaseIntentService: PurchaseIntentService
    
    @State private var purchaseType: PurchaseType? = nil
    @State private var selectedCategory: PlannedPurchaseCategory? = nil
    @State private var amount: String = ""
    @State private var merchant: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                
                Text("Did you make a purchase?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("We noticed you were shopping. Quick log to track your spending patterns.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Planned vs Impulse
                if purchaseType == nil {
                    VStack(spacing: 16) {
                        Text("Was this purchase planned or impulse?")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                purchaseType = .planned
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 32))
                                    Text("Planned")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                                )
                            }
                            
                            Button(action: {
                                purchaseType = .impulse
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "bolt.circle.fill")
                                        .font(.system(size: 32))
                                    Text("Impulse")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.98, green: 0.95, blue: 0.95))
                                )
                            }
                        }
                    }
                    .padding()
                }
                
                // Category selection if planned
                if purchaseType == .planned && selectedCategory == nil {
                    VStack(spacing: 16) {
                        Text("What category?")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(PlannedPurchaseCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 24))
                                        Text(category.displayName)
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Purchase details
                if purchaseType != nil {
                    VStack(spacing: 16) {
                        TextField("Amount (optional)", text: $amount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Merchant (optional)", text: $merchant)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        savePurchase()
                    }) {
                        Text("Log Purchase")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.1, green: 0.6, blue: 0.3))
                            )
                            .foregroundColor(.white)
                    }
                    .disabled(purchaseType == nil)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Skip")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
            .navigationTitle("Log Purchase")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func savePurchase() {
        guard let purchaseType = purchaseType else { return }
        
        // Record purchase intent
        let intent = PurchaseIntent(
            purchaseType: purchaseType,
            category: purchaseType == .planned ? selectedCategory : nil,
            amount: Double(amount),
            notes: notes.isEmpty ? nil : notes
        )
        purchaseIntentService.recordIntent(intent)
        
        // If impulse and amount provided, also log as potential regret
        if purchaseType == .impulse, let amountValue = Double(amount), amountValue > 0 {
            let regret = RegretEntry(
                amount: amountValue,
                merchant: merchant.isEmpty ? nil : merchant,
                reason: "Impulse purchase - auto-detected",
                mood: .neutral
            )
            regretService.addRegret(regret)
        }
        
        dismiss()
    }
}

