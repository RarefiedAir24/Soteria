//
//  MissedPointsTracker.swift
//  soteria
//
//  Tracks loyalty points that free users would have earned
//  Used to create FOMO and drive premium conversions
//

import Foundation
import Combine

class MissedPointsTracker: ObservableObject {
    static let shared = MissedPointsTracker()
    
    @Published var missedPoints: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let missedPointsKey = "missed_points_as_free_user"
    
    init() {
        loadMissedPoints()
    }
    
    // MARK: - Track Missed Points
    
    /// Track points that a free user would have earned if they were premium
    func trackMissedPoints(_ points: Int, action: String) {
        guard !SubscriptionService.shared.isPremium else {
            // Don't track if user is premium
            return
        }
        
        missedPoints += points
        saveMissedPoints()
        
        print("📊 [MissedPoints] Free user missed \(points) points for: \(action)")
        print("📊 [MissedPoints] Total missed: \(missedPoints) points")
        
        // Show periodic reminders (every 200 points)
        if missedPoints > 0 && missedPoints % 200 == 0 {
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowMissedPointsReminder"),
                object: ["missedPoints": missedPoints]
            )
        }
        
        // Show major milestone reminders
        if missedPoints >= 2500 && missedPoints < 2600 {
            // They've missed enough for a $5 gift card!
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowMissedGiftCardReminder"),
                object: ["cardValue": 5.0, "missedPoints": missedPoints]
            )
        }
    }
    
    // MARK: - Clear Missed Points
    
    /// Clear missed points when user upgrades to premium
    func clearMissedPoints() {
        print("✅ [MissedPoints] Clearing missed points (user upgraded to premium)")
        missedPoints = 0
        saveMissedPoints()
    }
    
    // MARK: - Conversion Messages
    
    /// Get a contextual message about missed points
    func getConversionMessage() -> String? {
        guard missedPoints > 0 else { return nil }
        
        if missedPoints >= 12500 {
            return "You've missed enough points for a $25 Visa gift card! 😱"
        } else if missedPoints >= 7500 {
            return "You've missed enough points for a $15 Starbucks card! ☕"
        } else if missedPoints >= 5000 {
            return "You've missed enough points for a $10 Target card! 🎯"
        } else if missedPoints >= 2500 {
            return "You've missed enough points for a $5 Amazon card! 🎁"
        } else if missedPoints >= 1000 {
            let remaining = 2500 - missedPoints
            return "Just \(remaining) more missed points until you could have had a $5 gift card"
        } else {
            return "Premium members earn loyalty points with every save"
        }
    }
    
    // MARK: - Progress to Next Card
    
    /// Calculate progress toward next gift card threshold
    func progressToNextCard() -> (current: Int, target: Int, percentage: Double) {
        let thresholds = [2500, 5000, 7500, 12500]
        
        for threshold in thresholds {
            if missedPoints < threshold {
                let percentage = Double(missedPoints) / Double(threshold)
                return (missedPoints, threshold, percentage)
            }
        }
        
        // Already exceeded all thresholds
        return (missedPoints, 12500, 1.0)
    }
    
    // MARK: - Persistence
    
    private func saveMissedPoints() {
        userDefaults.set(missedPoints, forKey: missedPointsKey)
    }
    
    private func loadMissedPoints() {
        missedPoints = userDefaults.integer(forKey: missedPointsKey)
        print("📊 [MissedPoints] Loaded: \(missedPoints) missed points")
    }
}
