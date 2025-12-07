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
                        
                        Text("Take a moment to reflect on your purchase")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Amount Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How much were you about to spend?")
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                            
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
                                Text("Add to savings goal:")
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
                                Text("Skip & Save")
                                    .frame(maxWidth: .infinity)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.1, green: 0.6, blue: 0.3))
                            
                            Button(action: {
                                handleContinueShopping()
                            }) {
                                Text("Continue Shopping")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                handleMarkAsPlanned()
                            }) {
                                Text("Mark as Planned")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            // Log as Regret button
                            Button(action: {
                                showRegretLog = true
                            }) {
                                Text("Log as Regret Purchase")
                                    .frame(maxWidth: .infinity)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal, 32)
                        
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
        
        if amount > 0 {
            savingsService.recordSkipAndSave(amount: amount)
            
            // Add to selected goal if one is selected
            if let goalId = selectedGoalId {
                goalsService.addToGoal(goalId: goalId, amount: amount)
                if let goal = goalsService.goals.first(where: { $0.id == goalId }) {
                    showConfirmation = "Nice! Added \(formattedSavedAmount) to '\(goal.name)'"
                } else {
                    showConfirmation = "Nice! You just saved \(formattedSavedAmount)"
                }
            } else {
                showConfirmation = "Nice! You just saved \(formattedSavedAmount)"
            }
            
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } else {
            showConfirmation = "Please enter an amount to save"
        }
    }
    
    private func handleContinueShopping() {
        // Temporarily unblock apps for 15 minutes
        deviceActivityService.temporarilyUnblock(durationMinutes: 15)
        showConfirmation = "Apps unlocked for 15 minutes. Shop mindfully!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    private func handleMarkAsPlanned() {
        showConfirmation = "No savings recorded this time."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
}
