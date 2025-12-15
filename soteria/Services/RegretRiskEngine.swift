//
//  RegretRiskEngine.swift
//  rever
//
//  Predictive regret risk engine based on patterns
//

import Foundation
import Combine
import UserNotifications

struct RegretRiskAssessment: Identifiable {
    let id: String
    var timestamp: Date
    var riskLevel: Double // 0.0 (low) to 1.0 (high)
    var factors: [RiskFactor]
    var recommendation: String?
    
    enum RiskFactor: String, Codable {
        case lateNight = "late_night"
        case stressMood = "stress_mood"
        case weekend = "weekend"
        case payday = "payday"
        case prePayday = "pre_payday"
        case recentRegret = "recent_regret" // Now used for "high activity pattern"
        case quietHoursOff = "quiet_hours_off"
        case highEnergy = "high_energy"
        case lowEnergy = "low_energy"
        
        var displayName: String {
            switch self {
            case .lateNight: return "Late Night"
            case .stressMood: return "High Impulse Pattern"
            case .weekend: return "Weekend"
            case .payday: return "Payday"
            case .prePayday: return "Pre-Payday"
            case .recentRegret: return "High Activity Pattern"
            case .quietHoursOff: return "Quiet Hours Disabled"
            case .highEnergy: return "High Energy"
            case .lowEnergy: return "Low Energy"
            }
        }
        
        var weight: Double {
            switch self {
            case .lateNight: return 0.3
            case .stressMood: return 0.4
            case .weekend: return 0.2
            case .payday: return 0.3
            case .prePayday: return 0.4
            case .recentRegret: return 0.5
            case .quietHoursOff: return 0.2
            case .highEnergy: return 0.3
            case .lowEnergy: return 0.2
            }
        }
    }
}

class RegretRiskEngine: ObservableObject {
    static let shared = RegretRiskEngine()
    
    @Published var currentRisk: RegretRiskAssessment? = nil
    @Published var riskHistory: [RegretRiskAssessment] = []
    
    // CRITICAL: Make all service dependencies lazy to prevent initialization chain during startup
    // Accessing .shared during init() triggers that service's init(), creating a blocking chain
    private var quietHoursService: QuietHoursService {
        QuietHoursService.shared
    }
    private var deviceActivityService: DeviceActivityService {
        DeviceActivityService.shared
    }
    
    @Published var lastAlertSent: Date? = nil
    private let alertCooldownMinutes: Int = 60 // Don't send alerts more than once per hour
    
    // Store timers so they can be invalidated
    private var riskAssessmentTimer: Timer?
    private var proactiveAlertTimer: Timer?
    
    private init() {
        let initStart = Date()
        print("✅ [RegretRiskEngine] Init started at \(initStart) (truly lazy - no work on startup)")
        // STREAMLINED: Do absolutely nothing on startup
        // All work will be done on-demand when user actually needs risk assessment
        let initEnd = Date()
        print("✅ [RegretRiskEngine] Initialized at \(initEnd) (total: \(initEnd.timeIntervalSince(initStart))s)")
    }
    
    // Request notification permission (disabled - handled by SoteriaApp)
    // private func requestNotificationAuthorization() {
    //     UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    //         if let error = error {
    //             print("❌ [RegretRiskEngine] Notification authorization error: \(error)")
    //         } else {
    //             print("✅ [RegretRiskEngine] Notification authorization granted: \(granted)")
    //         }
    //     }
    // }
    
    // Assess current regret risk
    func assessCurrentRisk() async {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        
        var factors: [RegretRiskAssessment.RiskFactor] = []
        var riskScore: Double = 0.0
        
        // Late night risk (10pm - 2am)
        if hour >= 22 || hour < 2 {
            factors.append(.lateNight)
            riskScore += RegretRiskAssessment.RiskFactor.lateNight.weight
        }
        
        // Weekend risk (Saturday = 7, Sunday = 1)
        if weekday == 1 || weekday == 7 {
            factors.append(.weekend)
            riskScore += RegretRiskAssessment.RiskFactor.weekend.weight
        }
        
        // High unblock frequency risk (automatic - no user input)
        // Access unblockEvents safely to avoid blocking
        let recentUnblocks = await MainActor.run {
            deviceActivityService.getRecentUnblockEvents(hours: 1)
        }
        if recentUnblocks.count >= 3 {
            factors.append(.recentRegret) // Reuse this factor for "high activity"
            riskScore += RegretRiskAssessment.RiskFactor.recentRegret.weight
        }
        
        // High impulse ratio risk (automatic - from unblock events)
        let todayUnblocks = await MainActor.run {
            deviceActivityService.getRecentUnblockEvents(hours: 24)
        }
        if !todayUnblocks.isEmpty {
            let impulseCount = todayUnblocks.filter { $0.purchaseType == "impulse" }.count
            let impulseRatio = Double(impulseCount) / Double(todayUnblocks.count)
            if impulseRatio >= 0.6 { // 60%+ impulse purchases today
                factors.append(.stressMood) // Reuse for "high impulse pattern"
                riskScore += RegretRiskAssessment.RiskFactor.stressMood.weight * impulseRatio
            }
        }
        
        // Rapid unblock pattern (multiple unblocks in short time - automatic)
        if recentUnblocks.count >= 2 {
            let timeBetween = recentUnblocks.last?.timeSinceLastUnblock ?? 0
            if timeBetween < 30 * 60 { // Less than 30 minutes between unblocks
                riskScore += 0.2 // Additional risk for rapid pattern
            }
        }
        
        // Quiet hours status
        if !quietHoursService.isQuietModeActive {
            factors.append(.quietHoursOff)
            riskScore += RegretRiskAssessment.RiskFactor.quietHoursOff.weight
        }
        
        // Normalize risk score (0.0 to 1.0)
        riskScore = min(riskScore, 1.0)
        
        // Generate recommendation
        let recommendation = generateRecommendation(riskScore: riskScore, factors: factors)
        
        let assessment = RegretRiskAssessment(
            id: UUID().uuidString,
            timestamp: now,
            riskLevel: riskScore,
            factors: factors,
            recommendation: recommendation
        )
        
        await MainActor.run {
            self.currentRisk = assessment
            self.riskHistory.append(assessment)
            
            // Keep only last 100 assessments
            if self.riskHistory.count > 100 {
                self.riskHistory.removeFirst()
            }
            
            // Send predictive alert if risk is high
            if assessment.riskLevel >= 0.7 {
                self.sendPredictiveAlert(assessment: assessment)
            }
        }
    }
    
    // Send predictive vulnerability alert
    private func sendPredictiveAlert(assessment: RegretRiskAssessment) {
        // Check cooldown
        if let lastAlert = lastAlertSent {
            let minutesSinceLastAlert = Calendar.current.dateComponents([.minute], from: lastAlert, to: Date()).minute ?? 0
            if minutesSinceLastAlert < alertCooldownMinutes {
                return // Still in cooldown
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "SOTERIA Protection Alert"
        content.body = assessment.recommendation ?? "You're entering a vulnerable moment. Consider enabling Quiet Hours."
        content.sound = .default
        content.categoryIdentifier = "VULNERABILITY_ALERT"
        content.userInfo = [
            "type": "vulnerability_alert",
            "risk_level": assessment.riskLevel,
            "factors": assessment.factors.map { $0.rawValue }
        ]
        
        // Send immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [RegretRiskEngine] Failed to send alert: \(error)")
            } else {
                print("✅ [RegretRiskEngine] Predictive alert sent")
                DispatchQueue.main.async {
                    self.lastAlertSent = Date()
                }
            }
        }
    }
    
    // Check if we should send a proactive alert based on patterns
    func checkForProactiveAlert() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Check if this is a historically high-risk time
        let historicalRisk = getRiskPattern(hour: hour, dayOfWeek: calendar.component(.weekday, from: now))
        
        if historicalRisk >= 0.7 {
            // Check if quiet hours are off
            if !quietHoursService.isQuietModeActive {
                sendProactiveAlert(hour: hour, historicalRisk: historicalRisk)
            }
        }
    }
    
    // Send proactive alert before vulnerable time
    private func sendProactiveAlert(hour: Int, historicalRisk: Double) {
        // Check cooldown
        if let lastAlert = lastAlertSent {
            let minutesSinceLastAlert = Calendar.current.dateComponents([.minute], from: lastAlert, to: Date()).minute ?? 0
            if minutesSinceLastAlert < alertCooldownMinutes {
                return
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "SOTERIA Protection Reminder"
        
        if hour >= 22 || hour < 2 {
            content.body = "Late night is often a vulnerable time. Your Financial Quiet Mode can protect you."
        } else {
            content.body = "You're entering a time when you're often vulnerable. Consider enabling Quiet Hours for protection."
        }
        
        content.sound = .default
        content.categoryIdentifier = "PROACTIVE_ALERT"
        content.userInfo = ["type": "proactive_alert"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [RegretRiskEngine] Failed to send proactive alert: \(error)")
            } else {
                print("✅ [RegretRiskEngine] Proactive alert sent")
                DispatchQueue.main.async {
                    self.lastAlertSent = Date()
                }
            }
        }
    }
    
    // Generate recommendation based on risk
    private func generateRecommendation(riskScore: Double, factors: [RegretRiskAssessment.RiskFactor]) -> String {
        if riskScore >= 0.8 {
            return "High risk detected. Consider enabling Quiet Hours and taking a moment to reflect."
        } else if riskScore >= 0.6 {
            return "Elevated risk. Be mindful of impulse purchases right now."
        } else if riskScore >= 0.4 {
            return "Moderate risk. Stay aware of your spending intentions."
        } else {
            return "Low risk. Good time for mindful spending decisions."
        }
    }
    
    // Start periodic risk assessment
    private func startPeriodicAssessment() {
        // Invalidate existing timers if any
        riskAssessmentTimer?.invalidate()
        proactiveAlertTimer?.invalidate()
        
        // Assess every 15 minutes
        riskAssessmentTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.assessCurrentRisk()
            }
        }
        
        // Check for proactive alerts every hour
        proactiveAlertTimer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            self?.checkForProactiveAlert()
        }
    }
    
    deinit {
        riskAssessmentTimer?.invalidate()
        proactiveAlertTimer?.invalidate()
        print("🧹 [RegretRiskEngine] Cleaned up timers")
    }
    
    // Get risk pattern for a specific time
    func getRiskPattern(hour: Int, dayOfWeek: Int) -> Double {
        let filtered = riskHistory.filter { assessment in
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: assessment.timestamp)
            let weekday = calendar.component(.weekday, from: assessment.timestamp)
            return hour == hour && weekday == dayOfWeek
        }
        
        guard !filtered.isEmpty else { return 0.5 }
        let avgRisk = filtered.reduce(0.0) { $0 + $1.riskLevel } / Double(filtered.count)
        return avgRisk
    }
}

