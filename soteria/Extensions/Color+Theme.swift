//
//  Color+Theme.swift
//  soteria
//
//  REVER UI KIT v1.0 - Color System
//  Emotional goals: calm • safety • reflection • warmth • dreamlike simplicity
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors
    /// Rever Blue: #AFCBEF
    static var reverBlue: Color {
        Color(red: 175.0/255.0, green: 203.0/255.0, blue: 239.0/255.0)
    }
    
    /// Deep Rever Blue: #7DA2C8
    static var deepReverBlue: Color {
        Color(red: 125.0/255.0, green: 162.0/255.0, blue: 200.0/255.0)
    }
    
    /// Dream Mist: #DCEBFA
    static var dreamMist: Color {
        Color(red: 220.0/255.0, green: 235.0/255.0, blue: 250.0/255.0)
    }
    
    /// Rever Blue Light: Lighter variant of Rever Blue (for gradients)
    static var reverBlueLight: Color {
        Color.dreamMist
    }
    
    /// Rever Blue Dark: Darker variant of Rever Blue (for gradients)
    static var reverBlueDark: Color {
        Color.deepReverBlue
    }
    
    // MARK: - Secondary Colors
    /// Comfort Lavender: #DAD7F8
    static var comfortLavender: Color {
        Color(red: 218.0/255.0, green: 215.0/255.0, blue: 248.0/255.0)
    }
    
    /// Gentle Rose: #F6DDE2
    static var gentleRose: Color {
        Color(red: 246.0/255.0, green: 221.0/255.0, blue: 226.0/255.0)
    }
    
    /// Warm Sand: #F5EDE1
    static var warmSand: Color {
        Color(red: 245.0/255.0, green: 237.0/255.0, blue: 225.0/255.0)
    }
    
    // MARK: - Neutral Colors
    /// Midnight Slate: #1E1F23
    static var midnightSlate: Color {
        Color(red: 30.0/255.0, green: 31.0/255.0, blue: 35.0/255.0)
    }
    
    /// Soft Graphite: #5A5D6A
    static var softGraphite: Color {
        Color(red: 90.0/255.0, green: 93.0/255.0, blue: 106.0/255.0)
    }
    
    /// Mist Gray: #F2F4F7
    static var mistGray: Color {
        Color(red: 242.0/255.0, green: 244.0/255.0, blue: 247.0/255.0)
    }
    
    /// Cloud White: #FFFFFF
    static var cloudWhite: Color {
        Color.white
    }
    
    // MARK: - Gradients
    /// Rever Sky: #AFCBEF → #DCEBFA
    static var reverSkyGradient: LinearGradient {
        LinearGradient(
            colors: [Color.reverBlue, Color.dreamMist],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Rever Dream: #AFCBEF → #DAD7F8
    static var reverDreamGradient: LinearGradient {
        LinearGradient(
            colors: [Color.reverBlue, Color.comfortLavender],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Rever Calm: #7DA2C8 → #AFCBEF
    static var reverCalmGradient: LinearGradient {
        LinearGradient(
            colors: [Color.deepReverBlue, Color.reverBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Legacy Support (for gradual migration)
    /// Primary theme color: #A7C7E7 (light blue) - DEPRECATED, use reverBlue
    @available(*, deprecated, message: "Use reverBlue instead")
    static var themePrimary: Color {
        Color.reverBlue
    }
    
    /// Lighter variant for gradients - DEPRECATED, use dreamMist
    @available(*, deprecated, message: "Use dreamMist instead")
    static var themePrimaryLight: Color {
        Color.dreamMist
    }
    
    /// Darker variant for gradients - DEPRECATED, use deepReverBlue
    @available(*, deprecated, message: "Use deepReverBlue instead")
    static var themePrimaryDark: Color {
        Color.deepReverBlue
    }
}
