//
//  SavingsTool.swift
//  soteria
//
//  Model for individual savings tools with tracking data
//

import Foundation

struct SavingsTool: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let monthlySavings: String
    let activationBonus: Int
    let appStoreURL: String
    let setupInstructions: String
    let isComingSoon: Bool
    
    // Tracking data
    var isActivated: Bool = false
    var activatedDate: Date? = nil
    var pointsEarned: Int = 0
    var totalSaved: Double = 0.0
    var usageCount: Int = 0
    var lastUsed: Date? = nil
    var notificationsEnabled: Bool = true
    var trackingEnabled: Bool = true
    
    // MARK: - Static Catalog
    
    static let upside = SavingsTool(
        id: "upside",
        name: "Upside",
        description: "Save 25¢ per gallon on gas at 50,000+ stations nationwide",
        icon: "fuelpump.fill",
        monthlySavings: "$20-40",
        activationBonus: 500,
        appStoreURL: "https://apps.apple.com/us/app/upside-save-on-gas-food/id1452945234",
        setupInstructions: "Sign up with your email and link your payment method",
        isComingSoon: false
    )
    
    static let goodrx = SavingsTool(
        id: "goodrx",
        name: "GoodRx",
        description: "Save up to 80% on prescriptions at 70,000+ pharmacies",
        icon: "pills.fill",
        monthlySavings: "$30-100",
        activationBonus: 500,
        appStoreURL: "https://apps.apple.com/us/app/goodrx-save-on-prescriptions/id485357017",
        setupInstructions: "Search for your medications and show the coupon at your pharmacy",
        isComingSoon: false
    )
    
    static let insurance = SavingsTool(
        id: "insurance",
        name: "Insurance Optimizer",
        description: "Compare rates and save on auto, home, and life insurance",
        icon: "shield.fill",
        monthlySavings: "$50-150",
        activationBonus: 750,
        appStoreURL: "",
        setupInstructions: "Coming soon - automatic insurance rate comparison",
        isComingSoon: true
    )
    
    static let phone = SavingsTool(
        id: "phone",
        name: "Phone Bill Optimizer",
        description: "Reduce your monthly phone bill with better plans",
        icon: "phone.fill",
        monthlySavings: "$20-40",
        activationBonus: 400,
        appStoreURL: "",
        setupInstructions: "Coming soon - personalized plan recommendations",
        isComingSoon: true
    )
    
    static let catalog: [SavingsTool] = [upside, goodrx, insurance, phone]
    
    // MARK: - Mock Data for Previews
    
    static let mockUpside: SavingsTool = {
        var tool = upside
        tool.isActivated = true
        tool.activatedDate = Date().addingTimeInterval(-30 * 24 * 3600) // 30 days ago
        tool.pointsEarned = 2340
        tool.totalSaved = 156.50
        tool.usageCount = 18
        tool.lastUsed = Date().addingTimeInterval(-2 * 24 * 3600) // 2 days ago
        return tool
    }()
    
    static let mockGoodRx: SavingsTool = {
        var tool = goodrx
        tool.isActivated = true
        tool.activatedDate = Date().addingTimeInterval(-15 * 24 * 3600) // 15 days ago
        tool.pointsEarned = 890
        tool.totalSaved = 67.30
        tool.usageCount = 4
        tool.lastUsed = Date().addingTimeInterval(-7 * 24 * 3600) // 1 week ago
        return tool
    }()
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SavingsTool, rhs: SavingsTool) -> Bool {
        return lhs.id == rhs.id
    }
}
