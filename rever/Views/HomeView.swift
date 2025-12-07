//
//  HomeView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI
import FirebaseAuth
import UIKit

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var savingsService: SavingsService
    
    private var userEmail: String {
        authService.currentUser?.email ?? "there"
    }
    
    private var formattedTotalSaved: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: savingsService.totalSaved)) ?? "$0.00"
    }
    
    private var formattedLastSaved: String {
        guard let lastSaved = savingsService.lastSavedAmount else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: lastSaved)) ?? "$0.00"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Total Saved Card - Hero Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Saved")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        
                        Text(formattedTotalSaved)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                        
                        Text("by skipping impulse purchases")
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.95, green: 0.98, blue: 0.95),
                                        Color(red: 0.92, green: 0.97, blue: 0.92)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    // Stats Row
                    HStack(spacing: 16) {
                        // Rever Moments Card
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Rever Moments")
                                .font(.system(size: 12, weight: .medium, design: .default))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            
                            Text("\(savingsService.reverMomentsCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        
                        // Last Saved Card
                        if savingsService.lastSavedAmount != nil {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Last Saved")
                                    .font(.system(size: 12, weight: .medium, design: .default))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                
                                Text(formattedLastSaved)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Fixed Header
            VStack(spacing: 2) {
                Text("Hi, \(userEmail)")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                
                Text("Welcome back")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(.gray)
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
    HomeView()
        .environmentObject(AuthService())
        .environmentObject(SavingsService())
}
