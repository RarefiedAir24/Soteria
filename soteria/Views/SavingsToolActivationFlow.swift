//
//  SavingsToolActivationFlow.swift
//  soteria
//
//  Step-by-step flow for activating savings tools
//

import SwiftUI

struct SavingsToolActivationFlow: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var toolsService = SavingsToolsService.shared
    @ObservedObject private var loyaltyService = LoyaltyPointsService.shared
    
    @State private var currentToolIndex = 0
    @State private var showingCelebration = false
    @State private var justActivatedTool: SavingsTool?
    
    private var unactivatedTools: [SavingsTool] {
        toolsService.unactivatedTools
    }
    
    private var currentTool: SavingsTool? {
        guard currentToolIndex < unactivatedTools.count else { return nil }
        return unactivatedTools[currentToolIndex]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cloudWhite.ignoresSafeArea()
                
                if let tool = currentTool {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Progress indicator
                            progressIndicator
                            
                            // Tool icon (animated)
                            toolIconView(for: tool)
                            
                            // Tool info
                            VStack(spacing: 16) {
                                Text(tool.name)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.midnightSlate)
                                
                                Text("Save money every month!")
                                    .font(.system(size: 16))
                                    .foregroundColor(.softGraphite)
                                
                                // Savings potential
                                savingsPotentialCard(for: tool)
                                
                                // How it works
                                howItWorksSection(for: tool)
                                
                                // Benefits
                                benefitsSection(for: tool)
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer(minLength: 40)
                            
                            // Action buttons
                            actionButtons(for: tool)
                        }
                        .padding(.vertical, 20)
                    }
                } else {
                    // All tools activated
                    allToolsActivatedView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCelebration) {
                if let tool = justActivatedTool {
                    ToolActivationCelebrationView(tool: tool) {
                        // Move to next tool or finish
                        if currentToolIndex < unactivatedTools.count - 1 {
                            currentToolIndex += 1
                        } else {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<unactivatedTools.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentToolIndex ? Color.reverBlue : Color.softGraphite.opacity(0.2))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func toolIconView(for tool: SavingsTool) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.reverBlue.opacity(0.2), Color.reverBlue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            Image(systemName: tool.icon)
                .font(.system(size: 50))
                .foregroundColor(.reverBlue)
        }
        .padding(.vertical, 20)
    }
    
    private func savingsPotentialCard(for tool: SavingsTool) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average Savings")
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                    
                    Text(tool.monthlySavings + "/month")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.reverBlue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Activation Bonus")
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                        Text("+\(tool.activationBonus)")
                            .font(.system(size: 24, weight: .bold))
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.reverBlue.opacity(0.05))
        )
    }
    
    private func howItWorksSection(for tool: SavingsTool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
            
            VStack(alignment: .leading, spacing: 12) {
                switch tool {
                case .upside:
                    howItWorksStep(number: 1, text: "Download the Upside app (free)")
                    howItWorksStep(number: 2, text: "Find nearby gas stations with offers")
                    howItWorksStep(number: 3, text: "Activate offer before pumping")
                    howItWorksStep(number: 4, text: "Upload receipt or link your card")
                    howItWorksStep(number: 5, text: "Get cash back instantly!")
                    
                case .goodrx:
                    howItWorksStep(number: 1, text: "Download the GoodRx app (free)")
                    howItWorksStep(number: 2, text: "Search for your medication")
                    howItWorksStep(number: 3, text: "Compare prices at nearby pharmacies")
                    howItWorksStep(number: 4, text: "Show coupon at the pharmacy")
                    howItWorksStep(number: 5, text: "Pay the discounted price!")
                    
                default:
                    howItWorksStep(number: 1, text: "Download the recommended app")
                    howItWorksStep(number: 2, text: "Follow the setup instructions")
                    howItWorksStep(number: 3, text: "Start saving money!")
                }
            }
        }
    }
    
    private func howItWorksStep(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.reverBlue)
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.midnightSlate)
            
            Spacer()
        }
    }
    
    private func benefitsSection(for tool: SavingsTool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why Activate This?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
            
            benefitRow(icon: "dollarsign.circle.fill", text: "Save money on expenses you already have", color: .green)
            benefitRow(icon: "star.fill", text: "Earn \(tool.activationBonus) loyalty points instantly", color: .orange)
            benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track all your savings in one place", color: .reverBlue)
            benefitRow(icon: "gift.fill", text: "Get closer to gift card rewards", color: .purple)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8)
        )
    }
    
    private func benefitRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.midnightSlate)
            
            Spacer()
        }
    }
    
    private func actionButtons(for tool: SavingsTool) -> some View {
        VStack(spacing: 12) {
            // Primary action
            if !tool.appStoreURL.isEmpty, let url = URL(string: tool.appStoreURL) {
                Button(action: {
                    // Open App Store and mark as activated
                    UIApplication.shared.open(url)
                    
                    // Mark as activated after short delay (assume they'll install)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        toolsService.activateTool(tool.id)
                        justActivatedTool = tool
                        showingCelebration = true
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Download & Activate")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.reverBlue, Color.reverBlue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.reverBlue.opacity(0.3), radius: 12)
                }
            } else {
                // Coming soon
                Button(action: {}) {
                    Text("Coming Soon")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.softGraphite.opacity(0.5))
                        .cornerRadius(16)
                }
                .disabled(true)
            }
            
            // Skip button
            Button(action: {
                if currentToolIndex < unactivatedTools.count - 1 {
                    currentToolIndex += 1
                } else {
                    dismiss()
                }
            }) {
                Text("Skip This Tool")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.softGraphite)
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var allToolsActivatedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("All Set!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.midnightSlate)
            
            Text("You've activated all available savings tools!")
                .font(.system(size: 16))
                .foregroundColor(.softGraphite)
                .multilineTextAlignment(.center)
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.reverBlue)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
    }
}

// MARK: - Tool Activation Celebration

struct ToolActivationCelebrationView: View {
    let tool: SavingsTool
    let onContinue: () -> Void
    
    @ObservedObject private var loyaltyService = LoyaltyPointsService.shared
    @ObservedObject private var toolsService = SavingsToolsService.shared
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated checkmark
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("✅ \(tool.name) Activated!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.midnightSlate)
                
                // Points earned
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 32))
                        Text("+\(tool.activationBonus)")
                            .font(.system(size: 36, weight: .bold))
                    }
                    .foregroundColor(.orange)
                    
                    Text("Loyalty Points Earned!")
                        .font(.system(size: 16))
                        .foregroundColor(.softGraphite)
                }
                
                // Current balance
                VStack(spacing: 4) {
                    Text("Your balance: \(loyaltyService.totalPoints) points")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.midnightSlate)
                    
                    // Progress to next gift card
                    let progress = Double(loyaltyService.totalPoints) / 2500.0
                    let percentage = min(Int(progress * 100), 100)
                    
                    if progress < 1.0 {
                        Text("Progress to $5 card: \(percentage)%")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                    } else {
                        Text("You can redeem a $5 gift card! 🎁")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.reverBlue)
                    }
                }
                .padding()
                .background(Color.reverBlue.opacity(0.05))
                .cornerRadius(12)
                
                // Continue button
                if toolsService.unactivatedTools.isEmpty {
                    Text("Keep going! Activate more tools for more points!")
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Button(action: onContinue) {
                    Text(toolsService.unactivatedTools.isEmpty ? "Done" : "Continue Setup")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.reverBlue)
                        .cornerRadius(16)
                }
            }
            .padding(32)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Preview

#Preview {
    SavingsToolActivationFlow()
}
