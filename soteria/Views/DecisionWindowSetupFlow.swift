//
//  DecisionWindowSetupFlow.swift
//  soteria
//
//  Guided setup flow for Decision Windows (≤ 60 seconds)
//
//  NOTE: User-facing name is "Decision Notifications" but internal code uses "Decision Windows"
//  The term "Window" refers to a time window (5 minutes around a set time) when notifications are sent
//

import SwiftUI

// Helper function for safe screen bounds access
private func getScreenWidth() -> CGFloat {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        return window.bounds.width
    }
    return UIScreen.main.bounds.width
}

struct DecisionWindowSetupFlow: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var decisionWindowsService = DecisionWindowsService.shared
    @ObservedObject private var plaidService = PlaidService.shared
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    @State private var currentStep: Int = 1
    @State private var limitError: String? = nil
    // Single window creation - simplified flow
    @State private var windowName: String = "" // User-entered name for the decision window
    @State private var windowTime: Date = Date()
    @State private var windowActions: Set<WindowAction> = []
    @State private var windowSaveAmount: Double = 3.0
    @State private var windowProtectAmount: Double = 10.0
    @State private var windowPauseIntention: String? = nil // Custom pause intention (premium)
    @State private var windowCondition: WindowCondition? = nil
    @State private var skipSetup = false
    
    // Celebration state
    @State private var showConfetti = false
    @State private var showBalloons = false
    @State private var balloonOffsets: [CGSize] = []
    @State private var confettiPieces: [DecisionConfettiPiece] = []
    
    enum WindowAction: String, Identifiable {
        case saveFirst
        case protectAmount
        case justRemind
        case manualEntry
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .saveFirst: return "Save First"
            case .protectAmount: return "Protect an Amount"
            case .justRemind: return "Just Remind Me"
            case .manualEntry: return "Record Manual Transfer"
            }
        }
        
        var icon: String {
            switch self {
            case .saveFirst: return "lock.fill"
            case .protectAmount: return "shield.fill"
            case .justRemind: return "brain.head.profile"
            case .manualEntry: return "dollarsign.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .saveFirst: return "Open transfer screen to save a small amount when this window opens."
            case .protectAmount: return "Open transfer screen to protect money when triggered."
            case .justRemind: return "No saving. Just a moment to pause and remember why I'm saving."
            case .manualEntry: return "Remind me to record a manual transfer (cash, external account, etc.)."
            }
        }
    }
    
    // Check if user has Plaid connected
    private var hasPlaidConnection: Bool {
        !plaidService.connectedAccounts.isEmpty
    }
    
    // Get available actions based on Plaid connection status
    private var availableActions: [WindowAction] {
        if hasPlaidConnection {
            // Plaid users get Save First and Just Remind Me
            // NOTE: "Protect an Amount" (spend gate) is commented out - not fully implemented yet
            return [.saveFirst, .justRemind]
            // return [.saveFirst, .protectAmount, .justRemind] // TODO: Re-enable when spend gate detection is implemented
        } else {
            // Non-Plaid users only get reminder and manual entry
            return [.justRemind, .manualEntry]
        }
    }
    
    struct WindowCondition: Identifiable {
        let id = UUID()
        var type: ConditionType
        var amount: Double
        var time: Int? // For "after X PM" condition
        
        enum ConditionType: String {
            case ifSpendToday = "if_spend_today"
            case ifSpendAfterTime = "if_spend_after_time"
            case ifOverspendDailyGoal = "if_overspend_daily_goal"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cloudWhite
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    if currentStep <= 6 {
                        ProgressView(value: Double(currentStep), total: 6.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .softGraphite))
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    }
                    
                    // Content
                    Group {
                        switch currentStep {
                        case 1:
                            conceptScreen
                        case 2:
                            nameEntryScreen
                        case 3:
                            timeSelectionScreen
                        case 4:
                            whatHappensScreen
                        case 5:
                            howNotificationsWorkScreen
                        case 6:
                            reviewScreen
                        case 7:
                            confirmationScreen
                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
                        // Dismiss and show paywall - handled by parent
                    }
                }
            } message: {
                if let error = limitError {
                    Text(error)
                }
            }
            .toolbar {
                if currentStep < 6 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if currentStep > 1 {
                            Button("Back") {
                                currentStep -= 1
                            }
                            .foregroundColor(.softGraphite)
                        } else {
                            Button("Skip") {
                                skipSetup = true
                                dismiss()
                            }
                            .foregroundColor(.softGraphite)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Screen 1: Concept
    private var conceptScreen: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("Choose Before the Day Gets Away From You")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.midnightSlate)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Most impulse decisions happen when we're tired, bored, or rushed.")
                        .font(.system(size: 17))
                        .foregroundColor(.softGraphite)
                    
                    Text("Decision Windows give you a moment before that happens.")
                        .font(.system(size: 17))
                        .foregroundColor(.softGraphite)
                    
                    Text("You choose the time.\nSoteria helps once.\nThen it stays quiet.")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.midnightSlate)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
            Button(action: {
                currentStep = 2 // Go to name entry screen
            }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.softGraphite)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    skipSetup = true
                    dismiss()
                }) {
                    Text("Skip for now")
                        .font(.system(size: 16))
                        .foregroundColor(.softGraphite)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Screen 2: Name Entry
    
    private var nameEntryScreen: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: ResponsiveSize.spacing(large: 24, medium: 20, small: 16)) {
                Text("Name your notification")
                    .font(.system(size: ResponsiveSize.font(large: 28, medium: 26, small: 24), weight: .bold))
                    .foregroundColor(.midnightSlate)
                    .multilineTextAlignment(.center)
                
                Text("Give it a name that helps you remember what it's for")
                    .font(.system(size: ResponsiveSize.font(large: 16, medium: 15, small: 14)))
                    .foregroundColor(.softGraphite)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                
                VStack(alignment: .leading, spacing: 12) {
                    TextField("e.g., Morning Planning, Afternoon Pause", text: $windowName)
                        .font(.system(size: 16))
                        .foregroundColor(.midnightSlate)
                        .padding(16)
                        .background(Color.dreamMist)
                        .cornerRadius(12)
                        .autocapitalization(.words)
                        .disableAutocorrection(false)
                }
                .padding(.horizontal, 40)
                
                // Quick suggestions
                VStack(spacing: 12) {
                    Text("Quick suggestions")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.softGraphite)
                    
                    VStack(spacing: 8) {
                        Button(action: {
                            windowName = "Morning Planning"
                        }) {
                            Text("Morning Planning")
                                .font(.system(size: 15))
                                .foregroundColor(.midnightSlate)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.dreamMist.opacity(0.5))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            windowName = "Afternoon Pause"
                        }) {
                            Text("Afternoon Pause")
                                .font(.system(size: 15))
                                .foregroundColor(.midnightSlate)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.dreamMist.opacity(0.5))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            windowName = "Evening Reflection"
                        }) {
                            Text("Evening Reflection")
                                .font(.system(size: 15))
                                .foregroundColor(.midnightSlate)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.dreamMist.opacity(0.5))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
            }
            
            Spacer()
            
            Button(action: {
                // Use default name if empty
                if windowName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    windowName = "My Decision Notification"
                }
                currentStep = 3 // Go to time selection
            }) {
                Text("Continue")
                    .font(.system(size: ResponsiveSize.font(large: 18, medium: 17, small: 16), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ResponsiveSize.padding(large: 16, medium: 14, small: 12))
                    .background(Color.softGraphite)
                    .cornerRadius(12)
            }
            .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
            .padding(.bottom, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
        }
    }
    
    // MARK: - Screen 3: Time Selection (removed "How Many Windows" step)
    
    private var timeSelectionScreen: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: ResponsiveSize.spacing(large: 24, medium: 20, small: 16)) {
                Text("Pick a time")
                    .font(.system(size: ResponsiveSize.font(large: 28, medium: 26, small: 24), weight: .bold))
                    .foregroundColor(.midnightSlate)
                
                Text("When should Soteria help you pause and save?")
                    .font(.system(size: ResponsiveSize.font(large: 16, medium: 15, small: 14)))
                    .foregroundColor(.softGraphite)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                
                DatePicker("", selection: $windowTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                // Helper suggestions - specific times, not ranges
                VStack(spacing: 12) {
                    Text("Quick suggestions")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.softGraphite)
                    
                    HStack(spacing: 12) {
                        SuggestionButton(title: "Morning planning", time: "8:00 AM") {
                            let calendar = Calendar.current
                            if let date = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) {
                                windowTime = date
                                windowName = "Morning Planning" // Set name to match selection
                            }
                        }
                        SuggestionButton(title: "Afternoon pause", time: "3:00 PM") {
                            let calendar = Calendar.current
                            if let date = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) {
                                windowTime = date
                                windowName = "Afternoon Pause" // Set name to match selection
                            }
                        }
                        SuggestionButton(title: "Evening reflection", time: "9:00 PM") {
                            let calendar = Calendar.current
                            if let date = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) {
                                windowTime = date
                                windowName = "Evening Reflection" // Set name to match selection
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
            
            Spacer()
            
            Button(action: {
                currentStep = 4 // Go to "What Happens" screen
            }) {
                Text("Continue")
                    .font(.system(size: ResponsiveSize.font(large: 18, medium: 17, small: 16), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ResponsiveSize.padding(large: 16, medium: 14, small: 12))
                    .background(Color.softGraphite)
                    .cornerRadius(12)
            }
            .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
            .padding(.bottom, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
        }
    }
    
    // MARK: - Screen 4: What Happens
    @State private var selectedActions: Set<WindowAction> = []
    @State private var currentSaveAmount: Double = 3.0
    @State private var currentProtectAmount: Double = 10.0
    @State private var currentPauseIntention: String = "" // Custom pause intention text (premium)
    @State private var showPaywallForCustomIntention = false
    
    private var whatHappensScreen: some View {
        VStack(spacing: 32) {
            ScrollView {
                VStack(spacing: ResponsiveSize.spacing(large: 24, medium: 20, small: 16)) {
                    Text("What should Soteria help you do?")
                        .font(.system(size: ResponsiveSize.font(large: 28, medium: 26, small: 24), weight: .bold))
                        .foregroundColor(.midnightSlate)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                        .padding(.top, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                    
                    VStack(spacing: 16) {
                        // Show only available actions based on Plaid connection
                        ForEach(availableActions) { action in
                            ActionCard(
                                icon: action.icon,
                                title: action.title,
                                description: action.description,
                                isSelected: selectedActions.contains(action),
                                onTap: {
                                    if selectedActions.contains(action) {
                                        selectedActions.remove(action)
                                    } else {
                                        selectedActions.insert(action)
                                    }
                                    print("✅ [DecisionWindowSetupFlow] \(action.title) tapped, selectedActions: \(selectedActions)")
                                }
                            ) {
                                if action == .saveFirst && selectedActions.contains(.saveFirst) {
                                    AmountPicker(amount: $currentSaveAmount)
                                } else if action == .protectAmount && selectedActions.contains(.protectAmount) {
                                    AmountPicker(amount: $currentProtectAmount)
                                } else if action == .justRemind && selectedActions.contains(.justRemind) {
                                    // Custom pause intention (premium feature)
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Custom Reminder")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.softGraphite)
                                            
                                            Spacer()
                                            
                                            if !subscriptionService.isPremium {
                                                Text("Premium")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.softGraphite)
                                                    .cornerRadius(6)
                                            }
                                        }
                                        
                                        if subscriptionService.isPremium {
                                            TextField("e.g., Remember why I'm saving for my trip to Hawaii", text: $currentPauseIntention, axis: .vertical)
                                                .font(.system(size: 14))
                                                .foregroundColor(.midnightSlate)
                                                .lineLimit(2...4)
                                                .padding(12)
                                                .background(Color.dreamMist)
                                                .cornerRadius(10)
                                            
                                            Text("Leave empty to use default: 'Remember why I'm saving'")
                                                .font(.system(size: 12))
                                                .foregroundColor(.softGraphite)
                                        } else {
                                            Button(action: {
                                                showPaywallForCustomIntention = true
                                            }) {
                                                HStack {
                                                    Image(systemName: "lock.fill")
                                                        .font(.system(size: 14))
                                                    Text("Unlock Custom Reminders")
                                                        .font(.system(size: 14, weight: .medium))
                                                }
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(Color.reverBlue)
                                                .cornerRadius(10)
                                            }
                                            
                                            Text("Premium feature: Create personalized reminder messages")
                                                .font(.system(size: 12))
                                                .foregroundColor(.softGraphite)
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                                // No additional content for .manualEntry
                            }
                        }
                    }
                    .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                }
            }
            
            Button(action: {
                print("✅ [DecisionWindowSetupFlow] Continue button tapped, selectedActions: \(selectedActions)")
                // Store actions and amounts for the window
                windowActions = selectedActions
                windowSaveAmount = currentSaveAmount
                windowProtectAmount = currentProtectAmount
                
                // Store custom pause intention if provided (premium only)
                if selectedActions.contains(.justRemind) {
                    if subscriptionService.isPremium && !currentPauseIntention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        windowPauseIntention = currentPauseIntention.trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        windowPauseIntention = nil // Use default
                    }
                } else {
                    windowPauseIntention = nil
                }
                
                currentStep = 5 // Go to how notifications work screen
            }) {
                Text("Continue")
                    .font(.system(size: ResponsiveSize.font(large: 18, medium: 17, small: 16), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ResponsiveSize.padding(large: 16, medium: 14, small: 12))
                    .background(!selectedActions.isEmpty ? Color.softGraphite : Color.gray.opacity(0.5))
                    .cornerRadius(12)
            }
            .disabled(selectedActions.isEmpty)
            .sheet(isPresented: $showPaywallForCustomIntention) {
                PaywallView()
                    .environmentObject(subscriptionService)
            }
            .onChange(of: selectedActions) { oldValue, newValue in
                print("✅ [DecisionWindowSetupFlow] selectedActions changed from \(oldValue) to \(newValue)")
            }
            .onAppear {
                // Restore state when screen appears
                if !windowActions.isEmpty {
                    selectedActions = windowActions
                    if windowActions.contains(.saveFirst) {
                        currentSaveAmount = windowSaveAmount
                    }
                    if windowActions.contains(.protectAmount) {
                        currentProtectAmount = windowProtectAmount
                    }
                    if windowActions.contains(.justRemind) {
                        currentPauseIntention = windowPauseIntention ?? ""
                    }
                }
            }
            .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
            .padding(.bottom, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
        }
    }
    
    // MARK: - Screen 4: How Notifications Work
    private var howNotificationsWorkScreen: some View {
        VStack(spacing: 32) {
            ScrollView {
                VStack(spacing: ResponsiveSize.spacing(large: 24, medium: 20, small: 16)) {
                    Text("How you'll see your notifications")
                        .font(.system(size: ResponsiveSize.font(large: 28, medium: 26, small: 24), weight: .bold))
                        .foregroundColor(.midnightSlate)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                        .padding(.top, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                    
                    VStack(spacing: 20) {
                        // Notification Center
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.softGraphite)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notification Center")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.midnightSlate)
                                
                                Text("Swipe down from the top of your screen to see all notifications")
                                    .font(.system(size: 14))
                                    .foregroundColor(.softGraphite)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(Color.dreamMist.opacity(0.3))
                        .cornerRadius(12)
                        
                        // Lock Screen
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.softGraphite)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Lock Screen")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.midnightSlate)
                                
                                Text("Notifications appear on your lock screen when your phone is locked")
                                    .font(.system(size: 14))
                                    .foregroundColor(.softGraphite)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(Color.dreamMist.opacity(0.3))
                        .cornerRadius(12)
                        
                        // Banner
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "rectangle.topthird.inset.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.softGraphite)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Banner Notification")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.midnightSlate)
                                
                                Text("A brief notification appears at the top of your screen when active")
                                    .font(.system(size: 14))
                                    .foregroundColor(.softGraphite)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(Color.dreamMist.opacity(0.3))
                        .cornerRadius(12)
                        
                        // App Badge
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "app.badge.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.softGraphite)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("App Badge")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.midnightSlate)
                                
                                Text("The Soteria app icon shows a badge count when you have notifications")
                                    .font(.system(size: 14))
                                    .foregroundColor(.softGraphite)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(Color.dreamMist.opacity(0.3))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                    
                    VStack(spacing: ResponsiveSize.spacing(large: 12, medium: 10, small: 8)) {
                        Text("💡 Tip")
                            .font(.system(size: ResponsiveSize.font(large: 15, medium: 14, small: 13), weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("Make sure notifications are enabled in Settings → Notifications → Soteria")
                            .font(.system(size: ResponsiveSize.font(large: 14, medium: 13, small: 12)))
                            .foregroundColor(.softGraphite)
                            .multilineTextAlignment(.center)
                    }
                    .padding(ResponsiveSize.padding(large: 20, medium: 16, small: 12))
                    .background(Color.softGraphite.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                }
            }
            
            Button(action: {
                windowCondition = nil // No conditions - feature removed
                currentStep = 6 // Go to review screen
            }) {
                Text("Continue")
                    .font(.system(size: ResponsiveSize.font(large: 18, medium: 17, small: 16), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ResponsiveSize.padding(large: 16, medium: 14, small: 12))
                    .background(Color.softGraphite)
                    .cornerRadius(12)
            }
            .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
            .padding(.bottom, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
        }
    }
    
    // MARK: - Screen 6: Review
    private var reviewScreen: some View {
        VStack(spacing: 32) {
            ScrollView {
                VStack(spacing: ResponsiveSize.spacing(large: 24, medium: 20, small: 16)) {
                    Text("Here's what will happen")
                        .font(.system(size: ResponsiveSize.font(large: 28, medium: 26, small: 24), weight: .bold))
                        .foregroundColor(.midnightSlate)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                        .padding(.top, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        WindowReviewCard(
                            index: 0,
                            name: windowName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Decision Notification" : windowName,
                            time: windowTime,
                            actions: Array(windowActions),
                            saveAmount: windowSaveAmount,
                            protectAmount: windowProtectAmount,
                            pauseIntention: windowPauseIntention
                        )
                    }
                    .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                    
                    VStack(spacing: ResponsiveSize.spacing(large: 12, medium: 10, small: 8)) {
                        Text("You're always in control.")
                            .font(.system(size: ResponsiveSize.font(large: 15, medium: 14, small: 13), weight: .medium))
                            .foregroundColor(.midnightSlate)
                        
                        Text("You can change or pause this anytime.")
                            .font(.system(size: ResponsiveSize.font(large: 14, medium: 13, small: 12)))
                            .foregroundColor(.softGraphite)
                    }
                    .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                    .padding(.top, ResponsiveSize.padding(large: 20, medium: 16, small: 12))
                }
            }
            
            Button(action: {
                createDecisionWindow()
                currentStep = 7 // Go to confirmation screen
            }) {
                Text("Turn On Decision Window")
                    .font(.system(size: ResponsiveSize.font(large: 18, medium: 17, small: 16), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ResponsiveSize.padding(large: 16, medium: 14, small: 12))
                    .background(Color.softGraphite)
                    .cornerRadius(12)
            }
            .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
            .padding(.bottom, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
        }
    }
    
    // MARK: - Screen 7: Confirmation
    private var confirmationScreen: some View {
        ZStack {
            // Confetti background
            if showConfetti {
                GeometryReader { geometry in
                    ForEach(confettiPieces) { piece in
                        DecisionConfettiPieceView(
                            piece: piece,
                            screenHeight: geometry.size.height,
                            screenWidth: geometry.size.width
                        )
                    }
                }
            }
            
            // Balloons
            if showBalloons {
                HStack(spacing: 30) {
                    ForEach(0..<5, id: \.self) { index in
                        DecisionBalloonView(color: decisionBalloonColors[index % decisionBalloonColors.count])
                            .offset(balloonOffsets[safe: index] ?? .zero)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 40)
            }
            
            // Main content
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 24) {
                    // Celebration icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.softGraphite, Color.midnightSlate],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.softGraphite.opacity(0.4), radius: 15, x: 0, y: 5)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(showConfetti ? 1.0 : 0.3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)
                    
                    VStack(spacing: ResponsiveSize.spacing(large: 16, medium: 14, small: 12)) {
                        Text("You've Protected Today")
                            .font(.system(size: ResponsiveSize.font(large: 32, medium: 28, small: 24), weight: .bold))
                            .foregroundColor(.midnightSlate)
                            .multilineTextAlignment(.center)
                        
                        Text("You just gave Future You a head start.")
                            .font(.system(size: ResponsiveSize.font(large: 18, medium: 17, small: 16)))
                            .foregroundColor(.softGraphite)
                            .multilineTextAlignment(.center)
                        
                        Text("No rules. No guilt. Just intention.")
                            .font(.system(size: ResponsiveSize.font(large: 16, medium: 15, small: 14), weight: .medium))
                            .foregroundColor(.midnightSlate)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(showConfetti ? 1.0 : 0.0)
                    .offset(y: showConfetti ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showConfetti)
                }
                .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: ResponsiveSize.font(large: 18, medium: 17, small: 16), weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ResponsiveSize.padding(large: 16, medium: 14, small: 12))
                        .background(Color.softGraphite)
                        .cornerRadius(12)
                }
                .padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
                .padding(.bottom, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
            }
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private func startCelebration() {
        // Initialize balloon offsets (start from bottom)
        balloonOffsets = (0..<5).map { _ in
            CGSize(width: CGFloat.random(in: -50...50), height: 400)
        }
        
        // Create confetti pieces
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .softGraphite, .midnightSlate]
        let shapes: [DecisionConfettiShape] = [.circle, .square, .triangle]
        let screenWidth = getScreenWidth()
        
        confettiPieces = (0..<60).map { _ in
            DecisionConfettiPiece(
                id: UUID(),
                color: colors.randomElement()!,
                shape: shapes.randomElement()!,
                startX: CGFloat.random(in: 0...screenWidth),
                velocityX: CGFloat.random(in: -100...100),
                duration: Double.random(in: 2.0...4.0),
                rotationSpeed: Double.random(in: -360...360)
            )
        }
        
        // Animate balloons rising
        withAnimation(.spring(response: 1.5, dampingFraction: 0.6)) {
            showBalloons = true
            balloonOffsets = (0..<5).map { index in
                CGSize(
                    width: CGFloat.random(in: -30...30),
                    height: CGFloat.random(in: -20...20)
                )
            }
        }
        
        // Show confetti and content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                showConfetti = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createDecisionWindow() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: windowTime)
        let minute = calendar.component(.minute, from: windowTime)
        let timeComponents = DateComponents(hour: hour, minute: minute)
        // Default to all weekdays (Monday-Friday) for consistency
        let daysOfWeek: Set<Int> = [2, 3, 4, 5, 6] // Monday-Friday
        
        // Determine default values based on selected actions
        var defaultMicroSave: Double? = nil
        let defaultSpendGate: SpendGate? = nil // Not currently used (commented out below)
        var defaultPauseIntention: String? = nil
        
        if windowActions.contains(.saveFirst) {
            defaultMicroSave = windowSaveAmount
        }
        
        // NOTE: Protect Amount (spend gate) is commented out - not fully implemented yet
        // if windowActions.contains(.protectAmount) {
        //     defaultSpendGate = SpendGate(
        //         condition: "protect_amount",
        //         saveAmount: windowProtectAmount,
        //         description: "Protect $\(String(format: "%.2f", windowProtectAmount)) for impulse decisions"
        //     )
        // }
        
        if windowActions.contains(.justRemind) {
            // Use custom pause intention if provided (premium), otherwise use default
            if let customIntention = windowPauseIntention, !customIntention.isEmpty {
                defaultPauseIntention = customIntention
            } else {
                defaultPauseIntention = "Remember why I'm saving"
            }
        }
        
        if windowActions.contains(.manualEntry) {
            // For manual entry, set a reminder to record the transfer
            defaultPauseIntention = "Time to record your manual transfer (cash, external account, etc.)"
        }
        
        // NOTE: Conditions (spend gates) are commented out - not fully implemented yet
        // Add condition if set (overrides protect amount if both exist)
        // if let condition = windowCondition {
        //     defaultSpendGate = SpendGate(
        //         condition: condition.type.rawValue,
        //         saveAmount: condition.amount,
        //         description: getConditionDescription(condition)
        //     )
        // }
        
        // Use user-entered name, or default if empty
        let finalName = windowName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
            ? "My Decision Notification" 
            : windowName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Determine the prompt message:
        // - For "Just Remind" windows, use the custom pause intention if provided, otherwise use default
        // - For other windows, use a default message
        let finalPromptMessage: String?
        if windowActions.contains(.justRemind) {
            // For "Just Remind" windows, the message is in defaultPauseIntention
            // But we also set promptMessage for display purposes
            finalPromptMessage = defaultPauseIntention
        } else {
            // For other windows, use a default message
            finalPromptMessage = "Before today continues — do you want to protect anything?"
        }
        
        let window = DecisionWindow(
            name: finalName,
            time: timeComponents,
            daysOfWeek: daysOfWeek,
            isEnabled: true,
            promptMessage: finalPromptMessage,
            defaultMicroSaveAmount: defaultMicroSave,
            defaultSpendGate: defaultSpendGate,
            defaultPauseIntention: defaultPauseIntention
        )
        
        do {
            try decisionWindowsService.addWindow(window, isPremium: subscriptionService.isPremium)
        } catch {
            limitError = error.localizedDescription
        }
    }
    
    private func getConditionDescription(_ condition: WindowCondition) -> String {
        switch condition.type {
        case .ifSpendToday:
            return "If I make an impulse decision today, deposit $\(String(format: "%.2f", condition.amount))"
        case .ifSpendAfterTime:
            return "If I make an impulse decision after \(condition.time ?? 21):00, deposit $\(String(format: "%.2f", condition.amount))"
        case .ifOverspendDailyGoal:
            return "If I exceed my daily limit, deposit $\(String(format: "%.2f", condition.amount))"
        }
    }
}

// MARK: - Supporting Views

struct RadioOption: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .reverBlue : .softGraphite)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.midnightSlate)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.reverBlue)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.reverBlue.opacity(0.1) : Color.dreamMist)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.reverBlue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SuggestionButton: View {
    let title: String
    let time: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.midnightSlate)
                Text(time)
                    .font(.system(size: 11))
                    .foregroundColor(.softGraphite)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.dreamMist)
            .cornerRadius(8)
        }
    }
}

struct ActionCard<Content: View>: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : .softGraphite)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.softGraphite : Color.softGraphite.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .softGraphite : .softGraphite.opacity(0.5))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.softGraphite.opacity(0.1) : Color.dreamMist)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.softGraphite : Color.clear, lineWidth: 2)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if isSelected {
                content()
                    .padding(.top, 12)
            }
        }
    }
}

struct WindowReviewCard: View {
    let index: Int
    let name: String
    let time: Date
    let actions: [DecisionWindowSetupFlow.WindowAction]
    let saveAmount: Double
    let protectAmount: Double
    let pauseIntention: String? // Custom pause intention (premium)
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.midnightSlate)
                .padding(.bottom, 4)
            
            Text("At \(timeString)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.softGraphite)
            
            if actions.contains(.saveFirst) {
                Text("• Soteria will save $\(String(format: "%.2f", saveAmount))")
                    .font(.system(size: 14))
                    .foregroundColor(.softGraphite)
            }
            
            // NOTE: Protect Amount is commented out - not fully implemented yet
            // if actions.contains(.protectAmount) {
            //     Text("• Protect $\(String(format: "%.2f", protectAmount))")
            //         .font(.system(size: 14))
            //         .foregroundColor(.softGraphite)
            // }
            
            if actions.contains(.justRemind) {
                if let customIntention = pauseIntention, !customIntention.isEmpty {
                    Text("• Remind: \"\(customIntention)\"")
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                } else {
                    Text("• Remind you what you're saving for")
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                }
            }
        }
        .padding(16)
        .background(Color.dreamMist.opacity(0.5))
        .cornerRadius(12)
    }
}

struct AmountPicker: View {
    @Binding var amount: Double
    @State private var showCustomInput = false
    @State private var customAmountText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            if showCustomInput {
                HStack {
                    Text("$")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.softGraphite)
                    TextField("0.00", text: $customAmountText)
                        .keyboardType(.decimalPad)
                        .onChange(of: customAmountText) { oldValue, newValue in
                            if let value = Double(newValue) {
                                amount = value
                            }
                        }
                }
                .padding(12)
                .background(Color.dreamMist)
                .cornerRadius(10)
            } else {
                HStack(spacing: 12) {
                    ForEach([1.0, 3.0, 5.0], id: \.self) { preset in
                        Button(action: {
                            amount = preset
                        }) {
                            Text("$\(String(format: "%.0f", preset))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(amount == preset ? .white : .softGraphite)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(amount == preset ? Color.softGraphite : Color.softGraphite.opacity(0.1))
                                )
                        }
                    }
                    
                    Button(action: {
                        showCustomInput = true
                        customAmountText = String(format: "%.2f", amount)
                    }) {
                        Text("Custom")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.softGraphite)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.softGraphite.opacity(0.1))
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Decision Window Celebration Components

private let decisionBalloonColors: [Color] = [
    .red, .blue, .green, .orange, .purple
]

struct DecisionBalloonView: View {
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // Balloon
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 65)
                .overlay(
                    Ellipse()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            // String
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 40)
        }
    }
}

struct DecisionConfettiPiece: Identifiable {
    let id: UUID
    let color: Color
    let shape: DecisionConfettiShape
    let startX: CGFloat
    let velocityX: CGFloat
    let duration: Double
    let rotationSpeed: Double
}

enum DecisionConfettiShape {
    case circle, square, triangle
}

struct DecisionConfettiPieceView: View {
    let piece: DecisionConfettiPiece
    let screenHeight: CGFloat
    let screenWidth: CGFloat
    
    @State private var yOffset: CGFloat = -50
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        Group {
            switch piece.shape {
            case .circle:
                Circle()
                    .fill(piece.color)
                    .frame(width: 8, height: 8)
            case .square:
                Rectangle()
                    .fill(piece.color)
                    .frame(width: 8, height: 8)
            case .triangle:
                Triangle()
                    .fill(piece.color)
                    .frame(width: 8, height: 8)
            }
        }
        .rotationEffect(.degrees(rotation))
        .position(
            x: piece.startX + xOffset,
            y: yOffset
        )
        .onAppear {
            // Animate falling
            withAnimation(.linear(duration: piece.duration).repeatForever(autoreverses: false)) {
                yOffset = screenHeight + 100
                xOffset = piece.velocityX
                rotation = piece.rotationSpeed * piece.duration
            }
        }
    }
}

#Preview {
    DecisionWindowSetupFlow()
}

