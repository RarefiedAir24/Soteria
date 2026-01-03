//
//  ProtectionHoursService.swift
//  soteria
//
//  Time-based protection reminders (replaces Quiet Hours)
//  No app blocking - just scheduled notifications for reflection moments
//

import Foundation
import Combine
import UserNotifications

enum ProtectionHoursError: LocalizedError {
    case editNotAllowed(String)
    case deleteNotAllowed(String)
    case toggleNotAllowed(String)
    case limitReached(String)
    
    var errorDescription: String? {
        switch self {
        case .editNotAllowed(let message):
            return message
        case .deleteNotAllowed(let message):
            return message
        case .toggleNotAllowed(let message):
            return message
        case .limitReached(let message):
            return message
        }
    }
}

struct ProtectionHoursSchedule: Identifiable, Codable {
    let id: String
    var name: String
    var startTime: DateComponents // Hour and minute
    var endTime: DateComponents
    var daysOfWeek: Set<Int> // 1 = Sunday, 2 = Monday, etc.
    var isActive: Bool
    
    init(id: String = UUID().uuidString, name: String, startTime: DateComponents, endTime: DateComponents, daysOfWeek: Set<Int>, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.daysOfWeek = daysOfWeek
        self.isActive = isActive
    }
    
    // Check if protection hours are currently active
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

class ProtectionHoursService: ObservableObject {
    static let shared = ProtectionHoursService()
    
    @Published var schedules: [ProtectionHoursSchedule] = []
    @Published var isProtectionActive: Bool = false
    @Published var currentActiveSchedule: ProtectionHoursSchedule? = nil
    
    private let schedulesKey = "protection_hours_schedules"
    private var timer: Timer?
    
    private init() {
        let initStart = Date()
        print("✅ [ProtectionHoursService] Init started at \(initStart)")
        // Load schedules on-demand (lazy loading)
        let initEnd = Date()
        print("✅ [ProtectionHoursService] Initialized at \(initEnd) (total: \(initEnd.timeIntervalSince(initStart))s)")
    }
    
    // Load schedules on-demand (lazy loading)
    func ensureSchedulesLoaded() {
        guard schedules.isEmpty else { return }
        loadSchedules()
    }
    
    deinit {
        timer?.invalidate()
        print("🧹 [ProtectionHoursService] Cleaned up timers")
    }
    
    // Load schedules from UserDefaults
    private func loadSchedules() {
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            let loadStart = Date()
            print("🟡 [ProtectionHoursService] loadSchedules() task started at \(loadStart)")
            
            let data = UserDefaults.standard.data(forKey: "protection_hours_schedules")
            let decoded = data.flatMap { try? JSONDecoder().decode([ProtectionHoursSchedule].self, from: $0) } ?? []
            
            await MainActor.run {
                self.schedules = decoded
                let updateEnd = Date()
                print("✅ [ProtectionHoursService] Schedules loaded: \(self.schedules.count) (total: \(updateEnd.timeIntervalSince(loadStart))s)")
            }
        }
    }
    
    // Save schedules to UserDefaults
    private func saveSchedules() {
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: schedulesKey)
            for schedule in schedules {
                print("💾 [ProtectionHoursService] Saved schedule '\(schedule.name)'")
            }
            // Reschedule notifications when schedules change
            scheduleNotifications()
        } else {
            print("❌ [ProtectionHoursService] Failed to encode schedules for saving")
        }
    }
    
    // Start monitoring protection hours status
    func startMonitoring() {
        guard timer == nil else {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.checkProtectionHoursStatus()
            }
            return
        }
        
        // Check immediately
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.checkProtectionHoursStatus()
        }
        
        // Check every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.checkProtectionHoursStatus()
            }
        }
    }
    
    // Check if protection hours are currently active
    func checkProtectionHoursStatus() async {
        let activeSchedule = schedules.first { $0.isCurrentlyActive() }
        let wasActive = isProtectionActive
        
        isProtectionActive = activeSchedule != nil
        currentActiveSchedule = activeSchedule
        
        // Update UserDefaults flag (for compatibility with existing code that checks this)
        UserDefaults.standard.set(isProtectionActive, forKey: "quietHoursActive") // Keep same key for compatibility
        
        if wasActive != isProtectionActive {
            print("🔄 [ProtectionHoursService] Protection Hours status changed: \(isProtectionActive ? "ACTIVE" : "INACTIVE")")
        }
    }
    
    // Check if user can add a schedule
    func canAddSchedule(isPremium: Bool) -> Bool {
        if isPremium {
            return true // Unlimited for premium
        } else {
            return schedules.count < 1 // Free: 1 schedule max
        }
    }
    
    // Add a new schedule
    func addSchedule(_ schedule: ProtectionHoursSchedule, isPremium: Bool) throws {
        if !canAddSchedule(isPremium: isPremium) {
            throw ProtectionHoursError.limitReached("Free users can create 1 Protection Hours schedule. Upgrade to Plus for unlimited schedules.")
        }
        
        schedules.append(schedule)
        saveSchedules()
        Task { @MainActor in
            await checkProtectionHoursStatus()
        }
    }
    
    // Update an existing schedule (Premium only for free users)
    func updateSchedule(_ schedule: ProtectionHoursSchedule, isPremium: Bool) throws {
        guard isPremium else {
            throw ProtectionHoursError.editNotAllowed("Editing Protection Hours schedules is a premium feature. Upgrade to Plus to customize your schedules.")
        }
        
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
            saveSchedules()
            Task { @MainActor in
                await checkProtectionHoursStatus()
            }
        }
    }
    
    // Delete a schedule (Premium only for free users)
    func deleteSchedule(_ schedule: ProtectionHoursSchedule, isPremium: Bool) throws {
        guard isPremium else {
            throw ProtectionHoursError.deleteNotAllowed("Deleting Protection Hours schedules is a premium feature. Upgrade to Plus to manage your schedules.")
        }
        
        schedules.removeAll { $0.id == schedule.id }
        saveSchedules()
        Task { @MainActor in
            await checkProtectionHoursStatus()
        }
    }
    
    // Toggle schedule active state (Premium only for free users)
    func toggleSchedule(_ schedule: ProtectionHoursSchedule, isPremium: Bool) throws {
        guard isPremium else {
            throw ProtectionHoursError.toggleNotAllowed("Enabling/disabling Protection Hours schedules is a premium feature. Upgrade to Plus to manage your schedules.")
        }
        
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index].isActive.toggle()
            saveSchedules()
            Task { @MainActor in
                await checkProtectionHoursStatus()
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    private func scheduleNotifications() {
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            
            // Cancel all existing protection hour notifications
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let protectionHourRequests = requests.filter { $0.identifier.hasPrefix("protection_hour_") }
                let identifiers = protectionHourRequests.map { $0.identifier }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            }
            
            // Schedule notifications for each active schedule
            for schedule in self.schedules where schedule.isActive {
                self.scheduleNotification(for: schedule)
            }
        }
    }
    
    private func scheduleNotification(for schedule: ProtectionHoursSchedule) {
        let content = UNMutableNotificationContent()
        content.title = "🌙 Protection Hour"
        content.body = "Take a moment to reflect before making impulse decisions."
        content.sound = .default
        content.userInfo = [
            "type": "protection_hour",
            "scheduleId": schedule.id
        ]
        
        // Schedule for start time of each day
        for day in schedule.daysOfWeek {
            var dateComponents = DateComponents()
            dateComponents.weekday = day
            dateComponents.hour = schedule.startTime.hour
            dateComponents.minute = schedule.startTime.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "protection_hour_\(schedule.id)_\(day)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ [ProtectionHoursService] Failed to schedule notification: \(error)")
                } else {
                    print("✅ [ProtectionHoursService] Scheduled notification for \(schedule.name) on day \(day)")
                }
            }
        }
    }
}

