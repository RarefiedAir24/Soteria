//
//  ProtectionHoursView.swift
//  soteria
//
//  Manage Protection Hours schedules (time-based reminders, no app blocking)
//

import SwiftUI

struct ProtectionHoursView: View {
    @EnvironmentObject var protectionHoursService: ProtectionHoursService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showCreateSchedule = false
    @State private var editingSchedule: ProtectionHoursSchedule? = nil
    @State private var showPaywall = false
    
    var body: some View {
        protectionHoursContent
    }
    
    private var protectionHoursContent: some View {
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
                            Image(systemName: protectionHoursService.isProtectionActive ? "moon.fill" : "moon")
                                .font(.system(size: 24))
                                .foregroundColor(protectionHoursService.isProtectionActive ? Color.reverBlue : .gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(protectionHoursService.isProtectionActive ? "Protection Hours Active" : "Protection Hours Inactive")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color.midnightSlate)
                                
                                if protectionHoursService.isProtectionActive {
                                    Text("You'll receive reminders during this time")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.reverBlue)
                                }
                                
                                if let schedule = protectionHoursService.currentActiveSchedule {
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
                    if protectionHoursService.schedules.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                            
                            Text("No Protection Hours Set")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                            
                            Text("Set times when you want gentle reminders to pause and reflect before making impulse decisions.")
                                .font(.system(size: 14))
                                .foregroundColor(Color.softGraphite)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                // Free tier: Can create 1 schedule
                                if !subscriptionService.isPremium && protectionHoursService.schedules.count >= 1 {
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
                            ForEach(protectionHoursService.schedules) { schedule in
                                ProtectionHoursScheduleCard(schedule: schedule)
                                    .environmentObject(protectionHoursService)
                                    .environmentObject(subscriptionService)
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
                    if !protectionHoursService.schedules.isEmpty {
                        Button(action: {
                            // Free tier: Can't create more than 1
                            if !subscriptionService.isPremium && protectionHoursService.schedules.count >= 1 {
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
                Text("Protection Hours")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color.midnightSlate)
                
                Text("Gentle reminders during vulnerable times")
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
            CreateProtectionHoursScheduleView()
                .environmentObject(protectionHoursService)
                .environmentObject(subscriptionService)
        }
        .sheet(item: $editingSchedule) { schedule in
            CreateProtectionHoursScheduleView(editingSchedule: schedule)
                .environmentObject(protectionHoursService)
                .environmentObject(subscriptionService)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .onAppear {
            protectionHoursService.ensureSchedulesLoaded()
            protectionHoursService.startMonitoring()
            Task {
                await protectionHoursService.checkProtectionHoursStatus()
            }
        }
    }
}

struct ProtectionHoursScheduleCard: View {
    @EnvironmentObject var protectionHoursService: ProtectionHoursService
    @EnvironmentObject var subscriptionService: SubscriptionService
    let schedule: ProtectionHoursSchedule
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
                                    try protectionHoursService.toggleSchedule(schedule, isPremium: subscriptionService.isPremium)
                                } catch {
                                    print("❌ [ProtectionHoursScheduleCard] Failed to toggle schedule: \(error)")
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
                        try protectionHoursService.deleteSchedule(schedule, isPremium: subscriptionService.isPremium)
                    } catch {
                        print("❌ [ProtectionHoursScheduleCard] Failed to delete schedule: \(error)")
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
                    try protectionHoursService.deleteSchedule(schedule, isPremium: subscriptionService.isPremium)
                } catch {
                    print("❌ [ProtectionHoursScheduleCard] Failed to delete schedule: \(error)")
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(schedule.name)'? This cannot be undone.")
        }
    }
}

struct CreateProtectionHoursScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var protectionHoursService: ProtectionHoursService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showPaywall = false
    @State private var showTimeValidationAlert = false
    
    let editingSchedule: ProtectionHoursSchedule?
    
    @State private var name: String = ""
    @State private var startHour: Int = 22
    @State private var startMinute: Int = 0
    @State private var endHour: Int = 23
    @State private var endMinute: Int = 0
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    
    init(editingSchedule: ProtectionHoursSchedule? = nil) {
        self.editingSchedule = editingSchedule
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Schedule Name") {
                    TextField("e.g., Late Night Protection", text: $name)
                }
                
                Section("Time Range") {
                    DatePicker("Start Time", selection: Binding(
                        get: {
                            Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: Date()) ?? Date()
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            let newStartHour = components.hour ?? 22
                            let newStartMinute = components.minute ?? 0
                            
                            let startTotalMinutes = newStartHour * 60 + newStartMinute
                            let endTotalMinutes = endHour * 60 + endMinute
                            
                            if endTotalMinutes <= startTotalMinutes {
                                let adjustedEndMinutes = min(startTotalMinutes + 1, 23 * 60 + 59)
                                endHour = adjustedEndMinutes / 60
                                endMinute = adjustedEndMinutes % 60
                            }
                            
                            startHour = newStartHour
                            startMinute = newStartMinute
                        }
                    ), displayedComponents: .hourAndMinute)
                    
                    DatePicker("End Time", selection: Binding(
                        get: {
                            Calendar.current.date(bySettingHour: endHour, minute: endMinute, second: 0, of: Date()) ?? Date()
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            let newEndHour = components.hour ?? 23
                            let newEndMinute = components.minute ?? 0
                            
                            let startTotalMinutes = startHour * 60 + startMinute
                            let endTotalMinutes = newEndHour * 60 + newEndMinute
                            
                            if endTotalMinutes <= startTotalMinutes {
                                let adjustedEndMinutes = min(startTotalMinutes + 1, 23 * 60 + 59)
                                endHour = adjustedEndMinutes / 60
                                endMinute = adjustedEndMinutes % 60
                            } else {
                                endHour = newEndHour
                                endMinute = newEndMinute
                            }
                        }
                    ), displayedComponents: .hourAndMinute)
                }
                
                Section("Days of Week") {
                    let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
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
            }
            .navigationTitle(editingSchedule != nil ? "Edit Schedule" : "New Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSchedule()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if let schedule = editingSchedule {
                name = schedule.name
                startHour = schedule.startTime.hour ?? 22
                startMinute = schedule.startTime.minute ?? 0
                endHour = schedule.endTime.hour ?? 23
                endMinute = schedule.endTime.minute ?? 0
                selectedDays = schedule.daysOfWeek
            }
        }
        .alert("Invalid Time Range", isPresented: $showTimeValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("End time must be after start time.")
        }
    }
    
    private func isValidTimeRange(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) -> Bool {
        let startTotalMinutes = startHour * 60 + startMinute
        let endTotalMinutes = endHour * 60 + endMinute
        return endTotalMinutes > startTotalMinutes
    }
    
    private func saveSchedule() {
        // Check if user can add schedule
        if editingSchedule == nil && !protectionHoursService.canAddSchedule(isPremium: subscriptionService.isPremium) {
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
        
        if let editing = editingSchedule {
            var updated = editing
            updated.name = name
            updated.startTime = startTime
            updated.endTime = endTime
            updated.daysOfWeek = selectedDays
            do {
                try protectionHoursService.updateSchedule(updated, isPremium: subscriptionService.isPremium)
            } catch {
                print("❌ [CreateProtectionHoursScheduleView] Failed to update schedule: \(error)")
                showPaywall = true
                return
            }
        } else {
            let newSchedule = ProtectionHoursSchedule(
                name: name,
                startTime: startTime,
                endTime: endTime,
                daysOfWeek: selectedDays
            )
            do {
                try protectionHoursService.addSchedule(newSchedule, isPremium: subscriptionService.isPremium)
            } catch {
                print("❌ [CreateProtectionHoursScheduleView] Failed to add schedule: \(error)")
                showPaywall = true
                return
            }
        }
        
        dismiss()
    }
}

#Preview {
    ProtectionHoursView()
        .environmentObject(ProtectionHoursService.shared)
        .environmentObject(SubscriptionService.shared)
}

