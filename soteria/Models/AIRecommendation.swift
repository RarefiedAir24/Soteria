//
//  AIRecommendation.swift
//  soteria
//
//  AI-generated recommendations for improving savings outcomes
//  Privacy-first, non-judgmental, optional
//

import Foundation

/// Base protocol for all AI recommendations
protocol AIRecommendation: Identifiable {
    var id: String { get }
    var type: RecommendationType { get }
    var confidence: Double { get } // 0.0 to 1.0
    var createdAt: Date { get }
}

enum RecommendationType: String, Codable {
    case timingRecommendation = "timing_recommendation"
    case amountSuggestion = "amount_suggestion"
    case copyVariant = "copy_variant"
    case weeklyReflection = "weekly_reflection"
}

enum RecommendationReasonCode: String, Codable {
    // Timing reasons
    case higherEngagement = "HIGHER_ENGAGEMENT"
    case lowNotificationFatigue = "LOW_NOTIFICATION_FATIGUE"
    case moreSuccessfulSaves = "MORE_SUCCESSFUL_SAVES"
    
    // Amount reasons
    case recentFollowThrough = "RECENT_FOLLOW_THROUGH"
    case recentFailedTransfers = "RECENT_FAILED_TRANSFERS"
    case lowEngagement = "LOW_ENGAGEMENT"
    case consistentSavingPattern = "CONSISTENT_SAVING_PATTERN" // Avoid "streak" word
}

/// User-facing copy for recommendations
struct UserFacingCopy: Codable {
    var title: String
    var body: String
    var header: String?
    var helper: String?
}

/// Timing recommendation - suggests moving a Decision Window to a better time
struct TimingRecommendation: AIRecommendation, Codable {
    let id: String
    let type: RecommendationType
    let windowId: String
    let recommendedTime: String // "HH:mm" format
    let confidence: Double
    let reasonCode: RecommendationReasonCode
    let userFacingCopy: UserFacingCopy
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         windowId: String,
         recommendedTime: String,
         confidence: Double,
         reasonCode: RecommendationReasonCode,
         userFacingCopy: UserFacingCopy,
         createdAt: Date = Date()) {
        self.id = id
        self.type = .timingRecommendation
        self.windowId = windowId
        self.recommendedTime = recommendedTime
        self.confidence = confidence
        self.reasonCode = reasonCode
        self.userFacingCopy = userFacingCopy
        self.createdAt = createdAt
    }
}

/// Amount suggestion - suggests micro-save amounts likely to succeed
struct AmountSuggestion: AIRecommendation, Codable {
    let id: String
    let type: RecommendationType
    let windowId: String
    let suggestedAmounts: [Double] // Discrete set: [1, 2, 3, 5, 10] + custom
    let defaultAmount: Double
    let confidence: Double
    let reasonCode: RecommendationReasonCode
    let userFacingCopy: UserFacingCopy
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         windowId: String,
         suggestedAmounts: [Double],
         defaultAmount: Double,
         confidence: Double,
         reasonCode: RecommendationReasonCode,
         userFacingCopy: UserFacingCopy,
         createdAt: Date = Date()) {
        self.id = id
        self.type = .amountSuggestion
        self.windowId = windowId
        self.suggestedAmounts = suggestedAmounts
        self.defaultAmount = defaultAmount
        self.confidence = confidence
        self.reasonCode = reasonCode
        self.userFacingCopy = userFacingCopy
        self.createdAt = createdAt
    }
}

/// Copy variant selection - chooses which notification copy performs best
enum CopyVariantId: String, Codable {
    case aMomentForToday = "A_MOMENT_FOR_TODAY"
    case saveFirst = "SAVE_FIRST"
    case takeAPause = "TAKE_A_PAUSE"
    case protectYourMoney = "PROTECT_YOUR_MONEY"
    case beforeDayEnds = "BEFORE_DAY_ENDS"
}

struct CopyVariantRecommendation: AIRecommendation, Codable {
    let id: String
    let type: RecommendationType
    let variantId: CopyVariantId
    let confidence: Double
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         variantId: CopyVariantId,
         confidence: Double,
         createdAt: Date = Date()) {
        self.id = id
        self.type = .copyVariant
        self.variantId = variantId
        self.confidence = confidence
        self.createdAt = createdAt
    }
}

/// Weekly reflection (Phase 2) - 1x/week insight
struct WeeklyReflection: AIRecommendation, Codable {
    let id: String
    let type: RecommendationType
    let weekOf: Date
    let userFacingCopy: UserFacingCopy
    let recommendations: [TimingRecommendation]
    let confidence: Double
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         weekOf: Date,
         userFacingCopy: UserFacingCopy,
         recommendations: [TimingRecommendation] = [],
         confidence: Double,
         createdAt: Date = Date()) {
        self.id = id
        self.type = .weeklyReflection
        self.weekOf = weekOf
        self.userFacingCopy = userFacingCopy
        self.recommendations = recommendations
        self.confidence = confidence
        self.createdAt = createdAt
    }
}

