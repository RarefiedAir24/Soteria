//
//  QuietHoursService.swift
//  rever
//
//  Behavioral spending protection - Quiet Hours management
//

import Foundation
import Combine

enum QuietHoursError: LocalizedError {
    case editNotAllowed(String)
    case deleteNotAllowed(String)
    case toggleNotAllowed(String)
    
    var errorDescription: String? {
        switch self {
        case .editNotAllowed(let message):
            return message
        case .deleteNotAllowed(let message):
            return message
        case .toggleNotAllowed(let message):
            return message
        }
    }
}

struct QuietHoursSchedule: Identifiable, Codable {
    let id: String
    var name: String
    var startTime: DateComponents // Hour and minute
    var endTime: DateComponents
    var daysOfWeek: Set<Int> // 1 = Sunday, 2 = Monday, etc.
    var isActive: Bool
    var categoryRestrictions: [String]? // App categories to restrict (e.g., "Shopping", "Food Delivery")
    var selectedAppIndices: [Int] // Indices of apps from DeviceActivityService.selectedApps to monitor for this schedule
    
    init(id: String = UUID().uuidString, name: String, startTime: DateComponents, endTime: DateComponents, daysOfWeek: Set<Int>, isActive: Bool = true, categoryRestrictions: [String]? = nil, selectedAppIndices: [Int] = []) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.daysOfWeek = daysOfWeek
        self.isActive = isActive
        self.categoryRestrictions = categoryRestrictions
        self.selectedAppIndices = selectedAppIndices
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
    @Published var autoActivatedByMood: Bool = false // Track if auto-activated by behavioral patterns
    
    private let schedulesKey = "quiet_hours_schedules"
    private var timer: Timer?
    private var moodCheckTimer: Timer?
    // CRITICAL: Make all service dependencies lazy to prevent initialization chain during startup
    // Accessing .shared during init() triggers that service's init(), creating a blocking chain
    private var moodService: MoodTrackingService {
        MoodTrackingService.shared
    }
    // Lazy to avoid circular dependency with RegretRiskEngine
    private lazy var regretRiskEngine = RegretRiskEngine.shared
    
    private init() {
        let initStart = Date()
        print("✅ [QuietHoursService] Init started at \(initStart) (truly lazy - no work on startup)")
        // STREAMLINED: Do absolutely nothing on startup
        // Schedules will be loaded on-demand when user opens Quiet Hours view
        // This eliminates unnecessary background tasks on app launch
        let initEnd = Date()
        print("✅ [QuietHoursService] Initialized at \(initEnd) (total: \(initEnd.timeIntervalSince(initStart))s)")
    }
    
    // Load schedules on-demand (lazy loading)
    // Call this when user actually opens Quiet Hours view
    func ensureSchedulesLoaded() {
        // Only load if not already loaded
        guard schedules.isEmpty else { return }
        loadSchedules()
    }
    
    deinit {
        timer?.invalidate()
        moodCheckTimer?.invalidate()
        print("🧹 [QuietHoursService] Cleaned up timers")
    }
    
    // Load schedules from UserDefaults - make this truly async to avoid blocking
    // Remove @MainActor - this function should not block the main thread
    private func loadSchedules() {
        // Start a detached task immediately - don't block anything
        // CRITICAL: Use .background priority to ensure it doesn't block critical operations
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            let loadStart = Date()
            print("🟡 [QuietHoursService] loadSchedules() task started at \(loadStart)")
            
            // Read UserDefaults in background (fast, but do it off main thread)
            let data = UserDefaults.standard.data(forKey: "quiet_hours_schedules")
            
            // Decode JSON in background (can be slow with large arrays)
            let decoded = data.flatMap { try? JSONDecoder().decode([QuietHoursSchedule].self, from: $0) } ?? []
            
            let decodeEnd = Date()
            print("🟡 [QuietHoursService] JSON decode completed (took \(decodeEnd.timeIntervalSince(loadStart))s)")
            
            // Update @Published property on MainActor (required for ObservableObject)
            await MainActor.run {
                self.schedules = decoded
                let updateEnd = Date()
                print("✅ [QuietHoursService] Schedules loaded: \(self.schedules.count) (total: \(updateEnd.timeIntervalSince(loadStart))s)")
                
                // DISABLED: Auto-start monitoring when schedules load
                // This was causing startup delays - monitoring will start manually when needed
                // self.startMonitoring()
            }
        }
    }
    
    // Save schedules to UserDefaults
    // PERSISTENCE: Schedules persist across app restarts and signout/signin
    // They are NOT cleared on signout (only auth tokens are cleared)
    private func saveSchedules() {
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: schedulesKey)
            // Log to verify persistence
            for schedule in schedules {
                print("💾 [QuietHoursService] Saved schedule '\(schedule.name)' with \(schedule.selectedAppIndices.count) selected app indices: \(schedule.selectedAppIndices)")
            }
        } else {
            print("❌ [QuietHoursService] Failed to encode schedules for saving")
        }
    }
    
    // Start monitoring quiet hours
    // Made public so views can ensure monitoring is active
    func startMonitoring() {
        // Prevent multiple timers
        guard timer == nil else {
            // Timer already running, just check status immediately
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.checkQuietHoursStatus()
            }
            return
        }
        
        // Check immediately (async, non-blocking)
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.checkQuietHoursStatus()
        }
        
        // Check every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.checkQuietHoursStatus()
            }
        }
    }
    
    // Check if quiet hours are currently active
    // Made public so views can trigger immediate status check
    func checkQuietHoursStatus() async {
        let activeSchedule = schedules.first { $0.isCurrentlyActive() }
        let wasActive = isQuietModeActive
        
        isQuietModeActive = activeSchedule != nil
        currentActiveSchedule = activeSchedule
        
        // Update UserDefaults flag for extension to check
        UserDefaults.standard.set(isQuietModeActive, forKey: "quietHoursActive")
        
        // Always notify DeviceActivityService to ensure blocking is applied
        // This handles the case where Quiet Hours are already active on app launch
        if wasActive != isQuietModeActive {
            print("🔄 [QuietHoursService] Quiet Hours status changed: \(isQuietModeActive ? "ACTIVE" : "INACTIVE")")
        } else if isQuietModeActive {
            print("🔄 [QuietHoursService] Quiet Hours are active - ensuring blocking is applied")
        }
        
        // Note: Blocking status updates are disabled - we use notifications only
        // Task.detached(priority: .background) {
        //     try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
        //     await DeviceActivityService.shared.updateBlockingStatus()
        // }
    }
    
    // Add a new schedule
    func addSchedule(_ schedule: QuietHoursSchedule) {
        schedules.append(schedule)
        saveSchedules()
        Task { @MainActor in
            await checkQuietHoursStatus()
        }
    }
    
    // Update an existing schedule (Premium only for free users)
    func updateSchedule(_ schedule: QuietHoursSchedule, isPremium: Bool) throws {
        // Free users cannot edit schedules (prevents loopholes)
        guard isPremium else {
            throw QuietHoursError.editNotAllowed("Editing Quiet Hours schedules is a premium feature. Upgrade to Plus to customize your schedules.")
        }
        
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
            print("💾 [QuietHoursService] Updated schedule '\(schedule.name)' with \(schedule.selectedAppIndices.count) selected app indices: \(schedule.selectedAppIndices)")
            saveSchedules()
            Task { @MainActor in
                await checkQuietHoursStatus()
            }
        } else {
            print("⚠️ [QuietHoursService] Schedule '\(schedule.name)' not found for update")
        }
    }
    
    // Delete a schedule (Premium only for free users)
    func deleteSchedule(_ schedule: QuietHoursSchedule, isPremium: Bool) throws {
        // Free users cannot delete schedules (prevents loopholes)
        guard isPremium else {
            throw QuietHoursError.deleteNotAllowed("Deleting Quiet Hours schedules is a premium feature. Upgrade to Plus to manage your schedules.")
        }
        
        schedules.removeAll { $0.id == schedule.id }
        saveSchedules()
        Task { @MainActor in
            await checkQuietHoursStatus()
        }
    }
    
    // Toggle schedule active state (Premium only for free users)
    func toggleSchedule(_ schedule: QuietHoursSchedule, isPremium: Bool) throws {
        // Free users cannot toggle schedules (prevents loopholes)
        guard isPremium else {
            throw QuietHoursError.toggleNotAllowed("Enabling/disabling Quiet Hours schedules is a premium feature. Upgrade to Plus to manage your schedules.")
        }
        
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index].isActive.toggle()
            saveSchedules()
            Task { @MainActor in
                await checkQuietHoursStatus()
            }
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
    
    // Start monitoring behavioral patterns for auto-activation (Premium feature)
    // Uses automatic behavioral patterns - no user input required
    private func startBehavioralMonitoring(isPremium: Bool = false) {
        // Only enable behavioral monitoring for premium users
        guard isPremium else {
            print("ℹ️ [QuietHoursService] Behavioral auto-activation is a Premium feature")
            return
        }
        
        // Invalidate existing timer if any
        moodCheckTimer?.invalidate()
        
        // Check every 5 minutes for behavioral risk patterns
        moodCheckTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            self?.checkBehavioralActivation()
        }
    }
    
    // Update premium status for behavioral monitoring
    func updatePremiumStatus(_ isPremium: Bool) {
        if isPremium {
            startBehavioralMonitoring(isPremium: true)
        } else {
            moodCheckTimer?.invalidate()
            moodCheckTimer = nil
        }
    }
    
    // Check if we should auto-activate based on automatic behavioral patterns
    private func checkBehavioralActivation() {
        // Only auto-activate if no schedule is currently active
        guard !isQuietModeActive else { return }
        
        // Use RegretRiskEngine - it automatically tracks patterns without user input
        // Factors include: late night, weekend, recent regrets, unblock frequency, etc.
        if let risk = regretRiskEngine.currentRisk, risk.riskLevel >= 0.8 {
            autoActivateForHighRisk(risk: risk)
        }
        
        // Also check unblock frequency patterns (automatic tracking)
        // Use getUnblockMetrics which is public
        let deviceActivityService = DeviceActivityService.shared
        let metrics = deviceActivityService.getUnblockMetrics()
        
        // If user has unblocked 3+ times today, that's a vulnerability signal
        // This is automatic - no user input required
        if metrics.totalUnblocks >= 3 {
            // Check if recent (within last hour)
            let recentEvents = deviceActivityService.getRecentUnblockEvents(hours: 1)
            if recentEvents.count >= 3 {
                autoActivateForHighFrequency()
            }
        }
    }
    
    // Auto-activate for high unblock frequency (automatic detection)
    private func autoActivateForHighFrequency() {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let endHour = (currentHour + 2) % 24
        
        let tempSchedule = QuietHoursSchedule(
            name: "Auto-Protection: High Activity Detected",
            startTime: DateComponents(hour: currentHour, minute: currentMinute),
            endTime: DateComponents(hour: endHour, minute: currentMinute),
            daysOfWeek: Set([calendar.component(.weekday, from: now)]),
            isActive: true
        )
        
        schedules.append(tempSchedule)
        saveSchedules()
        autoActivatedByMood = true
        Task { @MainActor in
            await checkQuietHoursStatus()
        }
        
        print("🛡️ [QuietHoursService] Auto-activated protection for high unblock frequency")
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
        autoActivatedByMood = true
        Task { @MainActor in
            await checkQuietHoursStatus()
        }
        
        print("🛡️ [QuietHoursService] Auto-activated protection for high risk (level: \(risk.riskLevel))")
    }
    
    // Suggest quiet hours activation (called from regret service)
    func suggestActivation(reason: String) {
        // This could show a notification or UI prompt
        // For now, just log it
        print("💡 [QuietHoursService] Suggestion to activate: \(reason)")
    }
}

