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
            Color.dreamMist
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Soteria Logo
                if let logoImage = UIImage(named: "soteria_logo") {
                    Image(uiImage: logoImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                } else {
                    // Fallback if image not found
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.deepReverBlue)
                }
                
                Text("SOTERIA")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.deepReverBlue)
                
                Spacer()
                
                // App version and build number at the bottom
                Text(Bundle.displayVersionString)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.softGraphite)
                    .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

