//
//  PurchaseIntentPromptView.swift
//  soteria
//
//  Prompt user to categorize purchase intent when opening shopping apps
//
import SwiftUI
import FamilyControls
import UIKit
// TEMPORARILY DISABLED: Firebase imports - testing if they're causing crash
// import FirebaseStorage
// import FirebaseAuth

struct PurchaseIntentPromptView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var purchaseIntentService: PurchaseIntentService
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    @EnvironmentObject var goalsService: GoalsService
    @EnvironmentObject var quietHoursService: QuietHoursService
    @EnvironmentObject var regretService: RegretLoggingService
    @EnvironmentObject var authService: AuthService
    
    @State private var purchaseType: PurchaseType? = nil
    @State private var selectedCategory: PlannedPurchaseCategory? = nil
    @State private var selectedMood: ImpulseMood? = nil
    @State private var moodNotes: String = ""
    @State private var showMoodNotes: Bool = false
    @State private var showConfirmation: String? = nil
    // Track which app index user selected (simpler than storing token)
    @State private var selectedAppIndex: Int? = nil
    @State private var appsCount: Int = 0 // Cache to avoid blocking access
    @State private var estimatedAmount: String = "" // For impact calculator
    @State private var goalPhoto: UIImage? = nil // Lazy loaded
    @State private var isLoadingGoalPhoto = false
    @State private var recentRegrets: [RegretEntry] = [] // Lazy loaded
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Goal Visualization (only when Quiet Hours are active and active goal exists)
                        if quietHoursService.isQuietModeActive, let activeGoal = goalsService.activeGoal {
                            GoalVisualizationCard(goal: activeGoal, goalPhoto: $goalPhoto, isLoadingPhoto: $isLoadingGoalPhoto)
                                .onAppear {
                                    loadGoalPhoto(for: activeGoal)
                                    loadRecentRegrets()
                                }
                        }
                        
                        Image(systemName: "app.badge.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.reverBlue)
                        
                        // First, ask which app they were trying to open
                        if selectedAppIndex == nil {
                            VStack(spacing: 20) {
                                Text("Which app were you trying to open?")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.midnightSlate)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                // Show list of selected apps
                                if appsCount == 1 {
                                    // Only one app - auto-select it
                                    Text("Opening \(appsCount) app")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .onAppear {
                                            selectedAppIndex = 0
                                        }
                                } else {
                                    // Multiple apps - let user select
                                    VStack(spacing: 12) {
                                        // Use cached count to avoid blocking
                                        ForEach(0..<appsCount, id: \.self) { index in
                                            Button(action: {
                                                selectedAppIndex = index
                                            }) {
                                                HStack {
                                                    Image(systemName: "app.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(selectedAppIndex == index ? .white : Color.reverBlue)
                                                    
                                                    Text(deviceActivityService.getAppName(forIndex: index))
                                                        .font(.headline)
                                                        .foregroundColor(selectedAppIndex == index ? .white : Color.midnightSlate)
                                                    
                                                    Spacer()
                                                    
                                                    if selectedAppIndex == index {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(selectedAppIndex == index ? Color.reverBlue : Color.mistGray)
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 32)
                                }
                            }
                        }
                        // Then ask activity type (only if app is selected)
                        else if selectedAppIndex != nil && purchaseType == nil {
                            Text("Is this a planned activity or impulse?")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.midnightSlate)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Purchase Type Selection
                            VStack(spacing: 16) {
                                HStack(spacing: 20) {
                                    // Planned Purchase Button
                                    Button(action: {
                                        purchaseType = .planned
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "calendar.circle.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(Color.reverBlue)
                                            Text("Planned")
                                                .font(.headline)
                                                .foregroundColor(Color.midnightSlate)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 24)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                                        )
                                    }
                                    
                                    // Impulse Purchase Button
                                    Button(action: {
                                        purchaseType = .impulse
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "bolt.circle.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.orange)
                                            Text("Impulse")
                                                .font(.headline)
                                                .foregroundColor(Color.midnightSlate)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 24)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 0.98, green: 0.95, blue: 0.95))
                                        )
                                    }
                                }
                                .padding(.horizontal, 32)
                            }
                        }
                        
                        // Planned Purchase - Category Selection
                        else if purchaseType == .planned {
                            VStack(spacing: 20) {
                                if selectedCategory == nil {
                                    Text("What category is this activity?")
                                        .font(.headline)
                                        .foregroundColor(Color.midnightSlate)
                                        .multilineTextAlignment(.center)
                                    
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                        ForEach(PlannedPurchaseCategory.allCases, id: \.self) { category in
                                            Button(action: {
                                                print("✅ [PurchaseIntentPromptView] Category selected: \(category.displayName)")
                                                selectedCategory = category
                                            }) {
                                                VStack(spacing: 8) {
                                                    Image(systemName: category.icon)
                                                        .font(.system(size: 32))
                                                        .foregroundColor(selectedCategory == category ? .white : Color.reverBlue)
                                                    Text(category.displayName)
                                                        .font(.subheadline)
                                                        .foregroundColor(selectedCategory == category ? .white : Color.midnightSlate)
                                                        .multilineTextAlignment(.center)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 16)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(selectedCategory == category ? Color.reverBlue : Color.mistGray)
                                                )
                                            }
                                        }
                                    }
                                } else {
                                    // Category selected - show Continue button
                                    VStack(spacing: 20) {
                                        Text("Selected: \(selectedCategory?.displayName ?? "")")
                                            .font(.headline)
                                            .foregroundColor(Color.reverBlue)
                                        
                                        Button(action: {
                                            print("✅ [PurchaseIntentPromptView] Continue button tapped for planned purchase")
                                            handleComplete()
                                        }) {
                                            Text("Continue")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.vertical, 14)
                                                .frame(maxWidth: .infinity)
                                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.reverBlue))
                                        }
                                        .padding(.horizontal, 32)
                                        
                                        Button(action: {
                                            selectedCategory = nil
                                        }) {
                                            Text("Change Category")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Impulse Purchase - Mood Selection
                        else if purchaseType == .impulse {
                            VStack(spacing: 20) {
                                if selectedMood == nil {
                                    Text("How are you feeling?")
                                        .font(.headline)
                                        .foregroundColor(Color.midnightSlate)
                                        .multilineTextAlignment(.center)
                                    
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                        ForEach(ImpulseMood.allCases, id: \.self) { mood in
                                            Button(action: {
                                                print("✅ [PurchaseIntentPromptView] Mood selected: \(mood.displayName)")
                                                selectedMood = mood
                                                if mood == .other {
                                                    showMoodNotes = true
                                                }
                                            }) {
                                                VStack(spacing: 8) {
                                                    Image(systemName: mood.icon)
                                                        .font(.system(size: 32))
                                                        .foregroundColor(selectedMood == mood ? .white : .orange)
                                                    Text(mood.displayName)
                                                        .font(.subheadline)
                                                        .foregroundColor(selectedMood == mood ? .white : Color.midnightSlate)
                                                        .multilineTextAlignment(.center)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 16)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(selectedMood == mood ? Color.orange : Color(red: 0.98, green: 0.95, blue: 0.95))
                                                )
                                            }
                                        }
                                    }
                                    
                                    // Free text field for mood notes (especially for "other")
                                    if showMoodNotes || selectedMood == .other {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Tell us more (optional)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            TextField("How are you feeling?", text: $moodNotes, axis: .vertical)
                                                .textFieldStyle(.plain)
                                                .padding(12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.mistGray)
                                                )
                                                .lineLimit(3...6)
                                        }
                                        .padding(.horizontal, 32)
                                    }
                                } else {
                                    // Mood selected - show amount field and impact calculator
                                    VStack(spacing: 20) {
                                        Text("Selected: \(selectedMood?.displayName ?? "")")
                                            .font(.headline)
                                            .foregroundColor(.orange)
                                        
                                        // Free text field for mood notes (especially for "other")
                                        if showMoodNotes || selectedMood == .other {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Tell us more (optional)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                                TextField("How are you feeling?", text: $moodNotes, axis: .vertical)
                                                    .textFieldStyle(.plain)
                                                    .padding(12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color.mistGray)
                                                    )
                                                    .lineLimit(3...6)
                                            }
                                            .padding(.horizontal, 32)
                                        }
                                        
                                        // Estimated Amount Field (for impact calculator)
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Estimated amount (optional)")
                                                .font(.subheadline)
                                                .foregroundColor(.softGraphite)
                                            
                                            TextField("$0.00", text: $estimatedAmount)
                                                .keyboardType(.decimalPad)
                                                .font(.system(size: 16))
                                                .foregroundColor(.midnightSlate)
                                                .padding(14)
                                                .background(Color.dreamMist)
                                                .cornerRadius(12)
                                            
                                            // Impact Calculator (if amount entered and active goal exists)
                                            if let amount = Double(estimatedAmount), amount > 0,
                                               let activeGoal = goalsService.activeGoal,
                                               let daysDelayed = activeGoal.daysDelayedByPurchase(amount) {
                                                ImpactCalculatorView(goal: activeGoal, purchaseAmount: amount, daysDelayed: daysDelayed)
                                            }
                                            
                                            // Past Regret Reminder
                                            if !recentRegrets.isEmpty {
                                                PastRegretReminderView(regrets: recentRegrets)
                                            }
                                        }
                                        .padding(.horizontal, 32)
                                        
                                        Button(action: {
                                            print("✅ [PurchaseIntentPromptView] Continue button tapped for impulse purchase")
                                            handleComplete()
                                        }) {
                                            Text("Continue")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.vertical, 14)
                                                .frame(maxWidth: .infinity)
                                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange))
                                        }
                                        .padding(.horizontal, 32)
                                        
                                        Button(action: {
                                            selectedMood = nil
                                            showMoodNotes = false
                                            estimatedAmount = ""
                                        }) {
                                            Text("Change Mood")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Show confirmation message after completing
                        if let confirmation = showConfirmation {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color.reverBlue)
                                
                                Text(confirmation)
                                    .font(.headline)
                                    .foregroundColor(Color.midnightSlate)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.vertical, 40)
                }
            }
            .navigationTitle("Purchase Intent")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Load apps count asynchronously to avoid blocking
                Task { @MainActor in
                    // Small delay to ensure view is rendered
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    self.appsCount = self.deviceActivityService.selectedApps.applicationTokens.count
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue Block") {
                        // Dismiss without unblocking - apps remain blocked
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleComplete() {
        print("✅ [PurchaseIntentPromptView] handleComplete() called")
        print("   - Purchase type: \(purchaseType?.rawValue ?? "nil")")
        print("   - Category: \(selectedCategory?.rawValue ?? "nil")")
        print("   - Mood: \(selectedMood?.rawValue ?? "nil")")
        
        // Get app name if available
        let appName = selectedAppIndex != nil ? deviceActivityService.getAppName(forIndex: selectedAppIndex!) : nil
        
        // Get estimated amount if entered
        let amount = Double(estimatedAmount)
        
        let intent = PurchaseIntent(
            purchaseType: purchaseType ?? .impulse,
            category: purchaseType == .planned ? selectedCategory : nil,
            impulseMood: purchaseType == .impulse ? selectedMood : nil,
            impulseMoodNotes: purchaseType == .impulse && !moodNotes.isEmpty ? moodNotes : nil,
            amount: amount,
            appName: appName
        )
        
        purchaseIntentService.recordIntent(intent)
        print("✅ [PurchaseIntentPromptView] Intent recorded")
        
        // Record dismissal time to prevent immediate re-prompt
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastPurchaseIntentPromptTime")
        
        // Store which app was selected for metrics (we already have the index)
        let appIndex = selectedAppIndex
        
        // Temporarily unblock apps so user can continue
        // Pass purchase intent data and app info for metrics tracking
        deviceActivityService.temporarilyUnblock(
            durationMinutes: 15,
            purchaseType: purchaseType?.rawValue,
            category: purchaseType == .planned ? selectedCategory?.rawValue : nil,
            mood: purchaseType == .impulse ? selectedMood?.rawValue : nil,
            moodNotes: purchaseType == .impulse && !moodNotes.isEmpty ? moodNotes : nil,
            appIndex: appIndex
        )
        print("✅ [PurchaseIntentPromptView] Apps unblocked (app index: \(appIndex ?? -1))")
        
        // Show confirmation message before dismissing
        // Note: We unblock all selected apps since we can't identify the specific app that was blocked
        // Use cached count to avoid blocking
        if appsCount == 1 {
            showConfirmation = "App is unblocked for 15 minutes.\nYou can now open it."
        } else {
            showConfirmation = "All \(appsCount) selected apps are unblocked for 15 minutes.\nYou can now open the app you want to use."
        }
        
        // Dismiss after showing confirmation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.dismiss()
        }
    }
    
    // Lazy load goal photo (only when view appears and goal exists)
    private func loadGoalPhoto(for goal: SavingsGoal) {
        guard goal.photoPath != nil,
              !isLoadingGoalPhoto else { return }
        
        isLoadingGoalPhoto = true
        
        // First try UserDefaults cache
        let cacheKey = "goal_photo_\(goal.id)"
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let image = UIImage(data: data) {
            goalPhoto = image
            isLoadingGoalPhoto = false
            return
        }
        
        // TEMPORARILY DISABLED: Firebase Storage - testing if it's causing crash
        // Then try Firebase Storage (async, lazy load)
        // if authService.currentUser?.uid != nil {
        //     Task {
        //         let storageRef = Storage.storage().reference().child(photoPath)
        //         
        //         do {
        //             let data = try await storageRef.data(maxSize: 2 * 1024 * 1024) // 2MB max
        //             if let image = UIImage(data: data) {
        //                 await MainActor.run {
        //                     goalPhoto = image
        //                     // Cache in UserDefaults
        //                     if let imageData = image.jpegData(compressionQuality: 0.8) {
        //                         UserDefaults.standard.set(imageData, forKey: cacheKey)
        //                     }
        //                     isLoadingGoalPhoto = false
        //                 }
        //             }
        //         } catch {
        //             print("ℹ️ [PurchaseIntentPromptView] Goal photo not found: \(photoPath)")
        //             await MainActor.run {
        //                 isLoadingGoalPhoto = false
        //             }
        //         }
        //     }
        // } else {
        //     isLoadingGoalPhoto = false
        // }
        isLoadingGoalPhoto = false
    }
    
    // Load recent regrets (lazy, only when view appears)
    private func loadRecentRegrets() {
        Task {
            // Get regrets from last 30 days
            let allRegrets = regretService.regretEntries
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let recent = allRegrets.filter { $0.date >= thirtyDaysAgo }
                .sorted { $0.date > $1.date }
                .prefix(2) // Show max 2 recent regrets
            
            await MainActor.run {
                recentRegrets = Array(recent)
            }
        }
    }
}

// MARK: - Goal Visualization Card
struct GoalVisualizationCard: View {
    let goal: SavingsGoal
    @Binding var goalPhoto: UIImage?
    @Binding var isLoadingPhoto: Bool
    
    private var progressPercentage: Int {
        return Int(goal.progress * 100)
    }
    
    private var countdownText: String? {
        guard let daysUntil = goal.daysUntilTarget else { return nil }
        if daysUntil < 0 {
            return "Target date passed"
        } else if daysUntil == 0 {
            return "Today!"
        } else if daysUntil == 1 {
            return "1 day remaining"
        } else {
            return "\(daysUntil) days remaining"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Goal Photo (if available)
            if let photo = goalPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if isLoadingPhoto {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dreamMist)
                    .frame(height: 150)
                    .overlay(ProgressView())
            }
            
            // Goal Info
            VStack(spacing: 8) {
                Text(goal.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.midnightSlate)
                
                if let countdown = countdownText {
                    Text(countdown)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.reverBlue)
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(progressPercentage)% complete")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.softGraphite)
                        Spacer()
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0.9, green: 0.9, blue: 0.9))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.reverBlue)
                                .frame(width: geometry.size.width * CGFloat(goal.progress), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.dreamMist, Color.reverBlue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.reverBlue.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Impact Calculator View
struct ImpactCalculatorView: View {
    let goal: SavingsGoal
    let purchaseAmount: Double
    let daysDelayed: Double
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: purchaseAmount)) ?? "$\(Int(purchaseAmount))"
    }
    
    private var formattedDays: String {
        if daysDelayed < 1 {
            return String(format: "%.1f", daysDelayed)
        } else {
            return String(format: "%.1f", daysDelayed)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                Text("Impact on Your Goal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.midnightSlate)
            }
            
            Text("This \(formattedAmount) purchase delays \"\(goal.name)\" by \(formattedDays) days")
                .font(.system(size: 13))
                .foregroundColor(.softGraphite)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Past Regret Reminder View
struct PastRegretReminderView: View {
    let regrets: [RegretEntry]
    
    private var mostRecentRegret: RegretEntry? {
        regrets.first
    }
    
    private var formattedAmount: String? {
        guard let regret = mostRecentRegret,
              let amount = regret.amount else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount))
    }
    
    var body: some View {
        if let regret = mostRecentRegret {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    Text("Remember This?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
                
                if let formattedAmount = formattedAmount {
                    Text("You regretted spending \(formattedAmount) on \(regret.merchant ?? "a purchase") recently. This feels similar.")
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                        .multilineTextAlignment(.center)
                } else {
                    Text("You had a recent regret purchase. This feels similar.")
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.red.opacity(0.1))
            )
        }
    }
}

#Preview {
    PurchaseIntentPromptView()
        .environmentObject(PurchaseIntentService.shared)
        .environmentObject(DeviceActivityService.shared)
}

