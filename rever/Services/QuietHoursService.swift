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
    
    private let schedulesKey = "quiet_hours_schedules"
    private var timer: Timer?
    
    private init() {
        loadSchedules()
        startMonitoring()
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
        
        DispatchQueue.main.async {
            self.isQuietModeActive = activeSchedule != nil
            self.currentActiveSchedule = activeSchedule
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
}

