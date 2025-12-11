//
//  SavingsSettingsView.swift
//  soteria
//
//  View for managing savings settings and connected accounts
//

import SwiftUI

struct SavingsSettingsView: View {
    @EnvironmentObject var plaidService: PlaidService
    @State private var showConnectionView = false
    @State private var showDisconnectAlert = false
    
    var body: some View {
        List {
            // Current Mode
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Savings Mode")
                            .font(.headline)
                        
                        Text(modeDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    modeBadge
                }
            } header: {
                Text("Status")
            }
            
            // Connected Accounts
            if !plaidService.connectedAccounts.isEmpty {
                Section {
                    ForEach(plaidService.connectedAccounts) { account in
                        AccountRow(account: account)
                    }
                } header: {
                    Text("Connected Accounts")
                }
            }
            
            // Protection Amount
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Protection Amount")
                        .font(.headline)
                    
                    Text("Amount saved per protection moment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach([5.0, 10.0, 25.0, 50.0], id: \.self) { amount in
                            Button(action: {
                                plaidService.protectionAmount = amount
                            }) {
                                Text("$\(Int(amount))")
                                    .font(.headline)
                                    .foregroundColor(plaidService.protectionAmount == amount ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(plaidService.protectionAmount == amount ? Color.reverBlue : Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Custom amount
                    HStack {
                        Text("Custom:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("$0.00", value: $plaidService.protectionAmount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Settings")
            }
            
            // Savings Summary
            if plaidService.savingsMode != .manual {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        if plaidService.savingsMode == .automatic {
                            if let savingsAccount = plaidService.savingsAccount {
                                HStack {
                                    Text("Savings Balance")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    if let balance = savingsAccount.balance {
                                        Text("$\(balance, specifier: "%.2f")")
                                            .font(.title2.bold())
                                            .foregroundColor(Color.reverBlue)
                                    } else {
                                        ProgressView()
                                    }
                                }
                                
                                Text("Account ending in \(savingsAccount.mask)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack {
                                Text("Virtual Savings")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("$\(plaidService.virtualSavings, specifier: "%.2f")")
                                    .font(.title2.bold())
                                    .foregroundColor(Color.reverBlue)
                            }
                            
                            Text("Create a savings account to enable automatic transfers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !plaidService.transferHistory.isEmpty {
                            Divider()
                            
                            Text("Total Transfers: \(plaidService.transferHistory.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Savings Summary")
                }
            }
            
            // Actions
            Section {
                if plaidService.connectedAccounts.isEmpty {
                    Button(action: {
                        showConnectionView = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Connect Accounts")
                        }
                        .foregroundColor(Color.reverBlue)
                    }
                } else {
                    Button(role: .destructive, action: {
                        showDisconnectAlert = true
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Disconnect Accounts")
                        }
                    }
                }
            }
        }
        .navigationTitle("Savings Settings")
        .sheet(isPresented: $showConnectionView) {
            PlaidConnectionView()
                .environmentObject(plaidService)
        }
        .alert("Disconnect Accounts?", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                plaidService.disconnectAccounts()
            }
        } message: {
            Text("This will disconnect all accounts and disable automatic transfers. Your money will remain in your bank accounts.")
        }
        .task {
            // Refresh balances when view appears
            await plaidService.refreshBalances()
        }
    }
    
    private var modeDescription: String {
        switch plaidService.savingsMode {
        case .automatic:
            return "Automatic transfers enabled"
        case .virtual:
            return "Virtual savings mode (no savings account)"
        case .manual:
            return "No accounts connected"
        }
    }
    
    private var modeBadge: some View {
        Text(plaidService.savingsMode == .automatic ? "Active" : "Inactive")
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(plaidService.savingsMode == .automatic ? Color.reverBlue : Color.gray)
            .cornerRadius(8)
    }
}

struct AccountRow: View {
    let account: ConnectedAccount
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)
                
                Text("\(account.subtype.capitalized) • •••• \(account.mask)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let balance = account.balance {
                Text("$\(balance, specifier: "%.2f")")
                    .font(.subheadline.bold())
            }
        }
    }
}

#Preview {
    NavigationView {
        SavingsSettingsView()
            .environmentObject(PlaidService.shared)
    }
}

