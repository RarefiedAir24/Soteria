//
//  PauseView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI

struct PauseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var savingsService: SavingsService
    
    @State private var plannedSpend: String = ""
    @State private var showConfirmation: String? = nil
    
    private var formattedSavedAmount: String {
        guard let amount = Double(plannedSpend), amount > 0 else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                        
                        Text("Rever Moment")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Take a moment to reflect on your purchase")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Amount Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How much were you about to spend?")
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                            
                            TextField("$0.00", text: $plannedSpend)
                                .textFieldStyle(.plain)
                                .keyboardType(.decimalPad)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                )
                        }
                        .padding(.horizontal, 32)
                        
                        // Confirmation Message
                        if let confirmation = showConfirmation {
                            Text(confirmation)
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                                )
                                .padding(.horizontal, 32)
                        }
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                handleSkipAndSave()
                            }) {
                                Text("Skip & Save")
                                    .frame(maxWidth: .infinity)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.1, green: 0.6, blue: 0.3))
                            
                            Button(action: {
                                handleContinueShopping()
                            }) {
                                Text("Continue Shopping")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                handleMarkAsPlanned()
                            }) {
                                Text("Mark as Planned")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Pause")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func handleSkipAndSave() {
        let amount = Double(plannedSpend) ?? 0
        
        if amount > 0 {
            savingsService.recordSkipAndSave(amount: amount)
            showConfirmation = "Nice! You just saved \(formattedSavedAmount)"
            
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } else {
            showConfirmation = "Please enter an amount to save"
        }
    }
    
    private func handleContinueShopping() {
        showConfirmation = "No savings recorded this time."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
    
    private func handleMarkAsPlanned() {
        showConfirmation = "No savings recorded this time."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}

#Preview {
    PauseView()
}

