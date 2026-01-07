//
//  WelcomeBackView.swift
//  soteria
//
//  Welcome back message shown after sign-in with deposit CTA
//

import SwiftUI

struct WelcomeBackView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var goalsService: GoalsService
    
    let onMakeDeposit: () -> Void
    let onDismiss: () -> Void
    
    // Get username from email (part before @)
    private var username: String {
        guard let email = authService.currentUserEmail else { return "there" }
        if let atIndex = email.firstIndex(of: "@") {
            let name = String(email[..<atIndex])
            // Capitalize first letter
            return name.prefix(1).uppercased() + name.dropFirst()
        }
        return email
    }
    
    // Get oldest active goal (cached to avoid repeated sorting)
    @State private var cachedOldestGoal: SavingsGoal? = nil
    
    private var oldestGoal: SavingsGoal? {
        // Use cached value if available and goals haven't changed
        if let cached = cachedOldestGoal,
           goalsService.activeGoals.contains(where: { $0.id == cached.id }) {
            return cached
        }
        
        // Recompute if cache is invalid
        let activeGoals = goalsService.activeGoals
        guard !activeGoals.isEmpty else {
            cachedOldestGoal = nil
            return nil
        }
        
        // Find oldest goal (O(n) instead of O(n log n) for sorting)
        let oldest = activeGoals.min(by: { $0.createdDate < $1.createdDate })
        cachedOldestGoal = oldest
        return oldest
    }
    
    // Format currency
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
    
    // Calculate progress percentage
    private func progressPercentage(for goal: SavingsGoal) -> Int {
        guard goal.targetAmount > 0 else { return 0 }
        return Int((goal.currentAmount / goal.targetAmount) * 100)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let goal = oldestGoal {
                    VStack(spacing: 24) {
                        // Header with icon
                        VStack(spacing: 12) {
                            // Welcome icon
                            ZStack {
                                Circle()
                                    .fill(Color.softGraphite.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "hand.wave.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.softGraphite)
                            }
                            
                            VStack(spacing: 6) {
                                Text("Hi \(username)!")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.midnightSlate)
                                
                                Text("Welcome Back")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                
                                Text("Would you like to make a deposit?")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.softGraphite)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.top, 20) // Reduced padding since we're in a scrollable view
                    
                    // Goal Progress Card - Enhanced styling
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 12) {
                            // Category icon with background
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.softGraphite.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: goal.category.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(.softGraphite)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.midnightSlate)
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.softGraphite)
                                        .frame(width: 6, height: 6)
                                    Text("in progress")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.softGraphite)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.dreamMist)
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.softGraphite)
                                    .frame(width: geometry.size.width * min(goal.progress, 1.0), height: 12)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: goal.progress)
                            }
                        }
                        .frame(height: 12)
                        
                        // Amounts
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                Text(formatCurrency(goal.currentAmount))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.softGraphite)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Target")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                Text(formatCurrency(goal.targetAmount))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.midnightSlate)
                            }
                        }
                        
                        // Percentage
                        HStack {
                            Text("\(progressPercentage(for: goal))% Complete")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.softGraphite)
                            
                            Spacer()
                            
                            Text("\(formatCurrency(goal.remainingAmount)) remaining")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.softGraphite)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.softGraphite.opacity(0.1), radius: 12, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.softGraphite.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    
                        // Action Buttons - Enhanced styling
                        VStack(spacing: 14) {
                            Button(action: onMakeDeposit) {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Make Deposit")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.softGraphite)
                                        .shadow(color: Color.softGraphite.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: onDismiss) {
                                Text("Maybe Later")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.dreamMist)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                } else {
                    // No active goals - simpler message with enhanced styling
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.softGraphite.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "hand.wave.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.softGraphite)
                            }
                            
                            VStack(spacing: 6) {
                                Text("Hi \(username)!")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.midnightSlate)
                                
                                Text("Welcome Back")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                
                                Text("Would you like to make a deposit?")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.softGraphite)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.top, 20) // Reduced padding since we're in a scrollable view
                        
                        VStack(spacing: 14) {
                            Button(action: onMakeDeposit) {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Make Deposit")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.softGraphite)
                                        .shadow(color: Color.softGraphite.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: onDismiss) {
                                Text("Maybe Later")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.dreamMist)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            // Reserve space for sheet drag indicator in compact view
            Color.clear.frame(height: 8)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Reserve space for bottom safe area
            Color.clear.frame(height: 20)
        }
        .background(
            LinearGradient(
                colors: [Color.mistGray, Color.cloudWhite],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            // Pre-compute oldest goal when view appears
            let _ = oldestGoal
        }
        .onChange(of: goalsService.goals.count) {
            // Invalidate cache when goals change
            cachedOldestGoal = nil
        }
    }
}

