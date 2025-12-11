//
//  ReverCard.swift
//  soteria
//
//  REVER UI KIT v1.0 - Card Components
//

import SwiftUI

// MARK: - Standard Card
struct ReverCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(Color.cloudWhite)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
}

// MARK: - Soft Blue Card
struct ReverSoftBlueCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(Color.reverSkyGradient)
            .cornerRadius(22)
    }
}

// MARK: - Card View Modifiers
extension View {
    func reverCard() -> some View {
        self
            .padding(20)
            .background(Color.cloudWhite)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    func reverSoftBlueCard() -> some View {
        self
            .padding(20)
            .background(Color.reverSkyGradient)
            .cornerRadius(22)
    }
}

