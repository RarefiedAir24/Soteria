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
    @Published var reverMomentsCount: Int = 0
    @Published var lastSavedAmount: Double? = nil
    
    func recordSkipAndSave(amount: Double) {
        guard amount > 0 else { return }
        totalSaved += amount
        reverMomentsCount += 1
        lastSavedAmount = amount
    }
}

