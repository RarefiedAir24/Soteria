//
//  EditDepositView.swift
//  soteria
//
//  Edit deposit reference ID and view verification status
//  NOTE: Screenshot upload is NOT allowed here for security (prevents fraud)
//

import SwiftUI

struct EditDepositView: View {
    let deposit: SavingsDeposit
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var plaidService = PlaidService.shared
    
    @State private var referenceId: String
    @State private var isSaving = false
    
    init(deposit: SavingsDeposit) {
        self.deposit = deposit
        _referenceId = State(initialValue: deposit.referenceId ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Deposit Info
                        VStack(spacing: 12) {
                            Text("Deposit Details")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.midnightSlate)
                            
                            Text(formatCurrency(deposit.amount))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.reverBlue)
                            
                            Text(formatDate(deposit.timestamp))
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cloudWhite)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Reference ID Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reference ID")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            TextField("e.g., DEP-550E840", text: $referenceId)
                                .font(.system(size: 14))
                                .foregroundColor(.midnightSlate)
                                .padding(14)
                                .background(Color.dreamMist)
                                .cornerRadius(10)
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                            
                            Text("Edit your deposit reference ID for tracking")
                                .font(.system(size: 12))
                                .foregroundColor(.softGraphite)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cloudWhite)
                        )
                        .padding(.horizontal, 20)
                        
                        // Screenshot Verification Status (Read-Only)
                        screenshotVerificationSection
                        
                        // Save Button
                        Button(action: saveChanges) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                }
                                
                                Text(isSaving ? "Saving..." : "Save Changes")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.reverBlueLight, Color.reverBlueDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Edit Deposit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.softGraphite)
                }
            }
        }
    }
    
    // MARK: - Screenshot Verification Status (Read-Only)
    
    @ViewBuilder
    private var screenshotVerificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Screenshot Verification")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.midnightSlate)
            
            // Get verification metadata
            let verificationMeta = EphemeralScreenshotService.shared.getVerificationMetadata(for: deposit.id)
            
            if let meta = verificationMeta {
                if meta.isVerified {
                    // Verified Status
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Verified at time of deposit")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.green)
                            
                            Text("Confidence: \(Int(meta.confidence * 100))%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.softGraphite)
                            
                            Text("Verified: \(formatDate(meta.verifiedAt))")
                                .font(.system(size: 12))
                                .foregroundColor(.softGraphite.opacity(0.7))
                            
                            if let extractedAmount = meta.extractedAmount {
                                Text("Detected amount: \(formatCurrency(extractedAmount))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.softGraphite.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                } else {
                    // Failed Verification
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.shield.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Verification failed at upload")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.orange)
                            
                            Text("No loyalty points awarded")
                                .font(.system(size: 13))
                                .foregroundColor(.softGraphite)
                            
                            Text("Reason: \(meta.reason)")
                                .font(.system(size: 12))
                                .foregroundColor(.softGraphite.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            } else {
                // No Screenshot Provided
                HStack(spacing: 12) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No screenshot provided")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.softGraphite)
                        
                        Text("No loyalty points awarded")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
            }
            
            // Security Notice
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.purple)
                
                Text("For security, screenshots cannot be added after deposit is recorded. This prevents fraud and protects your account.")
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.05))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cloudWhite)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Functions
    
    private func saveChanges() {
        isSaving = true
        
        // Update deposit in history
        if let index = plaidService.depositHistory.firstIndex(where: { $0.id == deposit.id }) {
            var updatedDeposit = deposit
            // Create new deposit with updated referenceId
            let newDeposit = SavingsDeposit(
                amount: updatedDeposit.amount,
                type: updatedDeposit.type,
                goalId: updatedDeposit.goalId,
                source: updatedDeposit.source,
                screenshotPath: updatedDeposit.screenshotPath,
                referenceId: referenceId.isEmpty ? nil : referenceId,
                id: updatedDeposit.id
            )
            plaidService.depositHistory[index] = newDeposit
            
            // Save to UserDefaults manually (since saveState() is private)
            if let encoded = try? JSONEncoder().encode(plaidService.depositHistory) {
                UserDefaults.standard.set(encoded, forKey: "deposit_history")
            }
        }
        
        // Dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    EditDepositView(deposit: SavingsDeposit(
        amount: 100.0,
        type: .manual,
        referenceId: "DEP-550E840"
    ))
}
