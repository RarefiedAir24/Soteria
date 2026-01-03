//
//  PremiumCardFront.swift
//  soteria
//
//  Front side of premium member card
//

import SwiftUI

struct PremiumCardFront: View {
    let isBlack: Bool
    let isAnnual: Bool
    let isBeta: Bool
    let isRoseGold: Bool
    let logoColor: Color
    let isSupergeek: Bool
    let streakMonths: Int
    let userName: String
    let showFounder: Bool
    
    var body: some View {
        ZStack {
            PremiumCardBackground(isBlack: isBlack, isAnnual: isAnnual, isBeta: isBeta, isRoseGold: isRoseGold)
            
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    PremiumCardLogo(isBlack: isBlack, isAnnual: isAnnual, isBeta: isBeta, isRoseGold: isRoseGold, logoColor: logoColor)
                    
                    Spacer()
                    
                    PremiumCardUpperRight(
                        isBlack: isBlack,
                        isAnnual: isAnnual,
                        isBeta: isBeta,
                        isRoseGold: isRoseGold,
                        isSupergeek: isSupergeek,
                        signUpYear: getUserSignUpYear()
                    )
                }
                
                Spacer()
                
                PremiumCardMiddleSection(isBlack: isBlack, isAnnual: isAnnual, isBeta: isBeta, isRoseGold: isRoseGold)
                
                PremiumCardBottomSection(
                    isBlack: isBlack,
                    isAnnual: isAnnual,
                    isBeta: isBeta,
                    isRoseGold: isRoseGold,
                    streakMonths: streakMonths,
                    userName: userName,
                    showFounder: showFounder
                )
            }
            .padding(26)
        }
    }
    
    private func getUserSignUpYear() -> String {
        if let signUpDate = UserDefaults.standard.object(forKey: "user_signup_date") as? Date {
            let year = Calendar.current.component(.year, from: signUpDate)
            return String(year)
        }
        if let firstSubscriptionDate = SubscriptionStreakService.shared.lastTransactionDate {
            let year = Calendar.current.component(.year, from: firstSubscriptionDate)
            return String(year)
        }
        let currentYear = Calendar.current.component(.year, from: Date())
        return String(currentYear)
    }
}

