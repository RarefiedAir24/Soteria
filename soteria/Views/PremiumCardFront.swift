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
    let userId: String
    let cardType: String
    let memberSince: Date
    
    var body: some View {
        ZStack {
            PremiumCardBackground(isBlack: isBlack, isAnnual: isAnnual, isBeta: isBeta, isRoseGold: isRoseGold)
            
            VStack(alignment: .leading, spacing: 0) {
                // Top section: Logo left (status removed - internal only)
                HStack(alignment: .top) {
                    // Logo in upper left
                    PremiumCardLogo(isBlack: isBlack, isAnnual: isAnnual, isBeta: isBeta, isRoseGold: isRoseGold, logoColor: logoColor)
                    
                    Spacer()
                }
                .padding(.top, 6)
                .padding(.horizontal, 26)
                
                // "SOTERIA PLUS" centered at top (like "AMERICAN EXPRESS")
                PremiumCardMiddleSection(isBlack: isBlack, isAnnual: isAnnual, isBeta: isBeta, isRoseGold: isRoseGold)
                    .padding(.top, 4)
                    .padding(.horizontal, 26)
                
                Spacer()
                
                // Center: Larger QR code
                HStack {
                    Spacer()
                    PremiumCardQRCode(
                        userId: userId,
                        cardType: cardType,
                        memberSince: memberSince,
                        isBlack: isBlack,
                        isAnnual: isAnnual,
                        isBeta: isBeta,
                        isRoseGold: isRoseGold,
                        compactSize: false
                    )
                    Spacer()
                }
                .padding(.vertical, 2)
                
                Spacer()
                    .frame(height: 2)
                
                // Bottom section: Username left, Member Since right
                PremiumCardBottomSection(
                    isBlack: isBlack,
                    isAnnual: isAnnual,
                    isBeta: isBeta,
                    isRoseGold: isRoseGold,
                    streakMonths: streakMonths,
                    userName: userName,
                    showFounder: showFounder,
                    memberSinceDate: getMemberSinceDate()
                )
                .padding(.bottom, 8)
                .padding(.horizontal, 26)
            }
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
    
    private func getMemberYear2Digit() -> String {
        let fullYear = getUserSignUpYear()
        if fullYear.count >= 2 {
            return String(fullYear.suffix(2))
        }
        return fullYear
    }
    
    private func getMemberSinceDate() -> String {
        // Get signup date or first subscription date
        var signUpDate: Date?
        
        if let userSignUpDate = UserDefaults.standard.object(forKey: "user_signup_date") as? Date {
            signUpDate = userSignUpDate
        } else if let firstSubscriptionDate = SubscriptionStreakService.shared.lastTransactionDate {
            signUpDate = firstSubscriptionDate
        }
        
        guard let date = signUpDate else {
            // Fallback to current date
            let calendar = Calendar.current
            let month = calendar.component(.month, from: Date())
            let year = calendar.component(.year, from: Date())
            return String(format: "%02d/%02d", month, year % 100)
        }
        
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        return String(format: "%02d/%02d", month, year % 100)
    }
    
}

