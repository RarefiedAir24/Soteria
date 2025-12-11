//
//  SplashScreenView.swift
//  soteria
//
//  Splash screen shown immediately while app initializes
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background - REVER Dream gradient for calm, dreamlike feel
            Color.reverDreamGradient
                .ignoresSafeArea()
            
            VStack(spacing: .spacingSection) {
                // Logo - using soteria_logo_2 asset
                Image("soteria_logo_2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.reverBlue.opacity(0.25), radius: 15, x: 0, y: 5)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
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
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    SplashScreenView()
}

