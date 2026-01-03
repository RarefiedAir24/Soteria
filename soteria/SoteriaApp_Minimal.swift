//
//  SoteriaApp_Minimal.swift
//  soteria
//
//  ABSOLUTE MINIMUM APP - Remove .task to test if that's blocking
//

import SwiftUI

// DISABLED: Using main SoteriaApp instead
// @main
struct SoteriaApp_Minimal: App {
    var body: some Scene {
        WindowGroup {
            MinimalTestView_Minimal()
        }
    }
}

struct MinimalTestView_Minimal: View {
    @State private var text = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Minimal Test")
                .font(.title)
            
            // Simple SwiftUI TextField
            TextField("Type here", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .onChange(of: text) { oldValue, newValue in
                    print("🔍 [Minimal] Text changed: \(newValue)")
                }
            
            Button("Test Button") {
                print("🔍 [Minimal] Button tapped")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Text("Text: \(text)")
                .padding()
        }
        .padding()
        .onAppear {
            print("🔍 [Minimal] View appeared")
        }
    }
}
