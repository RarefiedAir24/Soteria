//
//  DecisionWindowsView.swift
//  soteria
//
//  Time-based, app-agnostic savings prompts and behavior change
//  This is where money actually moves - intentional action, not contextual reminders
//
//  NOTE: User-facing name is "Decision Notifications" but internal code uses "Decision Windows"
//  The term "Window" refers to a time window (5 minutes around a set time) when notifications are sent
//

import SwiftUI

struct DecisionWindowsView: View {
    @ObservedObject private var decisionWindowsService = DecisionWindowsService.shared
    @ObservedObject private var aiService = BehavioralAIService.shared
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showCreateWindow = false
    @State private var editingWindow: DecisionWindow? = nil // When set, shows edit sheet; when nil, no edit sheet
    @State private var showPaywall = false
    @State private var limitError: String? = nil
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.cloudWhite
                .ignoresSafeArea()
            
            ScrollView {
                Color.clear
                    .frame(height: 60)
                
                VStack(spacing: 24) {
                    // Header Description
                    // NOTE: User-facing name is "Decision Notifications" but internal code uses "Decision Windows"
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Decision Notifications")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("Set intentional moments to pause and save. These are time-based prompts that help you make conscious savings decisions.")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // AI Timing Recommendations
                    if !aiService.timingRecommendations.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(aiService.timingRecommendations) { recommendation in
                                TimingRecommendationCard(
                                    recommendation: recommendation,
                                    onUpdateTime: {
                                        updateWindowTime(recommendation: recommendation)
                                    },
                                    onDismiss: {
                                        dismissRecommendation(recommendation: recommendation)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Windows List - Organized by Active/Inactive
                    let allWindows = decisionWindowsService.windows
                    let defaultWindowNames = ["Morning Planning", "End of Day Reflection"]
                    let userCreatedWindows = allWindows.filter { !defaultWindowNames.contains($0.name) }
                    let hasUserCreatedWindows = !userCreatedWindows.isEmpty
                    
                    // Filter: Hide disabled default windows if user has created their own
                    let visibleWindows = hasUserCreatedWindows 
                        ? allWindows.filter { window in
                            // Show user-created windows always, or default windows only if enabled
                            !defaultWindowNames.contains(window.name) || window.isEnabled
                        }
                        : allWindows
                    
                    let activeWindows = visibleWindows.filter { $0.isEnabled }
                    let inactiveWindows = visibleWindows.filter { !$0.isEnabled }
                    
                    if visibleWindows.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "clock.badge.questionmark")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                            
                            Text("No Decision Notifications")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                            
                            Text("Create time-based notifications to prompt intentional savings decisions.")
                                .font(.system(size: 14))
                                .foregroundColor(Color.softGraphite)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                let (canAdd, reason) = decisionWindowsService.canAddWindow(isPremium: subscriptionService.isPremium)
                                if !canAdd {
                                    limitError = reason
                                } else if !subscriptionService.isPremium {
                                    showPaywall = true
                                } else {
                                    showCreateWindow = true
                                }
                            }) {
                                Text("Create Your First Notification")
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
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 24) {
                            // Active Notifications Section
                            // NOTE: User-facing name is "Notifications" but internal code uses "Windows"
                            if !activeWindows.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Active Notifications")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.midnightSlate)
                                        Spacer()
                                        Text("\(activeWindows.count)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.softGraphite)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.reverBlue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    
                                    List {
                                        ForEach(activeWindows) { window in
                                            DecisionWindowCard(
                                                window: window,
                                                isPremium: subscriptionService.isPremium,
                                                onTap: {
                                                    if subscriptionService.isPremium {
                                                        // Set editing window - sheet will automatically show via item: binding
                                                        editingWindow = window
                                                    } else {
                                                        showPaywall = true
                                                    }
                                                },
                                                onDelete: {
                                                    do {
                                                        try decisionWindowsService.deleteWindow(window, isPremium: subscriptionService.isPremium)
                                                    } catch {
                                                        limitError = error.localizedDescription
                                                    }
                                                }
                                            )
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                                            .listRowBackground(Color.clear)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: subscriptionService.isPremium) {
                                                if subscriptionService.isPremium {
                                                    Button(role: .destructive) {
                                                        do {
                                                            try decisionWindowsService.deleteWindow(window, isPremium: subscriptionService.isPremium)
                                                        } catch {
                                                            limitError = error.localizedDescription
                                                        }
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .listStyle(.plain)
                                    .scrollContentBackground(.hidden)
                                    .frame(height: CGFloat(activeWindows.count) * 120) // Approximate height per card
                                }
                            }
                            
                            // Inactive Notifications Section
                            // NOTE: User-facing name is "Notifications" but internal code uses "Windows"
                            if !inactiveWindows.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Inactive Notifications")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.softGraphite)
                                        Spacer()
                                        Text("\(inactiveWindows.count)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.softGraphite)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.softGraphite.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    
                                    List {
                                        ForEach(inactiveWindows) { window in
                                            DecisionWindowCard(
                                                window: window,
                                                isPremium: subscriptionService.isPremium,
                                                onTap: {
                                                    if subscriptionService.isPremium {
                                                        // Ensure editingWindow is set before showing sheet
                                                        // This guarantees the edit modal opens on first tap
                                                        editingWindow = window
                                                        showCreateWindow = true
                                                    } else {
                                                        showPaywall = true
                                                    }
                                                },
                                                onDelete: {
                                                    do {
                                                        try decisionWindowsService.deleteWindow(window, isPremium: subscriptionService.isPremium)
                                                    } catch {
                                                        limitError = error.localizedDescription
                                                    }
                                                }
                                            )
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                                            .listRowBackground(Color.clear)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: subscriptionService.isPremium) {
                                                if subscriptionService.isPremium {
                                                    Button(role: .destructive) {
                                                        do {
                                                            try decisionWindowsService.deleteWindow(window, isPremium: subscriptionService.isPremium)
                                                        } catch {
                                                            limitError = error.localizedDescription
                                                        }
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .listStyle(.plain)
                                    .scrollContentBackground(.hidden)
                                    .frame(height: CGFloat(inactiveWindows.count) * 120) // Approximate height per card
                                }
                            }
                            
                            // Create Button
                            Button(action: {
                                let (canAdd, reason) = decisionWindowsService.canAddWindow(isPremium: subscriptionService.isPremium)
                                if !canAdd {
                                    limitError = reason
                                } else if !subscriptionService.isPremium {
                                    showPaywall = true
                                } else {
                                    // Creating new window - clear editing window and show create sheet
                                    editingWindow = nil
                                    showCreateWindow = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Create New Notification")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.reverBlue)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        // Separate sheet for editing existing windows - use item: to ensure window is available
        .sheet(item: $editingWindow) { window in
            CreateDecisionWindowView(
                editingWindow: window,
                onSave: { savedWindow in
                    do {
                        try decisionWindowsService.updateWindow(savedWindow, isPremium: subscriptionService.isPremium)
                    } catch {
                        limitError = error.localizedDescription
                    }
                    editingWindow = nil
                },
                onCancel: {
                    editingWindow = nil
                }
            )
        }
        // Separate sheet for creating new windows
        .sheet(isPresented: $showCreateWindow) {
            DecisionWindowSetupFlow()
                .environmentObject(subscriptionService)
        }
        .alert("Limit Reached", isPresented: Binding(
            get: { limitError != nil },
            set: { if !$0 { limitError = nil } }
        )) {
            Button("OK") {
                limitError = nil
            }
            if !subscriptionService.isPremium {
                Button("Upgrade to Plus") {
                    limitError = nil
                    showPaywall = true
                }
            }
        } message: {
            if let error = limitError {
                Text(error)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .onAppear {
            // Reload windows to ensure we have the latest data
            decisionWindowsService.loadWindows()
            print("📋 [DecisionWindowsView] onAppear - Loaded \(decisionWindowsService.windows.count) windows")
            for window in decisionWindowsService.windows {
                print("📋 [DecisionWindowsView] Window: \(window.name), enabled: \(window.isEnabled), id: \(window.id)")
            }
            // Generate timing recommendations for existing windows
            generateTimingRecommendations()
        }
    }
    
    private func generateTimingRecommendations() {
        // Check each window for timing recommendations
        for window in decisionWindowsService.windows {
            if let recommendation = aiService.generateTimingRecommendation(for: window.id) {
                // Only add if not already present
                if !aiService.timingRecommendations.contains(where: { $0.windowId == window.id }) {
                    aiService.timingRecommendations.append(recommendation)
                    aiService.saveRecommendations()
                }
            }
        }
    }
    
    private func updateWindowTime(recommendation: TimingRecommendation) {
        // Parse recommended time
        let components = recommendation.recommendedTime.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return
        }
        
        // Find and update the window
        if let windowIndex = decisionWindowsService.windows.firstIndex(where: { $0.id == recommendation.windowId }) {
            var updatedWindow = decisionWindowsService.windows[windowIndex]
            updatedWindow.time = DateComponents(hour: hour, minute: minute)
            decisionWindowsService.windows[windowIndex] = updatedWindow
            decisionWindowsService.saveWindows()
            
            // Remove the recommendation
            dismissRecommendation(recommendation: recommendation)
        }
    }
    
    private func dismissRecommendation(recommendation: TimingRecommendation) {
        aiService.timingRecommendations.removeAll { $0.id == recommendation.id }
        aiService.saveRecommendations()
    }
}

struct DecisionWindowCard: View {
    let window: DecisionWindow
    let isPremium: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var timeString: String {
        guard let hour = window.time.hour, let minute = window.time.minute else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private var daysString: String {
        let dayAbbreviations = ["Su", "M", "T", "W", "TH", "F", "Sa"]
        let sortedDays = window.daysOfWeek.sorted()
        
        if sortedDays.count == 7 {
            return "Daily"
        } else {
            // Show abbreviated day codes: M, T, W, TH, F, Sa, Su
            return sortedDays.map { dayAbbreviations[$0 - 1] }.joined(separator: ", ")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(window.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    HStack(spacing: 12) {
                        Label(timeString, systemImage: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                            .lineLimit(1)
                        
                        Label(daysString, systemImage: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                            .lineLimit(1)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                
                // Free users cannot toggle - editing is premium only
                if isPremium {
                    Toggle("", isOn: Binding(
                        get: { window.isEnabled },
                        set: { newValue in
                            var updated = window
                            updated.isEnabled = newValue
                            do {
                                try DecisionWindowsService.shared.updateWindow(updated, isPremium: isPremium)
                            } catch {
                                print("❌ [DecisionWindowCard] Failed to update window: \(error)")
                            }
                        }
                    ))
                    .fixedSize()
                } else {
                    // Show read-only state for free users (cannot edit)
                    HStack(spacing: 4) {
                        Image(systemName: window.isEnabled ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(window.isEnabled ? .reverBlue : .softGraphite)
                        Text(window.isEnabled ? "Enabled" : "Disabled")
                            .font(.system(size: 12))
                            .foregroundColor(.softGraphite)
                    }
                    .opacity(0.6) // Visual indicator that it's read-only
                    .fixedSize()
                }
            }
            
            if let message = window.promptMessage, !message.isEmpty {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.softGraphite)
                    .italic()
            }
            
            if let amount = window.defaultMicroSaveAmount, amount > 0 {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.reverBlue)
                    Text("Suggested micro-save: $\(String(format: "%.2f", amount))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.reverBlue)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .overlay(
            // Show premium lock indicator for free users
            Group {
                if !isPremium {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.softGraphite)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
        )
        // Note: Swipe actions are handled at the List level in DecisionWindowsView
        // This prevents duplicate delete buttons
    }
}

struct CreateDecisionWindowView: View {
    @Environment(\.dismiss) var dismiss
    let editingWindow: DecisionWindow?
    let onSave: (DecisionWindow) -> Void
    let onCancel: () -> Void
    
    @State private var name: String = ""
    @State private var selectedHour: Int = 8
    @State private var selectedMinute: Int = 0
    @State private var selectedDays: Set<Int> = []
    @State private var isEnabled: Bool = true
    @State private var promptMessage: String = ""
    
    private var allDays: [(Int, String)] {
        [(1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat")]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notification Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.softGraphite)
                            
                            TextField("e.g., Morning Planning", text: $name)
                                .font(.system(size: 16))
                                .foregroundColor(.midnightSlate)
                                .padding(14)
                                .background(Color.dreamMist)
                                .cornerRadius(12)
                        }
                        .padding(20)
                        .background(Color.cloudWhite)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
                        
                        // Time
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.softGraphite)
                            
                            DatePicker("", selection: Binding(
                                get: {
                                    Calendar.current.date(bySettingHour: selectedHour, minute: selectedMinute, second: 0, of: Date()) ?? Date()
                                },
                                set: { date in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                                    selectedHour = components.hour ?? 8
                                    selectedMinute = components.minute ?? 0
                                }
                            ), displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                        }
                        .padding(20)
                        .background(Color.cloudWhite)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
                        
                        // Days
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Days of Week")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.softGraphite)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                ForEach(allDays, id: \.0) { day, dayName in
                                    Button(action: {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }) {
                                        Text(dayName)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedDays.contains(day) ? .white : .midnightSlate)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedDays.contains(day) ? Color.reverBlue : Color.dreamMist)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.cloudWhite)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
                        
                        // Prompt Message
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Prompt Message (Optional)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.softGraphite)
                            
                            TextField("e.g., Before today continues — choose how you want to save.", text: $promptMessage, axis: .vertical)
                                .font(.system(size: 16))
                                .foregroundColor(.midnightSlate)
                                .lineLimit(2...4)
                                .padding(14)
                                .background(Color.dreamMist)
                                .cornerRadius(12)
                        }
                        .padding(20)
                        .background(Color.cloudWhite)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
                        
                    }
                    .padding(20)
                }
            }
            .navigationTitle(editingWindow != nil ? "Edit Notification" : "New Decision Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(.midnightSlate)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWindow()
                    }
                    .disabled(name.isEmpty || selectedDays.isEmpty)
                    .foregroundColor(.deepReverBlue)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let editing = editingWindow {
                    name = editing.name
                    selectedHour = editing.time.hour ?? 8
                    selectedMinute = editing.time.minute ?? 0
                    selectedDays = editing.daysOfWeek
                    isEnabled = editing.isEnabled
                    promptMessage = editing.promptMessage ?? ""
                }
            }
        }
    }
    
    private func saveWindow() {
        let time = DateComponents(hour: selectedHour, minute: selectedMinute)
        let message = promptMessage.isEmpty ? nil : promptMessage
        
        let window = DecisionWindow(
            id: editingWindow?.id ?? UUID().uuidString,
            name: name,
            time: time,
            daysOfWeek: selectedDays,
            isEnabled: isEnabled,
            promptMessage: message
        )
        
        onSave(window)
        dismiss()
    }
}

#Preview {
    DecisionWindowsView()
        .environmentObject(SubscriptionService.shared)
}

