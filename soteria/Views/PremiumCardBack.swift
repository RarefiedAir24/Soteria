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
            
            ZStack {
                VStack(spacing: 0) {
                    // Top section - Magnetic stripe area with horizontal barcode
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(magneticStripeColor)
                            .frame(height: 43) // Reduced height for compact card
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
                    .padding(.top, 6)
                    
                    Spacer()
                        .frame(height: 4)
                    
                    // Middle section - Signature box with username and member number
                    VStack(spacing: 6) {
                        // Signature box with username (left) and member number (right)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(signatureBoxColor)
                            .frame(height: 40)
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
                    .padding(.vertical, 4)
                    
                    Spacer()
                        .frame(height: 2)
                    
                    // Bottom section - Square Add to Apple Wallet button (centered) with Thank You aligned
                    HStack {
                        Spacer()
                        
                        ZStack {
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
                            
                            // Thank You message aligned with member number in signature box
                            Text("Thank You!")
                                .font(.system(size: 12, weight: .bold, design: .default))
                                .foregroundColor(thankYouTextColor)
                                .tracking(1.5)
                                .shadow(color: thankYouShadow, radius: 1, x: 0, y: 1)
                                .offset(x: 100, y: -20) // Positioned to align with right side of signature box (member number)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 6)
                    
                    // Fine print section at bottom - full width
                    VStack(alignment: .leading, spacing: 2) {
                        Text("soteria.zone • support@montebay.io")
                            .font(.system(size: 5.5, weight: .regular, design: .default))
                            .foregroundColor(finePrintColor)
                        
                        Text("Privacy Policy: Your data is protected. We collect only necessary information for service delivery. Member data is encrypted and never shared with third parties without consent. Full policy: montebay.io/privacy")
                            .font(.system(size: 4.5, weight: .regular, design: .default))
                            .foregroundColor(finePrintColor)
                            .lineSpacing(1)
                        
                        Text("Terms of Service: Membership is non-transferable. Partner discounts subject to individual partner terms. Soteria reserves the right to modify or terminate service. Full terms: montebay.io/terms")
                            .font(.system(size: 4.5, weight: .regular, design: .default))
                            .foregroundColor(finePrintColor)
                            .lineSpacing(1)
                    }
                    .padding(.horizontal, 26)
                    .padding(.bottom, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
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
        
        // Download and add pass to wallet
        Task {
            do {
                let pass = try await AppleWalletService.shared.downloadMemberCardPass(
                    userId: userId,
                    cardType: cardType
                )
                
                // Present add pass view controller on main thread
                await MainActor.run {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        AppleWalletService.shared.addPassToWallet(pass, from: rootViewController)
                    } else {
                        walletAlertMessage = "Unable to present Apple Wallet. Please try again."
                        showWalletAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    if let walletError = error as? AppleWalletError {
                        walletAlertMessage = walletError.errorDescription ?? "Failed to add card to Apple Wallet."
                    } else {
                        walletAlertMessage = error.localizedDescription
                    }
                    showWalletAlert = true
                }
                print("❌ [PremiumCardBack] Failed to add to Apple Wallet: \(error)")
            }
        }
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
    
    private var finePrintColor: Color {
        if isRoseGold { return Color.black.opacity(0.4) }
        if isBeta { return Color.black.opacity(0.42) }
        if isBlack { return Color.white.opacity(0.5) }
        return Color.black.opacity(0.35)
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
    
    private var thankYouTextColor: Color {
        if isRoseGold { return Color(red: 0.3, green: 0.22, blue: 0.15) }
        if isBeta { return Color(red: 0.28, green: 0.22, blue: 0.12) }
        if isBlack { return Color.white.opacity(0.95) }
        if isAnnual { return Color.white.opacity(0.95) }
        return Color(red: 0.25, green: 0.18, blue: 0.08)
    }
    
    private var thankYouShadow: Color {
        if isRoseGold { return Color.black.opacity(0.15) }
        if isBeta { return Color.black.opacity(0.15) }
        if isBlack { return Color.white.opacity(0.2) }
        return Color.black.opacity(0.1)
    }
    
}

