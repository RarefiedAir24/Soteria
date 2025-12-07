//
//  SavingsService.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import Foundation
import Combine

class SavingsService: ObservableObject {
    @Published var totalSaved: Double = 0
    @Published var soteriaMomentsCount: Int = 0
    @Published var lastSavedAmount: Double? = nil
    @Published var totalTransferredToSavings: Double = 0 // Money transferred to bank accounts
    
    func recordSkipAndSave(amount: Double) {
        guard amount > 0 else { return }
        totalSaved += amount
            soteriaMomentsCount += 1
        lastSavedAmount = amount
    }
    
    // Record transfer to savings account
    func recordTransferToSavings(amount: Double) {
        guard amount > 0 else { return }
        totalTransferredToSavings += amount
        print("💰 [SavingsService] Recorded transfer: $\(amount). Total transferred: $\(totalTransferredToSavings)")
    }
}

