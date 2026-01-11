//
//  SavingsToolsService.swift
//  soteria
//
//  Manages savings tools activation state and tracking
//

import Foundation
import Combine

@MainActor
class SavingsToolsService: ObservableObject {
    static let shared = SavingsToolsService()
    
    // MARK: - Feature Flag
    // 🚨 MASTER CONTROL: Set to false to completely disable savings tools feature
    private static let SAVINGS_TOOLS_ENABLED_DEFAULT = false  // Change to true when partners secured
    
    @Published var isFeatureEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isFeatureEnabled, forKey: featureFlagKey)
        }
    }
    
    // MARK: - Published Properties
    @Published var tools: [SavingsTool] = SavingsTool.catalog
    @Published var lastPromptDate: Date?
    @Published var promptsSnoozedUntil: Date?
    @Published var dismissedPrompts: Set<PromptType> = []
    
    // MARK: - Constants
    private let featureFlagKey = "savings_tools_feature_enabled"
    private let toolsKey = "savings_tools_data"
    private let lastPromptKey = "savings_tools_last_prompt"
    private let snoozeUntilKey = "savings_tools_snooze_until"
    private let dismissedPromptsKey = "savings_tools_dismissed"
    
    enum PromptType: String, Codable {
        case homeCard = "home_card"
        case postDeposit = "post_deposit"
        case weeklyCheckIn = "weekly_checkin"
        case milestone = "milestone"
        case giftCardProgress = "gift_card_progress"
        case afterPurchase = "after_purchase"
    }
    
    // MARK: - Computed Properties
    
    var activatedTools: [SavingsTool] {
        return tools.filter { $0.isActivated }
    }
    
    var unactivatedTools: [SavingsTool] {
        return tools.filter { !$0.isActivated && !$0.isComingSoon }
    }
    
    var hasAnyTools: Bool {
        return !activatedTools.isEmpty
    }
    
    var totalPointsEarned: Int {
        return activatedTools.reduce(0) { $0 + $1.pointsEarned }
    }
    
    var totalUnactivatedBonus: Int {
        return unactivatedTools.reduce(0) { $0 + $1.activationBonus }
    }
    
    var totalPotentialSavings: (min: Int, max: Int) {
        var min = 0
        var max = 0
        
        for tool in unactivatedTools {
            let savingsRange = tool.monthlySavings
                .replacingOccurrences(of: "$", with: "")
                .components(separatedBy: "-")
            
            if let minValue = Int(savingsRange.first ?? "0"),
               let maxValue = Int(savingsRange.last ?? "0") {
                min += minValue
                max += maxValue
            }
        }
        
        return (min, max)
    }
    
    // MARK: - Initialization
    private init() {
        // Load feature flag (defaults to SAVINGS_TOOLS_ENABLED_DEFAULT on first launch)
        if UserDefaults.standard.object(forKey: featureFlagKey) == nil {
            // First launch - use default
            isFeatureEnabled = Self.SAVINGS_TOOLS_ENABLED_DEFAULT
            UserDefaults.standard.set(isFeatureEnabled, forKey: featureFlagKey)
        } else {
            // Load saved value
            isFeatureEnabled = UserDefaults.standard.bool(forKey: featureFlagKey)
        }
        
        loadTools()
        loadPromptState()
    }
    
    // MARK: - Feature Flag Management
    
    /// Toggle the feature on/off (accessible from Developer Testing)
    func toggleFeature() {
        isFeatureEnabled.toggle()
        print("🎚️ [SavingsTools] Feature \(isFeatureEnabled ? "ENABLED" : "DISABLED")")
    }
    
    /// Manually enable the feature
    func enableFeature() {
        isFeatureEnabled = true
        print("✅ [SavingsTools] Feature ENABLED")
    }
    
    /// Manually disable the feature
    func disableFeature() {
        isFeatureEnabled = false
        print("🚫 [SavingsTools] Feature DISABLED")
    }
    
    // MARK: - Tool Management
    
    /// Check if a tool is activated
    func isActivated(_ toolId: String) -> Bool {
        return tools.first(where: { $0.id == toolId })?.isActivated ?? false
    }
    
    /// Activate a tool and award bonus points
    func activateTool(_ toolId: String) {
        guard let index = tools.firstIndex(where: { $0.id == toolId }) else {
            print("⚠️ [SavingsTools] Tool \(toolId) not found")
            return
        }
        
        guard !tools[index].isActivated else {
            print("⚠️ [SavingsTools] Tool \(toolId) already activated")
            return
        }
        
        tools[index].isActivated = true
        tools[index].activatedDate = Date()
        tools[index].pointsEarned = tools[index].activationBonus
        saveTools()
        
        // Award activation bonus points
        LoyaltyPointsService.shared.awardPointsForSaving(
            amount: Double(tools[index].activationBonus),
            hasStreak: false,
            source: "tool_activation_\(toolId)"
        )
        
        print("✅ [SavingsTools] Activated \(tools[index].name), awarded \(tools[index].activationBonus) points")
    }
    
    /// Deactivate a tool
    func deactivateTool(_ toolId: String) {
        guard let index = tools.firstIndex(where: { $0.id == toolId }) else {
            print("⚠️ [SavingsTools] Tool \(toolId) not found")
            return
        }
        
        tools[index].isActivated = false
        // Keep stats but mark as deactivated
        saveTools()
        
        print("🔴 [SavingsTools] Deactivated \(tools[index].name)")
    }
    
    /// Update tool settings
    func updateToolSettings(toolId: String, notificationsEnabled: Bool, trackingEnabled: Bool) {
        guard let index = tools.firstIndex(where: { $0.id == toolId }) else {
            print("⚠️ [SavingsTools] Tool \(toolId) not found")
            return
        }
        
        tools[index].notificationsEnabled = notificationsEnabled
        tools[index].trackingEnabled = trackingEnabled
        saveTools()
        
        print("⚙️ [SavingsTools] Updated settings for \(tools[index].name)")
    }
    
    /// Record tool usage
    func recordUsage(toolId: String, amountSaved: Double) {
        guard let index = tools.firstIndex(where: { $0.id == toolId }) else {
            print("⚠️ [SavingsTools] Tool \(toolId) not found")
            return
        }
        
        guard tools[index].isActivated && tools[index].trackingEnabled else {
            print("⚠️ [SavingsTools] Tool \(toolId) not activated or tracking disabled")
            return
        }
        
        tools[index].usageCount += 1
        tools[index].totalSaved += amountSaved
        tools[index].lastUsed = Date()
        
        // Award points for the save
        let points = Int(amountSaved * 10) // 10 points per dollar saved
        tools[index].pointsEarned += points
        
        saveTools()
        
        LoyaltyPointsService.shared.awardPointsForSaving(
            amount: amountSaved,
            hasStreak: false,
            source: "tool_usage_\(toolId)"
        )
        
        print("📊 [SavingsTools] Recorded $\(amountSaved) save for \(tools[index].name), awarded \(points) points")
    }
    
    /// Refresh tools status (call after sheet closes)
    func checkToolsStatus() {
        // Trigger UI refresh
        objectWillChange.send()
    }
    
    // MARK: - Prompt Management
    
    /// Check if we should show a prompt
    func shouldShowPrompt(_ type: PromptType) -> Bool {
        // Don't show if all tools activated
        guard !unactivatedTools.isEmpty else { return false }
        
        // Don't show if snoozed
        if let snoozeUntil = promptsSnoozedUntil, snoozeUntil > Date() {
            return false
        }
        
        // Don't show if permanently dismissed
        if dismissedPrompts.contains(type) {
            return false
        }
        
        // Check last prompt time (don't spam)
        if let lastPrompt = lastPromptDate {
            let hoursSinceLastPrompt = Date().timeIntervalSince(lastPrompt) / 3600
            
            // Different cooldowns for different prompt types
            let minimumHours: Double = {
                switch type {
                case .homeCard: return 168 // 7 days
                case .postDeposit: return 48 // 2 days
                case .weeklyCheckIn: return 168 // 7 days
                case .milestone: return 72 // 3 days
                case .giftCardProgress: return 24 // 1 day
                case .afterPurchase: return 24 // 1 day
                }
            }()
            
            if hoursSinceLastPrompt < minimumHours {
                return false
            }
        }
        
        return true
    }
    
    /// Mark that we showed a prompt
    func markPromptShown(_ type: PromptType) {
        lastPromptDate = Date()
        savePromptState()
    }
    
    /// Snooze prompts for 2 weeks
    func snoozePrompts(weeks: Int = 2) {
        promptsSnoozedUntil = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: Date())
        savePromptState()
        print("😴 [SavingsTools] Prompts snoozed until \(promptsSnoozedUntil!)")
    }
    
    /// Permanently dismiss a prompt type
    func dismissPrompt(_ type: PromptType, permanently: Bool = false) {
        if permanently {
            dismissedPrompts.insert(type)
            savePromptState()
            print("🚫 [SavingsTools] Permanently dismissed \(type.rawValue) prompts")
        }
    }
    
    // MARK: - Persistence
    
    private func loadTools() {
        if let data = UserDefaults.standard.data(forKey: toolsKey),
           let savedTools = try? JSONDecoder().decode([SavingsTool].self, from: data) {
            // Merge saved data with catalog (in case new tools were added)
            var mergedTools: [SavingsTool] = []
            for catalogTool in SavingsTool.catalog {
                if let savedTool = savedTools.first(where: { $0.id == catalogTool.id }) {
                    mergedTools.append(savedTool)
                } else {
                    mergedTools.append(catalogTool)
                }
            }
            tools = mergedTools
        } else {
            tools = SavingsTool.catalog
        }
    }
    
    private func saveTools() {
        if let data = try? JSONEncoder().encode(tools) {
            UserDefaults.standard.set(data, forKey: toolsKey)
        }
    }
    
    private func loadPromptState() {
        if let lastPromptTimestamp = UserDefaults.standard.object(forKey: lastPromptKey) as? Date {
            lastPromptDate = lastPromptTimestamp
        }
        
        if let snoozeTimestamp = UserDefaults.standard.object(forKey: snoozeUntilKey) as? Date {
            promptsSnoozedUntil = snoozeTimestamp
        }
        
        if let data = UserDefaults.standard.data(forKey: dismissedPromptsKey),
           let dismissed = try? JSONDecoder().decode(Set<PromptType>.self, from: data) {
            dismissedPrompts = dismissed
        }
    }
    
    private func savePromptState() {
        if let lastPrompt = lastPromptDate {
            UserDefaults.standard.set(lastPrompt, forKey: lastPromptKey)
        }
        
        if let snoozeUntil = promptsSnoozedUntil {
            UserDefaults.standard.set(snoozeUntil, forKey: snoozeUntilKey)
        }
        
        if let data = try? JSONEncoder().encode(dismissedPrompts) {
            UserDefaults.standard.set(data, forKey: dismissedPromptsKey)
        }
    }
}
