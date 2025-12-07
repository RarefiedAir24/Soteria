//
//  PauseView.swift
//  rever
//
//  Behavioral spending protection - Pause and reflect moment
//

import SwiftUI

struct PauseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var savingsService: SavingsService
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    @EnvironmentObject var goalsService: GoalsService
    @EnvironmentObject var regretService: RegretLoggingService
    @EnvironmentObject var moodService: MoodTrackingService
    @EnvironmentObject var purchaseIntentService: PurchaseIntentService
    
    @State private var purchaseType: PurchaseType? = nil // Planned or Impulse
    @State private var selectedCategory: PlannedPurchaseCategory? = nil
    @State private var plannedSpend: String = ""
    @State private var showConfirmation: String? = nil
    @State private var selectedGoalId: String? = nil
    @State private var currentMood: MoodLevel? = nil
    @State private var showRegretLog: Bool = false
    
    private var formattedSavedAmount: String {
        guard let amount = Double(plannedSpend), amount > 0 else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                        
                        Text("SOTERIA Moment")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("The pause that protects")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Planned vs Impulse Prompt (FIRST QUESTION)
                        if purchaseType == nil {
                            VStack(spacing: 20) {
                                Text("Is this a planned purchase or impulse?")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 16) {
                                    Button(action: {
                                        purchaseType = .planned
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 40))
                                            Text("Planned")
                                                .font(.headline)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                                        )
                                    }
                                    
                                    Button(action: {
                                        purchaseType = .impulse
                                        // Will record when user completes the flow
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "bolt.circle.fill")
                                                .font(.system(size: 40))
                                            Text("Impulse")
                                                .font(.headline)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 0.98, green: 0.95, blue: 0.95))
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                        
                        // Category Selection (if Planned)
                        if purchaseType == .planned && selectedCategory == nil {
                            VStack(spacing: 16) {
                                Text("What category is this purchase?")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    .multilineTextAlignment(.center)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(PlannedPurchaseCategory.allCases, id: \.self) { category in
                                        Button(action: {
                                            selectedCategory = category
                                        }) {
                                            VStack(spacing: 8) {
                                                Image(systemName: category.icon)
                                                    .font(.system(size: 28))
                                                Text(category.displayName)
                                                    .font(.subheadline)
                                                    .multilineTextAlignment(.center)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                            )
                                        }
                                    }
                                }
                                
                                // Quick continue button after selecting category
                                Button(action: {
                                    // Record planned purchase with category
                                    let intent = PurchaseIntent(
                                        purchaseType: .planned,
                                        category: selectedCategory,
                                        amount: Double(plannedSpend)
                                    )
                                    purchaseIntentService.recordIntent(intent)
                                    showConfirmation = "Planned purchase recorded. Continue shopping mindfully."
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        dismiss()
                                    }
                                }) {
                                    Text("Continue Shopping")
                                        .frame(maxWidth: .infinity)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(red: 0.1, green: 0.6, blue: 0.3))
                                        )
                                }
                                .disabled(selectedCategory == nil)
                            }
                            .padding(.horizontal, 32)
                        }
                        
                        // Show rest of the flow only after purchase type is selected
                        if purchaseType != nil {
                            // Future Self Prompt
                            VStack(spacing: 8) {
                                Text("What would your future self want?")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    .multilineTextAlignment(.center)
                                
                                Text("Your future self deserves a voice in every choice")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                            )
                            .padding(.horizontal, 32)
                        
                            // Amount Input Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How much were you about to spend?")
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                
                                Text("This pause helps you reconnect with your intentions")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                    .italic()
                                
                                TextField("$0.00", text: $plannedSpend)
                                    .textFieldStyle(.plain)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                    )
                            }
                            .padding(.horizontal, 32)
                            
                            // Mood Check-in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How are you feeling right now?")
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(MoodLevel.allCases, id: \.self) { mood in
                                        Button(action: {
                                            currentMood = mood
                                            moodService.addMoodEntry(MoodEntry(mood: mood))
                                        }) {
                                            VStack(spacing: 4) {
                                                Text(mood.emoji)
                                                    .font(.system(size: 32))
                                                Text(mood.displayName)
                                                    .font(.caption)
                                                    .foregroundColor(currentMood == mood ? .white : .gray)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(currentMood == mood ? Color(red: 0.1, green: 0.6, blue: 0.3) : Color(red: 0.95, green: 0.95, blue: 0.95))
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                            
                            // Goal Selection (if goals exist)
                            if !goalsService.goals.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Gift to your future self:")
                                        .font(.subheadline)
                                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                    
                                    Picker("Goal", selection: $selectedGoalId) {
                                        Text("No goal").tag(String?.none)
                                        ForEach(goalsService.goals) { goal in
                                            Text(goal.name).tag(goal.id as String?)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                    )
                                }
                                .padding(.horizontal, 32)
                            }
                            
                            // Confirmation Message
                            if let confirmation = showConfirmation {
                                Text(confirmation)
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                                    )
                                    .padding(.horizontal, 32)
                            }
                            
                            VStack(spacing: 16) {
                                Button(action: {
                                    handleSkipAndSave()
                                }) {
                                    VStack(spacing: 4) {
                                        Text("Protect & Save")
                                            .frame(maxWidth: .infinity)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("Choose peace and stability")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(red: 0.1, green: 0.6, blue: 0.3))
                                
                                Button(action: {
                                    handleContinueShopping()
                                }) {
                                    VStack(spacing: 4) {
                                        Text("Continue Shopping")
                                            .frame(maxWidth: .infinity)
                                        Text("We're here to protect, not restrict")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .buttonStyle(.bordered)
                                
                                // Log as Regret button
                                Button(action: {
                                    showRegretLog = true
                                }) {
                                    VStack(spacing: 4) {
                                        Text("I already made this purchase")
                                            .frame(maxWidth: .infinity)
                                            .font(.subheadline)
                                        Text("Regret is a signal, not a failure")
                                            .font(.system(size: 11))
                                            .foregroundColor(.orange)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Pause")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if selectedGoalId == nil, let activeGoal = goalsService.activeGoal {
                    selectedGoalId = activeGoal.id
                }
            }
            .sheet(isPresented: $showRegretLog) {
                LogRegretView(plannedAmount: plannedSpend, currentMood: currentMood ?? .neutral)
                    .environmentObject(regretService)
            }
        }
    }
    
    private func handleSkipAndSave() {
        let amount = Double(plannedSpend) ?? 0
        
        // Record purchase intent before saving
        if let purchaseType = purchaseType {
            let intent = PurchaseIntent(
                purchaseType: purchaseType,
                category: purchaseType == .planned ? selectedCategory : nil,
                amount: amount > 0 ? amount : nil
            )
            purchaseIntentService.recordIntent(intent)
        }
        
        if amount > 0 {
            savingsService.recordSkipAndSave(amount: amount)
            
            // Add to selected goal if one is selected
            if let goalId = selectedGoalId {
                goalsService.addToGoal(goalId: goalId, amount: amount)
                if let goal = goalsService.goals.first(where: { $0.id == goalId }) {
                    showConfirmation = "Your future self thanks you ✨\nAdded \(formattedSavedAmount) to '\(goal.name)'"
                } else {
                    showConfirmation = "Your future self thanks you ✨\nYou protected \(formattedSavedAmount)"
                }
            } else {
                showConfirmation = "Your future self thanks you ✨\nYou protected \(formattedSavedAmount)"
            }
            
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        } else {
            showConfirmation = "Please enter an amount to see your protection in action"
        }
    }
    
    private func handleContinueShopping() {
        // Record purchase intent
        if let purchaseType = purchaseType {
            let intent = PurchaseIntent(
                purchaseType: purchaseType,
                category: purchaseType == .planned ? selectedCategory : nil,
                amount: Double(plannedSpend)
            )
            purchaseIntentService.recordIntent(intent)
        }
        
        // Temporarily unblock apps for 15 minutes
        deviceActivityService.temporarilyUnblock(durationMinutes: 15)
        showConfirmation = "We're here to protect, not restrict.\nShop mindfully for the next 15 minutes."
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
    
    private func handleMarkAsPlanned() {
        // This is now handled by the purchase type selection above
        // If we reach here, it means they selected "Planned" and chose a category
        showConfirmation = "Understood. We're here to support your intentions."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// Simple regret logging view
struct LogRegretView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var regretService: RegretLoggingService
    
    let plannedAmount: String
    let currentMood: MoodLevel
    
    @State private var merchant: String = ""
    @State private var reason: String = ""
    @State private var amount: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Regret Details") {
                    TextField("Merchant (optional)", text: $merchant)
                    TextField("Amount (optional)", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Why was this a regret?", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Mood") {
                    Text(currentMood.displayName + " " + currentMood.emoji)
                }
                
                Button("Log Regret") {
                    let regret = RegretEntry(
                        amount: Double(amount) ?? Double(plannedAmount),
                        merchant: merchant.isEmpty ? nil : merchant,
                        reason: reason.isEmpty ? "Impulse purchase" : reason,
                        mood: currentMood
                    )
                    regretService.addRegret(regret)
                    dismiss()
                }
                .disabled(reason.isEmpty)
            }
            .navigationTitle("Log Regret")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PauseView()
        .environmentObject(SavingsService())
        .environmentObject(DeviceActivityService.shared)
        .environmentObject(GoalsService.shared)
        .environmentObject(RegretLoggingService.shared)
        .environmentObject(MoodTrackingService.shared)
        .environmentObject(PurchaseIntentService.shared)
}
