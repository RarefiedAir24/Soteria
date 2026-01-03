//
//  MicroCommitmentsView.swift
//  soteria
//
//  View for creating and managing daily/weekly savings commitments
//  Feature #5: Micro-Commitment System
//

import SwiftUI

struct MicroCommitmentsView: View {
    @ObservedObject private var commitmentService = MicroCommitmentService.shared
    @ObservedObject private var goalsService = GoalsService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showCreateCommitment = false
    @State private var commitmentType: MicroCommitment.CommitmentType = .daily
    @State private var commitmentAmount: String = ""
    @State private var showCelebration = false
    @State private var celebrationMessage: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Streak Cards
                        streakSection
                        
                        // Active Commitments
                        activeCommitmentsSection
                        
                        // Completed Commitments (Recent)
                        if !commitmentService.completedCommitments.isEmpty {
                            completedCommitmentsSection
                        }
                        
                        // Create New Commitment Button
                        createCommitmentButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("My Commitments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.midnightSlate)
                }
            }
            .sheet(isPresented: $showCreateCommitment) {
                CreateCommitmentView(
                    type: commitmentType,
                    onSave: { type, amount in
                        if let amountValue = Double(amount), amountValue > 0 {
                            switch type {
                            case .daily:
                                _ = commitmentService.createDailyCommitment(amount: amountValue)
                            case .weekly:
                                _ = commitmentService.createWeeklyCommitment(amount: amountValue)
                            case .challenge:
                                _ = commitmentService.createWeeklyChallenge(amount: amountValue)
                            }
                        }
                        showCreateCommitment = false
                    },
                    onCancel: {
                        showCreateCommitment = false
                    }
                )
            }
            .alert("🎉 Commitment Completed!", isPresented: $showCelebration) {
                Button("Awesome!") {
                    showCelebration = false
                }
            } message: {
                Text(celebrationMessage)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CommitmentCompleted"))) { notification in
                if let commitment = notification.object as? MicroCommitment {
                    showCelebration = true
                    if let message = commitmentService.getCelebrationMessage(for: commitment.type) {
                        celebrationMessage = message
                    } else {
                        celebrationMessage = "You completed your \(commitment.type.displayName)! Keep it up! 🔥"
                    }
                }
            }
        }
    }
    
    // MARK: - Streak Section
    
    private var streakSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Daily Streak
                streakCard(
                    title: "Daily Streak",
                    streak: commitmentService.dailyStreak.currentStreak,
                    longestStreak: commitmentService.dailyStreak.longestStreak,
                    emoji: "🔥"
                )
                
                // Weekly Streak
                streakCard(
                    title: "Weekly Streak",
                    streak: commitmentService.weeklyStreak.currentStreak,
                    longestStreak: commitmentService.weeklyStreak.longestStreak,
                    emoji: "⚡️"
                )
            }
        }
    }
    
    private func streakCard(title: String, streak: Int, longestStreak: Int, emoji: String) -> some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 32))
            
            Text("\(streak)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.reverBlue)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            if longestStreak > streak {
                Text("Best: \(longestStreak)")
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    // MARK: - Active Commitments
    
    private var activeCommitmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Commitments")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
            
            if commitmentService.activeCommitments.isEmpty {
                emptyStateView(
                    icon: "target",
                    title: "No Active Commitments",
                    message: "Create a daily or weekly commitment to build your savings habit!"
                )
            } else {
                ForEach(commitmentService.activeCommitments) { commitment in
                    commitmentCard(commitment: commitment)
                }
            }
        }
    }
    
    private func commitmentCard(commitment: MicroCommitment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(commitment.type.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    Text("$\(String(format: "%.2f", commitment.amount))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.reverBlue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Due")
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite)
                    Text(formatDate(commitment.targetDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.midnightSlate)
                }
            }
            
            // Progress indicator
            if let daysUntil = daysUntilTarget(commitment.targetDate) {
                HStack {
                    Text("\(daysUntil) day\(daysUntil == 1 ? "" : "s") remaining")
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.cloudWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    // MARK: - Completed Commitments
    
    private var completedCommitmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Completions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
            
            ForEach(commitmentService.completedCommitments.suffix(5).reversed()) { commitment in
                completedCommitmentCard(commitment: commitment)
            }
        }
    }
    
    private func completedCommitmentCard(commitment: MicroCommitment) -> some View {
        HStack {
            Image(systemName: commitment.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(commitment.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(commitment.type.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.midnightSlate)
                
                Text("$\(String(format: "%.2f", commitment.amount))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.softGraphite)
            }
            
            Spacer()
            
            if let completedDate = commitment.completedDate {
                Text(formatDate(completedDate))
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite)
            }
        }
        .padding(12)
        .background(Color.dreamMist)
        .cornerRadius(12)
    }
    
    // MARK: - Create Button
    
    private var createCommitmentButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                commitmentType = .daily
                showCreateCommitment = true
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Create Daily Commitment")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.reverBlue)
                .cornerRadius(12)
            }
            
            Button(action: {
                commitmentType = .weekly
                showCreateCommitment = true
            }) {
                HStack {
                    Image(systemName: "calendar")
                    Text("Create Weekly Commitment")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.reverBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.reverBlue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.softGraphite.opacity(0.5))
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.midnightSlate)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.softGraphite)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    // MARK: - Helper Functions
    
    private func daysUntilTarget(_ date: Date) -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: target).day
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Create Commitment View

struct CreateCommitmentView: View {
    let type: MicroCommitment.CommitmentType
    let onSave: (MicroCommitment.CommitmentType, String) -> Void
    let onCancel: () -> Void
    
    @State private var amount: String = ""
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Create \(type.displayName)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        Text(type == .daily ? "Commit to saving a small amount every day" : "Commit to saving a specific amount this week")
                            .font(.system(size: 16))
                            .foregroundColor(.softGraphite)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Amount")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.softGraphite)
                        
                        HStack {
                            Text("$")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.reverBlue)
                            TextField("0.00", text: $amount)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.midnightSlate)
                                .keyboardType(.decimalPad)
                                .focused($isAmountFocused)
                        }
                        .padding(20)
                        .background(Color.cloudWhite)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        onSave(type, amount)
                    }) {
                        Text("Create Commitment")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isValidAmount ? Color.reverBlue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isValidAmount)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.midnightSlate)
                }
            }
            .onAppear {
                isAmountFocused = true
            }
        }
    }
    
    private var isValidAmount: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return true
    }
}

#Preview {
    MicroCommitmentsView()
}

