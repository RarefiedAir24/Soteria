//
//  DecisionWindowPromptView.swift
//  soteria
//
//  "Choose Before You Spend" prompt shown during Decision Windows
//

import SwiftUI
import UserNotifications

struct DecisionWindowPromptView: View {
    let window: DecisionWindow
    let onDismiss: () -> Void
    
    @ObservedObject private var decisionWindowsService = DecisionWindowsService.shared
    @ObservedObject private var plaidService = PlaidService.shared
    @ObservedObject private var aiService = BehavioralAIService.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @ObservedObject private var goalsService = GoalsService.shared
    @ObservedObject private var regretService = RegretLoggingService.shared
    private let goalImpactService = GoalImpactService.shared
    private let smartSavingsService = SmartSavingsService.shared
    @State private var selectedOption: CommitmentType? = nil
    @State private var showPaywall = false
    
    // Goal Impact Enhancement States
    @State private var goalPhoto: UIImage? = nil
    @State private var isLoadingGoalPhoto = false
    @State private var similarRegrets: [RegretEntry] = []
    @State private var suggestedAmounts: [(amount: Double, impact: GoalImpact)] = []
    
    // Smart Savings Suggestions (Premium)
    @State private var smartSuggestions: [SmartSuggestion] = []
    @State private var topSmartSuggestion: SmartSuggestion? = nil
    
    // Option A: Micro-Save
    @State private var microSaveAmount: String = ""
    @State private var amountSuggestion: AmountSuggestion? = nil
    
    // Option B: Spend Gate
    @State private var spendGateCondition: String = "food_delivery"
    @State private var spendGateAmount: String = ""
    @State private var spendGateDescription: String = ""
    
    // Option C: Pause Intention
    @State private var pauseIntentionText: String = ""
    
    
    private var canSave: Bool {
        switch selectedOption {
        case .microSave:
            return Double(microSaveAmount) != nil && (Double(microSaveAmount) ?? 0) > 0
        // NOTE: Spend Gate is commented out - not fully implemented yet
        case .spendGate:
            // Not currently used, but required for exhaustive switch
            return false
        case .pauseIntention:
            return !pauseIntentionText.isEmpty
        case .none:
            return false
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("You're in control")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("Take 30 seconds to choose what you want to do — then we'll stay quiet.")
                            .font(.system(size: 16))
                            .foregroundColor(.softGraphite)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 32)
                    
                    // Goal Anchoring Section (Enhanced with Impact Intervention - Premium)
                    if let activeGoal = goalsService.activeGoal {
                        if subscriptionService.isPremium {
                            // Premium: Full enhanced Goal Impact features
                            enhancedGoalAnchoringCard(goal: activeGoal)
                                .onAppear {
                                    loadGoalImpactData(for: activeGoal)
                                }
                        } else {
                            // Free: Basic goal display only
                            basicGoalAnchoringCard(goal: activeGoal)
                        }
                    }
                    
                    // Options
                    VStack(spacing: 16) {
                        // Option A: Lock a Micro-Save
                        OptionCard(
                            icon: "lock.fill",
                            title: "Lock a Micro-Save",
                            subtitle: "Save now, before spending starts",
                            isSelected: selectedOption == .microSave,
                            onTap: {
                                selectedOption = .microSave
                                if microSaveAmount.isEmpty, let defaultAmount = window.defaultMicroSaveAmount {
                                    microSaveAmount = String(format: "%.2f", defaultAmount)
                                }
                            }
                        ) {
                            if selectedOption == .microSave {
                                VStack(alignment: .leading, spacing: 12) {
                                    // Smart Savings Suggestions Card (Premium + Active Goal)
                                    if subscriptionService.isPremium, let activeGoal = goalsService.activeGoal, !smartSuggestions.isEmpty {
                                        smartSuggestionsCard(goal: activeGoal)
                                            .padding(.bottom, 8)
                                    }
                                    
                                    // AI Amount Suggestion Header (Premium Feature)
                                    if let suggestion = amountSuggestion {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                if let header = suggestion.userFacingCopy.header {
                                                    Text(header)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(.softGraphite)
                                                }
                                                // Premium badge
                                                Image(systemName: "crown.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.orange)
                                            }
                                            if let helper = suggestion.userFacingCopy.helper {
                                                Text(helper)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.softGraphite)
                                            }
                                        }
                                        .padding(.bottom, 4)
                                    } else if !subscriptionService.isPremium {
                                        // Show locked state for free users
                                        Button(action: {
                                            showPaywall = true
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 12))
                                                Text("AI-powered amount suggestions")
                                                    .font(.system(size: 13, weight: .medium))
                                                Spacer()
                                                Text("Premium")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(.orange)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .fill(Color.orange.opacity(0.1))
                                                    )
                                            }
                                            .foregroundColor(.softGraphite)
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.dreamMist)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    Text("How much to save today?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.softGraphite)
                                    
                                    HStack {
                                        Text("$")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.softGraphite)
                                        TextField("0.00", text: $microSaveAmount)
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.midnightSlate)
                                            .keyboardType(.decimalPad)
                                    }
                                    .padding(16)
                                    .background(Color.dreamMist)
                                    .cornerRadius(12)
                                    
                                    // Quick Save Buttons - Smart Suggestions (Premium) or AI Suggestions
                                    if subscriptionService.isPremium, !smartSuggestions.isEmpty {
                                        // Smart Suggestions with impact
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 4) {
                                                Text("Smart Suggestions")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.softGraphite)
                                                Image(systemName: "crown.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.orange)
                                            }
                                            .padding(.bottom, 4)
                                            
                                            VStack(spacing: 8) {
                                                ForEach(smartSuggestions.prefix(3), id: \.amount) { suggestion in
                                                    Button(action: {
                                                        microSaveAmount = String(format: "%.2f", suggestion.amount)
                                                    }) {
                                                        HStack {
                                                            VStack(alignment: .leading, spacing: 2) {
                                                                Text("$\(String(format: "%.0f", suggestion.amount))")
                                                                    .font(.system(size: 16, weight: .bold))
                                                                    .foregroundColor(.midnightSlate)
                                                                Text(suggestion.reason)
                                                                    .font(.system(size: 12))
                                                                    .foregroundColor(.softGraphite)
                                                            }
                                                            
                                                            Spacer()
                                                            
                                                            VStack(alignment: .trailing, spacing: 2) {
                                                                Text("\(suggestion.impact.formattedDaysCloser)")
                                                                    .font(.system(size: 14, weight: .semibold))
                                                                    .foregroundColor(.softGraphite)
                                                                Text("closer")
                                                                    .font(.system(size: 11))
                                                                    .foregroundColor(.softGraphite)
                                                            }
                                                        }
                                                        .padding(12)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 10)
                                                                .fill(microSaveAmount == String(format: "%.2f", suggestion.amount) 
                                                                      ? Color.softGraphite.opacity(0.15)
                                                                      : Color.dreamMist)
                                                        )
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 10)
                                                                .stroke(microSaveAmount == String(format: "%.2f", suggestion.amount) 
                                                                        ? Color.softGraphite 
                                                                        : Color.clear, lineWidth: 2)
                                                        )
                                                    }
                                                }
                                            }
                                        }
                                    } else if let suggestion = amountSuggestion, !suggestion.suggestedAmounts.isEmpty {
                                        // AI Suggestions (fallback)
                                        HStack(spacing: 4) {
                                            Text("AI Suggestions")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.softGraphite)
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.orange)
                                        }
                                        .padding(.bottom, 4)
                                        
                                        HStack(spacing: 8) {
                                            ForEach(suggestion.suggestedAmounts, id: \.self) { amount in
                                                Button(action: {
                                                    microSaveAmount = String(format: "%.2f", amount)
                                                }) {
                                                    Text("$\(String(format: "%.0f", amount))")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(microSaveAmount == String(format: "%.2f", amount) ? .white : .softGraphite)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 8)
                                                        .background(
                                                            microSaveAmount == String(format: "%.2f", amount) 
                                                                ? Color.softGraphite 
                                                                : Color.softGraphite.opacity(0.1)
                                                        )
                                                        .cornerRadius(8)
                                                }
                                            }
                                        }
                                    } else if !subscriptionService.isPremium {
                                        // Show locked preview for free users
                                        Button(action: {
                                            showPaywall = true
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 12))
                                                Text("Unlock AI-powered amount suggestions")
                                                    .font(.system(size: 13, weight: .medium))
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12))
                                            }
                                            .foregroundColor(.softGraphite)
                                            .padding(10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.dreamMist)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    Text("This will be saved immediately")
                                        .font(.system(size: 12))
                                        .foregroundColor(.softGraphite)
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // NOTE: Option B (Spend Gate) is commented out - not fully implemented yet
                        // TODO: Re-enable when spend gate detection mechanism is implemented
                        // Option B: Create a Spend Gate
                        // OptionCard(
                        //     icon: "shield.fill",
                        //     title: "Create a Spend Gate",
                        //     subtitle: "Auto-save if you spend on specific things",
                        //     isSelected: selectedOption == .spendGate,
                        //     onTap: {
                        //         selectedOption = .spendGate
                        //         if spendGateAmount.isEmpty, let defaultGate = window.defaultSpendGate {
                        //             spendGateAmount = String(format: "%.2f", defaultGate.saveAmount)
                        //             spendGateDescription = defaultGate.description
                        //             spendGateCondition = defaultGate.condition
                        //         }
                        //     }
                        // ) {
                        //     if selectedOption == .spendGate {
                        //         VStack(alignment: .leading, spacing: 16) {
                        //             VStack(alignment: .leading, spacing: 8) {
                        //                 Text("If I spend on:")
                        //                     .font(.system(size: 14, weight: .medium))
                        //                     .foregroundColor(.softGraphite)
                        //                 
                        //                 Picker("Condition", selection: $spendGateCondition) {
                        //                     Text("Food Delivery").tag("food_delivery")
                        //                     Text("Shopping Apps").tag("shopping_app")
                        //                     Text("After 9 PM").tag("after_9pm")
                        //                     Text("Impulse Purchase").tag("impulse")
                        //                 }
                        //                 .pickerStyle(.menu)
                        //                 .padding(12)
                        //                 .background(Color.dreamMist)
                        //                 .cornerRadius(10)
                        //             }
                        //             
                        //             VStack(alignment: .leading, spacing: 8) {
                        //                 Text("Then auto-save:")
                        //                     .font(.system(size: 14, weight: .medium))
                        //                     .foregroundColor(.softGraphite)
                        //                 
                        //                 HStack {
                        //                     Text("$")
                        //                         .font(.system(size: 18, weight: .semibold))
                        //                         .foregroundColor(.softGraphite)
                        //                     TextField("0.00", text: $spendGateAmount)
                        //                         .font(.system(size: 20, weight: .bold))
                        //                         .foregroundColor(.midnightSlate)
                        //                         .keyboardType(.decimalPad)
                        //                 }
                        //                 .padding(14)
                        //                 .background(Color.dreamMist)
                        //                 .cornerRadius(10)
                        //             }
                        //             
                        //             VStack(alignment: .leading, spacing: 8) {
                        //                 Text("Description (optional)")
                        //                     .font(.system(size: 14, weight: .medium))
                        //                     .foregroundColor(.softGraphite)
                        //                 
                        //                 TextField("e.g., If I order food delivery today...", text: $spendGateDescription, axis: .vertical)
                        //                     .font(.system(size: 14))
                        //                     .foregroundColor(.midnightSlate)
                        //                     .lineLimit(2...3)
                        //                     .padding(12)
                        //                     .background(Color.dreamMist)
                        //                     .cornerRadius(10)
                        //             }
                        //             
                        //             Text("This will save automatically if the condition is met")
                        //                 .font(.system(size: 12))
                        //                 .foregroundColor(.softGraphite)
                        //         }
                        //         .padding(.top, 8)
                        //     }
                        // }
                        
                        // Option C: Set a Pause Intention
                        OptionCard(
                            icon: "pause.circle.fill",
                            title: "Set a Pause Intention",
                            subtitle: "Remind me why I'm saving",
                            isSelected: selectedOption == .pauseIntention,
                            onTap: {
                                selectedOption = .pauseIntention
                                if pauseIntentionText.isEmpty, let defaultIntention = window.defaultPauseIntention {
                                    pauseIntentionText = defaultIntention
                                }
                            }
                        ) {
                            if selectedOption == .pauseIntention {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("What should we remind you?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.softGraphite)
                                    
                                    TextField("e.g., If I feel bored-scrolling today, remind me why I'm saving", text: $pauseIntentionText, axis: .vertical)
                                        .font(.system(size: 14))
                                        .foregroundColor(.midnightSlate)
                                        .lineLimit(3...5)
                                        .padding(14)
                                        .background(Color.dreamMist)
                                        .cornerRadius(12)
                                    
                                    Text("You'll receive a reflection notification later")
                                        .font(.system(size: 12))
                                        .foregroundColor(.softGraphite)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Primary Action (based on selected option)
                        if selectedOption == .microSave, let amount = Double(microSaveAmount), amount > 0 {
                            Button(action: {
                                saveCommitment()
                            }) {
                                Text("Save $\(String(format: "%.0f", amount)) today")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.softGraphite)
                                    .cornerRadius(12)
                            }
                        // NOTE: Spend Gate button is commented out - not fully implemented yet
                        // } else if selectedOption == .spendGate, let amount = Double(spendGateAmount), amount > 0 {
                        //     Button(action: {
                        //         saveCommitment()
                        //     }) {
                        //         Text("Protect $\(String(format: "%.0f", amount))")
                        //             .font(.system(size: 18, weight: .semibold))
                        //             .foregroundColor(.white)
                        //             .frame(maxWidth: .infinity)
                        //             .padding(.vertical, 16)
                        //             .background(Color.softGraphite)
                        //             .cornerRadius(12)
                        //     }
                        // } else if selectedOption == .pauseIntention, !pauseIntentionText.isEmpty {
                            Button(action: {
                                saveCommitment()
                            }) {
                                Text("Just remind me")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.softGraphite)
                                    .cornerRadius(12)
                            }
                        } else if canSave {
                            Button(action: {
                                saveCommitment()
                            }) {
                                Text("Protect")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.softGraphite)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Secondary / Tertiary Actions
                        HStack(spacing: 12) {
                            if selectedOption == .pauseIntention {
                                Button(action: {
                                    // Switch to save option
                                    selectedOption = .microSave
                                    if microSaveAmount.isEmpty, let defaultAmount = window.defaultMicroSaveAmount {
                                        microSaveAmount = String(format: "%.2f", defaultAmount)
                                    }
                                }) {
                                    Text("Save instead")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.softGraphite)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.softGraphite.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                            
                            Button(action: {
                                // Track "not today" action
                                aiService.recordWindowAction(
                                    windowId: window.id,
                                    action: .notToday
                                )
                                onDismiss()
                            }) {
                                Text("Not today")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.dreamMist)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .background(Color.white)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: -5)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .onAppear {
            // Track window opened
            aiService.recordWindowOpened(windowId: window.id)
            
            // Get AI amount suggestion (Premium only)
            if subscriptionService.isPremium {
                amountSuggestion = aiService.generateAmountSuggestion(for: window.id)
            } else {
                amountSuggestion = nil // Explicitly set to nil for free users
            }
            
            // Load Smart Savings Suggestions (Premium + Active Goal)
            if subscriptionService.isPremium, let activeGoal = goalsService.activeGoal {
                loadSmartSuggestions(for: activeGoal)
            }
            
            // Pre-fill with smart suggestion (premium) or AI suggestion or default
            if microSaveAmount.isEmpty {
                if let topSuggestion = topSmartSuggestion {
                    // Pre-fill with top smart suggestion
                    microSaveAmount = String(format: "%.2f", topSuggestion.amount)
                } else if let suggestion = amountSuggestion {
                    // Fall back to AI suggestion (premium only)
                    microSaveAmount = String(format: "%.2f", suggestion.defaultAmount)
                } else if let defaultAmount = window.defaultMicroSaveAmount {
                    // Fall back to window default
                    microSaveAmount = String(format: "%.2f", defaultAmount)
                }
            }
        }
    }
    
    private func saveCommitment() {
        guard let option = selectedOption else { return }
        
        // Calculate expiration (end of day)
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
        
        let commitment: DecisionWindowCommitment
        var action: DecisionWindowEvent.WindowAction? = nil
        var suggestedAmount: Double? = nil
        var chosenAmount: Double? = nil
        
        switch option {
        case .microSave:
            guard let amount = Double(microSaveAmount) else { return }
            suggestedAmount = amountSuggestion?.defaultAmount
            chosenAmount = amount
            action = .saveFirst
            commitment = DecisionWindowCommitment(
                windowId: window.id,
                type: .microSave,
                expiresAt: endOfDay,
                microSaveAmount: amount
            )
            
        // NOTE: Spend Gate is commented out - not fully implemented yet
        case .spendGate:
            // Not currently used, but required for exhaustive switch
            return
            
        case .pauseIntention:
            action = .remindOnly
            commitment = DecisionWindowCommitment(
                windowId: window.id,
                type: .pauseIntention,
                expiresAt: endOfDay,
                pauseIntention: pauseIntentionText
            )
            
        }
        
        // Track action with AI service
        if let action = action {
            aiService.recordWindowAction(
                windowId: window.id,
                action: action,
                suggestedAmount: suggestedAmount,
                chosenAmount: chosenAmount
            )
        }
        
        decisionWindowsService.addCommitment(commitment)
        onDismiss()
    }
    
    // MARK: - Goal Anchoring (Feature #6)
    
    // Basic Goal Anchoring Card for Free Users
    private func basicGoalAnchoringCard(goal: SavingsGoal) -> some View {
        VStack(spacing: 16) {
            // Goal Name and Countdown
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: goal.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.softGraphite)
                    
                    Text(goal.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    Spacer()
                    
                    // Premium badge to indicate upgrade available
                    Button(action: {
                        showPaywall = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                            Text("Premium")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let daysUntil = goal.daysUntilTarget, daysUntil > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                        Text("\(daysUntil) day\(daysUntil == 1 ? "" : "s") until your goal")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.softGraphite)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                        Text("\(Int(goal.progress * 100))% complete")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.softGraphite)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.dreamMist)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.softGraphite)
                        .frame(width: geometry.size.width * goal.progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Progress Text
            HStack {
                Text("$\(Int(goal.currentAmount)) of $\(Int(goal.targetAmount))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.softGraphite)
                Spacer()
            }
            
            // Upgrade prompt for enhanced features
            Button(action: {
                showPaywall = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                    Text("Unlock goal photo, impact calculations, and regret reminders")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                }
                .foregroundColor(.softGraphite)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.dreamMist)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cloudWhite)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    // Enhanced Goal Anchoring Card with Impact Intervention (Premium Only)
    private func enhancedGoalAnchoringCard(goal: SavingsGoal) -> some View {
        VStack(spacing: 0) {
            // Prominent Goal Photo (Full-Width)
            if let photo = goalPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.3), Color.clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            } else {
                // Fallback: Goal icon with gradient background
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.softGraphite.opacity(0.3), Color.softGraphite.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: goal.category.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.softGraphite.opacity(0.6))
                }
                .frame(height: 120)
            }
            
            VStack(spacing: 16) {
                // Goal Name and Countdown
                VStack(spacing: 8) {
                    Text(goal.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    if let daysUntil = goal.daysUntilTarget, daysUntil > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                            Text("\(daysUntil) day\(daysUntil == 1 ? "" : "s") until your goal")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.softGraphite)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 14))
                            Text("\(Int(goal.progress * 100))% complete")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.softGraphite)
                    }
                }
                .padding(.top, 16)
                
                // Progress Bar with Projected Progress
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color.dreamMist)
                                .frame(height: 10)
                                .cornerRadius(5)
                            
                            // Current Progress
                            Rectangle()
                                .fill(Color.softGraphite.opacity(0.6))
                                .frame(width: geometry.size.width * goal.progress, height: 10)
                                .cornerRadius(5)
                            
                            // Projected Progress (if amount entered)
                            if let amount = Double(microSaveAmount), amount > 0,
                               let impact = goalImpactService.calculateImpact(amount: amount, goal: goal) {
                                Rectangle()
                                    .fill(Color.softGraphite)
                                    .frame(width: geometry.size.width * impact.projectedProgress, height: 10)
                                    .cornerRadius(5)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: impact.projectedProgress)
                            }
                        }
                    }
                    .frame(height: 10)
                    
                    // Progress Text
                    HStack {
                        Text("$\(Int(goal.currentAmount)) of $\(Int(goal.targetAmount))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.softGraphite)
                        
                        Spacer()
                        
                        if let amount = Double(microSaveAmount), amount > 0,
                           let impact = goalImpactService.calculateImpact(amount: amount, goal: goal) {
                            Text("→ $\(Int(goal.currentAmount + amount))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.softGraphite)
                        }
                    }
                }
                
                // Past Regret Reminder
                if !similarRegrets.isEmpty, let firstRegret = similarRegrets.first {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if let regretAmount = firstRegret.amount {
                                Text("You regretted not saving $\(Int(regretAmount)) on \(formatDate(firstRegret.date))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.midnightSlate)
                                
                                if let impact = goalImpactService.calculateImpact(amount: regretAmount, goal: goal) {
                                    Text("That would have been \(impact.formattedDaysCloser) closer to your goal")
                                        .font(.system(size: 11))
                                        .foregroundColor(.softGraphite)
                                }
                            } else {
                                Text("You had a regret on \(formatDate(firstRegret.date))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.midnightSlate)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
                
                // Dynamic Amount Suggestions
                if !suggestedAmounts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Save Options")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        HStack(spacing: 10) {
                            ForEach(suggestedAmounts.prefix(4), id: \.amount) { suggestion in
                                Button(action: {
                                    microSaveAmount = String(format: "%.2f", suggestion.amount)
                                    selectedOption = .microSave
                                }) {
                                    VStack(spacing: 4) {
                                        Text("$\(Int(suggestion.amount))")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text(suggestion.impact.formattedDaysCloser)
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(microSaveAmount == String(format: "%.2f", suggestion.amount) ? Color.softGraphite : Color.softGraphite)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // Impact Message (when amount entered)
                if let amount = Double(microSaveAmount), amount > 0,
                   let impact = goalImpactService.calculateImpact(amount: amount, goal: goal) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16))
                            .foregroundColor(.softGraphite)
                        
                        Text("Saving $\(Int(amount)) = \(impact.formattedDaysCloser) closer to \(goal.name)!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.softGraphite)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.softGraphite.opacity(0.1))
                    )
                }
                
                // Momentum Message
                if let momentumMessage = getMomentumMessage(for: goal) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text(momentumMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.softGraphite)
                    }
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cloudWhite)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // Keep original for backward compatibility (if needed elsewhere)
    @ViewBuilder
    private func goalAnchoringCard(goal: SavingsGoal) -> some View {
        if subscriptionService.isPremium {
            enhancedGoalAnchoringCard(goal: goal)
        } else {
            basicGoalAnchoringCard(goal: goal)
        }
    }
    
    // Load goal impact data (photo, regrets, suggestions)
    private func loadGoalImpactData(for goal: SavingsGoal) {
        // Load suggested amounts first (needed for regret matching)
        suggestedAmounts = goalImpactService.getSuggestedAmounts(for: goal)
        
        // Load goal photo
        loadGoalPhoto(for: goal)
        
        // Load similar regrets (use first suggested amount or default)
        regretService.ensureDataLoaded() // Ensure regrets are loaded
        let allRegrets = regretService.regretEntries
        let referenceAmount = suggestedAmounts.first?.amount ?? 25.0
        similarRegrets = goalImpactService.getSimilarRegrets(
            amount: referenceAmount,
            goal: goal,
            regrets: allRegrets
        )
    }
    
    // Load Smart Savings Suggestions (Premium)
    private func loadSmartSuggestions(for goal: SavingsGoal) {
        smartSuggestions = smartSavingsService.getSmartSuggestions(for: goal)
        topSmartSuggestion = smartSuggestions.first
    }
    
    // Smart Suggestions Card UI
    @ViewBuilder
    private func smartSuggestionsCard(goal: SavingsGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(.softGraphite)
                Text("Smart Savings Suggestions")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.midnightSlate)
                Image(systemName: "crown.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }
            
            if let topSuggestion = topSmartSuggestion {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("💡 \(topSuggestion.reason)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        Spacer()
                        Text("\(topSuggestion.impact.formattedDaysCloser) closer")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.softGraphite)
                    }
                    
                    if topSuggestion.type == .autoAdjust {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text("You're behind schedule - this helps you catch up")
                                .font(.system(size: 11))
                                .foregroundColor(.softGraphite)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.softGraphite.opacity(0.08))
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cloudWhite)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // Load goal photo from cache
    private func loadGoalPhoto(for goal: SavingsGoal) {
        guard let goalId = goalsService.activeGoal?.id else { return }
        
        isLoadingGoalPhoto = true
        
        // Try UserDefaults cache first
        let cacheKey = "goal_photo_\(goalId)"
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let image = UIImage(data: data) {
            goalPhoto = image
            isLoadingGoalPhoto = false
            return
        }
        
        // Try loading from S3 if photoPath exists
        if let photoPath = goal.photoPath, !photoPath.isEmpty {
            Task {
                let photoService = GoalPhotoService.shared
                do {
                    if let image = try await photoService.downloadGoalPhoto(goalId: goalId) {
                        await MainActor.run {
                            goalPhoto = image
                            isLoadingGoalPhoto = false
                        }
                    } else {
                        await MainActor.run {
                            isLoadingGoalPhoto = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        isLoadingGoalPhoto = false
                    }
                }
            }
        } else {
            isLoadingGoalPhoto = false
        }
    }
    
    // Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private func goalPhotoView(photoPath: String) -> some View {
        // Load goal photo from UserDefaults cache
        let cacheKey = "goal_photo_\(goalsService.activeGoal?.id ?? "")"
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.softGraphite.opacity(0.3), lineWidth: 2))
        } else {
            Image(systemName: goalsService.activeGoal?.category.icon ?? "star.fill")
                .font(.system(size: 24))
                .foregroundColor(.softGraphite)
                .frame(width: 50, height: 50)
                .background(Color.softGraphite.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    private func getMomentumMessage(for goal: SavingsGoal) -> String? {
        // This is a simplified version - in production, you'd track monthly savings
        let progress = goal.progress
        
        if progress > 0.9 {
            return "You're almost there! Keep going! 🎯"
        } else if progress > 0.5 {
            return "You're halfway there! Amazing progress! 💪"
        } else if progress > 0.25 {
            return "Great start! You're building momentum! ⚡️"
        } else if let daysUntil = goal.daysUntilTarget, daysUntil < 30 {
            return "Less than a month to go! You've got this! 🚀"
        }
        
        return nil
    }
    
    private func calculateDaysCloser(amount: Double, goal: SavingsGoal) -> Double? {
        guard let daysUntil = goal.daysUntilTarget,
              daysUntil > 0,
              goal.remainingAmount > 0 else { return nil }
        
        // Calculate daily savings rate needed
        let dailyRate = goal.remainingAmount / Double(daysUntil)
        guard dailyRate > 0 else { return nil }
        
        // Calculate how many days this amount saves
        let daysSaved = amount / dailyRate
        return max(daysSaved, 0)
    }
    
    private func getConditionDescription(_ condition: String) -> String {
        switch condition {
        case "food_delivery":
            return "If I order food delivery today"
        case "shopping_app":
            return "If I shop online today"
        case "after_9pm":
            return "If I make a purchase after 9 PM"
        case "impulse":
            return "If I make an impulse purchase"
        default:
            return "If I spend today"
        }
    }
}

struct OptionCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : .softGraphite)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.softGraphite : Color.softGraphite.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .softGraphite : .softGraphite.opacity(0.5))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.softGraphite.opacity(0.1) : Color.dreamMist)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.softGraphite : Color.clear, lineWidth: 2)
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

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    DecisionWindowPromptView(
        window: DecisionWindow(
            name: "Morning Planning",
            time: DateComponents(hour: 8, minute: 0),
            daysOfWeek: [2, 3, 4, 5, 6],
            promptMessage: "Before today continues — do you want to protect anything?"
        ),
        onDismiss: {}
    )
}

