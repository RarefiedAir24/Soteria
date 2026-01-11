//
//  ToolActivationView.swift
//  soteria
//
//  Step-by-step activation flow for individual savings tools
//

import SwiftUI

struct ToolActivationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var toolsService = SavingsToolsService.shared
    let tool: SavingsTool
    
    @State private var currentStep = 1
    @State private var confirmationChecked = false
    @State private var isActivating = false
    
    private let totalSteps = 3
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: tool.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                        }
                        
                        Text("Activate \(tool.name)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        Text(tool.description)
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    // Progress indicator
                    ProgressIndicator(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.horizontal, 40)
                    
                    // Steps
                    VStack(spacing: 16) {
                        ActivationStep(
                            stepNumber: 1,
                            title: "Download App",
                            description: "Get \(tool.name) from the App Store",
                            isCompleted: currentStep > 1,
                            isCurrent: currentStep == 1,
                            action: {
                                if let url = URL(string: tool.appStoreURL) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )
                        
                        ActivationStep(
                            stepNumber: 2,
                            title: "Sign Up",
                            description: tool.setupInstructions,
                            isCompleted: currentStep > 2,
                            isCurrent: currentStep == 2,
                            action: nil
                        )
                        
                        ActivationStep(
                            stepNumber: 3,
                            title: "Start Saving",
                            description: "Use \(tool.name) and watch your savings grow!",
                            isCompleted: false,
                            isCurrent: currentStep == 3,
                            action: nil
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Bonus highlight
                    if tool.activationBonus > 0 {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 24))
                                Text("Activation Bonus")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.orange)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16))
                                Text("+\(tool.activationBonus) loyalty points")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.orange)
                            
                            Text("Awarded on first verified use")
                                .font(.system(size: 13))
                                .foregroundColor(.softGraphite)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Confirmation
                    if currentStep == totalSteps {
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                confirmationChecked.toggle()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: confirmationChecked ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 24))
                                        .foregroundColor(confirmationChecked ? .reverBlue : .softGraphite)
                                    
                                    Text("I've completed the setup")
                                        .font(.system(size: 15))
                                        .foregroundColor(.midnightSlate)
                                    
                                    Spacer()
                                }
                            }
                            
                            Button(action: activateTool) {
                                HStack {
                                    if isActivating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Confirm Activation")
                                    }
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: confirmationChecked ? [Color.green, Color.green.opacity(0.8)] : [Color.softGraphite.opacity(0.5), Color.softGraphite.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .disabled(!confirmationChecked || isActivating)
                        }
                        .padding(.horizontal, 20)
                    } else {
                        // Next step button
                        Button(action: {
                            withAnimation {
                                currentStep += 1
                            }
                        }) {
                            HStack {
                                Text("Next Step")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 16, weight: .semibold))
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
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.mistGray.ignoresSafeArea())
            .navigationTitle("Activate Tool")
            .navigationBarTitleDisplayMode(.inline)
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
    }
    
    private func activateTool() {
        isActivating = true
        
        // Simulate activation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            toolsService.activateTool(tool.id)
            isActivating = false
            dismiss()
        }
    }
}

// MARK: - Progress Indicator

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 4)
                    .fill(step <= currentStep ? Color.orange : Color.softGraphite.opacity(0.2))
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Activation Step

struct ActivationStep: View {
    let stepNumber: Int
    let title: String
    let description: String
    let isCompleted: Bool
    let isCurrent: Bool
    let action: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number/checkmark
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(stepNumber)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isCurrent ? .white : .softGraphite)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.midnightSlate)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.softGraphite)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let action = action, isCurrent {
                    Button(action: action) {
                        HStack {
                            Image(systemName: "arrow.down.app.fill")
                            Text("Open App Store")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.reverBlue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.reverBlue.opacity(0.1))
                        )
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .opacity(isCompleted ? 0.6 : 1.0)
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .orange
        } else {
            return Color.softGraphite.opacity(0.2)
        }
    }
}

// MARK: - Preview

#Preview {
    ToolActivationView(tool: SavingsTool.mockUpside)
}
