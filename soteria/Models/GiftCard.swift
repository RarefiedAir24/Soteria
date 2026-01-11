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
    
    // Available gift cards - ALL FREE via Tremendous (no markup, no fees!)
    static let availableCards: [GiftCard] = [
        // TIER 1: Universal & Cash-Like (Most Popular)
        GiftCard(
            id: "visa_5",
            name: "$5 Visa Prepaid Card",
            brand: "Visa",
            amount: 5.00,
            pointsCost: 2500,
            iconName: "creditcard.fill",
            tremendousCampaignId: "VISA_5"
        ),
        GiftCard(
            id: "visa_10",
            name: "$10 Visa Prepaid Card",
            brand: "Visa",
            amount: 10.00,
            pointsCost: 5000,
            iconName: "creditcard.fill",
            tremendousCampaignId: "VISA_10"
        ),
        GiftCard(
            id: "visa_25",
            name: "$25 Visa Prepaid Card",
            brand: "Visa",
            amount: 25.00,
            pointsCost: 12500,
            iconName: "creditcard.fill",
            tremendousCampaignId: "VISA_25"
        ),
        GiftCard(
            id: "visa_50",
            name: "$50 Visa Prepaid Card",
            brand: "Visa",
            amount: 50.00,
            pointsCost: 25000,
            iconName: "creditcard.fill",
            tremendousCampaignId: "VISA_50"
        ),
        GiftCard(
            id: "visa_100",
            name: "$100 Visa Prepaid Card",
            brand: "Visa",
            amount: 100.00,
            pointsCost: 50000,
            iconName: "creditcard.fill",
            tremendousCampaignId: "VISA_100"
        ),
        
        // TIER 2: Top Retail Brands - Amazon
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
            id: "amazon_10",
            name: "$10 Amazon Gift Card",
            brand: "Amazon",
            amount: 10.00,
            pointsCost: 5000,
            iconName: "cart.fill",
            tremendousCampaignId: "AMAZON_10"
        ),
        GiftCard(
            id: "amazon_25",
            name: "$25 Amazon Gift Card",
            brand: "Amazon",
            amount: 25.00,
            pointsCost: 12500,
            iconName: "cart.fill",
            tremendousCampaignId: "AMAZON_25"
        ),
        GiftCard(
            id: "amazon_50",
            name: "$50 Amazon Gift Card",
            brand: "Amazon",
            amount: 50.00,
            pointsCost: 25000,
            iconName: "cart.fill",
            tremendousCampaignId: "AMAZON_50"
        ),
        GiftCard(
            id: "amazon_100",
            name: "$100 Amazon Gift Card",
            brand: "Amazon",
            amount: 100.00,
            pointsCost: 50000,
            iconName: "cart.fill",
            tremendousCampaignId: "AMAZON_100"
        ),
        
        // TIER 2: Top Retail Brands - Target
        GiftCard(
            id: "target_5",
            name: "$5 Target Gift Card",
            brand: "Target",
            amount: 5.00,
            pointsCost: 2500,
            iconName: "target",
            tremendousCampaignId: "TARGET_5"
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
            id: "target_25",
            name: "$25 Target Gift Card",
            brand: "Target",
            amount: 25.00,
            pointsCost: 12500,
            iconName: "target",
            tremendousCampaignId: "TARGET_25"
        ),
        GiftCard(
            id: "target_50",
            name: "$50 Target Gift Card",
            brand: "Target",
            amount: 50.00,
            pointsCost: 25000,
            iconName: "target",
            tremendousCampaignId: "TARGET_50"
        ),
        GiftCard(
            id: "target_100",
            name: "$100 Target Gift Card",
            brand: "Target",
            amount: 100.00,
            pointsCost: 50000,
            iconName: "target",
            tremendousCampaignId: "TARGET_100"
        ),
        
        // TIER 3: Food & Coffee - Starbucks (keep lower denominations)
        GiftCard(
            id: "starbucks_5",
            name: "$5 Starbucks Gift Card",
            brand: "Starbucks",
            amount: 5.00,
            pointsCost: 2500,
            iconName: "cup.and.saucer.fill",
            tremendousCampaignId: "STARBUCKS_5"
        ),
        GiftCard(
            id: "starbucks_10",
            name: "$10 Starbucks Gift Card",
            brand: "Starbucks",
            amount: 10.00,
            pointsCost: 5000,
            iconName: "cup.and.saucer.fill",
            tremendousCampaignId: "STARBUCKS_10"
        ),
        GiftCard(
            id: "starbucks_25",
            name: "$25 Starbucks Gift Card",
            brand: "Starbucks",
            amount: 25.00,
            pointsCost: 12500,
            iconName: "cup.and.saucer.fill",
            tremendousCampaignId: "STARBUCKS_25"
        ),
        
        // TIER 4: Walmart
        GiftCard(
            id: "walmart_5",
            name: "$5 Walmart Gift Card",
            brand: "Walmart",
            amount: 5.00,
            pointsCost: 2500,
            iconName: "bag.fill",
            tremendousCampaignId: "WALMART_5"
        ),
        GiftCard(
            id: "walmart_10",
            name: "$10 Walmart Gift Card",
            brand: "Walmart",
            amount: 10.00,
            pointsCost: 5000,
            iconName: "bag.fill",
            tremendousCampaignId: "WALMART_10"
        ),
        GiftCard(
            id: "walmart_25",
            name: "$25 Walmart Gift Card",
            brand: "Walmart",
            amount: 25.00,
            pointsCost: 12500,
            iconName: "bag.fill",
            tremendousCampaignId: "WALMART_25"
        ),
        GiftCard(
            id: "walmart_50",
            name: "$50 Walmart Gift Card",
            brand: "Walmart",
            amount: 50.00,
            pointsCost: 25000,
            iconName: "bag.fill",
            tremendousCampaignId: "WALMART_50"
        ),
        GiftCard(
            id: "walmart_100",
            name: "$100 Walmart Gift Card",
            brand: "Walmart",
            amount: 100.00,
            pointsCost: 50000,
            iconName: "bag.fill",
            tremendousCampaignId: "WALMART_100"
        )
    ]
    
    // Computed property for display description
    var description: String {
        switch brand {
        case "Visa":
            return "Use anywhere Visa is accepted - works like cash!"
        case "Amazon":
            return "Millions of items to choose from"
        case "Target":
            return "Everything you need, all in one place"
        case "Starbucks":
            return "Your favorite coffee drinks and food"
        case "Walmart":
            return "Save money, live better"
        default:
            return "Redeem for \(brand) purchases"
        }
    }
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
