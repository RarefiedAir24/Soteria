//
//  TestKeyboardView.swift
//  soteria
//
//  Test keyboard appearance - remove conditional rendering to test if that's blocking
//

import SwiftUI

struct TestKeyboardView: View {
    @State private var text = ""
    @State private var buttonTapped = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("TEST KEYBOARD")
                .font(.system(size: 24, weight: .bold))
                .padding()
            
            // Simple SwiftUI TextField WITHOUT @FocusState - let SwiftUI handle it naturally
            TextField("Type here", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
                .onChange(of: text) { oldValue, newValue in
                    print("🔍 [TestKeyboardView] Text changed: '\(oldValue)' -> '\(newValue)'")
                }
                .onSubmit {
                    print("🔍 [TestKeyboardView] TextField onSubmit called")
                }
            
            Button("Test Button") {
                print("🔍 [TestKeyboardView] Button tapped - BEFORE state change")
                buttonTapped.toggle()
                print("🔍 [TestKeyboardView] Button tapped - AFTER state change")
            }
            .padding()
            .background(buttonTapped ? Color.green : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            // REMOVED: Conditional rendering - this might be causing the lockup
            // if buttonTapped {
            //     Text("Button was tapped!")
            //         .foregroundColor(.green)
            // }
            
            // Always show this text to avoid conditional rendering
            Text(buttonTapped ? "Button was tapped!" : "Button not tapped")
                .foregroundColor(buttonTapped ? .green : .gray)
            
            Text("Text: \(text)")
                .padding()
        }
        .onAppear {
            print("🔍 [TestKeyboardView] onAppear - view is visible")
        }
        .onChange(of: buttonTapped) { oldValue, newValue in
            print("🔍 [TestKeyboardView] buttonTapped changed: \(oldValue) -> \(newValue)")
        }
    }
}
