//
//  SavingsToolsManagementView.swift
//  soteria
//
//  Full management interface for savings tools
//

import SwiftUI

struct SavingsToolsManagementView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var toolsService = SavingsToolsService.shared
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showActivationFor: SavingsTool? = nil
    @State private var showSettingsFor: SavingsTool? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Active Tools Section
                    if !toolsService.activatedTools.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("ACTIVE TOOLS (\(toolsService.activatedTools.count))")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.softGraphite)
                                    .tracking(0.5)
                                
                                Spacer()
                                
                                if toolsService.totalPointsEarned > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                        Text("\(toolsService.totalPointsEarned) pts earned")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(.green)
                                }
                            }
                            
                            ForEach(toolsService.activatedTools, id: \.id) { tool in
                                ActiveToolCard(tool: tool) {
                                    showSettingsFor = tool
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Available Tools Section
                    if !toolsService.unactivatedTools.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("AVAILABLE TO ACTIVATE (\(toolsService.unactivatedTools.count))")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.softGraphite)
                                    .tracking(0.5)
                                
                                Spacer()
                                
                                if toolsService.totalUnactivatedBonus > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "gift.fill")
                                            .font(.system(size: 12))
                                        Text("\(toolsService.totalUnactivatedBonus) pts bonus")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(.orange)
                                }
                            }
                            
                            let potentialSavings = toolsService.totalPotentialSavings
                            Text("Unlock $\(potentialSavings.min)-\(potentialSavings.max) more in monthly savings")
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                            
                            ForEach(toolsService.unactivatedTools, id: \.id) { tool in
                                AvailableToolCard(tool: tool) {
                                    showActivationFor = tool
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Empty state
                    if toolsService.activatedTools.isEmpty && toolsService.unactivatedTools.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bolt.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.softGraphite.opacity(0.3))
                            
                            Text("No Savings Tools Available")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            Text("Check back soon for new savings opportunities!")
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.mistGray.ignoresSafeArea())
            .navigationTitle("Savings Tools")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.softGraphite)
                    }
                }
            }
        }
        .sheet(item: $showActivationFor) { tool in
            ToolActivationView(tool: tool)
        }
        .sheet(item: $showSettingsFor) { tool in
            ToolSettingsView(tool: tool)
        }
    }
}

// MARK: - Active Tool Card

struct ActiveToolCard: View {
    let tool: SavingsTool
    let onSettingsTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: tool.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Active")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.green)
                        
                        if tool.lastUsed != nil {
                            Text("•")
                                .foregroundColor(.softGraphite.opacity(0.5))
                            
                            Text("Used recently")
                                .font(.system(size: 13))
                                .foregroundColor(.softGraphite)
                        }
                    }
                }
                
                Spacer()
                
                // Settings button
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.softGraphite)
                }
            }
            
            // Stats
            HStack(spacing: 16) {
                StatItem(
                    icon: "star.fill",
                    value: "\(tool.pointsEarned)",
                    label: "Points",
                    color: .orange
                )
                
                Divider()
                    .frame(height: 30)
                
                StatItem(
                    icon: "dollarsign.circle.fill",
                    value: tool.totalSaved > 0 ? "$\(Int(tool.totalSaved))" : "—",
                    label: "Saved",
                    color: .green
                )
                
                Divider()
                    .frame(height: 30)
                
                StatItem(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(tool.usageCount)",
                    label: "Uses",
                    color: .blue
                )
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.green.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(value)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.softGraphite)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Available Tool Card

struct AvailableToolCard: View {
    let tool: SavingsTool
    let onActivate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: tool.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    Text(tool.monthlySavings)
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                }
                
                Spacer()
                
                // Bonus badge
                if tool.activationBonus > 0 {
                    VStack(spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("+\(tool.activationBonus)")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.orange)
                        
                        Text("bonus")
                            .font(.system(size: 9))
                            .foregroundColor(.orange.opacity(0.8))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            
            // Description
            if !tool.description.isEmpty {
                Text(tool.description)
                    .font(.system(size: 13))
                    .foregroundColor(.softGraphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Activate button
            Button(action: onActivate) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Activate Now")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.orange.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    SavingsToolsManagementView()
        .environmentObject(SubscriptionService.shared)
}
