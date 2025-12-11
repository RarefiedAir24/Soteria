//
//  PurchaseIntentService.swift
//  soteria
//
//  Tracks purchase intentions (planned vs impulse) with categories
//

import Foundation
import Combine

enum PurchaseType: String, Codable {
    case planned = "planned"
    case impulse = "impulse"
    
    var displayName: String {
        switch self {
        case .planned: return "Planned Purchase"
        case .impulse: return "Impulse Purchase"
        }
    }
}

enum PlannedPurchaseCategory: String, Codable, CaseIterable {
    case event = "event"
    case birthday = "birthday"
    case anniversary = "anniversary"
    case holiday = "holiday"
    case giftShopping = "gift_shopping"
    case necessity = "necessity"
    case replacement = "replacement"
    case plannedExpense = "planned_expense"
    case subscription = "subscription"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .event: return "Event"
        case .birthday: return "Birthday"
        case .anniversary: return "Anniversary"
        case .holiday: return "Holiday"
        case .giftShopping: return "Gift Shopping"
        case .necessity: return "Necessity"
        case .replacement: return "Replacement Item"
        case .plannedExpense: return "Planned Expense"
        case .subscription: return "Subscription"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .event: return "calendar.badge.clock"
        case .birthday: return "birthday.cake.fill"
        case .anniversary: return "heart.fill"
        case .holiday: return "gift.fill"
        case .giftShopping: return "gift.fill"
        case .necessity: return "checkmark.circle.fill"
        case .replacement: return "arrow.triangle.2.circlepath"
        case .plannedExpense: return "calendar"
        case .subscription: return "repeat"
        case .other: return "ellipsis.circle"
        }
    }
}

enum ImpulseMood: String, Codable, CaseIterable {
    case lonely = "lonely"
    case bored = "bored"
    case stressed = "stressed"
    case depressed = "depressed"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .lonely: return "Lonely"
        case .bored: return "Bored"
        case .stressed: return "Stressed"
        case .depressed: return "Depressed"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .lonely: return "person.fill.xmark"
        case .bored: return "face.dashed"
        case .stressed: return "exclamationmark.triangle.fill"
        case .depressed: return "cloud.rain.fill"
        case .other: return "ellipsis.circle"
        }
    }
}

struct PurchaseIntent: Identifiable, Codable {
    let id: String
    var date: Date
    var purchaseType: PurchaseType
    var category: PlannedPurchaseCategory?
    var impulseMood: ImpulseMood?
    var impulseMoodNotes: String? // Free text for "other" mood or additional notes
    var amount: Double?
    var appName: String?
    var notes: String?
    
    init(id: String = UUID().uuidString, 
         date: Date = Date(), 
         purchaseType: PurchaseType, 
         category: PlannedPurchaseCategory? = nil,
         impulseMood: ImpulseMood? = nil,
         impulseMoodNotes: String? = nil,
         amount: Double? = nil,
         appName: String? = nil,
         notes: String? = nil) {
        self.id = id
        self.date = date
        self.purchaseType = purchaseType
        self.category = category
        self.impulseMood = impulseMood
        self.impulseMoodNotes = impulseMoodNotes
        self.amount = amount
        self.appName = appName
        self.notes = notes
    }
}

class PurchaseIntentService: ObservableObject {
    static let shared = PurchaseIntentService()
    
    @Published var purchaseIntents: [PurchaseIntent] = []
    @Published var useAWS: Bool = false // Toggle to enable/disable AWS sync
    
    private let purchaseIntentsKey = "purchase_intents"
    private let awsDataService = AWSDataService.shared
    
    private init() {
        loadData()
    }
    
    // Load data from UserDefaults or AWS
    private func loadData() {
        // Try AWS first if enabled
        if useAWS {
            Task {
                do {
                    let awsData: [PurchaseIntent] = try await awsDataService.getData(dataType: .purchaseIntents)
                    await MainActor.run {
                        self.purchaseIntents = awsData
                        // Also save to UserDefaults as cache
                        if let encoded = try? JSONEncoder().encode(awsData) {
                            UserDefaults.standard.set(encoded, forKey: self.purchaseIntentsKey)
                        }
                    }
                    print("✅ [PurchaseIntentService] Purchase intents loaded from AWS")
                    return
                } catch {
                    print("⚠️ [PurchaseIntentService] Failed to load purchase intents from AWS: \(error.localizedDescription)")
                    // Fall through to UserDefaults
                }
            }
        }
        
        // Fallback to UserDefaults
        if let data = UserDefaults.standard.data(forKey: purchaseIntentsKey),
           let decoded = try? JSONDecoder().decode([PurchaseIntent].self, from: data) {
            purchaseIntents = decoded
        }
    }
    
    // Save data to UserDefaults and AWS
    private func saveData() {
        // Save to UserDefaults (always, as fallback)
        if let encoded = try? JSONEncoder().encode(purchaseIntents) {
            UserDefaults.standard.set(encoded, forKey: purchaseIntentsKey)
        }
        
        // Sync to AWS if enabled
        if useAWS {
            Task {
                do {
                    try await awsDataService.batchSync(purchaseIntents, dataType: .purchaseIntents)
                    print("✅ [PurchaseIntentService] Purchase intents synced to AWS")
                } catch {
                    print("⚠️ [PurchaseIntentService] Failed to sync purchase intents to AWS: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Record a purchase intent
    func recordIntent(_ intent: PurchaseIntent) {
        purchaseIntents.append(intent)
        saveData()
        print("📝 [PurchaseIntentService] Recorded \(intent.purchaseType.displayName) purchase intent")
    }
    
    // Get purchase intents for a date range
    func getIntents(from startDate: Date, to endDate: Date) -> [PurchaseIntent] {
        return purchaseIntents.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    // Get planned vs impulse statistics
    func getStatistics() -> (planned: Int, impulse: Int, plannedPercentage: Double) {
        let planned = purchaseIntents.filter { $0.purchaseType == .planned }.count
        let impulse = purchaseIntents.filter { $0.purchaseType == .impulse }.count
        let total = planned + impulse
        let plannedPercentage = total > 0 ? Double(planned) / Double(total) * 100.0 : 0.0
        return (planned, impulse, plannedPercentage)
    }
    
    // Get category breakdown for planned purchases
    func getCategoryBreakdown() -> [PlannedPurchaseCategory: Int] {
        var breakdown: [PlannedPurchaseCategory: Int] = [:]
        for intent in purchaseIntents where intent.purchaseType == .planned {
            if let category = intent.category {
                breakdown[category, default: 0] += 1
            }
        }
        return breakdown
    }
}

