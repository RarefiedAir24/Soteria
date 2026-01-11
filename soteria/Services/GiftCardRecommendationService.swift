//
//  GiftCardRecommendationService.swift
//  soteria
//
//  AI-powered gift card recommendation engine
//  Learns from user behavior and provides personalized suggestions
//

import Foundation
import Combine

class GiftCardRecommendationService: ObservableObject {
    static let shared = GiftCardRecommendationService()
    
    @Published var recommendations: [GiftCard] = []
    @Published var preferredBrands: [String] = []
    @Published var preferredDenominations: [Double] = []
    
    private let userDefaults = UserDefaults.standard
    private let redemptionHistoryKey = "gift_card_redemption_history"
    private let preferencesKey = "gift_card_preferences"
    
    // Tracks redemption history (public for UI access)
    var redemptionHistory: [RedemptionRecord] = []
    
    // User preferences learned from behavior
    private var preferences: UserPreferences = UserPreferences()
    
    private init() {
        loadHistory()
        loadPreferences()
        updateRecommendations()
    }
    
    // MARK: - Public Methods
    
    /// Record a gift card redemption to learn user preferences
    func recordRedemption(_ card: GiftCard) {
        let record = RedemptionRecord(
            cardId: card.id,
            brand: card.brand,
            amount: card.amount,
            timestamp: Date()
        )
        
        redemptionHistory.append(record)
        
        // Keep only last 50 redemptions
        if redemptionHistory.count > 50 {
            redemptionHistory.removeFirst()
        }
        
        saveHistory()
        analyzePreferences()
        updateRecommendations()
    }
    
    /// Record when user views a card (for engagement tracking)
    func recordCardView(_ card: GiftCard) {
        preferences.viewedCards[card.id, default: 0] += 1
        savePreferences()
    }
    
    /// Get personalized recommendations based on user behavior
    func getRecommendations(currentPoints: Int, availableCards: [GiftCard]) -> [GiftCard] {
        var scoredCards: [(card: GiftCard, score: Double)] = []
        
        for card in availableCards {
            let score = calculateRecommendationScore(for: card, currentPoints: currentPoints)
            scoredCards.append((card, score))
        }
        
        // Sort by score and return top recommendations
        return scoredCards
            .sorted { $0.score > $1.score }
            .map { $0.card }
    }
    
    /// Get a personalized insight message for the user
    func getPersonalizedInsight() -> String? {
        guard !redemptionHistory.isEmpty else { return nil }
        
        if let topBrand = preferences.brandFrequency.max(by: { $0.value < $1.value })?.key {
            let count = preferences.brandFrequency[topBrand] ?? 0
            if count >= 3 {
                return "💡 You love \(topBrand)! We've prioritized \(topBrand) cards for you."
            }
        }
        
        if let avgAmount = preferences.averageRedemptionAmount {
            if avgAmount <= 10 {
                return "💡 You prefer smaller denominations. Perfect for frequent treats!"
            } else if avgAmount >= 50 {
                return "💡 You go big! We're showing you premium denominations."
            }
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func analyzePreferences() {
        // Reset preferences
        preferences.brandFrequency.removeAll()
        preferences.denominationFrequency.removeAll()
        
        var totalAmount: Double = 0
        
        for record in redemptionHistory {
            // Track brand frequency
            preferences.brandFrequency[record.brand, default: 0] += 1
            
            // Track denomination frequency
            preferences.denominationFrequency[record.amount, default: 0] += 1
            
            // Calculate average
            totalAmount += record.amount
        }
        
        if !redemptionHistory.isEmpty {
            preferences.averageRedemptionAmount = totalAmount / Double(redemptionHistory.count)
        }
        
        // Identify time-based patterns
        analyzeTimePatterns()
        
        // Update published properties
        preferredBrands = preferences.brandFrequency
            .sorted { $0.value > $1.value }
            .map { $0.key }
        
        preferredDenominations = preferences.denominationFrequency
            .sorted { $0.value > $1.value }
            .map { $0.key }
        
        savePreferences()
    }
    
    private func analyzeTimePatterns() {
        let calendar = Calendar.current
        var timeOfDayRedemptions: [Int: Int] = [:] // Hour: Count
        var dayOfWeekRedemptions: [Int: Int] = [:] // Weekday: Count
        
        for record in redemptionHistory {
            let hour = calendar.component(.hour, from: record.timestamp)
            let weekday = calendar.component(.weekday, from: record.timestamp)
            
            timeOfDayRedemptions[hour, default: 0] += 1
            dayOfWeekRedemptions[weekday, default: 0] += 1
        }
        
        preferences.timeOfDayPattern = timeOfDayRedemptions
        preferences.dayOfWeekPattern = dayOfWeekRedemptions
    }
    
    private func calculateRecommendationScore(for card: GiftCard, currentPoints: Int) -> Double {
        var score: Double = 0
        
        // Base score: Can user afford it?
        if card.pointsCost <= currentPoints {
            score += 100 // High priority for affordable cards
        } else {
            // Lower score for unaffordable cards
            let affordabilityRatio = Double(currentPoints) / Double(card.pointsCost)
            score += affordabilityRatio * 50
        }
        
        // Brand preference (0-50 points)
        let brandRedemptions = preferences.brandFrequency[card.brand] ?? 0
        score += Double(brandRedemptions) * 10
        
        // Denomination preference (0-30 points)
        let denomRedemptions = preferences.denominationFrequency[card.amount] ?? 0
        score += Double(denomRedemptions) * 5
        
        // Average amount preference (0-20 points)
        if let avgAmount = preferences.averageRedemptionAmount {
            let difference = abs(avgAmount - card.amount)
            let similarity = max(0, 1 - (difference / 100))
            score += similarity * 20
        }
        
        // Time-based boost (0-15 points)
        score += getTimeBasedBoost(for: card)
        
        // Popularity boost (cards others redeem) (0-10 points)
        // In the future, this could be based on aggregated user data
        
        // Recency bias: Prefer brands recently redeemed (0-10 points)
        if let lastRedemption = redemptionHistory.last(where: { $0.brand == card.brand }) {
            let daysSince = Date().timeIntervalSince(lastRedemption.timestamp) / 86400
            if daysSince <= 7 {
                score += 10 * (1 - daysSince / 7)
            }
        }
        
        return score
    }
    
    private func getTimeBasedBoost(for card: GiftCard) -> Double {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        let currentWeekday = calendar.component(.weekday, from: Date())
        
        var boost: Double = 0
        
        // Time of day patterns
        if let pattern = preferences.timeOfDayPattern[currentHour], pattern > 0 {
            boost += Double(pattern) * 2
        }
        
        // Day of week patterns
        if let pattern = preferences.dayOfWeekPattern[currentWeekday], pattern > 0 {
            boost += Double(pattern) * 1
        }
        
        // Contextual boosts (smart predictions)
        if card.brand == "Starbucks" && currentHour >= 6 && currentHour <= 10 {
            boost += 5 // Morning coffee boost
        }
        
        if card.brand == "Amazon" && currentWeekday == 1 {
            boost += 3 // Monday shopping boost
        }
        
        if (card.brand == "Target" || card.brand == "Walmart") && (currentWeekday == 6 || currentWeekday == 7) {
            boost += 4 // Weekend shopping boost
        }
        
        return boost
    }
    
    private func updateRecommendations() {
        let allCards = GiftCard.availableCards
        let userPoints = LoyaltyPointsService.shared.totalPoints
        
        recommendations = getRecommendations(currentPoints: userPoints, availableCards: allCards)
            .prefix(6)
            .map { $0 }
    }
    
    // MARK: - Persistence
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(redemptionHistory) {
            userDefaults.set(encoded, forKey: redemptionHistoryKey)
        }
    }
    
    private func loadHistory() {
        if let data = userDefaults.data(forKey: redemptionHistoryKey),
           let decoded = try? JSONDecoder().decode([RedemptionRecord].self, from: data) {
            redemptionHistory = decoded
        }
    }
    
    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            userDefaults.set(encoded, forKey: preferencesKey)
        }
    }
    
    private func loadPreferences() {
        if let data = userDefaults.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            preferences = decoded
        }
    }
}

// MARK: - Data Models

struct RedemptionRecord: Codable {
    let cardId: String
    let brand: String
    let amount: Double
    let timestamp: Date
}

struct UserPreferences: Codable {
    var brandFrequency: [String: Int] = [:]
    var denominationFrequency: [Double: Int] = [:]
    var averageRedemptionAmount: Double?
    var viewedCards: [String: Int] = [:]
    var timeOfDayPattern: [Int: Int] = [:] // Hour: Count
    var dayOfWeekPattern: [Int: Int] = [:] // Weekday: Count
}

// MARK: - Extension for Gift Card Analytics

extension GiftCard {
    /// Get a smart description based on user context
    func getSmartDescription(for preferences: UserPreferences) -> String {
        // Check if user frequently redeems this brand
        if let frequency = preferences.brandFrequency[brand], frequency >= 3 {
            return "⭐ One of your favorites!"
        }
        
        // Check if this matches their average amount
        if let avgAmount = preferences.averageRedemptionAmount,
           abs(avgAmount - amount) <= 5 {
            return "👍 Perfect for you"
        }
        
        // Default description
        return description
    }
}
