//
//  StreakService.swift
//  soteria
//
//  Tracks protection streaks (days without unblocking)
//

import Foundation
import Combine

class StreakService: ObservableObject {
    static let shared = StreakService()
    
    @Published var currentStreak: Int = 0 // Days in a row without unblocking
    @Published var longestStreak: Int = 0 // Best streak ever
    @Published var lastProtectionDate: Date? = nil // Last time user chose protection
    
    private let streakKey = "protection_streak"
    private let longestStreakKey = "longest_streak"
    private let lastProtectionKey = "last_protection_date"
    
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
        guard currentStreak == 0 && longestStreak == 0 && lastProtectionDate == nil else { return }
        loadStreakData()
        updateStreak()
    }
    
    // Load streak data from UserDefaults
    private func loadStreakData() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
        
        if let dateData = UserDefaults.standard.object(forKey: lastProtectionKey) as? Date {
            lastProtectionDate = dateData
        }
    }
    
    // Save streak data to UserDefaults
    private func saveStreakData() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        if let date = lastProtectionDate {
            UserDefaults.standard.set(date, forKey: lastProtectionKey)
        }
    }
    
    // Record a protection moment (user chose protection)
    func recordProtection() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = lastProtectionDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysSince = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysSince == 0 {
                // Same day - don't increment streak
                return
            } else if daysSince == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else {
                // Streak broken - reset to 1
                currentStreak = 1
            }
        } else {
            // First protection ever
            currentStreak = 1
        }
        
        lastProtectionDate = today
        
        // Update longest streak if needed
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        saveStreakData()
    }
    
    // Record an unblock (user unblocked and shopped)
    func recordUnblock() {
        // Check if streak should be broken
        updateStreak()
        
        // If unblock happened today and we had a streak, break it
        if let lastDate = lastProtectionDate {
            let today = Calendar.current.startOfDay(for: Date())
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            
            if Calendar.current.isDate(today, inSameDayAs: lastDay) {
                // Unblock happened on same day as last protection
                // Don't break streak yet (might have protected earlier today)
                return
            }
        }
        
        // If last protection was yesterday or earlier, and we unblock today, streak is broken
        // This will be handled by updateStreak() on next app launch
    }
    
    // Update streak based on time elapsed (call on app launch)
    func updateStreak() {
        guard let lastDate = lastProtectionDate else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let daysSince = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
        
        if daysSince > 1 {
            // More than 1 day since last protection - streak is broken
            currentStreak = 0
            saveStreakData()
        }
    }
    
    // Get streak message for display
    var streakMessage: String {
        if currentStreak == 0 {
            return "Start your protection streak today!"
        } else if currentStreak == 1 {
            return "1 day protecting your goals"
        } else {
            return "\(currentStreak) days protecting your goals"
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

