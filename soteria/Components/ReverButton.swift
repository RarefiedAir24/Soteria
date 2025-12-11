//
//  ReverButton.swift
//  soteria
//
//  REVER UI KIT v1.0 - Button System
//

import SwiftUI

// MARK: - Primary Button
/// Primary Button: Key action, high importance
struct ReverPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.cloudWhite)
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(Color.deepReverBlue)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button
/// Secondary Button: Soft CTA
struct ReverSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.midnightSlate)
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(Color.reverBlue)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.dreamMist, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Tertiary Button (Link)
/// Tertiary Button: Text only link style
struct ReverTertiaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.deepReverBlue)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Button View Modifiers
extension View {
    func reverPrimaryButton() -> some View {
        self.buttonStyle(ReverPrimaryButton())
    }
    
    func reverSecondaryButton() -> some View {
        self.buttonStyle(ReverSecondaryButton())
    }
    
    func reverTertiaryButton() -> some View {
        self.buttonStyle(ReverTertiaryButton())
    }
}

