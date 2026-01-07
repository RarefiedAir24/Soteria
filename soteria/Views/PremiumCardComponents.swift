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
            
            // Subtle background pattern (like AmEx)
            backgroundPattern
            
            // Texture overlay
            RoundedRectangle(cornerRadius: 24)
                .fill(textureGradient)
            
            // Sheen effects
            sheenEffects
        }
    }
    
    // Subtle repeating pattern overlay
    private var backgroundPattern: some View {
        GeometryReader { geometry in
            ZStack {
                // Repeating circular pattern
                ForEach(0..<8, id: \.self) { row in
                    ForEach(0..<4, id: \.self) { col in
                        Circle()
                            .stroke(patternColor, lineWidth: 0.5)
                            .frame(width: 40, height: 40)
                            .offset(
                                x: CGFloat(col) * (geometry.size.width / 3.5) - geometry.size.width / 2 + 30,
                                y: CGFloat(row) * (geometry.size.height / 7.5) - geometry.size.height / 2 + 20
                            )
                    }
                }
            }
            .opacity(0.15)
        }
    }
    
    private var patternColor: Color {
        isRoseGold ? Color(red: 0.3, green: 0.2, blue: 0.15) : (isBeta ? Color(red: 0.25, green: 0.2, blue: 0.1) : (isBlack ? Color.white.opacity(0.1) : (isAnnual ? Color.white.opacity(0.1) : Color(red: 0.2, green: 0.15, blue: 0.08))))
    }
    
    // Decorative borders at top and sides (like AmEx)
    private var decorativeBorders: some View {
        VStack(spacing: 0) {
            // Top decorative border
            HStack(spacing: 0) {
                decorativeBorderSegment
                    .frame(height: 3)
            }
            
            Spacer()
            
            // Bottom decorative border (subtle)
            HStack(spacing: 0) {
                decorativeBorderSegment
                    .frame(height: 2)
                    .opacity(0.6)
            }
        }
    }
    
    private var decorativeBorderSegment: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let segmentWidth = width / 20
                
                for i in 0..<20 {
                    let x = CGFloat(i) * segmentWidth
                    if i % 2 == 0 {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + segmentWidth, y: geometry.size.height))
                    } else {
                        path.move(to: CGPoint(x: x, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: x + segmentWidth, y: 0))
                    }
                }
            }
            .stroke(borderPatternColor, lineWidth: 1)
        }
    }
    
    private var borderPatternColor: Color {
        isRoseGold ? Color(red: 0.2, green: 0.15, blue: 0.1) : (isBeta ? Color(red: 0.2, green: 0.15, blue: 0.08) : (isBlack ? Color.white.opacity(0.2) : (isAnnual ? Color.white.opacity(0.2) : Color(red: 0.15, green: 0.1, blue: 0.05))))
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
                .frame(width: 48, height: 48)
                .shadow(color: circleShadow, radius: 6, x: 0, y: 3)
            
            if UIImage(named: "AppLogo") != nil {
                Image("AppLogo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(logoColor)
            } else if UIImage(named: "soteria_logo") != nil {
                Image("soteria_logo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(logoColor)
            } else {
                Image(systemName: "star.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(starGradient)
                    .shadow(color: starShadow, radius: 3, x: 0, y: 1.5)
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
        VStack(alignment: .trailing, spacing: 0) {
            if !isSupergeek {
                let isOtherBlackCard = isBlack && !isSupergeek
                let upperRightText = isBeta ? "BETA" : (isOtherBlackCard ? "FOUNDER" : (isAnnual ? "ANNUAL" : "MONTHLY"))
                
                Text(upperRightText)
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(upperRightTextColor)
                    .tracking(3)
                    .shadow(color: upperRightTextShadow, radius: 2, x: 0, y: 1)
            } else {
                // supergeek@me.com (rose gold) - show FOUNDER only
                Text("FOUNDER")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(upperRightTextColor)
                    .tracking(3)
                    .shadow(color: upperRightTextShadow, radius: 2, x: 0, y: 1)
            }
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
        VStack(alignment: .center, spacing: 10) {
            // SOTERIA PLUS centered with normal letter spacing (like American Express)
            Text("SOTERIA PLUS")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(plusTextColor)
                .tracking(4) // Increased letter spacing for premium card look
                .shadow(color: plusTextShadow, radius: 1, x: 0, y: 1)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            
            // Card type text (hidden for rose gold) - centered
            if let cardType = cardTypeText {
                Text(cardType)
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(cardTypeColor)
                    .tracking(1.5)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var cardTypeText: String? {
        if isRoseGold {
            return nil // Hidden - users have to discover it
        } else if isBeta {
            return "BETA"
        } else if isBlack {
            return "BLACK"
        } else if isAnnual {
            return "PLATINUM"
        } else {
            return "GOLD"
        }
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
    let isAnnual: Bool
    let isBeta: Bool
    let isRoseGold: Bool
    var compactSize: Bool = false // For upper-left chip position
    
    @State private var qrCodeImage: UIImage? = nil
    
    var body: some View {
        Group {
            if let qrImage = qrCodeImage {
                ZStack {
                    // Decorative border around QR code
                    RoundedRectangle(cornerRadius: compactSize ? 6 : 12)
                        .fill(
                            LinearGradient(
                                colors: decorativeBorderColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: compactSize ? 40 : 110, height: compactSize ? 40 : 110)
                        .shadow(color: decorativeBorderShadow, radius: 4, x: 0, y: 2)
                    
                    // Inner border
                    RoundedRectangle(cornerRadius: compactSize ? 5 : 11)
                        .stroke(decorativeInnerBorderColor, lineWidth: 1.5)
                        .frame(width: compactSize ? 38 : 108, height: compactSize ? 38 : 108)
                    
                    // QR code with white background
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: compactSize ? 32 : 100, height: compactSize ? 32 : 100)
                        .background(Color.white)
                        .cornerRadius(compactSize ? 4 : 8)
                        .padding(compactSize ? 2 : 4)
                }
            } else {
                // Placeholder while generating
                ZStack {
                    RoundedRectangle(cornerRadius: compactSize ? 6 : 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: compactSize ? 40 : 110, height: compactSize ? 40 : 110)
                    
                    ProgressView()
                        .scaleEffect(compactSize ? 0.5 : 1.0)
                        .tint(isBlack ? .white : .gray)
                }
            }
        }
        .onAppear {
            generateQRCode()
        }
    }
    
    private var decorativeBorderColors: [Color] {
        if isRoseGold {
            return [
                Color(red: 0.9, green: 0.7, blue: 0.6),
                Color(red: 0.85, green: 0.6, blue: 0.5),
                Color(red: 0.8, green: 0.55, blue: 0.45)
            ]
        } else if isBeta {
            return [
                Color(red: 0.95, green: 0.85, blue: 0.4),
                Color(red: 0.9, green: 0.8, blue: 0.35),
                Color(red: 0.85, green: 0.75, blue: 0.3)
            ]
        } else if isBlack {
            return [
                Color.white.opacity(0.2),
                Color.white.opacity(0.15),
                Color.white.opacity(0.1)
            ]
        } else if isAnnual {
            return [
                Color(red: 0.95, green: 0.95, blue: 1.0).opacity(0.3),
                Color(red: 0.85, green: 0.85, blue: 0.95).opacity(0.25),
                Color(red: 0.75, green: 0.75, blue: 0.9).opacity(0.2)
            ]
        } else {
            return [
                Color(red: 1.0, green: 0.9, blue: 0.6),
                Color(red: 0.95, green: 0.85, blue: 0.5),
                Color(red: 0.9, green: 0.8, blue: 0.4)
            ]
        }
    }
    
    private var decorativeBorderShadow: Color {
        isRoseGold ? Color(red: 0.6, green: 0.4, blue: 0.3).opacity(0.4) : (isBeta ? Color(red: 0.5, green: 0.4, blue: 0.2).opacity(0.4) : (isBlack ? Color.white.opacity(0.2) : (isAnnual ? Color.white.opacity(0.2) : Color(red: 0.6, green: 0.45, blue: 0.2).opacity(0.4))))
    }
    
    private var decorativeInnerBorderColor: Color {
        isRoseGold ? Color(red: 0.7, green: 0.5, blue: 0.4) : (isBeta ? Color(red: 0.6, green: 0.5, blue: 0.25) : (isBlack ? Color.white.opacity(0.4) : (isAnnual ? Color.white.opacity(0.4) : Color(red: 0.7, green: 0.55, blue: 0.3))))
    }
    
    private func generateQRCode() {
        let qrService = QRCodeService.shared
        // Optimized sizes for scanability:
        // - Compact: 100x100 (minimum for reliable scanning)
        // - Full: 150x150 (optimal for easy scanning from distance)
        let size = compactSize ? CGSize(width: 100, height: 100) : CGSize(width: 150, height: 150)
        qrCodeImage = qrService.generateMemberCardQRCode(
            userId: userId,
            cardType: cardType,
            memberSince: memberSince,
            size: size
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
    let memberSinceDate: String // Format: MM/YY
    
    var body: some View {
        HStack(alignment: .bottom) {
            // Bottom left: Username (like AmEx cardholder name)
            VStack(alignment: .leading, spacing: 0) {
                Text(userName.uppercased())
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(usernameColor)
                    .tracking(2)
                    .shadow(color: usernameShadow, radius: 1, x: 0, y: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer()
            
            // Bottom right: Member Since - vertical stack in square border (MEMBER / MM/YY / SINCE)
            VStack(alignment: .trailing, spacing: 0) {
                ZStack {
                    // Square border around the entire stack
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.clear)
                        .frame(width: 60, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(memberOvalBorderColor, lineWidth: 0.8)
                        )
                    
                    // Vertical stack - center aligned
                    VStack(alignment: .center, spacing: 2) {
                        // "MEMBER" on top
                        Text("MEMBER")
                            .font(.system(size: 7, weight: .bold, design: .default))
                            .foregroundColor(memberLabelColor)
                            .tracking(1.5)
                        
                        // Date in middle (MM/YY)
                        Text(memberSinceDate)
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundColor(yearNumberColor)
                            .shadow(color: yearNumberShadow, radius: 2, x: 0, y: 1)
                        
                        // "SINCE" on bottom
                        Text("SINCE")
                            .font(.system(size: 7, weight: .bold, design: .default))
                            .foregroundColor(memberLabelColor)
                            .tracking(1.5)
                    }
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
    
    // Member year styling (bottom left)
    private var yearPrefixColor: Color {
        isRoseGold ? Color(red: 0.4, green: 0.3, blue: 0.25) : (isBeta ? Color(red: 0.35, green: 0.28, blue: 0.15) : (isBlack ? Color.white.opacity(0.8) : (isAnnual ? Color.white.opacity(0.8) : Color(red: 0.3, green: 0.22, blue: 0.12))))
    }
    
    private var yearNumberColor: Color {
        isRoseGold ? Color(red: 0.3, green: 0.2, blue: 0.15) : (isBlack ? Color.black : (isAnnual ? Color.black : Color.black))
    }
    
    private var yearNumberShadow: Color {
        isRoseGold ? Color.black.opacity(0.15) : (isBlack ? Color.white.opacity(0.3) : (isAnnual ? Color.white.opacity(0.2) : Color.black.opacity(0.1)))
    }
    
    private var memberLabelColor: Color {
        isRoseGold ? Color(red: 0.3, green: 0.2, blue: 0.15) : (isBlack ? Color.black : (isAnnual ? Color.black : Color.black))
    }
    
    private var memberOvalBorderColor: Color {
        isRoseGold ? Color(red: 0.3, green: 0.2, blue: 0.15) : (isBlack ? Color.black : (isAnnual ? Color.black : Color.black))
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

