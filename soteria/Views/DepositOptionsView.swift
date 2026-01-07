//
//  DepositOptionsView.swift
//  soteria
//
//  View to present deposit options based on Plaid connection status
//

import SwiftUI

struct DepositOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var plaidService = PlaidService.shared
    @ObservedObject private var goalsService = GoalsService.shared
    
    let onPlaidDeposit: () -> Void
    let onManualDeposit: () -> Void
    
    // Check if user has Plaid connected
    private var hasPlaidConnection: Bool {
        !plaidService.connectedAccounts.isEmpty
    }
    
    // Check if user has savings account (for automatic transfers)
    private var hasSavingsAccount: Bool {
        plaidService.savingsAccount != nil
    }
    
    // Check if user has checking account
    private var hasCheckingAccount: Bool {
        plaidService.checkingAccount != nil
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
                    
                    Text("Make a Deposit")
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
                    VStack(spacing: 24) {
                        // Description
                        Text("Choose how you'd like to add to your savings")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.softGraphite)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        // Deposit Options
                        VStack(spacing: 16) {
                            // Plaid Transfer Option (if connected)
                            if hasPlaidConnection && hasCheckingAccount {
                                DepositOptionCard(
                                    title: "Transfer from Bank",
                                    subtitle: hasSavingsAccount 
                                        ? "Move money from checking to savings" 
                                        : "Track virtual savings",
                                    icon: "arrow.right.circle.fill",
                                    iconColor: .reverBlue,
                                    isAvailable: true
                                ) {
                                    onPlaidDeposit()
                                }
                            }
                            
                            // Manual Deposit Option (always available)
                            DepositOptionCard(
                                title: "Manual Entry",
                                subtitle: "Record cash or deposits made outside the app",
                                icon: "dollarsign.circle.fill",
                                iconColor: .reverBlue,
                                isAvailable: true
                            ) {
                                onManualDeposit()
                            }
                            
                            // Info if no Plaid connection
                            if !hasPlaidConnection {
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 16))
                                            .foregroundColor(.softGraphite)
                                        Text("Connect your bank account in Settings to enable transfers")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.softGraphite)
                                    }
                                    
                                    Button(action: {
                                        dismiss()
                                        // Navigate to settings - this will be handled by the parent
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("NavigateToPlaidSettings"),
                                            object: nil
                                        )
                                    }) {
                                        Text("Go to Settings")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.reverBlue)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.dreamMist)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
    }
}

struct DepositOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let isAvailable: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.softGraphite)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.softGraphite)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isAvailable ? 1.0 : 0.6)
    }
}

