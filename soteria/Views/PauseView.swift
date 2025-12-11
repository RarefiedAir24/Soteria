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
    @EnvironmentObject var streakService: StreakService
    @EnvironmentObject var plaidService: PlaidService
    
    @State private var purchaseType: PurchaseType? = nil // Planned or Impulse
    @State private var selectedCategory: PlannedPurchaseCategory? = nil
    @State private var plannedSpend: String = ""
    @State private var showConfirmation: String? = nil
    @State private var selectedGoalId: String? = nil
    @State private var currentMood: MoodLevel? = nil
    @State private var showRegretLog: Bool = false
    @State private var showSaveMoneyPrompt: Bool = false
    @State private var isProcessingTransfer: Bool = false
    
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
                        
                        Text("Creating awareness, not restriction")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            .italic()
                            .padding(.top, 4)
                        
                        // Planned vs Impulse Prompt (FIRST QUESTION)
                        if purchaseType == nil {
                            VStack(spacing: 20) {
                                Text("Is this a planned activity or impulse?")
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
                                Text("What category is this activity?")
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
                            }
                            .padding(.horizontal, 32)
                        }
                        
                        // Show rest of the flow only after purchase type is selected
                        // For planned: show after category is selected
                        // For impulse: show immediately
                        if (purchaseType == .planned && selectedCategory != nil) || (purchaseType == .impulse) {
                            // Future Self Prompt
                            VStack(spacing: 8) {
                                Text("Take a moment to reflect")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    .multilineTextAlignment(.center)
                                
                                Text("This pause helps you reconnect with your intentions")
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
                        
                            // Amount Input Field (Optional - for tracking only, relevant for purchases)
                            if purchaseType == .planned && selectedCategory != nil {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Estimated amount (Optional)")
                                        .font(.subheadline)
                                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                    
                                    Text("Skip if you prefer - the protection moment is what matters")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                        .italic()
                                    
                                    TextField("Skip this step", text: $plannedSpend)
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
                            }
                            
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
                                                    .fill(currentMood == mood ? Color.themePrimary : Color(red: 0.95, green: 0.95, blue: 0.95))
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
                                    .foregroundColor(Color.themePrimary)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                                    )
                                    .padding(.horizontal, 32)
                            }
                            
                            // Unblock & Continue button - only show after mood is selected
                            if currentMood != nil {
                                Button(action: {
                                    // If Plaid is connected, show save money prompt
                                    if plaidService.savingsMode != .manual {
                                        showSaveMoneyPrompt = true
                                    } else {
                                        handleUnblockAndShop()
                                    }
                                }) {
                                    HStack {
                                        if isProcessingTransfer {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            VStack(spacing: 4) {
                                                Text("Unblock & Continue")
                                                    .frame(maxWidth: .infinity)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Text("Temporarily unblock apps for 15 minutes")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.white.opacity(0.9))
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.themePrimary)
                                .disabled(isProcessingTransfer)
                                .padding(.horizontal, 32)
                                
                                // Secondary options
                                VStack(spacing: 16) {
                                    Button(action: {
                                        handleSkipAndSave()
                                    }) {
                                        VStack(spacing: 4) {
                                            Text("Continue Block")
                                                .frame(maxWidth: .infinity)
                                                .font(.subheadline)
                                            Text("Keep apps blocked and protect yourself")
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
            .alert("Save Money?", isPresented: $showSaveMoneyPrompt) {
                Button("Skip") {
                    handleUnblockAndShop()
                }
                Button("Save $\(Int(plaidService.protectionAmount))") {
                    Task {
                        await handleUnblockWithTransfer()
                    }
                }
            } message: {
                if plaidService.savingsMode == .automatic {
                    Text("Transfer $\(Int(plaidService.protectionAmount)) to your savings account?")
                } else {
                    Text("Track $\(Int(plaidService.protectionAmount)) as protected savings?")
                }
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
        
        // Continue blocking - apps remain blocked
        // Note: We don't call temporarilyUnblock, so blocking continues
        
        // Record protection moment (amount is optional)
        savingsService.soteriaMomentsCount += 1
        
        // Record streak
        streakService.recordProtection()
        
        // Auto-add to active goal (Protection = Goal Progress)
        var goalProgressMessage = ""
        if let activeGoal = goalsService.activeGoal {
            let protectionAmount = activeGoal.protectionAmount
            goalsService.addProtectionToActiveGoal()
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 0
            let amountString = formatter.string(from: NSNumber(value: protectionAmount)) ?? "$\(Int(protectionAmount))"
            
            let progressPercent = Int(activeGoal.progress * 100)
            goalProgressMessage = "\n\(amountString) added to '\(activeGoal.name)'\n\(progressPercent)% complete"
        }
        
        // If user entered an amount, also add that to the selected goal (if different from active)
        if amount > 0 {
            savingsService.recordSkipAndSave(amount: amount)
            
            if let goalId = selectedGoalId, goalId != goalsService.activeGoal?.id {
                goalsService.addToGoal(goalId: goalId, amount: amount)
                if let goal = goalsService.goals.first(where: { $0.id == goalId }) {
                    goalProgressMessage += "\n+ \(formattedSavedAmount) to '\(goal.name)'"
                }
            }
        }
        
        // Build confirmation message
        var confirmation = "You chose protection ✨"
        if !goalProgressMessage.isEmpty {
            confirmation += goalProgressMessage
        }
        confirmation += "\nApps remain blocked"
        
        if streakService.currentStreak > 1 {
            confirmation += "\n\(streakService.streakEmoji) \(streakService.currentStreak) day streak!"
        }
        
        showConfirmation = confirmation
        
        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
    
    private func handleUnblockAndShop() {
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
        deviceActivityService.temporarilyUnblock(
            durationMinutes: 15,
            purchaseType: purchaseType?.rawValue,
            category: purchaseType == .planned ? selectedCategory?.rawValue : nil,
            mood: currentMood?.rawValue,
            moodNotes: nil,
            appIndex: nil
        )
        
        showConfirmation = "Apps unblocked for 15 minutes.\nShop mindfully."
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
    
    private func handleUnblockWithTransfer() async {
        isProcessingTransfer = true
        
        // Record purchase intent
        if let purchaseType = purchaseType {
            let intent = PurchaseIntent(
                purchaseType: purchaseType,
                category: purchaseType == .planned ? selectedCategory : nil,
                amount: Double(plannedSpend)
            )
            purchaseIntentService.recordIntent(intent)
        }
        
        // Handle transfer based on mode
        do {
            if plaidService.savingsMode == .automatic {
                // Real transfer via Plaid
                _ = try await plaidService.initiateTransfer(amount: plaidService.protectionAmount)
                
                await MainActor.run {
                    let balance = String(format: "%.2f", plaidService.savingsAccount?.balance ?? 0)
                    showConfirmation = "✅ Saved $\(Int(plaidService.protectionAmount))!\nYour savings: $\(balance)\n\nApps unblocked for 15 minutes."
                }
            } else {
                // Virtual savings (no transfer)
                plaidService.recordVirtualSavings(amount: plaidService.protectionAmount)
                
                await MainActor.run {
                    let virtualSavings = String(format: "%.2f", plaidService.virtualSavings)
                    showConfirmation = "✅ Protected $\(Int(plaidService.protectionAmount))!\nVirtual savings: $\(virtualSavings)\n\nConnect a savings account to enable automatic transfers.\n\nApps unblocked for 15 minutes."
                }
            }
            
            // Temporarily unblock apps
            deviceActivityService.temporarilyUnblock(
                durationMinutes: 15,
                purchaseType: purchaseType?.rawValue,
                category: purchaseType == .planned ? selectedCategory?.rawValue : nil,
                mood: currentMood?.rawValue,
                moodNotes: nil,
                appIndex: nil
            )
            
            // Record streak
            streakService.recordProtection()
            
        } catch {
            await MainActor.run {
                showConfirmation = "⚠️ Transfer failed: \(error.localizedDescription)\n\nApps still unblocked for 15 minutes."
            }
        }
        
        await MainActor.run {
            isProcessingTransfer = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
