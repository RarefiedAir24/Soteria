//
//  HomeView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Welcome to Rever")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Your behavioral finance companion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}

