//
//  OnboardingSurveyView.swift
//  soteria
//
//  Onboarding survey to understand user and show value proposition
//

import SwiftUI

struct OnboardingSurveyView: View {
    @ObservedObject var surveyService = OnboardingSurveyService.shared
    // NOTE: SavingsReminderService removed - functionality consolidated into Decision Notifications
    @Environment(\.dismiss) var dismiss
    
    // Edit mode: if true, pre-populate fields and allow updating without resetting completion flag
    var isEditMode: Bool = false
    
    @State private var currentStep = 0
    @State private var selectedChallenges: Set<String> = [] // Changed to Set to support multiple selections
    @State private var showContent = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var dailySpendingText = ""
    @State private var weeklySpendingText = ""
    @State private var dailySavingsText = ""
    @State private var isEditingAmount = false
    
    let savingChallenges = [
        "I forget to save before spending",
        "I don't know how much I should save",
        "I lack motivation to save",
        "I spend impulsively",
        "I don't have a savings routine",
        "Other"
    ]
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.dreamMist, Color.dreamMist.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern progress indicator
                VStack(spacing: 8) {
                    HStack {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            Circle()
                                .fill(index <= currentStep ? Color.softGraphite : Color.mistGray)
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentStep ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3), value: currentStep)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.softGraphite)
                }
                .padding(.top, 20)
                
                // Question content with animation
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 40)
                        
                        // Animated logo
                        Image("soteria_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .scaleEffect(showContent ? 1.0 : 0.8)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: showContent)
                        
                        // Question title with animation
                        Text(questionTitle)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.midnightSlate)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: showContent)
                        
                        // Question content with animation
                        questionContent
                            .padding(.horizontal, 32)
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: showContent)
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
                
                // Modern navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                showContent = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.spring(response: 0.3)) {
                                    currentStep -= 1
                                    showContent = true
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline)
                            .foregroundColor(.midnightSlate)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                    }
                    
                    Button(action: {
                        buttonScale = 0.95
                        withAnimation(.spring(response: 0.2)) {
                            buttonScale = 1.0
                        }
                        
                        if currentStep < totalSteps - 1 {
                            withAnimation(.spring(response: 0.3)) {
                                showContent = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.spring(response: 0.3)) {
                                    currentStep += 1
                                    showContent = true
                                }
                            }
                        } else {
                            completeSurvey()
                        }
                    }) {
                        HStack {
                            if currentStep < totalSteps - 1 {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                            } else {
                                Text(isEditMode ? "Save Changes" : "Get Started")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            canProceed ? Color.softGraphite : Color.gray.opacity(0.3)
                        )
                        .cornerRadius(16)
                        .shadow(color: canProceed ? Color.softGraphite.opacity(0.4) : Color.clear, radius: 12, x: 0, y: 4)
                        .scaleEffect(buttonScale)
                    }
                    .disabled(!canProceed)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
            
            // Pre-populate fields if in edit mode
            if isEditMode {
                loadExistingSurveyData()
            }
        }
        .onChange(of: currentStep) { _, _ in
            showContent = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showContent = true
                }
            }
        }
    }
    
    private var totalSteps: Int {
        7 // Total number of questions
    }
    
    private var questionTitle: String {
        switch currentStep {
        case 0: return isEditMode ? "Update Your Profile" : "Welcome to Soteria!"
        case 1: return "Do you shop online?"
        case 2: return "How much do you spend daily?"
        case 3: return "How much do you spend weekly?"
        case 4: return "What's your biggest challenge to saving?"
        case 5: return "Would reminders help you save?"
        case 6: return "How much can you save daily?"
        default: return ""
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true // Welcome screen
        case 1: return true // Yes/No question
        case 2: return surveyService.estimatedDailySpending > 0
        case 3: return surveyService.estimatedWeeklySpending > 0
        case 4: return !selectedChallenges.isEmpty // At least one challenge must be selected
        case 5: return true // Yes/No question
        case 6: return surveyService.comfortableDailySavings > 0
        default: return false
        }
    }
    
    @ViewBuilder
    private var questionContent: some View {
        switch currentStep {
        case 0:
            welcomeContent
        case 1:
            yesNoQuestion(
                value: $surveyService.shopsOnline,
                yesText: "Yes, I shop online",
                noText: "No, I don't shop online"
            )
        case 2:
            amountInput(
                value: $surveyService.estimatedDailySpending,
                text: $dailySpendingText,
                placeholder: "Enter amount",
                description: "Estimate how much you typically spend in a day"
            )
        case 3:
            amountInput(
                value: $surveyService.estimatedWeeklySpending,
                text: $weeklySpendingText,
                placeholder: "Enter amount",
                description: "Estimate how much you typically spend in a week"
            )
        case 4:
            challengeSelection
        case 5:
            yesNoQuestion(
                value: $surveyService.reminderWouldHelp,
                yesText: "Yes, reminders would help",
                noText: "No, I don't need reminders"
            )
        case 6:
            amountInput(
                value: $surveyService.comfortableDailySavings,
                text: $dailySavingsText,
                placeholder: "Enter amount",
                description: "How much can you comfortably save each day?"
            )
        default:
            EmptyView()
        }
    }
    
    private var welcomeContent: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.softGraphite.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "tree.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.softGraphite)
            }
            .scaleEffect(showContent ? 1.0 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.4), value: showContent)
            
            VStack(spacing: 16) {
                Text("Your Personal Savings Assistant")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.midnightSlate)
                    .multilineTextAlignment(.center)
                
                Text(isEditMode 
                     ? "Update your preferences to keep your savings experience personalized."
                     : "We'll ask you a few quick questions to personalize your savings experience and help you grow your money tree.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.softGraphite)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
        }
    }
    
    private func yesNoQuestion(value: Binding<Bool>, yesText: String, noText: String) -> some View {
        VStack(spacing: 20) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    value.wrappedValue = true
                }
            }) {
                HStack {
                    Image(systemName: value.wrappedValue ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(value.wrappedValue ? .softGraphite : .softGraphite.opacity(0.5))
                    
                    Text(yesText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(value.wrappedValue ? Color.softGraphite.opacity(0.1) : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(value.wrappedValue ? Color.softGraphite : Color.mistGray, lineWidth: value.wrappedValue ? 3 : 1)
                )
                .shadow(color: value.wrappedValue ? Color.softGraphite.opacity(0.2) : Color.black.opacity(0.05), radius: value.wrappedValue ? 8 : 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    value.wrappedValue = false
                }
            }) {
                HStack {
                    Image(systemName: !value.wrappedValue ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(!value.wrappedValue ? .softGraphite : .softGraphite.opacity(0.5))
                    
                    Text(noText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(!value.wrappedValue ? Color.softGraphite.opacity(0.1) : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(!value.wrappedValue ? Color.softGraphite : Color.mistGray, lineWidth: !value.wrappedValue ? 3 : 1)
                )
                .shadow(color: !value.wrappedValue ? Color.softGraphite.opacity(0.2) : Color.black.opacity(0.05), radius: !value.wrappedValue ? 8 : 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func amountInput(value: Binding<Double>, text: Binding<String>, placeholder: String, description: String) -> some View {
        VStack(spacing: 24) {
            Text(description)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.softGraphite)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            HStack(spacing: 12) {
                Text("$")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.reverBlue)
                
                TextField(placeholder, text: text)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.midnightSlate)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .onChange(of: text.wrappedValue) { oldValue, newValue in
                        // Filter to allow only numbers and decimal point
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        
                        // Only allow one decimal point
                        let components = filtered.components(separatedBy: ".")
                        let filteredValue = components.count > 2 
                            ? components[0] + "." + components.dropFirst().joined()
                            : filtered
                        
                        // Update the text
                        if filteredValue != newValue {
                            text.wrappedValue = filteredValue
                        }
                        
                        // Convert to Double and update the binding
                        if let doubleValue = Double(filteredValue), doubleValue >= 0 {
                            value.wrappedValue = doubleValue
                        } else if filteredValue.isEmpty {
                            value.wrappedValue = 0
                        }
                    }
                    .onAppear {
                        // Initialize text field with current value if it exists
                        if value.wrappedValue > 0 {
                            let formatter = NumberFormatter()
                            formatter.numberStyle = .decimal
                            formatter.maximumFractionDigits = 2
                            formatter.minimumFractionDigits = 0
                            text.wrappedValue = formatter.string(from: NSNumber(value: value.wrappedValue)) ?? ""
                        } else {
                            text.wrappedValue = ""
                        }
                    }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(value.wrappedValue > 0 ? Color.softGraphite : Color.mistGray, lineWidth: value.wrappedValue > 0 ? 3 : 1)
            )
            .shadow(color: value.wrappedValue > 0 ? Color.softGraphite.opacity(0.2) : Color.black.opacity(0.05), radius: value.wrappedValue > 0 ? 12 : 4, x: 0, y: 4)
        }
    }
    
    private var challengeSelection: some View {
        VStack(spacing: 20) {
            Text("Select up to 3 challenges that resonate with you")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.softGraphite)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            if !selectedChallenges.isEmpty {
                Text("\(selectedChallenges.count) of 3 selected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.softGraphite)
            }
            
            ForEach(Array(savingChallenges.enumerated()), id: \.element) { index, challenge in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        if selectedChallenges.contains(challenge) {
                            // Deselect if already selected
                            selectedChallenges.remove(challenge)
                        } else {
                            // Select if not at max (3)
                            if selectedChallenges.count < 3 {
                                selectedChallenges.insert(challenge)
                            }
                        }
                        // Update service with array
                        surveyService.savingChallenges = Array(selectedChallenges)
                    }
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: selectedChallenges.contains(challenge) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(selectedChallenges.contains(challenge) ? .softGraphite : .softGraphite.opacity(0.5))
                        
                        Text(challenge)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.midnightSlate)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(selectedChallenges.contains(challenge) ? Color.softGraphite.opacity(0.1) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(selectedChallenges.contains(challenge) ? Color.softGraphite : Color.mistGray, lineWidth: selectedChallenges.contains(challenge) ? 3 : 1)
                    )
                    .shadow(color: selectedChallenges.contains(challenge) ? Color.softGraphite.opacity(0.2) : Color.black.opacity(0.05), radius: selectedChallenges.contains(challenge) ? 8 : 4, x: 0, y: 2)
                    .opacity(!selectedChallenges.contains(challenge) && selectedChallenges.count >= 3 ? 0.5 : 1.0) // Dim if max selected and this one isn't
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!selectedChallenges.contains(challenge) && selectedChallenges.count >= 3) // Disable if max selected
            }
        }
        .onAppear {
            // Load existing selections when view appears
            selectedChallenges = Set(surveyService.savingChallenges)
        }
    }
    
    private func completeSurvey() {
        if isEditMode {
            // Update existing survey data without resetting completion flag
            surveyService.updateSurveyData(
                shopsOnline: surveyService.shopsOnline,
                estimatedDailySpending: surveyService.estimatedDailySpending,
                estimatedWeeklySpending: surveyService.estimatedWeeklySpending,
                savingChallenges: Array(selectedChallenges),
                reminderWouldHelp: surveyService.reminderWouldHelp,
                comfortableDailySavings: surveyService.comfortableDailySavings
            )
            // Dismiss if presented as a sheet
            dismiss()
        } else {
            // First-time completion
            surveyService.completeSurvey()
            // The parent view will detect hasCompletedSurvey change and show MainTabView
        }
    }
    
    private func loadExistingSurveyData() {
        // Pre-populate all fields from existing survey data
        selectedChallenges = Set(surveyService.savingChallenges)
        
        // Pre-populate amount text fields
        if surveyService.estimatedDailySpending > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            dailySpendingText = formatter.string(from: NSNumber(value: surveyService.estimatedDailySpending)) ?? ""
        }
        
        if surveyService.estimatedWeeklySpending > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            weeklySpendingText = formatter.string(from: NSNumber(value: surveyService.estimatedWeeklySpending)) ?? ""
        }
        
        if surveyService.comfortableDailySavings > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            dailySavingsText = formatter.string(from: NSNumber(value: surveyService.comfortableDailySavings)) ?? ""
        }
    }
}

#Preview {
    OnboardingSurveyView()
}

