//
//  PlaidTransferView.swift
//  soteria
//
//  View for initiating Plaid transfers from checking to savings
//

import SwiftUI

struct PlaidTransferView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var plaidService = PlaidService.shared
    @ObservedObject private var goalsService = GoalsService.shared
    
    var initialAmount: Double? = nil // Optional initial amount (e.g., from Decision Window)
    
    @State private var transferAmount: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String? = nil
    @FocusState private var isAmountFocused: Bool
    
    private var isValidAmount: Bool {
        guard let amount = Double(transferAmount), amount > 0 else { return false }
        return true
    }
    
    private var transferValue: Double? {
        guard let amount = Double(transferAmount), amount > 0 else { return nil }
        return amount
    }
    
    private var formattedAmount: String {
        guard let amount = transferValue else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.mistGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                            .frame(width: 36, height: 36)
                            .background(Color.cloudWhite)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Transfer from Bank")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Color.clear
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Account Info
                        if let checkingAccount = plaidService.checkingAccount,
                           let savingsAccount = plaidService.savingsAccount {
                            VStack(spacing: 16) {
                                // From Account
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("From")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.softGraphite)
                                        Text("\(checkingAccount.name) ••••\(checkingAccount.mask)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.midnightSlate)
                                    }
                                    Spacer()
                                }
                                
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 20))
                                    .foregroundColor(.softGraphite)
                                
                                // To Account
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("To")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.softGraphite)
                                        Text("\(savingsAccount.name) ••••\(savingsAccount.mask)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.midnightSlate)
                                    }
                                    Spacer()
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                        } else if let checkingAccount = plaidService.checkingAccount {
                            // Virtual savings mode
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("From")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.softGraphite)
                                        Text("\(checkingAccount.name) ••••\(checkingAccount.mask)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.midnightSlate)
                                    }
                                    Spacer()
                                }
                                
                                Text("Virtual Savings")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.softGraphite)
                                    .padding(.top, 8)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Amount Input Section
                        VStack(spacing: 16) {
                            Text("Transfer Amount")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            // Amount Display
                            Text(formattedAmount)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.softGraphite)
                                .frame(height: 60)
                            
                            // Amount Input
                            TextField("$0.00", text: $transferAmount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20))
                                .multilineTextAlignment(.center)
                                .focused($isAmountFocused)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isAmountFocused ? Color.softGraphite : Color.clear, lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Error Message
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                        }
                        
                        // Submit Button
                        Button(action: submitTransfer) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Transfer")
                                }
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isValidAmount && !isSubmitting ? Color.softGraphite : Color.gray)
                            )
                        }
                        .disabled(!isValidAmount || isSubmitting)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .onAppear {
            // Set amount: use initialAmount if provided, otherwise use protection amount
            let amount = initialAmount ?? plaidService.protectionAmount
            transferAmount = String(format: "%.2f", amount)
            isAmountFocused = true
        }
    }
    
    private func submitTransfer() {
        guard let amount = transferValue, !isSubmitting else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                // Get active goal ID if available
                let activeGoalId = goalsService.activeGoal?.id
                
                // Check savings mode
                if plaidService.savingsMode == .automatic {
                    // Real transfer via Plaid
                    let transfer = try await plaidService.initiateTransfer(amount: amount)
                    
                    // Record the confirmed deposit with transfer ID as reference
                    plaidService.recordConfirmedDeposit(amount: amount, goalId: activeGoalId, transferId: transfer.id)
                } else if plaidService.savingsMode == .virtual {
                    // Virtual savings - just track, no actual transfer
                    plaidService.recordVirtualSavings(amount: amount, goalId: activeGoalId)
                } else {
                    // Fallback to manual if somehow in manual mode with Plaid connected
                    plaidService.recordManualDeposit(amount: amount, goalId: activeGoalId)
                }
                
                // Show success
                await MainActor.run {
                    showSuccess = true
                }
                
                // Dismiss after showing success
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}

