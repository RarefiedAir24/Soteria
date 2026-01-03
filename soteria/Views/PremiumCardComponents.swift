//
//  PremiumCardComponents.swift
//  soteria
//
//  Optimized components for premium member cards
//

import SwiftUI
import UIKit

// MARK: - Card Background Components

struct PremiumCardBackground: View {
    let isBlack: Bool
    let isAnnual: Bool
    let isBeta: Bool
    let isRoseGold: Bool
    
    var body: some View {
        ZStack {
            // Main card background
            RoundedRectangle(cornerRadius: 24)
                .fill(cardGradient)
                .shadow(color: shadowColor, radius: 25, x: 0, y: 12)
                .overlay(cardBorder)
                .overlay(enhancedBorder)
            
            // Texture overlay
            RoundedRectangle(cornerRadius: 24)
                .fill(textureGradient)
            
            // Sheen effects
            sheenEffects
        }
    }
    
    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: isRoseGold ? roseGoldColors : (isBeta ? yellowColors : (isBlack ? blackColors : (isAnnual ? platinumColors : goldColors))),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var blackColors: [Color] {
        [
            Color(red: 0.05, green: 0.05, blue: 0.05),
            Color(red: 0.08, green: 0.08, blue: 0.08),
            Color(red: 0.06, green: 0.06, blue: 0.06)
        ]
    }
    
    private var platinumColors: [Color] {
        [
            Color(red: 0.12, green: 0.12, blue: 0.18),
            Color(red: 0.18, green: 0.18, blue: 0.24),
            Color(red: 0.15, green: 0.15, blue: 0.21)
        ]
    }
    
    private var goldColors: [Color] {
        [
            Color(red: 0.98, green: 0.88, blue: 0.55),
            Color(red: 0.92, green: 0.78, blue: 0.45),
            Color(red: 0.88, green: 0.70, blue: 0.35)
        ]
    }
    
    private var yellowColors: [Color] {
        [
            Color(red: 1.0, green: 0.95, blue: 0.4),  // Bright yellow
            Color(red: 0.98, green: 0.90, blue: 0.35), // Medium yellow
            Color(red: 0.95, green: 0.85, blue: 0.30)  // Deeper yellow
        ]
    }
    
    private var roseGoldColors: [Color] {
        [
            Color(red: 0.95, green: 0.75, blue: 0.65),  // Light rose gold
            Color(red: 0.90, green: 0.65, blue: 0.55),   // Medium rose gold
            Color(red: 0.85, green: 0.55, blue: 0.45)   // Deeper rose gold
        ]
    }
    
    private var shadowColor: Color {
        isRoseGold ? Color(red: 0.8, green: 0.6, blue: 0.5).opacity(0.7) : (isBeta ? Color(red: 0.9, green: 0.8, blue: 0.3).opacity(0.7) : (isBlack ? Color.black.opacity(0.8) : (isAnnual ? Color.black.opacity(0.5) : Color(red: 0.9, green: 0.75, blue: 0.4).opacity(0.6))))
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 24)
            .stroke(borderGradient, lineWidth: 2)
    }
    
    // Enhanced border for more definition - same color as card but darker
    private var enhancedBorder: some View {
        RoundedRectangle(cornerRadius: 24)
            .stroke(enhancedBorderColor, lineWidth: 1.5)
    }
    
    private var enhancedBorderColor: Color {
        if isRoseGold {
            // Darker rose gold for rose gold card
            return Color(red: 0.7, green: 0.45, blue: 0.35).opacity(0.8)
        } else if isBeta {
            // Darker yellow/bronze for yellow card
            return Color(red: 0.4, green: 0.3, blue: 0.15).opacity(0.8)
        } else if isBlack {
            // Darker black/charcoal for black card
            return Color(red: 0.02, green: 0.02, blue: 0.02).opacity(0.9)
        } else if isAnnual {
            // Darker platinum for platinum card
            return Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.8)
        } else {
            // Darker gold for gold card
            return Color(red: 0.7, green: 0.55, blue: 0.25).opacity(0.8)
        }
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: isRoseGold ? roseGoldBorderColors : (isBeta ? yellowBorderColors : (isBlack ? blackBorderColors : (isAnnual ? platinumBorderColors : goldBorderColors))),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var blackBorderColors: [Color] {
        [
            Color.white.opacity(0.15),
            Color.white.opacity(0.08),
            Color.white.opacity(0.15)
        ]
    }
    
    private var platinumBorderColors: [Color] {
        [
            Color(red: 0.95, green: 0.95, blue: 1.0).opacity(0.3),
            Color(red: 0.7, green: 0.7, blue: 0.85).opacity(0.2),
            Color(red: 0.95, green: 0.95, blue: 1.0).opacity(0.3)
        ]
    }
    
    private var goldBorderColors: [Color] {
        [
            Color.white.opacity(0.5),
            Color(red: 1.0, green: 0.9, blue: 0.6).opacity(0.4),
            Color.white.opacity(0.5)
        ]
    }
    
    private var yellowBorderColors: [Color] {
        [
            Color.white.opacity(0.6),
            Color(red: 1.0, green: 0.95, blue: 0.5).opacity(0.5),
            Color.white.opacity(0.6)
        ]
    }
    
    private var roseGoldBorderColors: [Color] {
        [
            Color.white.opacity(0.5),
            Color(red: 0.95, green: 0.8, blue: 0.7).opacity(0.4),
            Color.white.opacity(0.5)
        ]
    }
    
    private var textureGradient: RadialGradient {
        RadialGradient(
            colors: [
                Color.clear,
                isRoseGold ? Color.white.opacity(0.06) : (isBeta ? Color.white.opacity(0.1) : (isBlack ? Color.white.opacity(0.02) : (isAnnual ? Color.white.opacity(0.03) : Color.white.opacity(0.08))))
            ],
            center: .topTrailing,
            startRadius: 50,
            endRadius: 300
        )
    }
    
    private var sheenEffects: some View {
        ZStack {
            // Diagonal shine
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            isRoseGold ? Color.white.opacity(0.25) : (isBeta ? Color.white.opacity(0.3) : (isBlack ? Color.white.opacity(0.15) : (isAnnual ? Color.white.opacity(0.2) : Color.white.opacity(0.25)))),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(-45))
                .offset(x: -100, y: -100)
                .blur(radius: 20)
            
            // Top-left highlight
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    RadialGradient(
                        colors: [
                            isRoseGold ? Color.white.opacity(0.3) : (isBeta ? Color.white.opacity(0.35) : (isBlack ? Color.white.opacity(0.2) : (isAnnual ? Color.white.opacity(0.25) : Color.white.opacity(0.3)))),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
            
            // Diagonal stripe
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            isRoseGold ? Color.white.opacity(0.14) : (isBeta ? Color.white.opacity(0.18) : (isBlack ? Color.white.opacity(0.1) : (isAnnual ? Color.white.opacity(0.12) : Color.white.opacity(0.15)))),
                            Color.clear
                        ],
                        startPoint: UnitPoint(x: 0.2, y: 0.2),
                        endPoint: UnitPoint(x: 0.8, y: 0.8)
                    )
                )
                .blur(radius: 15)
        }
    }
}

// MARK: - Card Content Components

struct PremiumCardLogo: View {
    let isBlack: Bool
    let isAnnual: Bool
    let isBeta: Bool
    let isRoseGold: Bool
    let logoColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(circleGradient)
                .frame(width: 56, height: 56)
                .shadow(color: circleShadow, radius: 8, x: 0, y: 4)
            
            if UIImage(named: "soteria_logo") != nil {
                Image("soteria_logo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(logoColor)
            } else {
                Image(systemName: "star.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(starGradient)
                    .shadow(color: starShadow, radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private var circleGradient: LinearGradient {
        LinearGradient(
            colors: isRoseGold ? roseGoldCircleColors : (isBeta ? yellowCircleColors : (isBlack ? blackCircleColors : (isAnnual ? platinumCircleColors : goldCircleColors))),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var blackCircleColors: [Color] {
        [Color.white.opacity(0.15), Color.white.opacity(0.08)]
    }
    
    private var platinumCircleColors: [Color] {
        [Color.white.opacity(0.25), Color.white.opacity(0.15)]
    }
    
    private var goldCircleColors: [Color] {
        [
            Color(red: 0.3, green: 0.25, blue: 0.15).opacity(0.6),
            Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.4)
        ]
    }
    
    private var yellowCircleColors: [Color] {
        [
            Color(red: 0.35, green: 0.28, blue: 0.12).opacity(0.7),
            Color(red: 0.25, green: 0.2, blue: 0.08).opacity(0.5)
        ]
    }
    
    private var roseGoldCircleColors: [Color] {
        [
            Color(red: 0.4, green: 0.3, blue: 0.25).opacity(0.7),
            Color(red: 0.3, green: 0.22, blue: 0.18).opacity(0.5)
        ]
    }
    
    private var circleShadow: Color {
        isRoseGold ? Color(red: 0.35, green: 0.25, blue: 0.2).opacity(0.5) : (isBeta ? Color(red: 0.3, green: 0.25, blue: 0.1).opacity(0.5) : (isBlack ? Color.white.opacity(0.1) : (isAnnual ? Color.white.opacity(0.2) : Color(red: 0.3, green: 0.2, blue: 0.1).opacity(0.4))))
    }
    
    private var starGradient: LinearGradient {
        LinearGradient(
            colors: isRoseGold ? roseGoldStarColors : (isBeta ? yellowStarColors : (isBlack ? blackStarColors : (isAnnual ? platinumStarColors : goldStarColors))),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var blackStarColors: [Color] {
        [Color.white.opacity(0.9), Color.white.opacity(0.7)]
    }
    
    private var platinumStarColors: [Color] {
        [
            Color(red: 0.95, green: 0.95, blue: 1.0),
            Color(red: 0.75, green: 0.75, blue: 0.85)
        ]
    }
    
    private var goldStarColors: [Color] {
        [
            Color(red: 0.4, green: 0.3, blue: 0.15),
            Color(red: 0.3, green: 0.2, blue: 0.1)
        ]
    }
    
    private var yellowStarColors: [Color] {
        [
            Color(red: 0.45, green: 0.35, blue: 0.15),
            Color(red: 0.35, green: 0.25, blue: 0.1)
        ]
    }
    
    private var roseGoldStarColors: [Color] {
        [
            Color(red: 0.5, green: 0.35, blue: 0.25),
            Color(red: 0.4, green: 0.28, blue: 0.2)
        ]
    }
    
    private var starShadow: Color {
        isRoseGold ? Color(red: 0.3, green: 0.22, blue: 0.15).opacity(0.6) : (isBeta ? Color(red: 0.25, green: 0.2, blue: 0.08).opacity(0.6) : (isBlack ? Color.white.opacity(0.3) : (isAnnual ? Color.white.opacity(0.3) : Color(red: 0.2, green: 0.15, blue: 0.05).opacity(0.5))))
    }
}

struct PremiumCardUpperRight: View {
    let isBlack: Bool
    let isAnnual: Bool
    let isBeta: Bool
    let isRoseGold: Bool
    let isSupergeek: Bool
    let signUpYear: String
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if !isSupergeek {
                let isOtherBlackCard = isBlack && !isSupergeek
                let upperRightText = isBeta ? "BETA" : (isOtherBlackCard ? "FOUNDER" : (isAnnual ? "ANNUAL" : "MONTHLY"))
                
                Text(upperRightText)
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(upperRightTextColor)
                    .tracking(3)
                    .shadow(color: upperRightTextShadow, radius: 2, x: 0, y: 1)
            } else {
                // supergeek@me.com (rose gold) - show FOUNDER at top, then year
                Text("FOUNDER")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(upperRightTextColor)
                    .tracking(3)
                    .shadow(color: upperRightTextShadow, radius: 2, x: 0, y: 1)
            }
            
            Text(signUpYear)
                .font(.system(size: 10, weight: .medium, design: .default))
                .foregroundColor(yearTextColor)
                .tracking(1)
        }
    }
    
    private var upperRightTextColor: Color {
        isRoseGold ? Color(red: 0.35, green: 0.25, blue: 0.2) : (isBeta ? Color(red: 0.3, green: 0.25, blue: 0.1) : (isBlack ? Color.white.opacity(0.95) : (isAnnual ? Color(red: 0.95, green: 0.95, blue: 1.0) : Color(red: 0.3, green: 0.2, blue: 0.1))))
    }
    
    private var upperRightTextShadow: Color {
        isRoseGold ? Color(red: 0.25, green: 0.18, blue: 0.12).opacity(0.7) : (isBeta ? Color(red: 0.2, green: 0.15, blue: 0.05).opacity(0.7) : (isBlack ? Color.white.opacity(0.4) : (isAnnual ? Color.white.opacity(0.3) : Color(red: 0.2, green: 0.15, blue: 0.05).opacity(0.6))))
    }
    
    private var memberTextColor: Color {
        isRoseGold ? Color(red: 0.32, green: 0.24, blue: 0.18) : (isBeta ? Color(red: 0.28, green: 0.22, blue: 0.12) : (isBlack ? Color.white.opacity(0.85) : (isAnnual ? Color.white.opacity(0.8) : Color(red: 0.25, green: 0.18, blue: 0.1))))
    }
    
    private var yearTextColor: Color {
        isRoseGold ? Color(red: 0.42, green: 0.32, blue: 0.25) : (isBeta ? Color(red: 0.38, green: 0.3, blue: 0.18) : (isBlack ? Color.white.opacity(0.7) : (isAnnual ? Color.white.opacity(0.65) : Color(red: 0.35, green: 0.25, blue: 0.15))))
    }
}

struct PremiumCardMiddleSection: View {
    let isBlack: Bool
    let isAnnual: Bool
    let isBeta: Bool
    let isRoseGold: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SOTERIA PLUS")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(plusTextColor)
                .tracking(2)
                .shadow(color: plusTextShadow, radius: 1, x: 0, y: 1)
            
            Text(cardTypeText)
                .font(.system(size: 15, weight: .semibold, design: .default))
                .foregroundColor(cardTypeColor)
                .tracking(1.5)
        }
    }
    
    private var cardTypeText: String {
        isBeta ? "BETA" : (isRoseGold ? "ROSE GOLD" : (isBlack ? "BLACK" : (isAnnual ? "PLATINUM" : "GOLD")))
    }
    
    private var plusTextColor: Color {
        isRoseGold ? Color(red: 0.32, green: 0.24, blue: 0.18) : (isBeta ? Color(red: 0.28, green: 0.22, blue: 0.1) : (isBlack ? Color.white.opacity(0.98) : (isAnnual ? Color.white.opacity(0.98) : Color(red: 0.25, green: 0.18, blue: 0.08))))
    }
    
    private var plusTextShadow: Color {
        isRoseGold ? Color.black.opacity(0.2) : (isBeta ? Color.black.opacity(0.15) : (isBlack ? Color.white.opacity(0.3) : (isAnnual ? Color.white.opacity(0.2) : Color.black.opacity(0.1))))
    }
    
    private var cardTypeColor: Color {
        isRoseGold ? Color(red: 0.42, green: 0.32, blue: 0.25) : (isBeta ? Color(red: 0.38, green: 0.3, blue: 0.18) : (isBlack ? Color.white.opacity(0.85) : (isAnnual ? Color.white.opacity(0.85) : Color(red: 0.35, green: 0.25, blue: 0.15))))
    }
}

struct PremiumCardQRCode: View {
    let userId: String
    let cardType: String
    let memberSince: Date
    let isBlack: Bool
    
    @State private var qrCodeImage: UIImage? = nil
    
    var body: some View {
        Group {
            if let qrImage = qrCodeImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(4)
                    .background(isBlack ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                    .cornerRadius(10)
            } else {
                // Placeholder while generating
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 88, height: 88)
                    .overlay(
                        ProgressView()
                            .tint(isBlack ? .white : .gray)
                    )
            }
        }
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        let qrService = QRCodeService.shared
        qrCodeImage = qrService.generateMemberCardQRCode(
            userId: userId,
            cardType: cardType,
            memberSince: memberSince
        )
    }
}

struct PremiumCardBottomSection: View {
    let isBlack: Bool
    let isAnnual: Bool
    let isBeta: Bool
    let isRoseGold: Bool
    let streakMonths: Int
    let userName: String
    let showFounder: Bool
    
    var body: some View {
        HStack(alignment: .bottom) {
            if isBeta {
                // Star icon for beta testers
                VStack(alignment: .center, spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(betaStarGradient)
                        .shadow(color: betaStarShadow, radius: 4, x: 0, y: 2)
                }
            } else {
                // Streak months for paid members - centered number over word
                VStack(alignment: .center, spacing: 6) {
                    Text("\(streakMonths)")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(streakNumberColor)
                        .shadow(color: streakNumberShadow, radius: 2, x: 0, y: 1)
                    
                    Text(streakMonths == 1 ? "MONTH" : "MONTHS")
                        .font(.system(size: 12, weight: .semibold, design: .default))
                        .foregroundColor(streakLabelColor)
                        .tracking(1.5)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                // Username moved to where UID was (first line)
                Text(userName.uppercased())
                    .font(.system(size: 15, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(usernameColor)
                    .tracking(3)
                    .shadow(color: usernameShadow, radius: 1, x: 0, y: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // FOUNDER label below username (if applicable, but NOT for rose gold cards)
                if showFounder && !isRoseGold {
                    Text("FOUNDER")
                        .font(.system(size: 10, weight: .bold, design: .default))
                        .foregroundColor(Color.white.opacity(0.8))
                        .tracking(1.5)
                }
            }
        }
    }
    
    private var streakNumberColor: Color {
        isRoseGold ? Color(red: 0.3, green: 0.2, blue: 0.15) : (isBlack ? Color.white : (isAnnual ? Color.white : Color(red: 0.25, green: 0.18, blue: 0.08)))
    }
    
    private var streakNumberShadow: Color {
        isRoseGold ? Color.black.opacity(0.15) : (isBlack ? Color.white.opacity(0.3) : (isAnnual ? Color.white.opacity(0.2) : Color.black.opacity(0.1)))
    }
    
    private var streakLabelColor: Color {
        isRoseGold ? Color(red: 0.45, green: 0.32, blue: 0.25) : (isBlack ? Color.white.opacity(0.75) : (isAnnual ? Color.white.opacity(0.75) : Color(red: 0.4, green: 0.3, blue: 0.2)))
    }
    
    private var usernameColor: Color {
        isRoseGold ? Color(red: 0.3, green: 0.22, blue: 0.15) : (isBlack ? Color.white.opacity(0.95) : (isAnnual ? Color.white.opacity(0.95) : Color(red: 0.25, green: 0.18, blue: 0.08)))
    }
    
    private var usernameShadow: Color {
        isRoseGold ? Color.black.opacity(0.12) : (isBlack ? Color.white.opacity(0.3) : (isAnnual ? Color.white.opacity(0.2) : Color.black.opacity(0.1)))
    }
    
    private var uidColor: Color {
        isRoseGold ? Color(red: 0.5, green: 0.38, blue: 0.3) : (isBlack ? Color.white.opacity(0.7) : (isAnnual ? Color.white.opacity(0.7) : Color(red: 0.45, green: 0.35, blue: 0.25)))
    }
    
    // Star gradient for beta card - complements yellow background
    private var betaStarGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.5, green: 0.4, blue: 0.2),  // Dark yellow/bronze
                Color(red: 0.4, green: 0.3, blue: 0.15), // Deeper bronze
                Color(red: 0.35, green: 0.25, blue: 0.1) // Darkest bronze
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Star shadow for beta card
    private var betaStarShadow: Color {
        Color(red: 0.3, green: 0.25, blue: 0.1).opacity(0.7)
    }
}

