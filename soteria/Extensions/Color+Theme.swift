//
//  Color+Theme.swift
//  soteria
//
//  Theme color extension for consistent branding
//

import SwiftUI

extension Color {
    /// Primary theme color: #A7C7E7 (light blue)
    static var themePrimary: Color {
        Color(red: 167.0/255.0, green: 199.0/255.0, blue: 231.0/255.0)
    }
    
    /// Lighter variant for gradients
    static var themePrimaryLight: Color {
        Color(red: 180.0/255.0, green: 210.0/255.0, blue: 240.0/255.0)
    }
    
    /// Darker variant for gradients
    static var themePrimaryDark: Color {
        Color(red: 150.0/255.0, green: 185.0/255.0, blue: 220.0/255.0)
    }
}

