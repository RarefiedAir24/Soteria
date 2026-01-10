//
//  GiftCard.swift
//  soteria
//
//  Gift card models for loyalty rewards system
//

import Foundation

// MARK: - Gift Card Definition
struct GiftCard: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let brand: String // "Amazon", "Target", "Starbucks", "Visa"
    let amount: Double // 5.00, 10.00, 15.00, 25.00
    let pointsCost: Int
    let iconName: String // SF Symbol
    let tremendousCampaignId: String // Maps to Tremendous API campaign
    
    // Available gift cards
    static let availableCards: [GiftCard] = [
        GiftCard(
            id: "amazon_5",
            name: "$5 Amazon Gift Card",
            brand: "Amazon",
            amount: 5.00,
            pointsCost: 2500,
            iconName: "cart.fill",
            tremendousCampaignId: "AMAZON_5"
        ),
        GiftCard(
            id: "target_10",
            name: "$10 Target Gift Card",
            brand: "Target",
            amount: 10.00,
            pointsCost: 5000,
            iconName: "target",
            tremendousCampaignId: "TARGET_10"
        ),
        GiftCard(
            id: "starbucks_15",
            name: "$15 Starbucks Gift Card",
            brand: "Starbucks",
            amount: 15.00,
            pointsCost: 7500,
            iconName: "cup.and.saucer.fill",
            tremendousCampaignId: "STARBUCKS_15"
        ),
        GiftCard(
            id: "visa_25",
            name: "$25 Visa Gift Card",
            brand: "Visa",
            amount: 25.00,
            pointsCost: 12500,
            iconName: "creditcard.fill",
            tremendousCampaignId: "VISA_25"
        )
    ]
}

// MARK: - Gift Card Redemption
struct GiftCardRedemption: Identifiable, Codable {
    let id: String
    let userId: String
    let giftCardId: String
    let brand: String
    let amount: Double
    let pointsSpent: Int
    let redemptionDate: Date
    let redemptionCode: String?
    let redemptionLink: String?
    let status: RedemptionStatus
    let tremendousOrderId: String?
    
    enum RedemptionStatus: String, Codable {
        case pending = "pending"
        case delivered = "delivered"
        case failed = "failed"
    }
    
    // Format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: redemptionDate)
    }
}
