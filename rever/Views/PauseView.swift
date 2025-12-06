//
//  PauseView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI

struct PauseView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Rever Moment")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Take a moment to reflect on your purchase")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    Button(action: {
                        // Handle Skip & Save
                        dismiss()
                    }) {
                        Text("Skip & Save")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        // Handle Continue Shopping
                        dismiss()
                    }) {
                        Text("Continue Shopping")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        // Handle Mark as Planned
                        dismiss()
                    }) {
                        Text("Mark as Planned")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Pause")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PauseView()
}

