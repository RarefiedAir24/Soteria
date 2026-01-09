//
//  DecisionWindowsService.swift
//  soteria
//
//  Time-based, app-agnostic savings prompts and behavior change
//  This is where money actually moves - intentional action, not contextual reminders
//
//  NOTE: User-facing name is "Decision Notifications" but internal code uses "Decision Windows"
//  The term "Window" refers to a time window (5 minutes around a set time) when notifications are sent
//

import Foundation
import UserNotifications
import Combine

enum DecisionWindowError: LocalizedError {
    case limitReached(String)
    
    var errorDescription: String? {
        switch self {
        case .limitReached(let message):
            return message
        }
    }
}

struct SpendGate: Codable {
    var condition: String // e.g., "food_delivery", "after_9pm", "shopping_app"
    var saveAmount: Double
    var description: String // User-friendly description
}

struct DecisionWindow: Identifiable, Codable {
    let id: String
    var name: String
    var time: DateComponents // Hour and minute
    var daysOfWeek: Set<Int> // 1 = Sunday, 7 = Saturday
    var isEnabled: Bool
    var promptMessage: String? // Custom message
    var createdDate: Date // Track when window was created (for daily limit enforcement)
    
    // New: Commitment options
    var defaultMicroSaveAmount: Double? // Suggested amount for Option A
    var defaultSpendGate: SpendGate? // Suggested spend gate for Option B
    var defaultPauseIntention: String? // Suggested pause intention for Option C
    
    // Custom coding keys for DateComponents encoding
    enum CodingKeys: String, CodingKey {
        case id, name, timeHour, timeMinute, daysOfWeek, isEnabled, promptMessage, createdDate
        case defaultMicroSaveAmount, defaultSpendGate, defaultPauseIntention
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         time: DateComponents,
         daysOfWeek: Set<Int>,
         isEnabled: Bool = true,
         promptMessage: String? = nil,
         defaultMicroSaveAmount: Double? = nil,
         defaultSpendGate: SpendGate? = nil,
         defaultPauseIntention: String? = nil,
         createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.time = time
        self.daysOfWeek = daysOfWeek
        self.isEnabled = isEnabled
        self.promptMessage = promptMessage
        self.defaultMicroSaveAmount = defaultMicroSaveAmount
        self.defaultSpendGate = defaultSpendGate
        self.defaultPauseIntention = defaultPauseIntention
        self.createdDate = createdDate
    }
    
    // Custom encoding to handle DateComponents
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(time.hour ?? 0, forKey: .timeHour)
        try container.encode(time.minute ?? 0, forKey: .timeMinute)
        try container.encode(daysOfWeek, forKey: .daysOfWeek)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encodeIfPresent(promptMessage, forKey: .promptMessage)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(defaultMicroSaveAmount, forKey: .defaultMicroSaveAmount)
        try container.encodeIfPresent(defaultSpendGate, forKey: .defaultSpendGate)
        try container.encodeIfPresent(defaultPauseIntention, forKey: .defaultPauseIntention)
    }
    
    // Custom decoding to handle DateComponents
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let hour = try container.decode(Int.self, forKey: .timeHour)
        let minute = try container.decode(Int.self, forKey: .timeMinute)
        time = DateComponents(hour: hour, minute: minute)
        daysOfWeek = try container.decode(Set<Int>.self, forKey: .daysOfWeek)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        promptMessage = try container.decodeIfPresent(String.self, forKey: .promptMessage)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        defaultMicroSaveAmount = try container.decodeIfPresent(Double.self, forKey: .defaultMicroSaveAmount)
        defaultSpendGate = try container.decodeIfPresent(SpendGate.self, forKey: .defaultSpendGate)
        defaultPauseIntention = try container.decodeIfPresent(String.self, forKey: .defaultPauseIntention)
    }
    
    // Check if this window is currently active
    func isCurrentlyActive() -> Bool {
        guard isEnabled else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        let currentDay = calendar.component(.weekday, from: now) // 1 = Sunday, 7 = Saturday
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // Check if today is in the days of week
        guard daysOfWeek.contains(currentDay) else { return false }
        
        // Check if current time matches window time (within 5 minute window)
        guard let windowHour = time.hour,
              let windowMinute = time.minute else { return false }
        
        let windowTotalMinutes = windowHour * 60 + windowMinute
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        // Active if within 5 minutes of the window time
        return abs(currentTotalMinutes - windowTotalMinutes) <= 5
    }
}

class DecisionWindowsService: ObservableObject {
    static let shared = DecisionWindowsService()
    
    @Published var windows: [DecisionWindow] = []
    @Published var commitments: [DecisionWindowCommitment] = [] // Active commitments
    
    private let windowsKey = "decision_windows"
    private let commitmentsKey = "decision_window_commitments"
    private var notificationTimer: Timer?
    private var commitmentCheckTimer: Timer?
    // Track which windows have already been notified to prevent duplicates
    private var notifiedWindowIds: Set<String> = []
    private var lastNotificationCheck: Date = Date()
    
    private init() {
        loadWindows()
        loadCommitments()
        // Reschedule notifications on app launch to ensure they persist
        scheduleNotifications()
        startMonitoring()
        startCommitmentMonitoring()
    }
    
    deinit {
        notificationTimer?.invalidate()
        commitmentCheckTimer?.invalidate()
    }
    
    // MARK: - Persistence
    
    func loadWindows() {
        guard let data = UserDefaults.standard.data(forKey: windowsKey) else {
            print("📋 [DecisionWindowsService] No saved windows found, creating defaults")
            createDefaultWindows()
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        do {
            let decoded = try decoder.decode([DecisionWindow].self, from: data)
            windows = decoded
            print("📋 [DecisionWindowsService] Loaded \(windows.count) windows from UserDefaults")
            for window in windows {
                print("📋 [DecisionWindowsService] Window '\(window.name)' (id: \(window.id)) - promptMessage: \(window.promptMessage ?? "nil"), defaultPauseIntention: \(window.defaultPauseIntention ?? "nil"), time: \(window.time.hour ?? 0):\(String(format: "%02d", window.time.minute ?? 0))")
            }
        } catch {
            print("❌ [DecisionWindowsService] Failed to decode windows: \(error)")
            print("❌ [DecisionWindowsService] Error details: \(error.localizedDescription)")
            // Create default windows if decoding fails
            createDefaultWindows()
        }
    }
    
    func saveWindows() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        do {
            let encoded = try encoder.encode(windows)
            UserDefaults.standard.set(encoded, forKey: windowsKey)
            UserDefaults.standard.synchronize() // Ensure immediate persistence
            print("💾 [DecisionWindowsService] Saved \(windows.count) windows to UserDefaults")
            for window in windows {
                print("💾 [DecisionWindowsService] Window '\(window.name)' (id: \(window.id)) - promptMessage: \(window.promptMessage ?? "nil"), defaultPauseIntention: \(window.defaultPauseIntention ?? "nil"), time: \(window.time.hour ?? 0):\(String(format: "%02d", window.time.minute ?? 0))")
            }
        } catch {
            print("❌ [DecisionWindowsService] Failed to encode windows for saving: \(error)")
            print("❌ [DecisionWindowsService] Error details: \(error.localizedDescription)")
        }
    }
    
    private func createDefaultWindows() {
        // Morning planning window (8 AM, weekdays)
        let morningWindow = DecisionWindow(
            name: "Morning Planning",
            time: DateComponents(hour: 8, minute: 0),
            daysOfWeek: [2, 3, 4, 5, 6], // Monday-Friday
            isEnabled: false,
            promptMessage: "Before today continues — choose how you want to save."
        )
        
        // End of day reflection (9 PM, daily)
        let eveningWindow = DecisionWindow(
            name: "End of Day Reflection",
            time: DateComponents(hour: 21, minute: 0),
            daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // All days
            isEnabled: false,
            promptMessage: "How did you do today? Set your intention for tomorrow."
        )
        
        windows = [morningWindow, eveningWindow]
        saveWindows()
    }
    
    // MARK: - Window Management
    
    /// Check if user can add another Decision Window based on subscription tier
    /// Limits both total windows and active windows to prevent abuse and ensure good UX
    func canAddWindow(isPremium: Bool) -> (canAdd: Bool, reason: String?) {
        // Daily limit enforcement (CRITICAL: Free tier limitation)
        let calendar = Calendar.current
        let windowsCreatedToday = windows.filter { window in
            calendar.isDate(window.createdDate, inSameDayAs: Date())
        }.count
        
        let maxPerDay = isPremium ? 3 : 1
        if windowsCreatedToday >= maxPerDay {
            let reason = isPremium
                ? "You've reached the daily limit of 3 Decision Windows. You can create more tomorrow."
                : "Free users can create 1 Decision Window per day. Upgrade to Plus for up to 3 per day."
            return (false, reason)
        }
        
        // Total window limits (prevents clutter and abuse)
        let maxTotal = isPremium ? 10 : 3
        let totalWindowsCount = windows.count
        
        if totalWindowsCount >= maxTotal {
            let reason = isPremium
                ? "You've reached the maximum of 10 Decision Windows. Delete unused windows to create new ones."
                : "Free users can create up to 3 Decision Windows total. Upgrade to Plus for up to 10 windows."
            return (false, reason)
        }
        
        // Active window limits (prevents notification spam and maintains focus)
        let maxActive = isPremium ? 3 : 1
        let activeWindowsCount = windows.filter { $0.isEnabled }.count
        
        if activeWindowsCount >= maxActive {
            let reason = isPremium
                ? "You can have up to 3 active Decision Windows at a time. Disable a window to enable a new one."
                : "Free users can have 1 active Decision Window. Upgrade to Plus for up to 3 active windows."
            return (false, reason)
        }
        
        return (true, nil)
    }
    
    func addWindow(_ window: DecisionWindow, isPremium: Bool) throws {
        let (canAdd, reason) = canAddWindow(isPremium: isPremium)
        guard canAdd else {
            throw DecisionWindowError.limitReached(reason ?? "Maximum Decision Windows reached")
        }
        
        windows.append(window)
        saveWindows()
        
        // Schedule notifications asynchronously to avoid blocking
        DispatchQueue.main.async { [weak self] in
            self?.scheduleNotifications()
            
            // Immediately check if the new window is currently active and send notification if so
            if window.isEnabled && window.isCurrentlyActive() {
                print("🔄 [DecisionWindowsService] New window is currently active, sending immediate notification")
                self?.sendDecisionWindowNotification(for: window)
                self?.notifiedWindowIds.insert(window.id)
            }
            
            // Also trigger a check in case the window becomes active soon
            self?.checkActiveWindows()
        }
        
        print("✅ [DecisionWindowsService] Added window: \(window.name), id: \(window.id), total windows: \(windows.count)")
    }
    
    func updateWindow(_ window: DecisionWindow, isPremium: Bool) throws {
        // Free users cannot edit Decision Windows
        guard isPremium else {
            throw DecisionWindowError.limitReached("Editing Decision Windows is a premium feature. Upgrade to Plus to customize your windows.")
        }
        
        if let index = windows.firstIndex(where: { $0.id == window.id }) {
            // Preserve original createdDate when updating
            var updatedWindow = window
            updatedWindow.createdDate = windows[index].createdDate
            windows[index] = updatedWindow
            saveWindows()
            
            // Schedule notifications asynchronously to avoid blocking
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.scheduleNotifications()
                
                // Immediately check if the updated window is currently active and send notification if so
                if updatedWindow.isEnabled && updatedWindow.isCurrentlyActive() {
                    print("🔄 [DecisionWindowsService] Updated window is currently active, sending immediate notification")
                    // Remove from notified set to allow re-notification if window was just enabled
                    self.notifiedWindowIds.remove(updatedWindow.id)
                    self.sendDecisionWindowNotification(for: updatedWindow)
                    self.notifiedWindowIds.insert(updatedWindow.id)
                }
                
                // Also trigger a check in case the window becomes active soon
                self.checkActiveWindows()
            }
        }
    }
    
    func deleteWindow(_ window: DecisionWindow, isPremium: Bool) throws {
        // Free users cannot delete Decision Windows (prevents loopholes)
        guard isPremium else {
            throw DecisionWindowError.limitReached("Deleting Decision Windows is a premium feature. Upgrade to Plus to manage your windows.")
        }
        
        windows.removeAll { $0.id == window.id }
        saveWindows()
        scheduleNotifications()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        // Check immediately
        checkActiveWindows()
        
        // Check every minute
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkActiveWindows()
        }
    }
    
    private func checkActiveWindows() {
        let now = Date()
        let activeWindows = windows.filter { $0.isCurrentlyActive() }
        
        // Clear old notifications (older than 10 minutes) to allow re-notification if window becomes active again
        if now.timeIntervalSince(lastNotificationCheck) > 600 { // 10 minutes
            notifiedWindowIds.removeAll()
            lastNotificationCheck = now
        }
        
        for window in activeWindows {
            // Only send notification if we haven't already notified for this window
            // AND if there's no scheduled notification that will fire at the exact time
            // This prevents duplicate notifications from both scheduled and active window checking
            if !notifiedWindowIds.contains(window.id) {
                // Check if there's a scheduled notification for this window that will fire soon
                // If a scheduled notification exists, let it handle the notification instead
                let hasScheduledNotification = checkForScheduledNotification(for: window)
                
                if !hasScheduledNotification {
                    // No scheduled notification found, send immediate notification
                    sendDecisionWindowNotification(for: window)
                    notifiedWindowIds.insert(window.id)
                    print("✅ [DecisionWindowsService] Notified for window: \(window.name), id: \(window.id)")
                } else {
                    // Scheduled notification exists, mark as notified to prevent duplicate
                    notifiedWindowIds.insert(window.id)
                    print("⏭️ [DecisionWindowsService] Skipping immediate notification for \(window.name) - scheduled notification will fire")
                }
            }
        }
        
        // Remove windows that are no longer active from the notified set
        let activeWindowIds = Set(activeWindows.map { $0.id })
        notifiedWindowIds = notifiedWindowIds.filter { activeWindowIds.contains($0) }
    }
    
    // Check if there's a scheduled notification for this window that will fire soon
    private func checkForScheduledNotification(for window: DecisionWindow) -> Bool {
        let isJustRemindMe = window.defaultPauseIntention != nil && 
                             window.defaultMicroSaveAmount == nil && 
                             window.defaultSpendGate == nil
        
        let identifierPrefix = isJustRemindMe 
            ? "decision_window_reminder_\(window.id)"
            : "decision_window_\(window.id)"
        
        var hasScheduled = false
        
        // Check pending notifications synchronously (this is a quick check)
        let semaphore = DispatchSemaphore(value: 0)
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            hasScheduled = requests.contains { request in
                request.identifier.hasPrefix(identifierPrefix)
            }
            semaphore.signal()
        }
        semaphore.wait()
        
        return hasScheduled
    }
    
    // MARK: - Notifications
    
    private func scheduleNotifications() {
        // Request notification permission
        // Note: Time-sensitive notifications are configured via entitlements, not authorization options
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, _ in
            guard granted else { return }
            
            // Cancel all existing notifications
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            // Schedule notifications for each enabled window
            for window in self.windows where window.isEnabled {
                self.scheduleNotification(for: window)
            }
        }
    }
    
    private func scheduleNotification(for window: DecisionWindow) {
        // Check if this is a "Just Remind Me" window
        let isJustRemindMe = window.defaultPauseIntention != nil && 
                             window.defaultMicroSaveAmount == nil && 
                             window.defaultSpendGate == nil
        
        let content = UNMutableNotificationContent()
        
        if isJustRemindMe {
            // For "Just Remind Me" windows, use the pause intention text
            let reminderText = window.defaultPauseIntention ?? "Remember why you're saving"
            content.title = "Reminder"
            content.body = reminderText
            content.userInfo = [
                "type": "decision_window_reminder",
                "windowId": window.id
            ]
        } else {
            // For regular Decision Windows, use the standard copy
            let (title, body) = getNotificationCopy(for: window)
            content.title = title
            content.body = body
            content.userInfo = [
                "type": "decision_window",
                "windowId": window.id
            ]
        }
        
        content.sound = .default
        
        // Make notifications time-sensitive alerts so they don't get drowned out
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        let calendar = Calendar.current
        let now = Date()
        let currentDay = calendar.component(.weekday, from: now)
        
        // Track if we've scheduled a notification for today to avoid duplicates
        var scheduledForToday = false
        
        // Schedule for each day of week
        for day in window.daysOfWeek {
            var dateComponents = DateComponents()
            dateComponents.weekday = day
            dateComponents.hour = window.time.hour
            dateComponents.minute = window.time.minute
            
            // If this is today and the time hasn't passed yet, schedule an immediate notification for today
            if day == currentDay {
                if let windowHour = window.time.hour, let windowMinute = window.time.minute {
                    if let windowTime = calendar.date(bySettingHour: windowHour, minute: windowMinute, second: 0, of: now) {
                        // If the window time is in the future today, schedule a one-time notification for today
                        if windowTime > now {
                            let timeInterval = windowTime.timeIntervalSince(now)
                            // Only schedule if it's within the next 24 hours (to avoid scheduling too far in advance)
                            if timeInterval > 0 && timeInterval < 86400 {
                                let immediateTrigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                                let immediateIdentifier = isJustRemindMe 
                                    ? "decision_window_reminder_\(window.id)_today"
                                    : "decision_window_\(window.id)_today"
                                
                                let immediateRequest = UNNotificationRequest(
                                    identifier: immediateIdentifier,
                                    content: content,
                                    trigger: immediateTrigger
                                )
                                
                                UNUserNotificationCenter.current().add(immediateRequest) { error in
                                    if let error = error {
                                        print("❌ [DecisionWindowsService] Failed to schedule today's notification: \(error)")
                                    } else {
                                        let type = isJustRemindMe ? "reminder" : "prompt"
                                        print("✅ [DecisionWindowsService] Scheduled \(type) notification for \(window.name) today at \(windowHour):\(String(format: "%02d", windowMinute))")
                                        // Mark as unread when scheduled (will be delivered when notification fires)
                                        NotificationBadgeManager.shared.markNotificationAsUnread(identifier: immediateIdentifier)
                                    }
                                }
                                scheduledForToday = true // Mark that we've scheduled for today
                            }
                        }
                    }
                }
            }
            
            // Schedule recurring notification for future occurrences
            // BUT: Skip today since we already scheduled a one-time notification for today
            // This prevents duplicate notifications on the same day
            if day != currentDay || !scheduledForToday {
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let identifier = isJustRemindMe 
                    ? "decision_window_reminder_\(window.id)_\(day)"
                    : "decision_window_\(window.id)_\(day)"
                
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ [DecisionWindowsService] Failed to schedule recurring notification: \(error)")
                    } else {
                        let type = isJustRemindMe ? "reminder" : "prompt"
                        print("✅ [DecisionWindowsService] Scheduled recurring \(type) notification for \(window.name) on day \(day)")
                        // Mark as unread when scheduled (will be delivered when notification fires)
                        NotificationBadgeManager.shared.markNotificationAsUnread(identifier: identifier)
                    }
                }
            }
        }
    }
    
    private func sendDecisionWindowNotification(for window: DecisionWindow) {
        // Check if this is a "Just Remind Me" or "Manual Entry" window (has defaultPauseIntention but no other actions)
        let isJustRemindMe = window.defaultPauseIntention != nil && 
                             window.defaultMicroSaveAmount == nil && 
                             window.defaultSpendGate == nil
        
        if isJustRemindMe {
            // For "Just Remind Me" or "Manual Entry" windows, only send a notification - no in-app prompt
            let reminderText = window.defaultPauseIntention ?? "Remember why you're saving"
            
            let content = UNMutableNotificationContent()
            content.title = "Reminder"
            content.body = reminderText
            content.sound = .default
            // Make reminder notifications time-sensitive alerts
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
            content.userInfo = [
                "type": "decision_window_reminder",
                "windowId": window.id
            ]
            
            // Send immediate notification
            let request = UNNotificationRequest(
                identifier: "decision_window_reminder_\(window.id)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil // Immediate delivery
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ [DecisionWindowsService] Failed to send reminder notification: \(error)")
                } else {
                    print("✅ [DecisionWindowsService] Sent reminder notification: \(reminderText)")
                    // Mark as unread and update badge when notification is successfully added
                    let identifier = request.identifier
                    NotificationBadgeManager.shared.markNotificationAsUnread(identifier: identifier)
                    NotificationBadgeManager.shared.updateBadgeCount()
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NotificationDelivered"),
                        object: nil
                    )
                }
            }
            
            // Don't set flags for in-app prompt - this is just a reminder
            return
        }
        
        // Check if this is a "Save First" window (has defaultMicroSaveAmount)
        if let saveAmount = window.defaultMicroSaveAmount {
            // For "Save First" windows, automatically open Plaid transfer view
            let content = UNMutableNotificationContent()
            content.title = "Time to Save"
            content.body = "Open Soteria to transfer $\(String(format: "%.2f", saveAmount)) to your savings."
            content.sound = .default
            // Make save-first notifications time-sensitive alerts
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
            content.userInfo = [
                "type": "decision_window_save_first",
                "windowId": window.id,
                "amount": saveAmount
            ]
            
            // Send immediate notification
            let request = UNNotificationRequest(
                identifier: "decision_window_save_first_\(window.id)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil // Immediate delivery
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ [DecisionWindowsService] Failed to send Save First notification: \(error)")
                } else {
                    print("✅ [DecisionWindowsService] Sent Save First notification for $\(saveAmount)")
                    // Update badge when notification is successfully added
                    NotificationBadgeManager.shared.updateBadgeCount()
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NotificationDelivered"),
                        object: nil
                    )
                }
            }
            
            // Post notification to open Plaid transfer view
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenPlaidTransferForDecisionWindow"),
                object: [
                    "windowId": window.id,
                    "amount": saveAmount
                ]
            )
            
            return
        }
        
        // For regular Decision Windows (with Protect Amount or other actions), send notification and show in-app prompt
        let (title, body) = getNotificationCopy(for: window)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        // Make Decision Window notifications time-sensitive alerts
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        content.userInfo = [
            "type": "decision_window",
            "windowId": window.id
        ]
        
        // Send immediate notification
        let request = UNNotificationRequest(
            identifier: "decision_window_immediate_\(window.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ [DecisionWindowsService] Failed to send immediate notification: \(error)")
                } else {
                    print("✅ [DecisionWindowsService] Sent Decision Window notification: \(title)")
                    // Mark as unread and update badge when notification is successfully added
                    let identifier = request.identifier
                    NotificationBadgeManager.shared.markNotificationAsUnread(identifier: identifier)
                    NotificationBadgeManager.shared.updateBadgeCount()
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NotificationDelivered"),
                        object: nil
                    )
                }
            }
        
        // Set flag for in-app prompt (only show when user taps notification, not immediately)
        UserDefaults.standard.set(true, forKey: "shouldShowDecisionWindowPrompt")
        UserDefaults.standard.set(window.id, forKey: "activeDecisionWindowId")
        
        // DO NOT post DecisionWindowActive notification here - it will be posted by NotificationDelegate
        // when the user actually taps the notification. This prevents the prompt from showing
        // when notifications are sent programmatically (e.g., when creating a window).
    }
    
    // MARK: - Notification Copy
    
    private func getNotificationCopy(for window: DecisionWindow) -> (title: String, body: String) {
        // Use AI service to select best copy variant
        let aiService = BehavioralAIService.shared
        let variant = aiService.selectCopyVariant(for: window.id)
        
        // Map variant to approved copy
        switch variant {
        case .aMomentForToday:
            return ("A moment for today", "Before the day continues, choose how you want to protect your money.")
        case .saveFirst:
            return ("Save before you spend", "Take a moment to set aside a small amount for today.")
        case .takeAPause:
            return ("Pause for a second", "What do you want today's money to support?")
        case .protectYourMoney:
            return ("Protect today's money", "Set aside a small amount now, so it's there later.")
        case .beforeDayEnds:
            let hour = window.time.hour ?? 12
            if hour >= 18 {
                return ("Before the day winds down", "Choose how you want to take care of tomorrow.")
            } else {
                return ("A moment for today", "Before the day continues, choose how you want to protect your money.")
            }
        }
    }
    
    // MARK: - Commitment Management
    
    private func loadCommitments() {
        guard let data = UserDefaults.standard.data(forKey: commitmentsKey),
              let decoded = try? JSONDecoder().decode([DecisionWindowCommitment].self, from: data) else {
            commitments = []
            return
        }
        // Filter out expired commitments
        commitments = decoded.filter { $0.isActive }
        saveCommitments()
    }
    
    private func saveCommitments() {
        // Remove expired commitments before saving
        commitments = commitments.filter { $0.isActive }
        if let encoded = try? JSONEncoder().encode(commitments) {
            UserDefaults.standard.set(encoded, forKey: commitmentsKey)
        }
    }
    
    func addCommitment(_ commitment: DecisionWindowCommitment) {
        commitments.append(commitment)
        saveCommitments()
        
        // Execute micro-save immediately if that's the type
        if commitment.type == .microSave, let amount = commitment.microSaveAmount {
            executeMicroSave(commitmentId: commitment.id, amount: amount)
        }
    }
    
    func executeMicroSave(commitmentId: String, amount: Double) {
        guard let index = commitments.firstIndex(where: { $0.id == commitmentId }) else { return }
        
        // Get active goal ID if available
        let activeGoalId = GoalsService.shared.activeGoal?.id
        
        // Record the save via PlaidService with timestamp and goalId
        // Note: PlaidService will handle the actual transfer or virtual savings
        PlaidService.shared.recordManualDeposit(amount: amount, goalId: activeGoalId)
        
        // Track transfer result with AI service
        let aiService = BehavioralAIService.shared
        // For now, assume success (PlaidService handles actual transfer errors internally)
        // In a full implementation, we'd check the result from PlaidService
        aiService.recordTransfer(
            amount: amount,
            source: .decisionWindow,
            result: .success
        )
        
        // Mark as executed
        commitments[index].microSaveExecuted = true
        saveCommitments()
        
        // Post notification
        NotificationCenter.default.post(
            name: NSNotification.Name("MicroSaveExecuted"),
            object: amount
        )
    }
    
    func triggerSpendGate(condition: String) {
        // Find active spend gate commitments that match the condition
        let matchingCommitments = commitments.filter { commitment in
            commitment.type == .spendGate &&
            commitment.isActive &&
            !commitment.spendGateTriggered &&
            commitment.spendGate?.condition == condition
        }
        
        for commitment in matchingCommitments {
            guard let index = commitments.firstIndex(where: { $0.id == commitment.id }),
                  let spendGate = commitment.spendGate else { continue }
            
            // Mark as triggered
            commitments[index].spendGateTriggered = true
            
            // Execute the save
            PlaidService.shared.recordManualDeposit(amount: spendGate.saveAmount)
            
            // Track transfer result with AI service
            let aiService = BehavioralAIService.shared
            aiService.recordTransfer(
                amount: spendGate.saveAmount,
                source: .decisionWindow,
                result: .success
            )
            
            commitments[index].spendGateExecuted = true
            
            // Post notification
            NotificationCenter.default.post(
                name: NSNotification.Name("SpendGateExecuted"),
                object: spendGate
            )
        }
        
        saveCommitments()
    }
    
    private func startCommitmentMonitoring() {
        // Check commitments every minute
        commitmentCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkCommitments()
        }
    }
    
    private func checkCommitments() {
        // Remove expired commitments
        let beforeCount = commitments.count
        commitments = commitments.filter { $0.isActive }
        
        if commitments.count != beforeCount {
            saveCommitments()
        }
        
        // Check for pause intentions that need reminders
        for commitment in commitments where commitment.type == .pauseIntention && !commitment.pauseIntentionReminderSent {
            // Logic to send pause intention reminders would go here
            // This could be triggered by app usage patterns, time of day, etc.
        }
    }
    
    // MARK: - Helper Methods
    
    func getActiveWindow() -> DecisionWindow? {
        return windows.first { $0.isCurrentlyActive() }
    }
    
    func getActiveCommitments(for windowId: String) -> [DecisionWindowCommitment] {
        return commitments.filter { $0.windowId == windowId && $0.isActive }
    }
}

