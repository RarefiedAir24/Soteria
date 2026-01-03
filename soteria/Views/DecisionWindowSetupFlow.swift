//
//  DecisionWindowSetupFlow.swift
//  soteria
//
//  Guided setup flow for Decision Windows (≤ 60 seconds)
//
//  NOTE: User-facing name is "Decision Notifications" but internal code uses "Decision Windows"
//  The term "Window" refers to a time window (5 minutes around a set time) when notifications are sent
//

import SwiftUI

struct DecisionWindowSetupFlow: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var decisionWindowsService = DecisionWindowsService.shared
    @ObservedObject private var plaidService = PlaidService.shared
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    @State private var currentStep: Int = 1
    @State private var limitError: String? = nil
    // Single window creation - simplified flow
    @State private var windowTime: Date = Date()
    @State private var windowActions: Set<WindowAction> = []
    @State private var windowSaveAmount: Double = 3.0
    @State private var windowProtectAmount: Double = 10.0
    @State private var windowPauseIntention: String? = nil // Custom pause intention (premium)
    @State private var windowCondition: WindowCondition? = nil
    @State private var skipSetup = false
    
    enum WindowAction: String, Identifiable {
        case saveFirst
        case protectAmount
        case justRemind
        case manualEntry
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .saveFirst: return "Save First"
            case .protectAmount: return "Protect an Amount"
            case .justRemind: return "Just Remind Me"
            case .manualEntry: return "Record Manual Transfer"
            }
        }
        
        var icon: String {
            switch self {
            case .saveFirst: return "lock.fill"
            case .protectAmount: return "shield.fill"
            case .justRemind: return "brain.head.profile"
            case .manualEntry: return "dollarsign.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .saveFirst: return "Open transfer screen to save a small amount when this window opens."
            case .protectAmount: return "Open transfer screen to protect money when triggered."
            case .justRemind: return "No saving. Just a moment to pause and remember why I'm saving."
            case .manualEntry: return "Remind me to record a manual transfer (cash, external account, etc.)."
            }
        }
    }
    
    // Check if user has Plaid connected
    private var hasPlaidConnection: Bool {
        !plaidService.connectedAccounts.isEmpty
    }
    
    // Get available actions based on Plaid connection status
    private var availableActions: [WindowAction] {
        if hasPlaidConnection {
            // Plaid users get Save First and Just Remind Me
            // NOTE: "Protect an Amount" (spend gate) is commented out - not fully implemented yet
            return [.saveFirst, .justRemind]
            // return [.saveFirst, .protectAmount, .justRemind] // TODO: Re-enable when spend gate detection is implemented
        } else {
            // Non-Plaid users only get reminder and manual entry
            return [.justRemind, .manualEntry]
        }
    }
    
    struct WindowCondition: Identifiable {
        let id = UUID()
        var type: ConditionType
        var amount: Double
        var time: Int? // For "after X PM" condition
        
        enum ConditionType: String {
            case ifSpendToday = "if_spend_today"
            case ifSpendAfterTime = "if_spend_after_time"
            case ifOverspendDailyGoal = "if_overspend_daily_goal"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cloudWhite
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    if currentStep <= 5 {
                        ProgressView(value: Double(currentStep), total: 5.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .reverBlue))
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    }
                    
                    // Content
                    Group {
                        switch currentStep {
                        case 1:
                            conceptScreen
                        case 2:
                            timeSelectionScreen
                        case 3:
                            whatHappensScreen
                        case 4:
                            optionalConditionsScreen
                        case 5:
                            reviewScreen
                        case 6:
                            confirmationScreen
                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Limit Reached", isPresented: Binding(
                get: { limitError != nil },
                set: { if !$0 { limitError = nil } }
            )) {
                Button("OK") {
                    limitError = nil
                }
                if !subscriptionService.isPremium {
                    Button("Upgrade to Plus") {
                        limitError = nil
                        // Dismiss and show paywall - handled by parent
                    }
                }
            } message: {
                if let error = limitError {
                    Text(error)
                }
            }
            .toolbar {
                if currentStep < 6 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if currentStep > 1 {
                            Button("Back") {
                                currentStep -= 1
                            }
                            .foregroundColor(.reverBlue)
                        } else {
                            Button("Skip") {
                                skipSetup = true
                                dismiss()
                            }
                            .foregroundColor(.softGraphite)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Screen 1: Concept
    private var conceptScreen: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("Choose Before the Day Gets Away From You")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.midnightSlate)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Most impulse decisions happen when we're tired, bored, or rushed.")
                        .font(.system(size: 17))
                        .foregroundColor(.softGraphite)
                    
                    Text("Decision Windows give you a moment before that happens.")
                        .font(.system(size: 17))
                        .foregroundColor(.softGraphite)
                    
                    Text("You choose the time.\nSoteria helps once.\nThen it stays quiet.")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.midnightSlate)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: {
                    currentStep = 2 // Go directly to time selection
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.reverBlue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    skipSetup = true
                    dismiss()
                }) {
                    Text("Skip for now")
                        .font(.system(size: 16))
                        .foregroundColor(.softGraphite)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Screen 2: Time Selection (removed "How Many Windows" step)
    
    private var timeSelectionScreen: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("Pick a time")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.midnightSlate)
                
                Text("When should Soteria help you pause and save?")
                    .font(.system(size: 16))
                    .foregroundColor(.softGraphite)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                DatePicker("", selection: $windowTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                // Helper suggestions - specific times, not ranges
                VStack(spacing: 12) {
                    Text("Quick suggestions")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.softGraphite)
                    
                    HStack(spacing: 12) {
                        SuggestionButton(title: "Morning planning", time: "8:00 AM") {
                            let calendar = Calendar.current
                            if let date = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) {
                                windowTime = date
                            }
                        }
                        SuggestionButton(title: "Afternoon pause", time: "3:00 PM") {
                            let calendar = Calendar.current
                            if let date = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) {
                                windowTime = date
                            }
                        }
                        SuggestionButton(title: "Evening reflection", time: "9:00 PM") {
                            let calendar = Calendar.current
                            if let date = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) {
                                windowTime = date
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                currentStep = 3 // Go to "What Happens" screen
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.reverBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Screen 4: What Happens
    @State private var selectedActions: Set<WindowAction> = []
    @State private var currentSaveAmount: Double = 3.0
    @State private var currentProtectAmount: Double = 10.0
    @State private var currentPauseIntention: String = "" // Custom pause intention text (premium)
    @State private var showPaywallForCustomIntention = false
    
    private var whatHappensScreen: some View {
        VStack(spacing: 32) {
            ScrollView {
                VStack(spacing: 24) {
                    Text("What should Soteria help you do?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.midnightSlate)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        // Show only available actions based on Plaid connection
                        ForEach(availableActions) { action in
                            ActionCard(
                                icon: action.icon,
                                title: action.title,
                                description: action.description,
                                isSelected: selectedActions.contains(action),
                                onTap: {
                                    if selectedActions.contains(action) {
                                        selectedActions.remove(action)
                                    } else {
                                        selectedActions.insert(action)
                                    }
                                    print("✅ [DecisionWindowSetupFlow] \(action.title) tapped, selectedActions: \(selectedActions)")
                                }
                            ) {
                                if action == .saveFirst && selectedActions.contains(.saveFirst) {
                                    AmountPicker(amount: $currentSaveAmount)
                                } else if action == .protectAmount && selectedActions.contains(.protectAmount) {
                                    AmountPicker(amount: $currentProtectAmount)
                                } else if action == .justRemind && selectedActions.contains(.justRemind) {
                                    // Custom pause intention (premium feature)
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Custom Reminder")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.softGraphite)
                                            
                                            Spacer()
                                            
                                            if !subscriptionService.isPremium {
                                                Text("Premium")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.reverBlue)
                                                    .cornerRadius(6)
                                            }
                                        }
                                        
                                        if subscriptionService.isPremium {
                                            TextField("e.g., Remember why I'm saving for my trip to Hawaii", text: $currentPauseIntention, axis: .vertical)
                                                .font(.system(size: 14))
                                                .foregroundColor(.midnightSlate)
                                                .lineLimit(2...4)
                                                .padding(12)
                                                .background(Color.dreamMist)
                                                .cornerRadius(10)
                                            
                                            Text("Leave empty to use default: 'Remember why I'm saving'")
                                                .font(.system(size: 12))
                                                .foregroundColor(.softGraphite)
                                        } else {
                                            Button(action: {
                                                showPaywallForCustomIntention = true
                                            }) {
                                                HStack {
                                                    Image(systemName: "lock.fill")
                                                        .font(.system(size: 14))
                                                    Text("Unlock Custom Reminders")
                                                        .font(.system(size: 14, weight: .medium))
                                                }
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(Color.reverBlue)
                                                .cornerRadius(10)
                                            }
                                            
                                            Text("Premium feature: Create personalized reminder messages")
                                                .font(.system(size: 12))
                                                .foregroundColor(.softGraphite)
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                                // No additional content for .manualEntry
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Button(action: {
                print("✅ [DecisionWindowSetupFlow] Continue button tapped, selectedActions: \(selectedActions)")
                // Store actions and amounts for the window
                windowActions = selectedActions
                windowSaveAmount = currentSaveAmount
                windowProtectAmount = currentProtectAmount
                
                // Store custom pause intention if provided (premium only)
                if selectedActions.contains(.justRemind) {
                    if subscriptionService.isPremium && !currentPauseIntention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        windowPauseIntention = currentPauseIntention.trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        windowPauseIntention = nil // Use default
                    }
                } else {
                    windowPauseIntention = nil
                }
                
                currentStep = 4 // Go to optional conditions screen
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(!selectedActions.isEmpty ? Color.reverBlue : Color.gray.opacity(0.5))
                    .cornerRadius(12)
            }
            .disabled(selectedActions.isEmpty)
            .sheet(isPresented: $showPaywallForCustomIntention) {
                PaywallView()
                    .environmentObject(subscriptionService)
            }
            .onChange(of: selectedActions) { oldValue, newValue in
                print("✅ [DecisionWindowSetupFlow] selectedActions changed from \(oldValue) to \(newValue)")
            }
            .onAppear {
                // Restore state when screen appears
                if !windowActions.isEmpty {
                    selectedActions = windowActions
                    if windowActions.contains(.saveFirst) {
                        currentSaveAmount = windowSaveAmount
                    }
                    if windowActions.contains(.protectAmount) {
                        currentProtectAmount = windowProtectAmount
                    }
                    if windowActions.contains(.justRemind) {
                        currentPauseIntention = windowPauseIntention ?? ""
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Screen 5: Optional Conditions
    @State private var wantsConditions = false
    @State private var conditionType: WindowCondition.ConditionType = .ifSpendToday
    @State private var conditionAmount: Double = 5.0
    @State private var conditionTime: Int = 21 // 9 PM
    
    private var optionalConditionsScreen: some View {
        VStack(spacing: 32) {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Want Soteria to react later today?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.midnightSlate)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 40)
                    
                    VStack(spacing: 20) {
                        Toggle(isOn: $wantsConditions) {
                            Text("Yes, add a condition")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.midnightSlate)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .reverBlue))
                        
                        if wantsConditions {
                            VStack(alignment: .leading, spacing: 16) {
                                Picker("Condition", selection: $conditionType) {
                                    Text("If I make an impulse decision today").tag(WindowCondition.ConditionType.ifSpendToday)
                                    Text("If I make an impulse decision after 9 PM").tag(WindowCondition.ConditionType.ifSpendAfterTime)
                                    Text("If I exceed my daily limit").tag(WindowCondition.ConditionType.ifOverspendDailyGoal)
                                }
                                .pickerStyle(.menu)
                                
                                if conditionType == .ifSpendAfterTime {
                                    Picker("Time", selection: $conditionTime) {
                                        ForEach(18...23, id: \.self) { hour in
                                            Text("\(hour):00").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                HStack {
                                    Text("Deposit $")
                                    TextField("0.00", value: $conditionAmount, format: .number)
                                        .keyboardType(.decimalPad)
                                }
                                .padding(12)
                                .background(Color.dreamMist)
                                .cornerRadius(10)
                                
                                Text("This deposit helps you save when you make an impulse decision. Works for spending, eating, or any behavior you want to change.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.softGraphite)
                                    .italic()
                            }
                            .padding(20)
                            .background(Color.dreamMist.opacity(0.5))
                            .cornerRadius(12)
                        }
                        
                        Toggle(isOn: Binding(
                            get: { !wantsConditions },
                            set: { wantsConditions = !$0 }
                        )) {
                            Text("No, keep it simple")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.midnightSlate)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .reverBlue))
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Button(action: {
                if wantsConditions {
                    windowCondition = WindowCondition(
                        type: conditionType,
                        amount: conditionAmount,
                        time: conditionType == .ifSpendAfterTime ? conditionTime : nil
                    )
                } else {
                    windowCondition = nil
                }
                currentStep = 5 // Go to review screen
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.reverBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Screen 6: Review
    private var reviewScreen: some View {
        VStack(spacing: 32) {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Here's what will happen")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.midnightSlate)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        WindowReviewCard(
                            index: 0,
                            time: windowTime,
                            actions: Array(windowActions),
                            saveAmount: windowSaveAmount,
                            protectAmount: windowProtectAmount,
                            pauseIntention: windowPauseIntention
                        )
                        
                        Text("• Only outside Quiet Hours")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 40)
                    
                    VStack(spacing: 12) {
                        Text("You're always in control.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.midnightSlate)
                        
                        Text("You can change or pause this anytime.")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
            }
            
            Button(action: {
                createDecisionWindow()
                currentStep = 6 // Go to confirmation screen
            }) {
                Text("Turn On Decision Window")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.reverBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Screen 7: Confirmation
    private var confirmationScreen: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("You've Protected Today")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.midnightSlate)
                    .multilineTextAlignment(.center)
                
                Text("You just gave Future You a head start.")
                    .font(.system(size: 18))
                    .foregroundColor(.softGraphite)
                    .multilineTextAlignment(.center)
                
                Text("No rules. No guilt. Just intention.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.midnightSlate)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.reverBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createDecisionWindow() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: windowTime)
        let minute = calendar.component(.minute, from: windowTime)
        let timeComponents = DateComponents(hour: hour, minute: minute)
        // Default to all weekdays (Monday-Friday) for consistency
        let daysOfWeek: Set<Int> = [2, 3, 4, 5, 6] // Monday-Friday
        
        // Determine default values based on selected actions
        var defaultMicroSave: Double? = nil
        let defaultSpendGate: SpendGate? = nil // Not currently used (commented out below)
        var defaultPauseIntention: String? = nil
        
        if windowActions.contains(.saveFirst) {
            defaultMicroSave = windowSaveAmount
        }
        
        // NOTE: Protect Amount (spend gate) is commented out - not fully implemented yet
        // if windowActions.contains(.protectAmount) {
        //     defaultSpendGate = SpendGate(
        //         condition: "protect_amount",
        //         saveAmount: windowProtectAmount,
        //         description: "Protect $\(String(format: "%.2f", windowProtectAmount)) for impulse decisions"
        //     )
        // }
        
        if windowActions.contains(.justRemind) {
            // Use custom pause intention if provided (premium), otherwise use default
            if let customIntention = windowPauseIntention, !customIntention.isEmpty {
                defaultPauseIntention = customIntention
            } else {
                defaultPauseIntention = "Remember why I'm saving"
            }
        }
        
        if windowActions.contains(.manualEntry) {
            // For manual entry, set a reminder to record the transfer
            defaultPauseIntention = "Time to record your manual transfer (cash, external account, etc.)"
        }
        
        // NOTE: Conditions (spend gates) are commented out - not fully implemented yet
        // Add condition if set (overrides protect amount if both exist)
        // if let condition = windowCondition {
        //     defaultSpendGate = SpendGate(
        //         condition: condition.type.rawValue,
        //         saveAmount: condition.amount,
        //         description: getConditionDescription(condition)
        //     )
        // }
        
        let window = DecisionWindow(
            name: "My Decision Notification",
            time: timeComponents,
            daysOfWeek: daysOfWeek,
            isEnabled: true,
            promptMessage: "Before today continues — do you want to protect anything?",
            defaultMicroSaveAmount: defaultMicroSave,
            defaultSpendGate: defaultSpendGate,
            defaultPauseIntention: defaultPauseIntention
        )
        
        do {
            try decisionWindowsService.addWindow(window, isPremium: subscriptionService.isPremium)
        } catch {
            limitError = error.localizedDescription
        }
    }
    
    private func getConditionDescription(_ condition: WindowCondition) -> String {
        switch condition.type {
        case .ifSpendToday:
            return "If I make an impulse decision today, deposit $\(String(format: "%.2f", condition.amount))"
        case .ifSpendAfterTime:
            return "If I make an impulse decision after \(condition.time ?? 21):00, deposit $\(String(format: "%.2f", condition.amount))"
        case .ifOverspendDailyGoal:
            return "If I exceed my daily limit, deposit $\(String(format: "%.2f", condition.amount))"
        }
    }
}

// MARK: - Supporting Views

struct RadioOption: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .reverBlue : .softGraphite)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.midnightSlate)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.reverBlue)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.reverBlue.opacity(0.1) : Color.dreamMist)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.reverBlue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SuggestionButton: View {
    let title: String
    let time: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.midnightSlate)
                Text(time)
                    .font(.system(size: 11))
                    .foregroundColor(.softGraphite)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.dreamMist)
            .cornerRadius(8)
        }
    }
}

struct ActionCard<Content: View>: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : .reverBlue)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.reverBlue : Color.reverBlue.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .reverBlue : .softGraphite)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.reverBlue.opacity(0.1) : Color.dreamMist)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.reverBlue : Color.clear, lineWidth: 2)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if isSelected {
                content()
                    .padding(.top, 12)
            }
        }
    }
}

struct WindowReviewCard: View {
    let index: Int
    let time: Date
    let actions: [DecisionWindowSetupFlow.WindowAction]
    let saveAmount: Double
    let protectAmount: Double
    let pauseIntention: String? // Custom pause intention (premium)
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("At \(timeString)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.midnightSlate)
            
            if actions.contains(.saveFirst) {
                Text("• Soteria will save $\(String(format: "%.2f", saveAmount))")
                    .font(.system(size: 14))
                    .foregroundColor(.softGraphite)
            }
            
            // NOTE: Protect Amount is commented out - not fully implemented yet
            // if actions.contains(.protectAmount) {
            //     Text("• Protect $\(String(format: "%.2f", protectAmount))")
            //         .font(.system(size: 14))
            //         .foregroundColor(.softGraphite)
            // }
            
            if actions.contains(.justRemind) {
                if let customIntention = pauseIntention, !customIntention.isEmpty {
                    Text("• Remind: \"\(customIntention)\"")
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                } else {
                    Text("• Remind you what you're saving for")
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                }
            }
        }
        .padding(16)
        .background(Color.dreamMist.opacity(0.5))
        .cornerRadius(12)
    }
}

struct AmountPicker: View {
    @Binding var amount: Double
    @State private var showCustomInput = false
    @State private var customAmountText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            if showCustomInput {
                HStack {
                    Text("$")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.reverBlue)
                    TextField("0.00", text: $customAmountText)
                        .keyboardType(.decimalPad)
                        .onChange(of: customAmountText) { oldValue, newValue in
                            if let value = Double(newValue) {
                                amount = value
                            }
                        }
                }
                .padding(12)
                .background(Color.dreamMist)
                .cornerRadius(10)
            } else {
                HStack(spacing: 12) {
                    ForEach([1.0, 3.0, 5.0], id: \.self) { preset in
                        Button(action: {
                            amount = preset
                        }) {
                            Text("$\(String(format: "%.0f", preset))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(amount == preset ? .white : .reverBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(amount == preset ? Color.reverBlue : Color.reverBlue.opacity(0.1))
                                )
                        }
                    }
                    
                    Button(action: {
                        showCustomInput = true
                        customAmountText = String(format: "%.2f", amount)
                    }) {
                        Text("Custom")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.reverBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.reverBlue.opacity(0.1))
                            )
                    }
                }
            }
        }
    }
}

#Preview {
    DecisionWindowSetupFlow()
}

