//
//  QuietHoursView.swift
//  rever
//
//  Manage spending quiet hours schedules
//

import SwiftUI

struct QuietHoursView: View {
    @EnvironmentObject var quietHoursService: QuietHoursService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showCreateSchedule = false
    @State private var editingSchedule: QuietHoursSchedule? = nil
    @State private var showPaywall = false
    
    var body: some View {
        // Free users can have 1 schedule (view-only), premium users get unlimited
        quietHoursContent
    }
    
    private var quietHoursContent: some View {
        ZStack(alignment: .top) {
            Color.cloudWhite
                .ignoresSafeArea()
            
            ScrollView {
                Color.clear
                    .frame(height: 60)
                
                VStack(spacing: 24) {
                    // Current Status Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: quietHoursService.isQuietModeActive ? "moon.fill" : "moon")
                                .font(.system(size: 24))
                                .foregroundColor(quietHoursService.isQuietModeActive ? Color.reverBlue : .gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quietHoursService.isQuietModeActive ? "Financial Quiet Mode Active" : "Financial Quiet Mode Inactive")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color.midnightSlate)
                                
                                if quietHoursService.isQuietModeActive {
                                    Text("Your sanctuary is protecting you")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.reverBlue)
                                }
                                
                                if let schedule = quietHoursService.currentActiveSchedule {
                                    Text(schedule.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                } else {
                                    Text("No active schedule")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Schedules List
                    if quietHoursService.schedules.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                            
                            Text("No Quiet Hours Set")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                            
                            Text("Financial Quiet Mode is your sanctuary, not a restriction.\nCreate protective boundaries during vulnerable times.")
                                .font(.system(size: 14))
                                .foregroundColor(Color.softGraphite)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                // Free tier: Can create 1 schedule
                                if !subscriptionService.isPremium && quietHoursService.schedules.count >= 1 {
                                    showPaywall = true
                                } else {
                                    showCreateSchedule = true
                                }
                            }) {
                                Text("Create Schedule")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.reverBlue)
                                    )
                            }
                        }
                        .padding(.vertical, 60)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(quietHoursService.schedules) { schedule in
                                QuietHoursScheduleCard(schedule: schedule)
                                    .environmentObject(quietHoursService)
                                    .environmentObject(subscriptionService)
                                    .environmentObject(DeviceActivityService.shared)
                                    .onTapGesture {
                                        // Free tier: Show paywall if trying to edit
                                        if !subscriptionService.isPremium {
                                            showPaywall = true
                                        } else {
                                            editingSchedule = schedule
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Create Schedule Button (Premium only if already have 1)
                    if !quietHoursService.schedules.isEmpty {
                        Button(action: {
                            // Free tier: Can't create more than 1
                            if !subscriptionService.isPremium && quietHoursService.schedules.count >= 1 {
                                showPaywall = true
                            } else {
                                showCreateSchedule = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create New Schedule")
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.reverBlue)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Fixed Header
            VStack(spacing: 2) {
                Text("Financial Quiet Mode")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color.midnightSlate)
                
                Text("Your sanctuary, not a restriction")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Color(red: 0.92, green: 0.97, blue: 0.94)
                    .ignoresSafeArea(edges: .top)
            )
            .zIndex(100)
        }
        .sheet(isPresented: $showCreateSchedule) {
            CreateQuietHoursScheduleView()
                .environmentObject(quietHoursService)
                .environmentObject(subscriptionService)
                .environmentObject(DeviceActivityService.shared)
        }
        .sheet(item: $editingSchedule) { schedule in
            CreateQuietHoursScheduleView(editingSchedule: schedule)
                .environmentObject(quietHoursService)
                .environmentObject(subscriptionService)
                .environmentObject(DeviceActivityService.shared)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .onAppear {
            // OPTION 1 FIX: Load schedules on-demand when view appears
            // This fixes the issue where schedules weren't loading on app launch
            // (QuietHoursService.init() does nothing to prevent startup delays)
            // REVERT: If this causes issues, remove this line and schedules will only load when explicitly accessed
            quietHoursService.ensureSchedulesLoaded()
            
            // Update premium status for mood-based monitoring
            quietHoursService.updatePremiumStatus(subscriptionService.isPremium)
        }
        .onChange(of: subscriptionService.isPremium) { oldValue, newValue in
            quietHoursService.updatePremiumStatus(newValue)
        }
    }
    
    private var paywallPrompt: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "moon.fill")
                .font(.system(size: 64))
                .foregroundColor(.reverBlue)
            
            Text("Quiet Hours")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.midnightSlate)
            
            Text("Create schedules to block distracting apps during your quiet hours. This feature is available for premium subscribers.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showPaywall = true
            }) {
                Text("Upgrade to Premium")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.reverBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cloudWhite)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
    }
}

struct QuietHoursScheduleCard: View {
    @EnvironmentObject var quietHoursService: QuietHoursService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    let schedule: QuietHoursSchedule
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false
    
    private var timeString: String {
        let startHour = schedule.startTime.hour ?? 0
        let startMin = schedule.startTime.minute ?? 0
        let endHour = schedule.endTime.hour ?? 0
        let endMin = schedule.endTime.minute ?? 0
        
        let start = String(format: "%d:%02d", startHour, startMin)
        let end = String(format: "%d:%02d", endHour, endMin)
        return "\(start) - \(end)"
    }
    
    private var daysString: String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = schedule.daysOfWeek.sorted()
        if sortedDays.count == 7 {
            return "Every day"
        } else if sortedDays == [2, 3, 4, 5, 6] {
            return "Weekdays"
        } else if sortedDays == [1, 7] {
            return "Weekends"
        } else {
            return sortedDays.map { dayNames[$0 - 1] }.joined(separator: ", ")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.midnightSlate)
                    
                    Text(timeString)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text(daysString)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Delete button (Premium only)
                    if subscriptionService.isPremium {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Free users cannot toggle - editing is premium only
                    if subscriptionService.isPremium {
                        Toggle("", isOn: Binding(
                            get: { schedule.isActive },
                            set: { newValue in
                                do {
                                    try quietHoursService.toggleSchedule(schedule, isPremium: subscriptionService.isPremium)
                                } catch {
                                    print("❌ [QuietHoursScheduleCard] Failed to toggle schedule: \(error)")
                                }
                            }
                        ))
                    } else {
                        // Show read-only state for free users
                        HStack(spacing: 4) {
                            Image(systemName: schedule.isActive ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(schedule.isActive ? .reverBlue : .softGraphite)
                            Text(schedule.isActive ? "Active" : "Inactive")
                                .font(.system(size: 12))
                                .foregroundColor(.softGraphite)
                        }
                        .opacity(0.6) // Visual indicator that it's read-only
                    }
                }
            }
            
            if schedule.isCurrentlyActive() {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.reverBlue)
                    Text("Currently Active")
                        .font(.system(size: 12))
                        .foregroundColor(Color.reverBlue)
                }
            }
            
            // Display monitored apps
            if !schedule.selectedAppIndices.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monitored Apps")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.softGraphite)
                    
                    // Get app names from DeviceActivityService
                    let appNames = schedule.selectedAppIndices.compactMap { index -> String? in
                        deviceActivityService.appNames[index] ?? "App \(index + 1)"
                    }
                    
                    if !appNames.isEmpty {
                        // Simple wrapping layout using LazyVGrid
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(appNames, id: \.self) { appName in
                                HStack(spacing: 4) {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 10))
                                    Text(appName)
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                }
                                .foregroundColor(Color.reverBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.reverBlue.opacity(0.1))
                                )
                            }
                        }
                    } else {
                        Text("\(schedule.selectedAppIndices.count) app\(schedule.selectedAppIndices.count == 1 ? "" : "s") selected")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "app.badge")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("No apps selected")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        // Only allow delete for premium users (prevents loopholes)
        .swipeActions(edge: .trailing, allowsFullSwipe: subscriptionService.isPremium) {
            if subscriptionService.isPremium {
                Button(role: .destructive) {
                    do {
                        try quietHoursService.deleteSchedule(schedule, isPremium: subscriptionService.isPremium)
                    } catch {
                        print("❌ [QuietHoursScheduleCard] Failed to delete schedule: \(error)")
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .alert("Delete Schedule", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                do {
                    try quietHoursService.deleteSchedule(schedule, isPremium: subscriptionService.isPremium)
                } catch {
                    print("❌ [QuietHoursScheduleCard] Failed to delete schedule: \(error)")
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(schedule.name)'? This cannot be undone.")
        }
    }
}

struct CreateQuietHoursScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var quietHoursService: QuietHoursService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    @State private var showPaywall = false
    @State private var showLimitAlert = false
    @State private var showAppSelection = false
    @State private var showTimeValidationAlert = false
    
    let editingSchedule: QuietHoursSchedule?
    
    @State private var name: String = ""
    @State private var startHour: Int = 22
    @State private var startMinute: Int = 0
    @State private var endHour: Int = 23
    @State private var endMinute: Int = 0
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    @State private var selectedAppIndices: Set<Int> = []
    
    init(editingSchedule: QuietHoursSchedule? = nil) {
        self.editingSchedule = editingSchedule
        if let schedule = editingSchedule {
            _name = State(initialValue: schedule.name)
            let scheduleStartHour = schedule.startTime.hour ?? 22
            let scheduleStartMinute = schedule.startTime.minute ?? 0
            let scheduleEndHour = schedule.endTime.hour ?? 23
            let scheduleEndMinute = schedule.endTime.minute ?? 0
            
            // If editing an overnight schedule, adjust to same-day
            let startTotalMinutes = scheduleStartHour * 60 + scheduleStartMinute
            let endTotalMinutes = scheduleEndHour * 60 + scheduleEndMinute
            
            if endTotalMinutes <= startTotalMinutes {
                // Overnight schedule detected - adjust end time to same day
                _endHour = State(initialValue: min(23, scheduleStartHour + 1))
                _endMinute = State(initialValue: scheduleStartMinute)
            } else {
                _endHour = State(initialValue: scheduleEndHour)
                _endMinute = State(initialValue: scheduleEndMinute)
            }
            
            _startHour = State(initialValue: scheduleStartHour)
            _startMinute = State(initialValue: scheduleStartMinute)
            _selectedDays = State(initialValue: schedule.daysOfWeek)
            // Load selectedAppIndices from schedule - these should persist across app rebuilds
            _selectedAppIndices = State(initialValue: Set(schedule.selectedAppIndices))
            
            // Log to help diagnose persistence issues
            print("📋 [CreateQuietHoursScheduleView] Loading schedule '\(schedule.name)' with \(schedule.selectedAppIndices.count) selected app indices: \(schedule.selectedAppIndices)")
        }
    }
    
    private let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Schedule Name") {
                    TextField("e.g., Late Night Protection", text: $name)
                }
                
                Section("Time Range") {
                    // ENHANCED: Use wheel style for clearer minute selection (e.g., 8:05 AM, 9:10 PM)
                    DatePicker("Start Time", selection: Binding(
                        get: {
                            Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: Date()) ?? Date()
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            let newStartHour = components.hour ?? 22
                            let newStartMinute = components.minute ?? 0
                            
                            // Validate: end time must be at least 1 minute after start time on same day
                                let startTotalMinutes = newStartHour * 60 + newStartMinute
                                let endTotalMinutes = endHour * 60 + endMinute
                                
                            // Prevent overnight schedules - end must be after start on same day
                            // Adjust end time if it's not at least 1 minute after start
                                if endTotalMinutes <= startTotalMinutes {
                                // Adjust end time to be at least 1 minute after start, but same day
                                let adjustedEndMinutes = min(startTotalMinutes + 1, 23 * 60 + 59)
                                endHour = adjustedEndMinutes / 60
                                endMinute = adjustedEndMinutes % 60
                            }
                            
                            startHour = newStartHour
                            startMinute = newStartMinute
                        }
                    ), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    
                    DatePicker("End Time", selection: Binding(
                        get: {
                            Calendar.current.date(bySettingHour: endHour, minute: endMinute, second: 0, of: Date()) ?? Date()
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            let newEndHour = components.hour ?? 23
                            let newEndMinute = components.minute ?? 0
                            
                            // Validate: end time must be at least 1 minute after start time on same day
                                let startTotalMinutes = startHour * 60 + startMinute
                                let endTotalMinutes = newEndHour * 60 + newEndMinute
                                
                            // Prevent overnight schedules - end must be after start on same day
                                if endTotalMinutes <= startTotalMinutes {
                                // Overnight schedule detected - adjust to same day
                                let adjustedEndMinutes = min(startTotalMinutes + 1, 23 * 60 + 59)
                                endHour = adjustedEndMinutes / 60
                                endMinute = adjustedEndMinutes % 60
                            } else {
                                // Same day schedule - use selected time
                                endHour = newEndHour
                                endMinute = newEndMinute
                            }
                        }
                    ), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    
                    if !isValidTimeRange(startHour: startHour, startMinute: startMinute, endHour: endHour, endMinute: endMinute) {
                        Text("End time must be at least 1 minute after start time on the same day")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section("Days of Week") {
                    ForEach(1...7, id: \.self) { day in
                        Toggle(dayNames[day - 1], isOn: Binding(
                            get: { selectedDays.contains(day) },
                            set: { isOn in
                                if isOn {
                                    selectedDays.insert(day)
                                } else {
                                    selectedDays.remove(day)
                                }
                            }
                        ))
                    }
                }
                
                Section("Monitored Apps") {
                    // Get available apps from master selection
                    let availableAppIndices = Array(0..<deviceActivityService.cachedAppsCount)
                    
                    if availableAppIndices.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No apps selected for monitoring")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Go to Settings → App Monitoring to select apps first")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        ForEach(availableAppIndices, id: \.self) { index in
                            let appName = deviceActivityService.appNames[index] ?? "App \(index + 1)"
                            Toggle(appName, isOn: Binding(
                                get: { 
                                    let isSelected = selectedAppIndices.contains(index)
                                    // Log on first render to debug
                                    if index == availableAppIndices.first {
                                        print("🔍 [CreateQuietHoursScheduleView] Toggle get() for index \(index) (\(appName)): \(isSelected ? "SELECTED" : "UNSELECTED")")
                                        print("🔍 [CreateQuietHoursScheduleView] Current selectedAppIndices: \(Array(selectedAppIndices).sorted())")
                                    }
                                    return isSelected
                                },
                                set: { isOn in
                                    // Free users limited to 1 app
                                    if !subscriptionService.isPremium && selectedAppIndices.count >= 1 && isOn {
                                        // Already at limit, don't allow more
                                        return
                                    }
                                    
                                    if isOn {
                                        selectedAppIndices.insert(index)
                                        print("✅ [CreateQuietHoursScheduleView] Selected app index \(index): \(appName)")
                                    } else {
                                        selectedAppIndices.remove(index)
                                        print("❌ [CreateQuietHoursScheduleView] Deselected app index \(index): \(appName)")
                                    }
                                    print("📋 [CreateQuietHoursScheduleView] Current selectedAppIndices: \(Array(selectedAppIndices).sorted())")
                                }
                            ))
                        }
                    }
                }
                
                // Premium Features Section
                if !subscriptionService.isPremium {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(Color.reverBlue)
                                Text("Premium Features")
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.gray)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Smart Auto-Protection")
                                            .font(.subheadline)
                                        Text("Automatically protects based on behavior patterns - no input needed")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.gray)
                                    Text("Category Restrictions")
                                        .font(.subheadline)
                                }
                            }
                            .padding(.leading, 28)
                            
                            Button(action: {
                                showPaywall = true
                            }) {
                                Text("Upgrade to Premium")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.reverBlue)
                                    )
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(editingSchedule == nil ? "New Schedule" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSchedule()
                    }
                    .disabled(name.isEmpty || selectedDays.isEmpty || !isValidTimeRange(startHour: startHour, startMinute: startMinute, endHour: endHour, endMinute: endMinute))
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(subscriptionService)
            }
            .alert("Invalid Time Range", isPresented: $showTimeValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("End time must be at least 1 minute after start time on the same day. Overnight schedules are not allowed.")
            }
            .onAppear {
                // Ensure app count is loaded when view appears
                // This is critical for the toggles to show correctly
                if deviceActivityService.cachedAppsCount == 0 {
                    // Try to get count from UserDefaults if available
                    let cachedCount = UserDefaults.standard.integer(forKey: "cachedSelectedAppsCount")
                    if cachedCount > 0 {
                        deviceActivityService.cachedAppsCount = cachedCount
                    }
                }
                
                // Re-initialize selectedAppIndices from schedule if editing
                // This ensures the state is correct even if cachedAppsCount wasn't ready during init
                if let schedule = editingSchedule {
                    selectedAppIndices = Set(schedule.selectedAppIndices)
                    print("📋 [CreateQuietHoursScheduleView] onAppear - Restored \(selectedAppIndices.count) selected app indices: \(Array(selectedAppIndices).sorted())")
                    print("📋 [CreateQuietHoursScheduleView] Cached app count: \(deviceActivityService.cachedAppsCount)")
                }
            }
            .onChange(of: deviceActivityService.cachedAppsCount) { oldCount, newCount in
                // When app count loads, restore selectedAppIndices from schedule if editing
                // This ensures toggles are checked even if cachedAppsCount was 0 during init
                if newCount > 0 && newCount != oldCount, let schedule = editingSchedule {
                    // Restore from schedule - this ensures saved indices are displayed
                    let scheduleIndices = Set(schedule.selectedAppIndices)
                    if selectedAppIndices != scheduleIndices {
                        selectedAppIndices = scheduleIndices
                        print("📋 [CreateQuietHoursScheduleView] onChange - Restored \(selectedAppIndices.count) selected app indices after app count loaded: \(Array(selectedAppIndices).sorted())")
                    }
                }
            }
        }
    }
    
    // Validate that end time is at least 1 minute after start time on the same day
    // Overnight schedules (spanning midnight) are not allowed
    private func isValidTimeRange(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) -> Bool {
        let startTotalMinutes = startHour * 60 + startMinute
        let endTotalMinutes = endHour * 60 + endMinute
        
        // Prevent overnight schedules - end must be after start on same day
        // End time must be at least 1 minute after start time
        return endTotalMinutes > startTotalMinutes
    }
    
    private func saveSchedule() {
        // CRITICAL: Quiet hours are premium features - check subscription first
        guard subscriptionService.isPremium else {
            showPaywall = true
            return
        }
        
        // Validate time range before saving
        guard isValidTimeRange(startHour: startHour, startMinute: startMinute, endHour: endHour, endMinute: endMinute) else {
            showTimeValidationAlert = true
            return
        }
        
        let startTime = DateComponents(hour: startHour, minute: startMinute)
        let endTime = DateComponents(hour: endHour, minute: endMinute)
        
        // Validate app selection limit for free users
        if !subscriptionService.isPremium && selectedAppIndices.count > 1 {
            showLimitAlert = true
            return
        }
        
        let savedIndices = Array(selectedAppIndices).sorted()
        print("💾 [CreateQuietHoursScheduleView] Saving with \(savedIndices.count) selected app indices: \(savedIndices)")
        
        if let editing = editingSchedule {
            var updated = editing
            updated.name = name
            updated.startTime = startTime
            updated.endTime = endTime
            updated.daysOfWeek = selectedDays
            updated.selectedAppIndices = savedIndices
            do {
                try quietHoursService.updateSchedule(updated, isPremium: subscriptionService.isPremium)
            } catch {
                print("❌ [CreateQuietHoursScheduleView] Failed to update schedule: \(error)")
                showPaywall = true
                return
            }
        } else {
            let newSchedule = QuietHoursSchedule(
                name: name,
                startTime: startTime,
                endTime: endTime,
                daysOfWeek: selectedDays,
                selectedAppIndices: savedIndices
            )
            quietHoursService.addSchedule(newSchedule)
        }
        
        dismiss()
    }
}

#Preview {
    QuietHoursView()
        .environmentObject(QuietHoursService.shared)
}

