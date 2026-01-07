//
//  UnitAccountDetailsView.swift
//  Soteria
//
//  View to display Unit account details and information
//

import SwiftUI

struct UnitAccountDetailsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var account: UnitAccount? = nil
    @State private var accountBalance: Double? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let account = account {
                        // Account Header
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Dedicated Savings Account")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.midnightSlate)
                            
                            Text("FDIC-insured account for your goals")
                                .font(.system(size: 16))
                                .foregroundColor(.softGraphite)
                        }
                        .padding(.top, 20)
                        
                        // Account Details Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            if let accountNumber = UserDefaults.standard.string(forKey: "unit_account_number"),
                               !accountNumber.isEmpty {
                                DetailRow(
                                    label: "Account Number",
                                    value: "••••\(String(accountNumber.suffix(4)))"
                                )
                            }
                            
                            if let routingNumber = UserDefaults.standard.string(forKey: "unit_routing_number"),
                               !routingNumber.isEmpty {
                                DetailRow(
                                    label: "Routing Number",
                                    value: routingNumber
                                )
                            }
                            
                            if let accountId = UserDefaults.standard.string(forKey: "unit_account_id"),
                               !accountId.isEmpty {
                                DetailRow(
                                    label: "Account ID",
                                    value: String(accountId.prefix(8)) + "..."
                                )
                            }
                            
                            if let balance = accountBalance {
                                Divider()
                                DetailRow(
                                    label: "Current Balance",
                                    value: String(format: "$%.2f", balance)
                                )
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mistGray)
                        )
                        .padding(.horizontal, 20)
                        
                        // Transfer Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How to Transfer Funds")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            Text("You can transfer funds to this account from your connected bank accounts via Plaid, or make manual deposits through the deposit tracker.")
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mistGray.opacity(0.5))
                        )
                        .padding(.horizontal, 20)
                        
                    } else if let error = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Unable to Load Account")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Savings Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
        .task {
            await loadAccountDetails()
        }
    }
    
    private func loadAccountDetails() async {
        isLoading = true
        errorMessage = nil
        
        // Load account from UserDefaults first
        if let accountId = UserDefaults.standard.string(forKey: "unit_account_id"),
           !accountId.isEmpty {
            do {
                if let loadedAccount = try await UnitService.shared.getAccount(accountId: accountId) {
                    await MainActor.run {
                        account = loadedAccount
                    }
                    
                    // Try to load balance
                    do {
                        let balance = try await UnitService.shared.getAccountBalance(accountId: accountId)
                        await MainActor.run {
                            accountBalance = balance
                        }
                    } catch {
                        print("⚠️ [UnitAccountDetailsView] Could not load balance: \(error)")
                        // Balance is optional, so we continue
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Account not found. Please verify your account ID."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Unable to load account details: \(error.localizedDescription)"
                }
            }
        } else {
            // Try to find account by email/userId
            guard let email = authService.currentUser?.email,
                  let userId = authService.getUserId() else {
                await MainActor.run {
                    errorMessage = "Unable to identify user"
                }
                return
            }
            
            if let foundAccount = await UnitService.shared.findExistingAccount(email: email, userId: userId) {
                await MainActor.run {
                    account = foundAccount
                    // Save to UserDefaults for future use
                    UserDefaults.standard.set(foundAccount.id, forKey: "unit_account_id")
                    UserDefaults.standard.set(foundAccount.accountNumber, forKey: "unit_account_number")
                    UserDefaults.standard.set(foundAccount.routingNumber, forKey: "unit_routing_number")
                    UserDefaults.standard.set(true, forKey: "unit_account_created")
                }
            } else {
                await MainActor.run {
                    errorMessage = "No account found. Please create an account first."
                }
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.midnightSlate)
        }
    }
}

#Preview {
    UnitAccountDetailsView(onDismiss: {})
        .environmentObject(AuthService())
}

