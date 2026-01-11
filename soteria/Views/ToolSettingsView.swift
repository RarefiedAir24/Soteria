//
//  ToolSettingsView.swift
//  soteria
//
//  Settings and management for individual savings tools
//

import SwiftUI

struct ToolSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var toolsService = SavingsToolsService.shared
    let tool: SavingsTool
    
    @State private var notificationsEnabled: Bool
    @State private var trackingEnabled: Bool
    @State private var showDeactivateConfirmation = false
    
    init(tool: SavingsTool) {
        self.tool = tool
        _notificationsEnabled = State(initialValue: tool.notificationsEnabled)
        _trackingEnabled = State(initialValue: tool.trackingEnabled)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Tool Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: tool.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                        }
                        
                        Text(tool.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Active since \(formattedActivationDate)")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.green)
                    }
                    .padding(.top, 20)
                    
                    // Stats Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("YOUR STATS")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.softGraphite)
                            .tracking(0.5)
                        
                        StatsGrid(tool: tool)
                    }
                    .padding(.horizontal, 20)
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SETTINGS")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.softGraphite)
                            .tracking(0.5)
                        
                        VStack(spacing: 0) {
                            SettingRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                subtitle: "Reminders and updates",
                                isOn: $notificationsEnabled
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            SettingRow(
                                icon: "chart.bar.fill",
                                title: "Track Loyalty Points",
                                subtitle: "Count saves for rewards",
                                isOn: $trackingEnabled
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Deactivate Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("MANAGE")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.softGraphite)
                            .tracking(0.5)
                        
                        Button(action: {
                            showDeactivateConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Deactivate Tool")
                                        .font(.system(size: 15, weight: .semibold))
                                    
                                    Text("Stop tracking this tool")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.red)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.red.opacity(0.1), radius: 8, x: 0, y: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color.mistGray.ignoresSafeArea())
            .navigationTitle("Tool Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.reverBlue)
                }
            }
        }
        .alert("Deactivate \(tool.name)?", isPresented: $showDeactivateConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Deactivate", role: .destructive) {
                toolsService.deactivateTool(tool.id)
                dismiss()
            }
        } message: {
            Text("You can always reactivate this tool later. Your stats will be preserved.")
        }
    }
    
    private var formattedActivationDate: String {
        guard let activatedDate = tool.activatedDate else { return "recently" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: activatedDate)
    }
    
    private func saveSettings() {
        toolsService.updateToolSettings(
            toolId: tool.id,
            notificationsEnabled: notificationsEnabled,
            trackingEnabled: trackingEnabled
        )
    }
}

// MARK: - Stats Grid

struct StatsGrid: View {
    let tool: SavingsTool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ToolStatBox(
                    icon: "star.fill",
                    value: "\(tool.pointsEarned)",
                    label: "Points Earned",
                    color: .orange
                )
                
                ToolStatBox(
                    icon: "dollarsign.circle.fill",
                    value: tool.totalSaved > 0 ? "$\(Int(tool.totalSaved))" : "$0",
                    label: "Total Saved",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                ToolStatBox(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(tool.usageCount)",
                    label: "Times Used",
                    color: .blue
                )
                
                ToolStatBox(
                    icon: "calendar.badge.clock",
                    value: lastUsedText,
                    label: "Last Used",
                    color: .purple
                )
            }
        }
    }
    
    private var lastUsedText: String {
        guard let lastUsed = tool.lastUsed else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUsed, relativeTo: Date())
    }
}

struct ToolStatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.midnightSlate)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.softGraphite)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Setting Row

struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.reverBlue.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.reverBlue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(16)
    }
}

// MARK: - Preview

#Preview {
    ToolSettingsView(tool: SavingsTool.mockUpside)
}
