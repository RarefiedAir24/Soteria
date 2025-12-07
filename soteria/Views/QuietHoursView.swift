//
//  QuietHoursView.swift
//  rever
//
//  Manage spending quiet hours schedules
//

import SwiftUI

struct QuietHoursView: View {
    @EnvironmentObject var quietHoursService: QuietHoursService
    @State private var showCreateSchedule = false
    @State private var editingSchedule: QuietHoursSchedule? = nil
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.98, green: 0.98, blue: 0.98)
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
                                .foregroundColor(quietHoursService.isQuietModeActive ? Color(red: 0.1, green: 0.6, blue: 0.3) : .gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quietHoursService.isQuietModeActive ? "Financial Quiet Mode Active" : "Financial Quiet Mode Inactive")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
                                if quietHoursService.isQuietModeActive {
                                    Text("Your sanctuary is protecting you")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
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
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                showCreateSchedule = true
                            }) {
                                Text("Create Schedule")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.1, green: 0.6, blue: 0.3))
                                    )
                            }
                        }
                        .padding(.vertical, 60)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(quietHoursService.schedules) { schedule in
                                QuietHoursScheduleCard(schedule: schedule)
                                    .environmentObject(quietHoursService)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Create Schedule Button
                    if !quietHoursService.schedules.isEmpty {
                        Button(action: {
                            showCreateSchedule = true
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
                                    .fill(Color(red: 0.1, green: 0.6, blue: 0.3))
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
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                
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
        }
        .sheet(item: $editingSchedule) { schedule in
            CreateQuietHoursScheduleView(editingSchedule: schedule)
                .environmentObject(quietHoursService)
        }
    }
}

struct QuietHoursScheduleCard: View {
    @EnvironmentObject var quietHoursService: QuietHoursService
    let schedule: QuietHoursSchedule
    @State private var showDeleteConfirmation = false
    
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
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text(timeString)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text(daysString)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Delete button
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    
                    Toggle("", isOn: Binding(
                        get: { schedule.isActive },
                        set: { _ in
                            quietHoursService.toggleSchedule(schedule)
                        }
                    ))
                }
            }
            
            if schedule.isCurrentlyActive() {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                    Text("Currently Active")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                quietHoursService.deleteSchedule(schedule)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Schedule", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                quietHoursService.deleteSchedule(schedule)
            }
        } message: {
            Text("Are you sure you want to delete '\(schedule.name)'? This cannot be undone.")
        }
    }
}

struct CreateQuietHoursScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var quietHoursService: QuietHoursService
    
    let editingSchedule: QuietHoursSchedule?
    
    @State private var name: String = ""
    @State private var startHour: Int = 22
    @State private var startMinute: Int = 0
    @State private var endHour: Int = 8
    @State private var endMinute: Int = 0
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    
    init(editingSchedule: QuietHoursSchedule? = nil) {
        self.editingSchedule = editingSchedule
        if let schedule = editingSchedule {
            _name = State(initialValue: schedule.name)
            _startHour = State(initialValue: schedule.startTime.hour ?? 22)
            _startMinute = State(initialValue: schedule.startTime.minute ?? 0)
            _endHour = State(initialValue: schedule.endTime.hour ?? 8)
            _endMinute = State(initialValue: schedule.endTime.minute ?? 0)
            _selectedDays = State(initialValue: schedule.daysOfWeek)
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
                    DatePicker("Start Time", selection: Binding(
                        get: {
                            Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: Date()) ?? Date()
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            startHour = components.hour ?? 22
                            startMinute = components.minute ?? 0
                        }
                    ), displayedComponents: .hourAndMinute)
                    
                    DatePicker("End Time", selection: Binding(
                        get: {
                            Calendar.current.date(bySettingHour: endHour, minute: endMinute, second: 0, of: Date()) ?? Date()
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            endHour = components.hour ?? 8
                            endMinute = components.minute ?? 0
                        }
                    ), displayedComponents: .hourAndMinute)
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
                    .disabled(name.isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }
    
    private func saveSchedule() {
        let startTime = DateComponents(hour: startHour, minute: startMinute)
        let endTime = DateComponents(hour: endHour, minute: endMinute)
        
        if let editing = editingSchedule {
            var updated = editing
            updated.name = name
            updated.startTime = startTime
            updated.endTime = endTime
            updated.daysOfWeek = selectedDays
            quietHoursService.updateSchedule(updated)
        } else {
            let newSchedule = QuietHoursSchedule(
                name: name,
                startTime: startTime,
                endTime: endTime,
                daysOfWeek: selectedDays
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

