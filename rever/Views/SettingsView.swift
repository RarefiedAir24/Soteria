//
//  SettingsView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI
import FirebaseAuth
import UIKit

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.95, green: 0.95, blue: 0.95)
                .ignoresSafeArea()
            
            List {
                Section {
                    if let user = authService.currentUser {
                        Text("Signed in as: \(user.email ?? "Unknown")")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                }
                .listRowBackground(Color.white)
                
                Section {
                    Button(action: {
                        try? authService.signOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
                .listRowBackground(Color.white)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .padding(.top, 50)
            
            // Fixed Header - matches Home style
            VStack(spacing: 2) {
                Text("Settings")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Color(red: 0.92, green: 0.97, blue: 0.94)
                    .ignoresSafeArea(edges: .top)
            )
            .zIndex(100)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
}

