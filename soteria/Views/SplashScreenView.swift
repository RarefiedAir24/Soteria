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
            // Background - using brand color #012945
            LinearGradient(
                colors: [
                    Color(red: 1.0/255.0, green: 41.0/255.0, blue: 69.0/255.0), // #012945
                    Color(red: 1.0/255.0, green: 41.0/255.0, blue: 69.0/255.0).opacity(0.9) // Slightly lighter for gradient
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo - using custom logo asset
                Image("soteria_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.white.opacity(0.2), radius: 15, x: 0, y: 5) // White shadow for dark background
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                // App Name
                Text("SOTERIA")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .foregroundColor(.white) // White text for contrast on dark background
                
                // Loading indicator
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white) // White loading indicator for contrast
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    SplashScreenView()
}

