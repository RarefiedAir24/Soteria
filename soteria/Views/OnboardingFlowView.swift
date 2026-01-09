//
//  OnboardingFlowView.swift
//  soteria
//
//  Streamlined onboarding - get users to value in 60 seconds
//

import SwiftUI

struct OnboardingFlowView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var goalsService = GoalsService.shared
    @ObservedObject var surveyService = OnboardingSurveyService.shared
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var goalName = ""
    @State private var goalAmountText = ""
    @State private var showContent = false
    @State private var buttonScale: CGFloat = 1.0
    
    enum OnboardingStep {
        case welcome
        case createGoal
        case success
    }
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.90, green: 0.93, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content based on current step
            Group {
                switch currentStep {
                case .welcome:
                    welcomeView
                case .createGoal:
                    createGoalView
                case .success:
                    successView
                }
            }
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showContent)
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Animated tree icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "tree.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.green)
                }
                .scaleEffect(showContent ? 1.0 : 0.8)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: showContent)
                
                VStack(spacing: 16) {
                    Text("Welcome to Soteria!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Watch your money tree grow\nas you save for your dreams")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Navigation buttons
            VStack(spacing: 16) {
                Button(action: {
                    transitionToStep(.createGoal)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.arrow.circlepath")
                            .font(.title3)
                        Text("Set Your First Goal")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 4)
                }
                .scaleEffect(buttonScale)
                
                Button(action: skipOnboarding) {
                    Text("I'll explore first")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Create Goal View
    private var createGoalView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)
                
                // Money tree preview
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green.opacity(0.7))
                }
                
                VStack(spacing: 16) {
                    Text("What are you saving for?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Set your first goal and watch\nyour money tree come to life!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                // Goal input fields
                VStack(spacing: 20) {
                    // Goal name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Name")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        TextField("e.g., New Car, Vacation, Emergency Fund", text: $goalName)
                            .font(.system(size: 17))
                            .padding(16)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(goalName.isEmpty ? Color.gray.opacity(0.2) : Color.green, lineWidth: goalName.isEmpty ? 1 : 2)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    
                    // Goal amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Amount")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        HStack(spacing: 12) {
                            Text("$")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.green)
                            
                            TextField("25,000", text: $goalAmountText)
                                .font(.system(size: 28, weight: .semibold))
                                .keyboardType(.decimalPad)
                                .onChange(of: goalAmountText) { oldValue, newValue in
                                    // Filter to only allow numbers and decimal
                                    let filtered = newValue.filter { "0123456789.,".contains($0) }
                                    if filtered != newValue {
                                        goalAmountText = filtered
                                    }
                                }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(goalAmountText.isEmpty ? Color.gray.opacity(0.2) : Color.green, lineWidth: goalAmountText.isEmpty ? 1 : 2)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    
                    // Quick amount suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or choose a common goal:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                QuickAmountButton(emoji: "🚗", name: "New Car", amount: "25000", goalName: $goalName, goalAmount: $goalAmountText)
                                QuickAmountButton(emoji: "🏡", name: "House Down Payment", amount: "50000", goalName: $goalName, goalAmount: $goalAmountText)
                                QuickAmountButton(emoji: "✈️", name: "Dream Vacation", amount: "5000", goalName: $goalName, goalAmount: $goalAmountText)
                                QuickAmountButton(emoji: "🎓", name: "Education Fund", amount: "20000", goalName: $goalName, goalAmount: $goalAmountText)
                                QuickAmountButton(emoji: "💍", name: "Wedding", amount: "30000", goalName: $goalName, goalAmount: $goalAmountText)
                                QuickAmountButton(emoji: "🆘", name: "Emergency Fund", amount: "10000", goalName: $goalName, goalAmount: $goalAmountText)
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 20)
            }
        }
        .overlay(alignment: .bottom) {
            // Navigation buttons
            VStack(spacing: 12) {
                Button(action: {
                    if canCreateGoal {
                        createGoalAndContinue()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Create My Tree")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        canCreateGoal 
                            ? LinearGradient(colors: [Color.green, Color.green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                    .shadow(color: canCreateGoal ? Color.green.opacity(0.4) : Color.clear, radius: 12, x: 0, y: 4)
                }
                .scaleEffect(buttonScale)
                .disabled(!canCreateGoal)
                
                HStack {
                    Button(action: {
                        transitionToStep(.welcome)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: skipOnboarding) {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.95, green: 0.97, blue: 1.0).opacity(0.95)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea()
            )
        }
    }
    
    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Success animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(showContent ? 1.2 : 0.8)
                        .opacity(showContent ? 0.5 : 0)
                        .animation(.easeOut(duration: 1.0).delay(0.2), value: showContent)
                    
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: showContent)
                    
                    Text("🎉")
                        .font(.system(size: 80))
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.5).delay(0.3), value: showContent)
                }
                
                VStack(spacing: 16) {
                    Text("You're all set!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Your money tree is ready to grow!\n\nEvery time you save, watch it\nget greener and fuller.")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 32)
                
                // Goal info card
                if let goal = goalsService.activeGoals.first {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "target")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.name)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Goal: $\(goal.targetAmount, specifier: "%.0f")")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            // Start button
            Button(action: finishOnboarding) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                    Text("Start Saving")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 4)
            }
            .scaleEffect(buttonScale)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Views
    struct QuickAmountButton: View {
        let emoji: String
        let name: String
        let amount: String
        @Binding var goalName: String
        @Binding var goalAmount: String
        
        var body: some View {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    goalName = name
                    goalAmount = amount
                }
                
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }) {
                VStack(spacing: 8) {
                    Text(emoji)
                        .font(.system(size: 32))
                    
                    Text(name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("$\(amount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .frame(width: 100, height: 110)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Helper Properties
    private var canCreateGoal: Bool {
        !goalName.isEmpty && !goalAmountText.isEmpty && goalAmount != nil
    }
    
    private var goalAmount: Double? {
        let cleaned = goalAmountText.replacingOccurrences(of: ",", with: "")
        return Double(cleaned)
    }
    
    // MARK: - Actions
    private func transitionToStep(_ step: OnboardingStep) {
        withAnimation(.spring(response: 0.3)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentStep = step
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        
        // Animate button
        buttonScale = 0.95
        withAnimation(.spring(response: 0.2)) {
            buttonScale = 1.0
        }
    }
    
    private func createGoalAndContinue() {
        guard let amount = goalAmount else { return }
        
        // Create goal
        goalsService.createGoal(
            name: goalName,
            targetAmount: amount,
            startDate: Date(), // Start today
            targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            category: .other,
            photoPath: nil,
            description: nil
        )
        
        // Success feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Transition to success
        transitionToStep(.success)
    }
    
    private func skipOnboarding() {
        markOnboardingComplete()
        dismiss()
    }
    
    private func finishOnboarding() {
        markOnboardingComplete()
        dismiss()
    }
    
    private func markOnboardingComplete() {
        surveyService.hasCompletedSurvey = true
        surveyService.saveSurveyData()
    }
}

#Preview {
    OnboardingFlowView()
}
