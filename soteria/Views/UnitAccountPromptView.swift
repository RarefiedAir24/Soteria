//
//  UnitAccountPromptView.swift
//  Soteria
//
//  Positive popup notification prompting users to create their dedicated savings account
//  Shows on app open if user account exists but Unit account doesn't
//

import SwiftUI

struct UnitAccountPromptView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showCreateAccount = false
    @State private var bannerScale: CGFloat = 0.95
    @State private var sparkleRotation: Double = 0
    
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Main card
            VStack(spacing: 0) {
                // Content
                VStack(spacing: 20) {
                    // Icon with sparkle animation
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.6, blue: 0.9),
                                        Color(red: 0.3, green: 0.5, blue: 0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "tree.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        // Sparkle effect
                        ForEach(0..<6, id: \.self) { index in
                            Image(systemName: "sparkle")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .offset(x: 45)
                                .rotationEffect(.degrees(Double(index) * 60 + sparkleRotation))
                        }
                    }
                    .frame(height: 100)
                    
                    // Title
                    Text("Grow Your Money Tree 🌳")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.midnightSlate)
                        .multilineTextAlignment(.center)
                    
                    // Subtitle - positive and brief
                    Text("Create your dedicated savings account and watch your goals bloom! Your money tree grows with every deposit.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.softGraphite)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                    
                    // Info about dismissal
                    Text("You can dismiss this for 3 days if you're not ready yet.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.softGraphite.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    
                    // Quick benefits
                    VStack(alignment: .leading, spacing: 10) {
                        benefitRow(icon: "lock.shield.fill", text: "FDIC-insured protection")
                        benefitRow(icon: "arrow.triangle.2.circlepath", text: "Easy transfers via Plaid or account credentials")
                        benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track all goals in one place")
                    }
                    .padding(.vertical, 8)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Create Account button
                        Button(action: {
                            showCreateAccount = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Create My Account")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.6, blue: 0.9),
                                        Color(red: 0.3, green: 0.5, blue: 0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        // Maybe Later button (dismiss for 3 days)
                        Button(action: {
                            // Mark as dismissed for 3 days
                            let dismissUntil = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
                            UserDefaults.standard.set(dismissUntil, forKey: "unit_account_prompt_dismiss_until")
                            onDismiss()
                        }) {
                            Text("Remind Me in 3 Days")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.softGraphite)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
            .scaleEffect(bannerScale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                bannerScale = 1.0
            }
            
            // Animate sparkles
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
        .sheet(isPresented: $showCreateAccount) {
            UnitAccountCreationBanner(onDismiss: {
                showCreateAccount = false
                onDismiss()
            })
            .environmentObject(authService)
        }
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.9))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.midnightSlate)
            
            Spacer()
        }
    }
}

#Preview {
    UnitAccountPromptView(onDismiss: {})
        .environmentObject(AuthService())
}

