//
//  SettingsView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = authService.currentUser {
                        Text("Signed in as: \(user.email ?? "Unknown")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        try? authService.signOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
}

