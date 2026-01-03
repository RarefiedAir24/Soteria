//
//  StreakService.swift
//  soteria
//
//  Tracks savings streaks (days in a row with savings deposits)
//

import Foundation
import Combine

class StreakService: ObservableObject {
    static let shared = StreakService()
    
    @Published var currentStreak: Int = 0 // Days in a row with savings deposits
    @Published var longestStreak: Int = 0 // Best streak ever
    @Published var lastSavingsDate: Date? = nil // Last time user made a savings deposit
    
    private let streakKey = "savings_streak"
    private let longestStreakKey = "longest_savings_streak"
    private let lastSavingsKey = "last_savings_date"
    
    private init() {
        let initStart = Date()
        print("✅ [StreakService] Init started at \(initStart) (truly lazy - no work on startup)")
        // STREAMLINED: Do absolutely nothing on startup
        // Data will be loaded on-demand when user accesses streak features
        // This eliminates blocking UserDefaults reads and Calendar calculations during app launch
        let initEnd = Date()
        print("✅ [StreakService] Initialized at \(initEnd) (total: \(initEnd.timeIntervalSince(initStart))s)")
        
        // Defer all work to background task with delay
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            // Wait 30 seconds to ensure app is fully loaded and responsive
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            await MainActor.run {
                self.loadStreakData()
                self.updateStreak()
                print("✅ [StreakService] Data loaded and streak updated")
            }
        }
    }
    
    // Ensure data is loaded (call on-demand)
    func ensureDataLoaded() {
        // Only load if not already loaded
        guard currentStreak == 0 && longestStreak == 0 && lastSavingsDate == nil else { return }
        loadStreakData()
        updateStreak()
    }
    
    // Load streak data from UserDefaults
    private func loadStreakData() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
        
        if let dateData = UserDefaults.standard.object(forKey: lastSavingsKey) as? Date {
            lastSavingsDate = dateData
        }
    }
    
    // Save streak data to UserDefaults
    private func saveStreakData() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        if let date = lastSavingsDate {
            UserDefaults.standard.set(date, forKey: lastSavingsKey)
        }
    }
    
    // Record a savings deposit (user made a deposit - manual, plaid, or virtual)
    func recordSavings() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = lastSavingsDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysSince = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysSince == 0 {
                // Same day - don't increment streak (already saved today)
                // But ensure streak is at least 1 if it's 0
                if currentStreak == 0 {
                    currentStreak = 1
                }
                return
            } else if daysSince == 1 {
                // Consecutive day - increment streak
                // The first day already counts as day 1, so we increment for the new day
                currentStreak += 1
            } else {
                // Streak broken - reset to 1 (the day you make the initial save counts as day 1)
                currentStreak = 1
            }
        } else {
            // First savings deposit ever - the day you make the initial save counts as day 1
            currentStreak = 1
        }
        
        lastSavingsDate = today
        
        // Update longest streak if needed
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        saveStreakData()
        print("✅ [StreakService] Recorded savings deposit - streak: \(currentStreak) days, lastDate: \(lastSavingsDate?.description ?? "nil")")
    }
    
    // Update streak based on time elapsed (call on app launch)
    // If more than 1 day has passed since last savings, streak is broken
    func updateStreak() {
        guard let lastDate = lastSavingsDate else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let daysSince = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
        
        if daysSince > 1 {
            // More than 1 day since last savings - streak is broken
            currentStreak = 0
            saveStreakData()
            print("⚠️ [StreakService] Streak broken - \(daysSince) days since last savings")
        }
    }
    
    // Get streak message for display
    var streakMessage: String {
        if currentStreak == 0 {
            return "Start your savings streak today!"
        } else if currentStreak == 1 {
            return "1 day saving"
        } else {
            return "\(currentStreak) days saving"
        }
    }
    
    // Get streak emoji based on length
    var streakEmoji: String {
        switch currentStreak {
        case 0: return "🌱"
        case 1...6: return "🔥"
        case 7...13: return "⚡️"
        case 14...29: return "💎"
        default: return "👑"
        }
    }
}

