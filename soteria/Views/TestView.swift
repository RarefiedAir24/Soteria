//
//  TestView.swift
//  soteria
//
//  Ultra-minimal test view - no services, no dependencies
//

import SwiftUI

struct MinimalTestView: View {
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()
            
            VStack {
                Text("TEST VIEW")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("If you see this, the view loaded")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 20)
            }
        }
        .onAppear {
            print("🟢 [TestView] onAppear - view is visible!")
        }
    }
}

#Preview {
    MinimalTestView()
}

