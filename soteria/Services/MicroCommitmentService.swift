//
//  MicroCommitmentService.swift
//  soteria
//
//  Micro-Commitment System: Daily and weekly savings commitments with streak tracking
//  Builds excitement and focus on goals through small, frequent wins
//

import Foundation
import Combine

struct MicroCommitment: Identifiable, Codable {
    let id: String
    var type: CommitmentType
    var amount: Double
    var targetDate: Date // When the commitment should be completed
    var completedDate: Date? // When it was actually completed
    var isCompleted: Bool
    var createdAt: Date
    
    enum CommitmentType: String, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case challenge = "challenge" // Special weekly challenges
        
        var displayName: String {
            switch self {
            case .daily: return "Daily Commitment"
            case .weekly: return "Weekly Commitment"
            case .challenge: return "Weekly Challenge"
            }
        }
    }
    
    init(id: String = UUID().uuidString,
         type: CommitmentType,
         amount: Double,
         targetDate: Date,
         completedDate: Date? = nil,
         isCompleted: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.amount = amount
        self.targetDate = targetDate
        self.completedDate = completedDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

struct CommitmentStreak: Codable {
    var currentStreak: Int // Days/weeks in a row
    var longestStreak: Int // Best streak ever
    var lastCompletedDate: Date? // Last time a commitment was completed
    var totalCommitmentsCompleted: Int // Total count
    var totalAmountCommitted: Double // Total amount from all commitments
    
    init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastCompletedDate = nil
        self.totalCommitmentsCompleted = 0
        self.totalAmountCommitted = 0
    }
}

class MicroCommitmentService: ObservableObject {
    static let shared = MicroCommitmentService()
    
    @Published var activeCommitments: [MicroCommitment] = []
    @Published var completedCommitments: [MicroCommitment] = []
    @Published var dailyStreak: CommitmentStreak = CommitmentStreak()
    @Published var weeklyStreak: CommitmentStreak = CommitmentStreak()
    
    private let activeCommitmentsKey = "micro_commitments_active"
    private let completedCommitmentsKey = "micro_commitments_completed"
    private let dailyStreakKey = "micro_commitment_daily_streak"
    private let weeklyStreakKey = "micro_commitment_weekly_streak"
    
    private init() {
        loadData()
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        // Load active commitments
        if let data = UserDefaults.standard.data(forKey: activeCommitmentsKey),
           let commitments = try? JSONDecoder().decode([MicroCommitment].self, from: data) {
            activeCommitments = commitments
        }
        
        // Load completed commitments
        if let data = UserDefaults.standard.data(forKey: completedCommitmentsKey),
           let commitments = try? JSONDecoder().decode([MicroCommitment].self, from: data) {
            completedCommitments = commitments
        }
        
        // Load streaks
        if let data = UserDefaults.standard.data(forKey: dailyStreakKey),
           let streak = try? JSONDecoder().decode(CommitmentStreak.self, from: data) {
            dailyStreak = streak
        }
        
        if let data = UserDefaults.standard.data(forKey: weeklyStreakKey),
           let streak = try? JSONDecoder().decode(CommitmentStreak.self, from: data) {
            weeklyStreak = streak
        }
        
        // Clean up expired commitments
        cleanupExpiredCommitments()
    }
    
    private func saveData() {
        // Save active commitments
        if let data = try? JSONEncoder().encode(activeCommitments) {
            UserDefaults.standard.set(data, forKey: activeCommitmentsKey)
        }
        
        // Save completed commitments
        if let data = try? JSONEncoder().encode(completedCommitments) {
            UserDefaults.standard.set(data, forKey: completedCommitmentsKey)
        }
        
        // Save streaks
        if let data = try? JSONEncoder().encode(dailyStreak) {
            UserDefaults.standard.set(data, forKey: dailyStreakKey)
        }
        
        if let data = try? JSONEncoder().encode(weeklyStreak) {
            UserDefaults.standard.set(data, forKey: weeklyStreakKey)
        }
    }
    
    // MARK: - Commitment Management
    
    /// Create a daily commitment
    func createDailyCommitment(amount: Double) -> MicroCommitment {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        
        let commitment = MicroCommitment(
            type: .daily,
            amount: amount,
            targetDate: tomorrow
        )
        
        activeCommitments.append(commitment)
        saveData()
        
        print("✅ [MicroCommitmentService] Created daily commitment: $\(amount)")
        return commitment
    }
    
    /// Create a weekly commitment
    func createWeeklyCommitment(amount: Double) -> MicroCommitment {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        
        let commitment = MicroCommitment(
            type: .weekly,
            amount: amount,
            targetDate: nextWeek
        )
        
        activeCommitments.append(commitment)
        saveData()
        
        print("✅ [MicroCommitmentService] Created weekly commitment: $\(amount)")
        return commitment
    }
    
    /// Create a weekly challenge (special commitment)
    func createWeeklyChallenge(amount: Double, days: Int = 7) -> MicroCommitment {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let challengeEnd = calendar.date(byAdding: .day, value: days, to: today) ?? today
        
        let commitment = MicroCommitment(
            type: .challenge,
            amount: amount,
            targetDate: challengeEnd
        )
        
        activeCommitments.append(commitment)
        saveData()
        
        print("✅ [MicroCommitmentService] Created weekly challenge: $\(amount) for \(days) days")
        return commitment
    }
    
    /// Complete a commitment (called when user makes a deposit)
    func completeCommitment(_ commitmentId: String, depositAmount: Double) {
        guard let index = activeCommitments.firstIndex(where: { $0.id == commitmentId }) else {
            return
        }
        
        var commitment = activeCommitments[index]
        
        // Check if deposit amount meets or exceeds commitment
        guard depositAmount >= commitment.amount else {
            print("⚠️ [MicroCommitmentService] Deposit amount \(depositAmount) is less than commitment \(commitment.amount)")
            return
        }
        
        commitment.isCompleted = true
        commitment.completedDate = Date()
        
        // Move to completed
        completedCommitments.append(commitment)
        activeCommitments.remove(at: index)
        
        // Update streak
        updateStreak(for: commitment.type)
        
        saveData()
        
        print("✅ [MicroCommitmentService] Completed commitment: \(commitmentId), amount: $\(depositAmount)")
    }
    
    /// Get today's active daily commitment
    func getTodaysDailyCommitment() -> MicroCommitment? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return activeCommitments.first { commitment in
            commitment.type == .daily &&
            !commitment.isCompleted &&
            calendar.isDate(commitment.targetDate, inSameDayAs: today) ||
            calendar.isDate(commitment.targetDate, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: today) ?? today)
        }
    }
    
    /// Get this week's active weekly commitment
    func getThisWeeksCommitment() -> MicroCommitment? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        
        return activeCommitments.first { commitment in
            (commitment.type == .weekly || commitment.type == .challenge) &&
            !commitment.isCompleted &&
            commitment.targetDate <= nextWeek
        }
    }
    
    // MARK: - Streak Management
    
    private func updateStreak(for type: MicroCommitment.CommitmentType) {
        let streak: CommitmentStreak
        
        switch type {
        case .daily:
            streak = dailyStreak
        case .weekly, .challenge:
            streak = weeklyStreak
        }
        
        var updatedStreak = streak
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastDate = streak.lastCompletedDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if type == .daily {
                if daysSince == 0 {
                    // Same day - don't increment
                    return
                } else if daysSince == 1 {
                    // Consecutive day
                    updatedStreak.currentStreak += 1
                } else {
                    // Streak broken
                    updatedStreak.currentStreak = 1
                }
            } else {
                // Weekly commitment
                let weeksSince = daysSince / 7
                if weeksSince == 0 {
                    // Same week
                    return
                } else if weeksSince == 1 {
                    // Consecutive week
                    updatedStreak.currentStreak += 1
                } else {
                    // Streak broken
                    updatedStreak.currentStreak = 1
                }
            }
        } else {
            // First commitment
            updatedStreak.currentStreak = 1
        }
        
        updatedStreak.lastCompletedDate = today
        updatedStreak.totalCommitmentsCompleted += 1
        
        // Update longest streak
        if updatedStreak.currentStreak > updatedStreak.longestStreak {
            updatedStreak.longestStreak = updatedStreak.currentStreak
        }
        
        // Save updated streak
        switch type {
        case .daily:
            dailyStreak = updatedStreak
        case .weekly, .challenge:
            weeklyStreak = updatedStreak
        }
        
        saveData()
    }
    
    // MARK: - Cleanup
    
    private func cleanupExpiredCommitments() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Move expired commitments to completed (as failed)
        let expired = activeCommitments.filter { commitment in
            !commitment.isCompleted && commitment.targetDate < today
        }
        
        for var commitment in expired {
            commitment.isCompleted = false // Mark as failed
            completedCommitments.append(commitment)
        }
        
        activeCommitments.removeAll { commitment in
            !commitment.isCompleted && commitment.targetDate < today
        }
        
        if !expired.isEmpty {
            saveData()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get streak message for display
    func getStreakMessage(for type: MicroCommitment.CommitmentType) -> String {
        let streak = type == .daily ? dailyStreak : weeklyStreak
        
        if streak.currentStreak == 0 {
            return type == .daily ? "Start your daily commitment streak!" : "Start your weekly commitment streak!"
        } else if streak.currentStreak == 1 {
            return type == .daily ? "1 day commitment streak 🔥" : "1 week commitment streak 🔥"
        } else {
            return type == .daily ? "\(streak.currentStreak) day commitment streak 🔥" : "\(streak.currentStreak) week commitment streak 🔥"
        }
    }
    
    /// Get celebration message for milestones
    func getCelebrationMessage(for type: MicroCommitment.CommitmentType) -> String? {
        let streak = type == .daily ? dailyStreak : weeklyStreak
        
        switch streak.currentStreak {
        case 7:
            return "🎉 Amazing! 7 day streak!"
        case 14:
            return "🌟 Incredible! 2 weeks strong!"
        case 30:
            return "🏆 Unstoppable! 30 days!"
        case 100:
            return "👑 Legendary! 100 days!"
        default:
            return nil
        }
    }
}

