//
//  PremiumCardBack.swift
//  soteria
//
//  Back side of premium member card (credit card style)
//

import SwiftUI
import PassKit

struct PremiumCardBack: View {
    let isBlack: Bool
    let isAnnual: Bool
    let isBeta: Bool
    let isRoseGold: Bool
    let userId: String
    let cardType: String
    let memberSince: Date
    let userName: String
    
    @State private var showWalletAlert = false
    @State private var walletAlertMessage = ""
    
    var body: some View {
        ZStack {
            PremiumCardBackground(isBlack: isBlack, isAnnual: isAnnual, isBeta: isBeta, isRoseGold: isRoseGold)
            
            VStack(spacing: 0) {
                // Top section - Magnetic stripe area with horizontal barcode
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(magneticStripeColor)
                        .frame(height: 60) // Increased height for better barcode readability
                        .overlay(
                            // Horizontal barcode spanning full width of magnetic stripe
                            PremiumCardBarcode(
                                userId: userId,
                                cardType: cardType,
                                memberSince: memberSince,
                                isBlack: barcodeIsBlack
                            )
                            .padding(.horizontal, 4) // Minimal padding for edge clearance only
                        )
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Middle section - Signature box with username and member number
                VStack(spacing: 6) {
                    // Signature box with username (left) and member number (right)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(signatureBoxColor)
                        .frame(height: 50)
                        .overlay(
                            HStack {
                                // Username on left
                                Text(userName.uppercased())
                                    .font(.system(size: 15, weight: .light, design: .serif))
                                    .italic()
                                    .foregroundColor(signatureUsernameColor)
                                    .tracking(3)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                
                                Spacer()
                                
                                // Member number on right
                                if let memberNumber = MemberNumberService.shared.memberNumber {
                                    Text(memberNumber)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundColor(signatureMemberNumberColor)
                                        .tracking(1)
                                }
                            }
                            .padding(.horizontal, 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(signatureBoxStrokeColor, lineWidth: 1)
                        )
                    
                    // "SIGNATURE" label
                    Text("SIGNATURE")
                        .font(.system(size: 9, weight: .medium, design: .default))
                        .foregroundColor(signatureTextColor)
                        .tracking(1.5)
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 16)
                
                Spacer()
                
                // Bottom section - Square Add to Apple Wallet button
                VStack(spacing: 6) {
                    Button(action: {
                        handleAddToAppleWallet()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(walletIconColor)
                            
                            Text("Add to\nApple Wallet")
                                .font(.system(size: 8, weight: .semibold, design: .default))
                                .foregroundColor(walletTextColor)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(walletButtonBackgroundColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(walletButtonStrokeColor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("Scan barcode for Partner Discounts")
                        .font(.system(size: 7, weight: .medium, design: .default))
                        .foregroundColor(scanTextColor)
                        .tracking(0.5)
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            // Load member number when card back appears
            if MemberNumberService.shared.memberNumber == nil {
                Task {
                    await MemberNumberService.shared.fetchMemberNumber()
                }
            }
        }
        .alert("Apple Wallet", isPresented: $showWalletAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(walletAlertMessage)
        }
    }
    
    private func handleAddToAppleWallet() {
        // Check if Apple Wallet is available
        guard AppleWalletService.shared.isWalletAvailable else {
            walletAlertMessage = "Apple Wallet is not available on this device."
            showWalletAlert = true
            return
        }
        
        // For now, show informative message since backend pass generation is pending
        walletAlertMessage = "Apple Wallet integration is coming soon! This feature requires backend setup with Apple Developer Pass Type ID and signing certificates. Your premium card will be available in Apple Wallet in a future update."
        showWalletAlert = true
        
        print("ℹ️ [PremiumCardBack] Add to Apple Wallet requested")
        print("   - User ID: \(userId)")
        print("   - Card Type: \(cardType)")
        print("   - Member Since: \(memberSince)")
    }
    
    // Computed properties for colors to simplify complex conditionals
    private var magneticStripeColor: Color {
        if isRoseGold { return Color.black.opacity(0.12) }
        if isBeta { return Color.black.opacity(0.15) }
        if isBlack { return Color.white.opacity(0.1) }
        return Color.black.opacity(0.2)
    }
    
    private var signatureBoxColor: Color {
        if isRoseGold { return Color.white.opacity(0.32) }
        if isBeta { return Color.white.opacity(0.35) }
        if isBlack { return Color.white.opacity(0.15) }
        return Color.white.opacity(0.3)
    }
    
    private var barcodeIsBlack: Bool {
        !isRoseGold && !isBeta && isBlack
    }
    
    private var signatureBoxStrokeColor: Color {
        if isRoseGold { return Color.black.opacity(0.23) }
        if isBeta { return Color.black.opacity(0.25) }
        if isBlack { return Color.white.opacity(0.2) }
        return Color.black.opacity(0.2)
    }
    
    private var signatureTextColor: Color {
        if isRoseGold { return Color.black.opacity(0.48) }
        if isBeta { return Color.black.opacity(0.5) }
        if isBlack { return Color.white.opacity(0.5) }
        return Color.black.opacity(0.4)
    }
    
    private var walletIconColor: Color {
        if isRoseGold { return Color.black.opacity(0.68) }
        if isBeta { return Color.black.opacity(0.7) }
        if isBlack { return Color.white.opacity(0.9) }
        return Color.black.opacity(0.7)
    }
    
    private var walletTextColor: Color {
        if isRoseGold { return Color.black.opacity(0.58) }
        if isBeta { return Color.black.opacity(0.6) }
        if isBlack { return Color.white.opacity(0.8) }
        return Color.black.opacity(0.6)
    }
    
    private var walletButtonBackgroundColor: Color {
        if isRoseGold { return Color.white.opacity(0.28) }
        if isBeta { return Color.white.opacity(0.3) }
        if isBlack { return Color.white.opacity(0.15) }
        return Color.white.opacity(0.25)
    }
    
    private var walletButtonStrokeColor: Color {
        if isRoseGold { return Color.black.opacity(0.18) }
        if isBeta { return Color.black.opacity(0.2) }
        if isBlack { return Color.white.opacity(0.2) }
        return Color.black.opacity(0.2)
    }
    
    private var scanTextColor: Color {
        if isRoseGold { return Color.black.opacity(0.38) }
        if isBeta { return Color.black.opacity(0.4) }
        if isBlack { return Color.white.opacity(0.4) }
        return Color.black.opacity(0.3)
    }
    
    private var signatureUsernameColor: Color {
        if isRoseGold { return Color(red: 0.3, green: 0.22, blue: 0.15) }
        if isBeta { return Color(red: 0.28, green: 0.22, blue: 0.12) }
        if isBlack { return Color.white.opacity(0.95) }
        if isAnnual { return Color.white.opacity(0.95) }
        return Color(red: 0.25, green: 0.18, blue: 0.08)
    }
    
    private var signatureMemberNumberColor: Color {
        if isRoseGold { return Color(red: 0.35, green: 0.25, blue: 0.2) }
        if isBeta { return Color(red: 0.3, green: 0.25, blue: 0.15) }
        if isBlack { return Color.white.opacity(0.9) }
        if isAnnual { return Color.white.opacity(0.9) }
        return Color(red: 0.3, green: 0.22, blue: 0.12)
    }
    
}

