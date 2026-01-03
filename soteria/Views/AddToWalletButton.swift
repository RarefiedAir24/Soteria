//
//  AddToWalletButton.swift
//  soteria
//
//  Button to add premium card to Apple Wallet
//

import SwiftUI
import PassKit

struct AddToWalletButton: View {
    @State private var showWalletError = false
    @State private var walletErrorMessage = ""
    
    var body: some View {
        Button(action: {
            addToWallet()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Add to Apple Wallet")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black)
            .cornerRadius(10)
        }
        .alert("Apple Wallet", isPresented: $showWalletError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(walletErrorMessage)
        }
    }
    
    private func addToWallet() {
        // TODO: Implement actual pass creation when backend is ready
        // For now, show informative message
        walletErrorMessage = "Apple Wallet integration requires backend setup. This feature will be available soon!"
        showWalletError = true
        
        print("ℹ️ [AddToWalletButton] Apple Wallet pass creation requires:")
        print("   - Backend API for pass generation")
        print("   - Apple Developer Pass Type ID")
        print("   - Pass signing certificate")
    }
}

