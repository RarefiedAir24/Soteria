//
//  SplashScreenView.swift
//  soteria
//
//  Splash screen shown immediately while app initializes
//

import SwiftUI

struct SplashScreenView: View {
    // REMOVED: @State private var isAnimating - animations block MainActor
    // REMOVED: All animations - they cause 49-second delays in view rendering
    
    var body: some View {
        ZStack {
            // Background - Lighter REVER color for better logo contrast
            Color.dreamMist
                .ignoresSafeArea()
            
            VStack(spacing: .spacingSection) {
                // Logo - using soteria_logo asset
                // REMOVED: Animations to prevent blocking
                Image("soteria_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.reverBlue.opacity(0.25), radius: 15, x: 0, y: 5)
                
                // App Name - H1 style
                Text("SOTERIA")
                    .reverH1()
                
                // Loading indicator
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.deepReverBlue)
            }
            .padding(.spacingHero)
        }
        // REMOVED: .onAppear with animation - it was blocking MainActor
    }
}

#Preview {
    SplashScreenView()
}

