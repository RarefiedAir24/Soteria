//
//  SavingsToolsHomeCard.swift
//  soteria
//
//  Compact badge on home screen that opens full savings tools management
//

import SwiftUI

struct SavingsToolsHomeCard: View {
    @ObservedObject private var toolsService = SavingsToolsService.shared
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showManagementView = false
    @State private var isDismissed = false
    
    var body: some View {
        // Only show if:
        // 1. Feature is enabled
        // 2. User is premium
        // 3. Not dismissed
        // 4. Has any tools (active or available)
        if toolsService.isFeatureEnabled &&
           subscriptionService.isPremium && 
           !isDismissed &&
           (toolsService.hasAnyTools || !toolsService.unactivatedTools.isEmpty) {
            
            Button(action: {
                showManagementView = true
            }) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.2), Color.blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                    }
                    
                    // Status text
                    VStack(alignment: .leading, spacing: 2) {
                        let activeCount = toolsService.activatedTools.count
                        let totalPoints = toolsService.totalPointsEarned
                        
                        if activeCount > 0 {
                            HStack(spacing: 6) {
                                Text("\(activeCount) Tool\(activeCount == 1 ? "" : "s") Active")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.midnightSlate)
                                
                                if totalPoints > 0 {
                                    Text("•")
                                        .foregroundColor(.softGraphite.opacity(0.5))
                                    
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                        Text("+\(totalPoints) pts")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(.green)
                                }
                            }
                        } else {
                            Text("Activate Savings Tools")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                        }
                        
                        // Subtitle
                        if !toolsService.unactivatedTools.isEmpty {
                            Text("\(toolsService.unactivatedTools.count) available to activate")
                                .font(.system(size: 12))
                                .foregroundColor(.softGraphite)
                        } else if activeCount > 0 {
                            Text("Manage your tools")
                                .font(.system(size: 12))
                                .foregroundColor(.softGraphite)
                        }
                    }
                    
                    Spacer()
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.softGraphite)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.green.opacity(0.1), radius: 8, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
            .sheet(isPresented: $showManagementView) {
                SavingsToolsManagementView()
                    .environmentObject(subscriptionService)
            }
            .onChange(of: showManagementView) { _, isShowing in
                if !isShowing {
                    // Refresh tools status when sheet closes
                    toolsService.checkToolsStatus()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SavingsToolsHomeCard()
        .environmentObject(SubscriptionService.shared)
}
