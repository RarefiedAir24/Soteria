//
//  Typography.swift
//  soteria
//
//  REVER UI KIT v1.0 - Typography System
//

import SwiftUI

extension Font {
    // MARK: - Headings
    /// H1: 32pt, Semibold, Midnight Slate
    static var reverH1: Font {
        .system(size: 32, weight: .semibold, design: .default)
    }
    
    /// H2: 24pt, Semibold, Midnight Slate
    static var reverH2: Font {
        .system(size: 24, weight: .semibold, design: .default)
    }
    
    /// H3: 20pt, Medium, Soft Graphite
    static var reverH3: Font {
        .system(size: 20, weight: .medium, design: .default)
    }
    
    // MARK: - Body
    /// Body Large: 18pt, Regular, Midnight Slate
    static var reverBodyLarge: Font {
        .system(size: 18, weight: .regular, design: .default)
    }
    
    /// Body: 16pt, Regular, Soft Graphite
    static var reverBody: Font {
        .system(size: 16, weight: .regular, design: .default)
    }
    
    /// Caption: 13pt, Regular, Soft Graphite
    static var reverCaption: Font {
        .system(size: 13, weight: .regular, design: .default)
    }
}

extension Text {
    // MARK: - Typography Modifiers
    /// H1: 32pt, Semibold, Midnight Slate
    func reverH1() -> some View {
        self
            .font(.reverH1)
            .foregroundColor(.midnightSlate)
    }
    
    /// H2: 24pt, Semibold, Midnight Slate
    func reverH2() -> some View {
        self
            .font(.reverH2)
            .foregroundColor(.midnightSlate)
    }
    
    /// H3: 20pt, Medium, Soft Graphite
    func reverH3() -> some View {
        self
            .font(.reverH3)
            .foregroundColor(.softGraphite)
    }
    
    /// Body Large: 18pt, Regular, Midnight Slate
    func reverBodyLarge() -> some View {
        self
            .font(.reverBodyLarge)
            .foregroundColor(.midnightSlate)
    }
    
    /// Body: 16pt, Regular, Soft Graphite
    func reverBody() -> some View {
        self
            .font(.reverBody)
            .foregroundColor(.softGraphite)
    }
    
    /// Caption: 13pt, Regular, Soft Graphite
    func reverCaption() -> some View {
        self
            .font(.reverCaption)
            .foregroundColor(.softGraphite)
    }
}

