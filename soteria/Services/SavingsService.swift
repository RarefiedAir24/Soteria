//
//  SavingsService.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import Foundation
import Combine

class SavingsService: ObservableObject {
    static let shared = SavingsService()
    
    // Note: These are user-reported estimates, not actual purchase tracking
    // We cannot track actual purchases - users manually enter amounts when they skip a purchase
    @Published var totalSaved: Double = 0 // User-reported estimated amount avoided
    @Published var soteriaMomentsCount: Int = 0 // Number of times user chose protection
    @Published var lastSavedAmount: Double? = nil // Last user-reported estimated amount
    @Published var totalTransferredToSavings: Double = 0 // Money transferred to bank accounts (if Plaid integration used)
    
    private init() {}
    
    // Record when user skips a purchase and reports estimated amount
    // This is NOT actual purchase tracking - it's user-reported data
    // Amount is optional - the protection moment is what matters
    func recordSkipAndSave(amount: Double) {
        soteriaMomentsCount += 1 // Count of protection moments (always increment)
        
        if amount > 0 {
            totalSaved += amount // User-reported estimated amount they avoided spending
            lastSavedAmount = amount
        }
    }
    
    // Record transfer to savings account
    func recordTransferToSavings(amount: Double) {
        guard amount > 0 else { return }
        totalTransferredToSavings += amount
        print("💰 [SavingsService] Recorded transfer: $\(amount). Total transferred: $\(totalTransferredToSavings)")
    }
}

