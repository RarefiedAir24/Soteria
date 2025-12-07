//
//  QuietHoursService.swift
//  rever
//
//  Behavioral spending protection - Quiet Hours management
//

import Foundation
import Combine

struct QuietHoursSchedule: Identifiable, Codable {
    let id: String
    var name: String
    var startTime: DateComponents // Hour and minute
    var endTime: DateComponents
    var daysOfWeek: Set<Int> // 1 = Sunday, 2 = Monday, etc.
    var isActive: Bool
    var categoryRestrictions: [String]? // App categories to restrict (e.g., "Shopping", "Food Delivery")
    
    init(id: String = UUID().uuidString, name: String, startTime: DateComponents, endTime: DateComponents, daysOfWeek: Set<Int>, isActive: Bool = true, categoryRestrictions: [String]? = nil) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.daysOfWeek = daysOfWeek
        self.isActive = isActive
        self.categoryRestrictions = categoryRestrictions
    }
    
    // Check if quiet hours are currently active
    func isCurrentlyActive() -> Bool {
        guard isActive else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        let currentDay = calendar.component(.weekday, from: now) // 1 = Sunday
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // Check if today is in the schedule
        guard daysOfWeek.contains(currentDay) else { return false }
        
        // Check if current time is within the range
        let currentTimeMinutes = currentHour * 60 + currentMinute
        let startTimeMinutes = (startTime.hour ?? 0) * 60 + (startTime.minute ?? 0)
        let endTimeMinutes = (endTime.hour ?? 0) * 60 + (endTime.minute ?? 0)
        
        if startTimeMinutes <= endTimeMinutes {
            // Same day range (e.g., 8pm to 10pm)
            return currentTimeMinutes >= startTimeMinutes && currentTimeMinutes < endTimeMinutes
        } else {
            // Overnight range (e.g., 8pm to 8am)
            return currentTimeMinutes >= startTimeMinutes || currentTimeMinutes < endTimeMinutes
        }
    }
}

class QuietHoursService: ObservableObject {
    static let shared = QuietHoursService()
    
    @Published var schedules: [QuietHoursSchedule] = []
    @Published var isQuietModeActive: Bool = false
    @Published var currentActiveSchedule: QuietHoursSchedule? = nil
    @Published var autoActivatedByMood: Bool = false // Track if auto-activated by mood
    
    private let schedulesKey = "quiet_hours_schedules"
    private var timer: Timer?
    private var moodCheckTimer: Timer?
    private let moodService = MoodTrackingService.shared
    // Lazy to avoid circular dependency with RegretRiskEngine
    private lazy var regretRiskEngine = RegretRiskEngine.shared
    
    private init() {
        loadSchedules()
        startMonitoring()
        startMoodBasedMonitoring()
    }
    
    deinit {
        timer?.invalidate()
        moodCheckTimer?.invalidate()
        print("🧹 [QuietHoursService] Cleaned up timers")
    }
    
    // Load schedules from UserDefaults
    private func loadSchedules() {
        if let data = UserDefaults.standard.data(forKey: schedulesKey),
           let decoded = try? JSONDecoder().decode([QuietHoursSchedule].self, from: data) {
            schedules = decoded
        }
    }
    
    // Save schedules to UserDefaults
    private func saveSchedules() {
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: schedulesKey)
        }
    }
    
    // Start monitoring quiet hours
    private func startMonitoring() {
        // Check immediately
        checkQuietHoursStatus()
        
        // Check every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkQuietHoursStatus()
        }
    }
    
    // Check if quiet hours are currently active
    private func checkQuietHoursStatus() {
        let activeSchedule = schedules.first { $0.isCurrentlyActive() }
        let wasActive = isQuietModeActive
        
        DispatchQueue.main.async {
            self.isQuietModeActive = activeSchedule != nil
            self.currentActiveSchedule = activeSchedule
            
            // Notify DeviceActivityService when Quiet Hours status changes
            if wasActive != self.isQuietModeActive {
                print("🔄 [QuietHoursService] Quiet Hours status changed: \(self.isQuietModeActive ? "ACTIVE" : "INACTIVE")")
                Task {
                    await DeviceActivityService.shared.updateBlockingStatus()
                }
            }
        }
    }
    
    // Add a new schedule
    func addSchedule(_ schedule: QuietHoursSchedule) {
        schedules.append(schedule)
        saveSchedules()
        checkQuietHoursStatus()
    }
    
    // Update an existing schedule
    func updateSchedule(_ schedule: QuietHoursSchedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
            saveSchedules()
            checkQuietHoursStatus()
        }
    }
    
    // Delete a schedule
    func deleteSchedule(_ schedule: QuietHoursSchedule) {
        schedules.removeAll { $0.id == schedule.id }
        saveSchedules()
        checkQuietHoursStatus()
    }
    
    // Toggle schedule active state
    func toggleSchedule(_ schedule: QuietHoursSchedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index].isActive.toggle()
            saveSchedules()
            checkQuietHoursStatus()
        }
    }
    
    // Get recommended quiet hours based on patterns
    func getRecommendedQuietHours() -> QuietHoursSchedule? {
        // TODO: Implement pattern-based recommendations
        // For now, return a default late-night schedule
        return QuietHoursSchedule(
            name: "Recommended: Late Night",
            startTime: DateComponents(hour: 22, minute: 0), // 10pm
            endTime: DateComponents(hour: 8, minute: 0), // 8am
            daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // All days
            isActive: false
        )
    }
    
    // Start monitoring mood for auto-activation
    private func startMoodBasedMonitoring() {
        // Invalidate existing timer if any
        moodCheckTimer?.invalidate()
        
        // Check every 5 minutes for mood-based activation
        moodCheckTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            self?.checkMoodBasedActivation()
        }
    }
    
    // Check if we should auto-activate based on emotional state
    private func checkMoodBasedActivation() {
        // Only auto-activate if no schedule is currently active
        guard !isQuietModeActive else { return }
        
        // Check current mood risk
        if let currentMood = moodService.currentMood {
            let moodRisk = currentMood.regretRisk
            
            // Auto-activate if mood risk is very high (>= 0.8)
            if moodRisk >= 0.8 {
                autoActivateForMood(mood: currentMood, risk: moodRisk)
            }
        }
        
        // Also check regret risk engine
        if let risk = regretRiskEngine.currentRisk, risk.riskLevel >= 0.8 {
            autoActivateForHighRisk(risk: risk)
        }
    }
    
    // Auto-activate quiet hours for high mood risk
    private func autoActivateForMood(mood: MoodLevel, risk: Double) {
        // Create a temporary 2-hour protection window
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let endHour = (currentHour + 2) % 24
        
        let tempSchedule = QuietHoursSchedule(
            name: "Auto-Protection: \(mood.displayName) Mood",
            startTime: DateComponents(hour: currentHour, minute: currentMinute),
            endTime: DateComponents(hour: endHour, minute: currentMinute),
            daysOfWeek: Set([calendar.component(.weekday, from: now)]),
            isActive: true
        )
        
        // Add as temporary schedule
        schedules.append(tempSchedule)
        saveSchedules()
        checkQuietHoursStatus()
        autoActivatedByMood = true
        
        print("🛡️ [QuietHoursService] Auto-activated protection for \(mood.displayName) mood (risk: \(risk))")
    }
    
    // Auto-activate for high general risk
    private func autoActivateForHighRisk(risk: RegretRiskAssessment) {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let endHour = (currentHour + 2) % 24
        
        let tempSchedule = QuietHoursSchedule(
            name: "Auto-Protection: High Risk Detected",
            startTime: DateComponents(hour: currentHour, minute: currentMinute),
            endTime: DateComponents(hour: endHour, minute: currentMinute),
            daysOfWeek: Set([calendar.component(.weekday, from: now)]),
            isActive: true
        )
        
        schedules.append(tempSchedule)
        saveSchedules()
        checkQuietHoursStatus()
        autoActivatedByMood = true
        
        print("🛡️ [QuietHoursService] Auto-activated protection for high risk (level: \(risk.riskLevel))")
    }
    
    // Suggest quiet hours activation (called from regret service)
    func suggestActivation(reason: String) {
        // This could show a notification or UI prompt
        // For now, just log it
        print("💡 [QuietHoursService] Suggestion to activate: \(reason)")
    }
}

