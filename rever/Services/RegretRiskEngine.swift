//
//  RegretRiskEngine.swift
//  rever
//
//  Predictive regret risk engine based on patterns
//

import Foundation
import Combine

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
        case recentRegret = "recent_regret"
        case quietHoursOff = "quiet_hours_off"
        case highEnergy = "high_energy"
        case lowEnergy = "low_energy"
        
        var displayName: String {
            switch self {
            case .lateNight: return "Late Night"
            case .stressMood: return "Stressed Mood"
            case .weekend: return "Weekend"
            case .payday: return "Payday"
            case .prePayday: return "Pre-Payday"
            case .recentRegret: return "Recent Regret"
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
    
    private let moodService = MoodTrackingService.shared
    private let quietHoursService = QuietHoursService.shared
    private let regretService = RegretLoggingService.shared
    
    private init() {
        assessCurrentRisk()
        startPeriodicAssessment()
    }
    
    // Assess current regret risk
    func assessCurrentRisk() {
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
        
        // Current mood risk
        if let currentMood = moodService.currentMood {
            let moodRisk = currentMood.regretRisk
            if moodRisk > 0.6 {
                factors.append(.stressMood)
                riskScore += RegretRiskAssessment.RiskFactor.stressMood.weight * moodRisk
            }
        }
        
        // Recent regret risk
        let recentRegrets = regretService.regretEntries.filter {
            calendar.dateInterval(of: .day, for: $0.date)?.contains(now) ?? false ||
            calendar.isDate($0.date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
        }
        if !recentRegrets.isEmpty {
            factors.append(.recentRegret)
            riskScore += RegretRiskAssessment.RiskFactor.recentRegret.weight
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
        
        DispatchQueue.main.async {
            self.currentRisk = assessment
            self.riskHistory.append(assessment)
            
            // Keep only last 100 assessments
            if self.riskHistory.count > 100 {
                self.riskHistory.removeFirst()
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
        // Assess every 15 minutes
        Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            self?.assessCurrentRisk()
        }
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

