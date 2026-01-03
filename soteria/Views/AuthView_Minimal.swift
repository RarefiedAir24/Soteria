//
//  AuthView_Minimal.swift
//  soteria
//
//  ABSOLUTE MINIMAL TEST VERSION - Just text, no TextFields
//

import SwiftUI

struct AuthView_Minimal: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        // CRITICAL: Use synchronous print to detect if body evaluation is happening
        let _ = print("🔍 [AuthView_Minimal] body evaluation started at \(Date().timeIntervalSince1970)")
        
        // ABSOLUTE MINIMAL - Just text, no TextFields, no complex views
        return VStack(spacing: 20) {
            Text("SOTERIA")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .padding(.top, 60)
            
            Text("Your behavioral finance companion")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.softGraphite)
                .padding(.bottom, 40)
            
            Text("Sign In")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(Color.deepReverBlue)
                .cornerRadius(14)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color.dreamMist.ignoresSafeArea())
        .onAppear {
            let onAppearStart = Date()
            print("🔍 [AuthView_Minimal] onAppear called at \(Date().timeIntervalSince1970)")
            
            // Post notification
            NotificationCenter.default.post(name: NSNotification.Name("AuthViewAppeared"), object: nil)
            
            let onAppearDuration = Date().timeIntervalSince(onAppearStart)
            print("⏱️ [AuthView_Minimal] onAppear handler took \(String(format: "%.3f", onAppearDuration))s")
        }
    }
}

