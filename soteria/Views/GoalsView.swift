//
//  GoalsView.swift
//  rever
//
//  Savings goals tracking (manual, no bank integration)
//

import SwiftUI
import PhotosUI
// TEMPORARILY DISABLED: Firebase imports - testing if they're causing crash
// import FirebaseStorage
// import FirebaseAuth
import UIKit

struct GoalsView: View {
    @EnvironmentObject var goalsService: GoalsService
    @EnvironmentObject var authService: AuthService
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @State private var showCreateGoal = false
    @State private var showPaywall = false
    @State private var isActiveGoalsExpanded = true
    @State private var isHistoricalGoalsExpanded = true
    @State private var refreshTrigger = UUID() // Force view refresh
    
    var body: some View {
        ZStack(alignment: .top) {
            // REVER background
            Color.mistGray
                .ignoresSafeArea(.all, edges: .top)
            Color.cloudWhite
                .ignoresSafeArea()
            
            ScrollView {
                // Spacer for fixed header
                Color.clear
                    .frame(height: 60)
                
                VStack(spacing: 24) {
                    // Active Goals Section
                    // Active Goals Section
                    if !goalsService.activeGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header with Expand/Collapse
                            HStack {
                                Text("Active Goals")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.midnightSlate)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isActiveGoalsExpanded.toggle()
                                    }
                                }) {
                                    Image(systemName: isActiveGoalsExpanded ? "minus.circle.fill" : "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.softGraphite)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Goals List (collapsible)
                            if isActiveGoalsExpanded {
                                // Additional safety filter: ensure only active goals with active status
                                let filteredActiveGoals = goalsService.activeGoals.filter { goal in
                                    let isActive = goal.status == .active
                                    let notInArchived = !goalsService.archivedGoals.contains(where: { $0.id == goal.id })
                                    if !isActive || !notInArchived {
                                        print("⚠️ [GoalsView] Filtering out goal from active: \(goal.id), status: \(goal.status), in archived: \(!notInArchived)")
                                    }
                                    return isActive && notInArchived
                                }
                                
                                List {
                                    ForEach(filteredActiveGoals) { goal in
                                        GoalCard(goal: goal)
                                            .id("goal_card_\(goal.id)") // Explicit ID to help SwiftUI track the card
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                                            .listRowBackground(Color.clear)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                // Cancel action
                                                Button(role: .cancel) {
                                                    goalsService.cancelGoal(goal)
                                                } label: {
                                                    Label("Cancel", systemImage: "xmark.circle")
                                                }
                                                .tint(.orange)
                                                
                                                // Delete action
                                                Button(role: .destructive) {
                                                    goalsService.deleteGoal(goal)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .scrollDisabled(true) // Disable List scrolling, let parent ScrollView handle it
                                .frame(height: CGFloat(filteredActiveGoals.count) * 550) // Fixed height based on count (accounts for photo + all content)
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    
                    // Historical Goals Section
                    // archivedGoals already filters out active goals, so we can use it directly
                    if !goalsService.archivedGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header with Expand/Collapse
                            HStack {
                                Text("Historical Goals")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.midnightSlate)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isHistoricalGoalsExpanded.toggle()
                                    }
                                }) {
                                    Image(systemName: isHistoricalGoalsExpanded ? "minus.circle.fill" : "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.softGraphite)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Goals List (collapsible)
                            if isHistoricalGoalsExpanded {
                                // Additional safety filter: ensure no active goals show in historical
                                let activeGoalIds = Set(goalsService.activeGoals.map { $0.id })
                                let baseFilteredGoals = goalsService.archivedGoals.filter { goal in
                                    // Double-check: must not be active status
                                    guard goal.status != .active else {
                                        print("⚠️ [GoalsView] Filtering out active goal from historical: \(goal.id)")
                                        return false
                                    }
                                    // Double-check: must not exist in active goals
                                    guard !activeGoalIds.contains(goal.id) else {
                                        print("⚠️ [GoalsView] Filtering out goal from historical (exists in active): \(goal.id)")
                                        return false
                                    }
                                    // Must be one of the historical statuses
                                    let isHistorical = goal.status == .achieved || goal.status == .failed || goal.status == .cancelled
                                    if !isHistorical {
                                        print("⚠️ [GoalsView] Filtering out goal from historical (invalid status): \(goal.id), status: \(goal.status)")
                                    }
                                    return isHistorical
                                }
                                
                                // Free users limited to last 7 days of historical goals
                                let filteredHistoricalGoals: [SavingsGoal] = {
                                    if !subscriptionService.isPremium {
                                        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                                        return baseFilteredGoals.filter { goal in
                                            let goalDate = goal.completedDate ?? goal.createdDate
                                            return goalDate >= sevenDaysAgo
                                        }
                                    } else {
                                        return baseFilteredGoals
                                    }
                                }()
                                
                                let sortedHistoricalGoals = filteredHistoricalGoals.sorted(by: { ($0.completedDate ?? $0.createdDate) > ($1.completedDate ?? $1.createdDate) })
                                
                                if !sortedHistoricalGoals.isEmpty {
                                    List {
                                        ForEach(sortedHistoricalGoals) { goal in
                                            GoalCard(goal: goal)
                                                .listRowSeparator(.hidden)
                                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                                                .listRowBackground(Color.clear)
                                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                    Button(role: .destructive) {
                                                        goalsService.deleteArchivedGoal(goal)
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                        }
                                    }
                                    .listStyle(.plain)
                                    .scrollContentBackground(.hidden)
                                    .scrollDisabled(true) // Disable List scrolling, let parent ScrollView handle it
                                    .frame(height: CGFloat(sortedHistoricalGoals.count) * 550) // Fixed height based on count (accounts for photo + all content)
                                    .padding(.horizontal, 20)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .top)),
                                        removal: .opacity.combined(with: .move(edge: .top))
                                    ))
                                }
                            }
                        }
                    }
                    
                    // Empty State
                    if goalsService.activeGoals.isEmpty && goalsService.archivedGoals.isEmpty {
                        // Empty State
                        VStack(spacing: 16) {
                            Image(systemName: "target")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                            
                            Text("No Savings Goals")
                                .font(.system(size: 20, weight: .semibold, design: .default))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                            
                            Text("Create a goal to start saving for trips, purchases, or emergencies")
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(Color.softGraphite)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                if subscriptionService.isPremium {
                                    showCreateGoal = true
                                } else {
                                    showPaywall = true
                                }
                            }) {
                                Text("Create Goal")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.softGraphite)
                                    )
                            }
                        }
                        .padding(.vertical, 60)
                    }
                    
                    // Create Goal Button
                    if !goalsService.activeGoals.isEmpty || !goalsService.archivedGoals.isEmpty {
                        Button(action: {
                            if subscriptionService.isPremium {
                                showCreateGoal = true
                            } else {
                                showPaywall = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create New Goal")
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.softGraphite)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Premium Header
            PremiumHeaderView(
                title: "Savings Goals",
                subscriptionService: subscriptionService,
                userEmail: authService.currentUser?.email ?? ""
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowCreateGoal"))) { _ in
            print("✅ [GoalsView] Received ShowCreateGoal notification - showing create goal view")
            if subscriptionService.isPremium {
                showCreateGoal = true
            } else {
                showPaywall = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .sheet(isPresented: $showCreateGoal) {
            CreateGoalView()
                .environmentObject(goalsService)
                .environmentObject(authService)
                .onDisappear {
                    // Refresh goals after creating to ensure proper filtering and UI update
                    print("🔄 [GoalsView] CreateGoalView dismissed - refreshing goals")
                    // Force immediate refresh and UI update
                    DispatchQueue.main.async {
                        goalsService.refreshGoals()
                        
                        // Check for duplicates
                        let activeIds = Set(goalsService.activeGoals.map { $0.id })
                        let archivedIds = Set(goalsService.archivedGoals.map { $0.id })
                        let duplicates = activeIds.intersection(archivedIds)
                        if !duplicates.isEmpty {
                            print("❌ [GoalsView] Found duplicate goals in both arrays: \(duplicates)")
                            // Force cleanup
                            for duplicateId in duplicates {
                                if let goal = goalsService.activeGoals.first(where: { $0.id == duplicateId }) {
                                    print("   - Removing duplicate from archived: \(duplicateId)")
                                    var cleanedArchived = goalsService.archivedGoals
                                    cleanedArchived.removeAll { $0.id == duplicateId }
                                    // This will be saved by refreshArchivedGoals
                                }
                            }
                            goalsService.refreshGoals()
                        }
                        
                        print("🔄 [GoalsView] Goals refreshed - Active: \(goalsService.activeGoals.count), Archived: \(goalsService.archivedGoals.count)")
                    }
                }
        }
        .onAppear {
            // Refresh goals when view appears to ensure UI is up to date
            // Only refresh if we haven't already done so recently
            goalsService.refreshGoals()
        }
        .task {
            // FIXED: Load goals immediately when GoalsView appears
            // This fixes the delay where goals weren't loading until 30 seconds after app launch
            // GoalsService.init() defers loading to prevent startup delays, but we need to load on-demand
            print("🟢 [GoalsView] .task started - ensuring goals are loaded")
            goalsService.ensureDataLoaded()
            print("🟢 [GoalsView] Goals loaded (if not already loaded)")
        }
        .onAppear {
            // Clean up archived goals on appear to ensure no active goals show in historical
            goalsService.ensureDataLoaded()
            // Force refresh of archived goals to remove any active goals
            // This ensures the view refreshes with correct data
            goalsService.refreshGoals()
        }
    }
}

struct GoalCard: View {
    @EnvironmentObject var goalsService: GoalsService
    @EnvironmentObject var authService: AuthService
    let goal: SavingsGoal
    
    @State private var goalPhoto: UIImage? = nil
    @State private var isLoadingPhoto = false
    @State private var showAddDeposit = false
    @State private var showEditGoal = false
    @State private var isCardReady = false // Track if card is fully ready to prevent premature photo loading
    @State private var hasAttemptedPhotoLoad = false // Prevent multiple photo load attempts
    
    private var progressPercentage: Int {
        return Int(goal.progress * 100)
    }
    
    private var formattedCurrent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: goal.currentAmount)) ?? "$0.00"
    }
    
    private var formattedTarget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: goal.targetAmount)) ?? "$0.00"
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
    
    // Helper function to get color for goal status
    private func statusColor(for status: SavingsGoal.GoalStatus) -> Color {
        switch status {
        case .active:
            return .softGraphite
        case .achieved:
            return .green
        case .failed:
            return .orange
        case .cancelled:
            return .gray
        }
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Goal name and details (ALWAYS show first to ensure card structure is stable)
            // This prevents SwiftUI from creating a separate card for the photo
            HStack {
                Image(systemName: goal.category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color.softGraphite)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(goal.name)
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(Color.midnightSlate)
                        
                        // Status Badge
                        if goal.status != .active {
                            HStack(spacing: 4) {
                                Image(systemName: goal.status.icon)
                                    .font(.system(size: 10))
                                Text(goal.status.displayName)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(statusColor(for: goal.status))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(statusColor(for: goal.status).opacity(0.15))
                            )
                        }
                    }
                    
                    Text(goal.category.rawValue)
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(Color.softGraphite)
                }
                
                Spacer()
                
                if goalsService.activeGoal?.id == goal.id && goal.status == .active {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.softGraphite)
                }
            }
            
            // Description (if available)
            if let description = goal.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.softGraphite)
                    .lineLimit(2)
            }
            
            // Countdown or Completion Info
            if goal.status == .active, let countdown = countdownText {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                    Text(countdown)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.softGraphite)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.dreamMist)
                )
            } else if goal.status != .active, let completedDate = goal.completedDate {
                HStack {
                    Image(systemName: goal.status.icon)
                        .font(.system(size: 14))
                        .foregroundColor(statusColor(for: goal.status))
                    Text("Completed: \(formatDate(completedDate))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(statusColor(for: goal.status))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(statusColor(for: goal.status).opacity(0.15))
                )
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(formattedCurrent)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color.softGraphite)
                    
                    Text("of \(formattedTarget)")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(Color.softGraphite)
                    
                    Spacer()
                    
                    Text("\(progressPercentage)%")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(Color.softGraphite)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.9, green: 0.9, blue: 0.9))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.softGraphite)
                            .frame(width: geometry.size.width * CGFloat(goal.progress), height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Action Buttons
            if goal.status == .active {
                HStack(spacing: 12) {
                    Button(action: {
                        showAddDeposit = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Add Deposit")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.softGraphite)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if goalsService.activeGoal?.id != goal.id {
                        Button(action: {
                            goalsService.setActiveGoal(goal)
                        }) {
                            Text("Set as Active")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.softGraphite)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Only show cancel button for active goals
                    if goal.status == .active {
                        Button(action: {
                            goalsService.cancelGoal(goal)
                        }) {
                            Text("Cancel Goal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.1))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Goal Photo (if available) - Loaded at the end to ensure card structure is stable
            if let photo = goalPhoto, !goal.name.isEmpty, isCardReady {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if goal.photoPath != nil && !isLoadingPhoto && !goal.name.isEmpty && isCardReady && !hasAttemptedPhotoLoad {
                // Placeholder while loading (only if goal has a name, card is ready, and we haven't tried loading yet)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dreamMist)
                    .frame(height: 180)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                    )
                    .onAppear {
                        // Only attempt to load photo once, after a brief delay to ensure card is stable
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if !self.hasAttemptedPhotoLoad && self.isCardReady && !self.goal.name.isEmpty {
                                self.hasAttemptedPhotoLoad = true
                                self.loadGoalPhoto()
                            }
                        }
                    }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16)) // Ensure all content is clipped to card shape
        .contentShape(Rectangle())
        .id("goal_card_\(goal.id)") // Explicit ID to help SwiftUI track the entire card
        .onAppear {
            // Reset state when card appears to prevent duplicate renders
            hasAttemptedPhotoLoad = false
            
            // Mark card as ready after ensuring goal name is rendered
            // Use a delay to ensure the entire card structure is stable
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Only mark as ready if goal name is still present (safety check)
                if !self.goal.name.isEmpty && !self.isCardReady {
                    self.isCardReady = true
                    // Trigger photo load if goal has a photo path
                    if self.goal.photoPath != nil && !self.hasAttemptedPhotoLoad && !self.isLoadingPhoto {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if self.isCardReady && !self.goal.name.isEmpty {
                                self.hasAttemptedPhotoLoad = true
                                self.loadGoalPhoto()
                            }
                        }
                    }
                }
            }
        }
        .onTapGesture {
            showEditGoal = true
        }
        .sheet(isPresented: $showEditGoal) {
            EditGoalView(goal: goal)
                .environmentObject(goalsService)
                .environmentObject(authService)
        }
        .sheet(isPresented: $showAddDeposit) {
            AddDepositView(goal: goal)
                .environmentObject(goalsService)
        }
    }
    
    // Lazy load goal photo from S3 (only when card appears)
    private func loadGoalPhoto() {
        guard goal.photoPath != nil,
              !isLoadingPhoto else { return }
        
        isLoadingPhoto = true
        
        // First try UserDefaults cache (fastest)
        let cacheKey = "goal_photo_\(goal.id)"
        
        // Safety check: Only load photo if goal has a name and card is ready (prevents photo-only cards)
        guard !goal.name.isEmpty else {
            print("⚠️ [GoalCard] Skipping photo load - goal has no name: \(goal.id)")
            isLoadingPhoto = false
            return
        }
        
        // Additional safety: Don't load photo if card isn't ready yet
        // This prevents the photo from loading before the goal name is rendered
        // The isCardReady flag is set in onAppear after a brief delay
        
        // Check if photo was explicitly deleted (UserDefaults key exists but is nil/removed)
        // If the key doesn't exist in UserDefaults but photoPath is set, it might have been deleted
        // We'll still try to load from S3, but if it fails, we won't keep retrying
        
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let image = UIImage(data: data) {
            // CRITICAL: Wait for card to be ready before loading photo
            // This prevents SwiftUI from creating a separate card for just the photo
            // Check if card is ready, if not, wait and check again
            func setPhotoWhenReady() {
                if self.isCardReady && !self.goal.name.isEmpty {
                    self.goalPhoto = image
                    self.isLoadingPhoto = false
                } else {
                    // Card not ready yet, check again in 0.2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        setPhotoWhenReady()
                    }
                }
            }
            
            // Start checking after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                setPhotoWhenReady()
            }
            return
        }
        
        // Check if photo was explicitly marked as deleted
        // If UserDefaults has a "deleted" marker, don't try to reload
        if UserDefaults.standard.bool(forKey: "goal_photo_deleted_\(goal.id)") {
            print("ℹ️ [GoalCard] Goal photo was deleted, not reloading: \(goal.id)")
            isLoadingPhoto = false
            return
        }
        
        // Then try S3 (async, lazy load)
        Task {
            let photoService = GoalPhotoService.shared
            
            do {
                if let image = try await photoService.downloadGoalPhoto(goalId: goal.id) {
                    // Cache in UserDefaults for future fast access
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        UserDefaults.standard.set(imageData, forKey: cacheKey)
                        // Clear deletion marker if photo was successfully loaded
                        UserDefaults.standard.removeObject(forKey: "goal_photo_deleted_\(goal.id)")
                    }
                    
                    await MainActor.run {
                        goalPhoto = image
                        isLoadingPhoto = false
                    }
                } else {
                    // Photo not found in S3 - mark as deleted to prevent future reload attempts
                    UserDefaults.standard.set(true, forKey: "goal_photo_deleted_\(goal.id)")
                    await MainActor.run {
                        isLoadingPhoto = false
                    }
                }
            } catch {
                // Photo not found or error - mark as deleted to prevent future reload attempts
                UserDefaults.standard.set(true, forKey: "goal_photo_deleted_\(goal.id)")
                print("ℹ️ [GoalCard] Goal photo not found in S3: \(error.localizedDescription)")
                await MainActor.run {
                    isLoadingPhoto = false
                }
            }
        }
    }
    
    // Add Deposit Sheet
    private var addDepositSheet: some View {
        AddDepositView(goal: goal)
            .environmentObject(goalsService)
    }
}

struct CreateGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var goalsService: GoalsService
    @EnvironmentObject var authService: AuthService
    
    @State private var goalName: String = ""
    @State private var targetAmount: String = ""
    @State private var selectedCategory: SavingsGoal.GoalCategory = .trip
    @State private var startDate: Date? = nil
    @State private var showStartDatePicker: Bool = false
    @State private var targetDate: Date? = nil
    @State private var showTargetDatePicker: Bool = false
    @State private var goalDescription: String = ""
    @State private var goalPhoto: UIImage? = nil
    @State private var showImageSourceActionSheet = false
    @State private var showImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploadingPhoto = false
    @State private var isCreatingGoal = false // Prevent duplicate creation
    @State private var showDateValidationAlert = false
    @State private var customSavingsAmount: String = ""
    @State private var showSavingsPlan = false
    @State private var productLink: String = ""
    @State private var isFetchingProductInfo = false
    @State private var productInfo: ProductInfo? = nil
    @State private var productFetchError: String? = nil
    @State private var showProductInfo = false
    @State private var selectedTimeframe: Int? = nil // 30, 60, 90, or nil for custom
    
    // Notification settings
    @State private var notificationsEnabled: Bool = true
    @State private var progressNotificationFrequency: SavingsGoal.ProgressNotificationFrequency = .daily
    @State private var milestoneNotificationsEnabled: Bool = true
    @State private var achievementNotificationEnabled: Bool = true
    @State private var notificationTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var showNotificationSettings: Bool = false
    
    // Reset flag when view appears (in case it was left in true state)
    private func resetCreationState() {
        isCreatingGoal = false
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        goalDetailsSection
                        dateRangeSection
                        if showTargetDatePicker && targetDate != nil {
                            savingsPlanSection
                        }
                        goalPhotoSection // Moved to bottom - photo appears after goal details
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.midnightSlate)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        print("🔵 [CreateGoalView] Create button tapped")
                        createGoal()
                    }
                    .disabled(isCreateButtonDisabled || !areDatesValid() || isCreatingGoal)
                    .foregroundColor(.deepReverBlue)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Reset creation state when view appears
                resetCreationState()
            }
            .alert("Invalid Date Range", isPresented: $showDateValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Target date must be at least 1 day after start date.")
            }
            .confirmationDialog("Choose Photo", isPresented: $showImageSourceActionSheet, titleVisibility: .visible) {
                photoSelectionButtons
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: imagePickerSourceType) { image in
                    // Resize image immediately to prevent UI issues
                    // Standard size for goal photos: 600px max dimension (maintains aspect ratio)
                    goalPhoto = image.resized(toMaxDimension: 600)
                    // Photo will be uploaded after goal is created (in createGoal())
                }
            }
        }
    }
    
    // MARK: - Computed Properties for Body Sections
    
    private var isCreateButtonDisabled: Bool {
        goalName.isEmpty || targetAmount.isEmpty || Double(targetAmount) == nil || isUploadingPhoto || isCreatingGoal
    }
    
    private var goalPhotoSection: some View {
        VStack(spacing: 16) {
            Text("Goal Photo (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                showImageSourceActionSheet = true
            }) {
                photoButtonContent
            }
            
            if goalPhoto != nil {
                Button(action: {
                    goalPhoto = nil
                }) {
                    Text("Remove Photo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                }
            }
            
            if isUploadingPhoto {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Uploading photo...")
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite)
                }
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    private var photoButtonContent: some View {
        ZStack {
            if let photo = goalPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.dreamMist)
                
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.reverBlue)
                    Text("Add Photo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.softGraphite)
                }
            }
        }
        .frame(height: 200) // Fixed height to prevent overflow
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.reverBlue.opacity(0.3), lineWidth: 2)
        )
    }
    
    private var goalDetailsSection: some View {
        VStack(spacing: 16) {
            Text("Goal Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            goalNameField
            targetAmountField
            categoryPicker
            descriptionField
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    private var goalNameField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Name")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            TextField("e.g., Trip to Hawaii", text: $goalName)
                .font(.system(size: 16))
                .foregroundColor(.midnightSlate)
                .padding(14)
                .background(Color.dreamMist)
                .cornerRadius(12)
        }
    }
    
    private var targetAmountField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Amount")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            TextField("0.00", text: $targetAmount)
                .font(.system(size: 16))
                .foregroundColor(.midnightSlate)
                .keyboardType(.decimalPad)
                .padding(14)
                .background(Color.dreamMist)
                .cornerRadius(12)
        }
    }
    
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            Picker("Category", selection: $selectedCategory) {
                ForEach(SavingsGoal.GoalCategory.allCases, id: \.self) { category in
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.rawValue)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(.menu)
            .padding(14)
            .background(Color.dreamMist)
            .cornerRadius(12)
        }
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description (Optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            TextField("What does this goal mean to you?", text: $goalDescription, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(.midnightSlate)
                .lineLimit(3...6)
                .padding(14)
                .background(Color.dreamMist)
                .cornerRadius(12)
        }
    }
    
    private var dateRangeSection: some View {
        VStack(spacing: 16) {
            Text("Date Range (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                startDateToggle
                targetDateToggle
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    private var startDateToggle: some View {
        Group {
            Toggle(isOn: $showStartDatePicker) {
                Text("Set Start Date")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.softGraphite)
            }
            
            if showStartDatePicker {
                DatePicker("Start Date", selection: Binding(
                    get: { startDate ?? Date() },
                    set: { newDate in
                        startDate = newDate
                        // Validate: if target date is set, it must be at least 1 day after start date
                        if let target = targetDate, showTargetDatePicker {
                            let calendar = Calendar.current
                            if let daysBetween = calendar.dateComponents([.day], from: newDate, to: target).day, daysBetween < 1 {
                                // Adjust target date to be at least 1 day after start date
                                targetDate = calendar.date(byAdding: .day, value: 1, to: newDate) ?? target
                            }
                        }
                    }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)
                
                if let start = startDate, let target = targetDate, showTargetDatePicker, !isValidDateRange(start: start, target: target) {
                    Text("Target date must be at least 1 day after start date")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var targetDateToggle: some View {
        Group {
            Toggle(isOn: $showTargetDatePicker) {
                Text("Set Target Date")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.softGraphite)
            }
            
            if showTargetDatePicker {
                DatePicker("Target Date", selection: Binding(
                    get: { 
                        // Default to tomorrow if no date is set (must be at least 1 day after start date or today)
                        if let date = targetDate {
                            return date
                        } else {
                            let calendar = Calendar.current
                            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                            // If start date is set, ensure target is at least 1 day after start
                            if let start = startDate, showStartDatePicker {
                                let daysBetween = calendar.dateComponents([.day], from: start, to: tomorrow).day ?? 0
                                if daysBetween < 1 {
                                    return calendar.date(byAdding: .day, value: 1, to: start) ?? tomorrow
                                }
                            }
                            return tomorrow
                        }
                    },
                    set: { newDate in
                        // Validate: if start date is set, target must be at least 1 day after start
                        if let start = startDate, showStartDatePicker {
                            let calendar = Calendar.current
                            if let daysBetween = calendar.dateComponents([.day], from: start, to: newDate).day, daysBetween < 1 {
                                // Adjust target date to be at least 1 day after start date
                                targetDate = calendar.date(byAdding: .day, value: 1, to: start) ?? newDate
                            } else {
                                targetDate = newDate
                            }
                        } else {
                            // If no start date, ensure target is at least tomorrow
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())
                            let selectedDay = calendar.startOfDay(for: newDate)
                            if calendar.isDate(selectedDay, inSameDayAs: today) {
                                // If user selects today, default to tomorrow
                                targetDate = calendar.date(byAdding: .day, value: 1, to: today) ?? newDate
                            } else {
                                targetDate = newDate
                            }
                        }
                    }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)
                
                if let start = startDate, let target = targetDate, showStartDatePicker, !isValidDateRange(start: start, target: target) {
                    Text("Target date must be at least 1 day after start date")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var savingsPlanSection: some View {
        VStack(spacing: 16) {
            Text("Savings Plan")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let requiredSavings = calculateRequiredSavings() {
                VStack(spacing: 12) {
                    // Required savings per week/day
                    savingsRequirementCard(requiredSavings: requiredSavings)
                    
                    // Custom amount input
                    customAmountInput
                    
                    // Show extension calculation if custom amount is less than required
                    if let customAmount = Double(customSavingsAmount), customAmount > 0 {
                        if let extensionInfo = calculateExtensionDays(customAmount: customAmount, requiredPerDay: requiredSavings.perDay) {
                            extensionWarningCard(extensionDays: extensionInfo.days, newDueDate: extensionInfo.newDate)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    private func savingsRequirementCard(requiredSavings: (perDay: Double, perWeek: Double)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Required Savings")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Per Day")
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite)
                    Text(formatCurrency(requiredSavings.perDay))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Per Week")
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite)
                    Text(formatCurrency(requiredSavings.perWeek))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.dreamMist)
        .cornerRadius(12)
    }
    
    private var customAmountInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Savings Amount (Optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            TextField("Enter amount", text: $customSavingsAmount)
                .font(.system(size: 16))
                .foregroundColor(.midnightSlate)
                .keyboardType(.decimalPad)
                .padding(14)
                .background(Color.dreamMist)
                .cornerRadius(12)
        }
    }
    
    private func extensionWarningCard(extensionDays: Double, newDueDate: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goal Extension")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    Text("This amount is less than required. Your goal would be extended by approximately \(Int(ceil(extensionDays))) day\(Int(ceil(extensionDays)) == 1 ? "" : "s").")
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("New Due Date")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.softGraphite)
                Text(formatDateForExtension(newDueDate))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.midnightSlate)
            }
            
            Button(action: {
                targetDate = newDueDate
                showTargetDatePicker = true
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 14))
                    Text("Set as Target Date")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.reverBlue)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatDateForExtension(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Calculate required savings per day and per week
    private func calculateRequiredSavings() -> (perDay: Double, perWeek: Double)? {
        guard let targetDate = targetDate,
              let targetAmount = Double(targetAmount),
              targetAmount > 0 else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = self.startDate ?? now
        
        // Calculate days between start and target date (inclusive of both dates)
        // Add 1 to include both start and end dates in the count
        guard let daysBetween = calendar.dateComponents([.day], from: startDate, to: targetDate).day,
              daysBetween >= 1 else { return nil }
        
        // Calculate days including both start and end dates
        let totalDays = Double(daysBetween + 1)
        
        // Calculate required savings per day
        let perDay = targetAmount / totalDays
        
        // Calculate required savings per week
        // If goal period is less than a week, show what would be saved per week at this rate
        // But cap it at the total goal amount to avoid showing values that exceed the goal
        let weeksInPeriod = totalDays / 7.0
        let perWeek: Double
        if weeksInPeriod >= 1.0 {
            // Goal period is a week or more: show savings per week
            perWeek = targetAmount / weeksInPeriod
        } else {
            // Goal period is less than a week: show what would be saved per week at this daily rate
            // But don't exceed the total goal amount
            perWeek = min(perDay * 7.0, targetAmount)
        }
        
        return (perDay: perDay, perWeek: perWeek)
    }
    
    // Calculate how many days a custom amount would extend the goal and the new due date
    private func calculateExtensionDays(customAmount: Double, requiredPerDay: Double) -> (days: Double, newDate: Date)? {
        guard customAmount < requiredPerDay, requiredPerDay > 0 else { return nil }
        
        guard let targetAmount = Double(targetAmount),
              targetAmount > 0,
              let targetDate = targetDate else { return nil }
        
        let calendar = Calendar.current
        let startDate = self.startDate ?? Date()
        guard let originalDays = calendar.dateComponents([.day], from: startDate, to: targetDate).day,
              originalDays > 0 else { return nil }
        
        // With custom amount per day, how many days would it take?
        let daysWithCustomAmount = targetAmount / customAmount
        
        // Extension = difference
        let extensionDays = max(daysWithCustomAmount - Double(originalDays), 0)
        
        // Calculate new due date
        guard let newDate = calendar.date(byAdding: .day, value: Int(ceil(extensionDays)), to: targetDate) else {
            return nil
        }
        
        return (days: extensionDays, newDate: newDate)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    // MARK: - Notification Settings Section
    
    private var notificationSettingsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Notifications")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Spacer()
                
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
            }
            
            if notificationsEnabled {
                VStack(spacing: 16) {
                    // Progress notification frequency
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress Updates")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.softGraphite)
                        
                        Picker("Frequency", selection: $progressNotificationFrequency) {
                            Text("Daily").tag(SavingsGoal.ProgressNotificationFrequency.daily)
                            Text("Twice Weekly").tag(SavingsGoal.ProgressNotificationFrequency.twiceWeekly)
                            Text("Weekly").tag(SavingsGoal.ProgressNotificationFrequency.weekly)
                            Text("Never").tag(SavingsGoal.ProgressNotificationFrequency.never)
                        }
                        .pickerStyle(.menu)
                        .padding(12)
                        .background(Color.dreamMist)
                        .cornerRadius(10)
                    }
                    
                    // Notification time (if not "Never")
                    if progressNotificationFrequency != .never {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notification Time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.softGraphite)
                            
                            DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .padding(12)
                                .background(Color.dreamMist)
                                .cornerRadius(10)
                        }
                    }
                    
                    // Milestone notifications
                    Toggle("Milestone Notifications (25%, 50%, 75%)", isOn: $milestoneNotificationsEnabled)
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                    
                    // Achievement notification
                    Toggle("Achievement Notification", isOn: $achievementNotificationEnabled)
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    private var photoSelectionButtons: some View {
        Group {
            Button("Take Photo") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    imagePickerSourceType = .camera
                    showImagePicker = true
                }
            }
            
            Button("Choose from Library") {
                imagePickerSourceType = .photoLibrary
                showImagePicker = true
            }
            
            if goalPhoto != nil {
                Button("Remove Photo", role: .destructive) {
                    goalPhoto = nil
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
    
    // Validate date range: if both dates are set, target must be at least 1 day after start
    // This ensures the end date is not the same as the start date (minimum next day)
    private func isValidDateRange(start: Date, target: Date) -> Bool {
        let calendar = Calendar.current
        // Check if dates are on the same day
        if calendar.isDate(start, inSameDayAs: target) {
            return false // Same day is not allowed
        }
        // Check if target is at least 1 day after start
        if let daysBetween = calendar.dateComponents([.day], from: start, to: target).day {
            return daysBetween >= 1
        }
        return false
    }
    
    // Check if dates are valid (both set and valid range, or at least one not set)
    private func areDatesValid() -> Bool {
        if showStartDatePicker && showTargetDatePicker {
            guard let start = startDate, let target = targetDate else { return true }
            return isValidDateRange(start: start, target: target)
        }
        return true // If only one or neither is set, it's valid
    }
    
    private func createGoal() {
        // CRITICAL: Prevent duplicate creation - check and set flag atomically
        print("🔵 [CreateGoalView] createGoal() called - goalName: '\(goalName)', isCreatingGoal: \(isCreatingGoal)")
        
        guard !isCreatingGoal else { 
            print("⚠️ [CreateGoalView] Duplicate createGoal() call prevented - flag already set")
            return 
        }
        guard let amount = Double(targetAmount), amount > 0 else { 
            print("⚠️ [CreateGoalView] Invalid amount: '\(targetAmount)'")
            return 
        }
        
        // Validate date range
        if !areDatesValid() {
            print("⚠️ [CreateGoalView] Invalid date range")
            showDateValidationAlert = true
            return
        }
        
        // Set flag IMMEDIATELY to prevent duplicate calls (must be before any async operations)
        isCreatingGoal = true
        print("🔵 [CreateGoalView] isCreatingGoal flag set to true")
        
        // Disable button immediately on main thread
        DispatchQueue.main.async {
            // Button is already disabled via .disabled modifier, but ensure state is consistent
        }
        
        // Prepare optional values to simplify expression
        let goalStartDate = showStartDatePicker ? startDate : nil
        let goalTargetDate = showTargetDatePicker ? targetDate : nil
        let goalDescriptionText = goalDescription.isEmpty ? nil : goalDescription
        
        // Create goal and get the created goal with its ID
        print("🔵 [CreateGoalView] Calling goalsService.createGoal() with name: '\(goalName)'")
        var createdGoal = goalsService.createGoal(
            name: goalName,
            targetAmount: amount,
            startDate: goalStartDate,
            targetDate: goalTargetDate,
            category: selectedCategory,
            photoPath: nil, // Will be set after upload
            description: goalDescriptionText
        )
        print("🔵 [CreateGoalView] Goal created/returned with ID: \(createdGoal.id), name: '\(createdGoal.name)'")
        
        // Update notification settings using updateGoal (which handles saving properly)
        // The createGoal function already schedules notifications, but we need to update with user's settings
        var updatedGoal = createdGoal
        updatedGoal.notificationsEnabled = notificationsEnabled
        updatedGoal.progressNotificationFrequency = progressNotificationFrequency
        updatedGoal.milestoneNotificationsEnabled = milestoneNotificationsEnabled
        updatedGoal.achievementNotificationEnabled = achievementNotificationEnabled
        updatedGoal.notificationTime = notificationsEnabled ? notificationTime : nil
        
        // Use updateGoal to properly save the changes
        goalsService.updateGoal(updatedGoal)
        
        print("✅ [CreateGoalView] Goal created with ID: \(createdGoal.id)")
        
        // Upload photo if one was selected (async, doesn't block goal creation)
        if let photo = goalPhoto {
            uploadGoalPhoto(image: photo, goalId: createdGoal.id)
        }
        
        // Dismiss immediately - don't wait
        dismiss()
        
        // Reset flag after a delay (in case view is re-opened)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                isCreatingGoal = false
            }
        }
    }
    
    private func uploadGoalPhoto(image: UIImage, goalId: String) {
        isUploadingPhoto = true
        
        Task {
            do {
                // Upload to S3 via GoalPhotoService
                let photoService = GoalPhotoService.shared
                let photoUrl = try await photoService.uploadGoalPhoto(image: image, goalId: goalId)
                
                // Also cache in UserDefaults for fast local access
                let cacheKey = "goal_photo_\(goalId)"
                let maxDimension: CGFloat = 600
                let resizedImage = max(image.size.width, image.size.height) > maxDimension
                    ? image.resized(toMaxDimension: maxDimension)
                    : image
                
                if let imageData = resizedImage.jpegData(compressionQuality: 0.8) {
                    UserDefaults.standard.set(imageData, forKey: cacheKey)
                }
                
                // Update goal with S3 photo URL
                await MainActor.run {
                    goalsService.updateGoalPhoto(goalId: goalId, photoPath: photoUrl)
                    isUploadingPhoto = false
                    print("✅ [CreateGoalView] Goal photo uploaded to S3: \(photoUrl)")
                }
            } catch {
                // Fallback to UserDefaults if S3 upload fails
                print("⚠️ [CreateGoalView] S3 upload failed, falling back to UserDefaults: \(error.localizedDescription)")
                
                let cacheKey = "goal_photo_\(goalId)"
                let maxDimension: CGFloat = 600
                let resizedImage = max(image.size.width, image.size.height) > maxDimension
                    ? image.resized(toMaxDimension: maxDimension)
                    : image
                
                guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
                    await MainActor.run {
                        isUploadingPhoto = false
                    }
                    return
                }
                
                UserDefaults.standard.set(imageData, forKey: cacheKey)
                
                // Update goal with local identifier
                let photoPath = "local://\(goalId)"
                await MainActor.run {
                    goalsService.updateGoalPhoto(goalId: goalId, photoPath: photoPath)
                    isUploadingPhoto = false
                    print("✅ [CreateGoalView] Goal photo saved to UserDefaults (fallback): \(cacheKey)")
                }
            }
        }
    }
    
    // Helper function to get status color
    private func statusColor(for status: SavingsGoal.GoalStatus) -> Color {
        switch status {
        case .active:
            return .reverBlue
        case .achieved:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Delete archived goal
    private func deleteArchivedGoal(_ goal: SavingsGoal) {
        goalsService.deleteArchivedGoal(goal)
    }
}

struct EditGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var goalsService: GoalsService
    @EnvironmentObject var authService: AuthService
    
    let goal: SavingsGoal
    
    @State private var goalName: String = ""
    @State private var targetAmount: String = ""
    @State private var selectedCategory: SavingsGoal.GoalCategory = .trip
    @State private var startDate: Date? = nil
    @State private var showStartDatePicker: Bool = false
    @State private var targetDate: Date? = nil
    @State private var showTargetDatePicker: Bool = false
    @State private var goalDescription: String = ""
    @State private var goalPhoto: UIImage? = nil
    @State private var showImageSourceActionSheet = false
    @State private var showImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploadingPhoto = false
    @State private var isSaving = false
    @State private var showDateValidationAlert = false
    @State private var customSavingsAmount: String = ""
    
    // Notification settings
    @State private var notificationsEnabled: Bool = true
    @State private var progressNotificationFrequency: SavingsGoal.ProgressNotificationFrequency = .daily
    @State private var milestoneNotificationsEnabled: Bool = true
    @State private var achievementNotificationEnabled: Bool = true
    @State private var notificationTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        goalPhotoSection
                        goalDetailsSection
                        dateRangeSection
                        if showTargetDatePicker && targetDate != nil {
                            savingsPlanSection
                        }
                        editNotificationSettingsSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.midnightSlate)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(isSaveButtonDisabled || !areDatesValid())
                    .foregroundColor(.deepReverBlue)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Pre-populate fields with goal data
                goalName = goal.name
                targetAmount = String(format: "%.2f", goal.targetAmount)
                selectedCategory = goal.category
                startDate = goal.startDate
                showStartDatePicker = goal.startDate != nil
                targetDate = goal.targetDate
                showTargetDatePicker = goal.targetDate != nil
                goalDescription = goal.description ?? ""
                
                // Load notification settings
                notificationsEnabled = goal.notificationsEnabled
                progressNotificationFrequency = goal.progressNotificationFrequency
                milestoneNotificationsEnabled = goal.milestoneNotificationsEnabled
                achievementNotificationEnabled = goal.achievementNotificationEnabled
                notificationTime = goal.notificationTime ?? {
                    var components = DateComponents()
                    components.hour = 9
                    components.minute = 0
                    return Calendar.current.date(from: components) ?? Date()
                }()
                
                // Load existing photo if available
                if let photoPath = goal.photoPath {
                    loadGoalPhoto(photoPath: photoPath)
                }
            }
            .alert("Invalid Date Range", isPresented: $showDateValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Target date must be at least 1 day after start date.")
            }
            .confirmationDialog("Choose Photo", isPresented: $showImageSourceActionSheet, titleVisibility: .visible) {
                photoSelectionButtons
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: imagePickerSourceType) { image in
                    goalPhoto = image.resized(toMaxDimension: 600)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isSaveButtonDisabled: Bool {
        goalName.isEmpty || targetAmount.isEmpty || Double(targetAmount) == nil || isUploadingPhoto || isSaving
    }
    
    private var goalPhotoSection: some View {
        VStack(spacing: 16) {
            Text("Goal Photo (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                showImageSourceActionSheet = true
            }) {
                photoButtonContent
            }
            
            if goalPhoto != nil {
                Button(action: {
                    goalPhoto = nil
                }) {
                    Text("Remove Photo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                }
            }
            
            if isUploadingPhoto {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Uploading photo...")
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite)
                }
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    private var photoButtonContent: some View {
        ZStack {
            if let photo = goalPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.dreamMist)
                
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.reverBlue)
                    Text("Add Photo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.softGraphite)
                }
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.reverBlue.opacity(0.3), lineWidth: 2)
        )
    }
    
    private var goalDetailsSection: some View {
        VStack(spacing: 16) {
            Text("Goal Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            goalNameField
            targetAmountField
            categoryPicker
            descriptionField
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    private var goalNameField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Name")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            TextField("e.g., Trip to Hawaii", text: $goalName)
                .font(.system(size: 16))
                .foregroundColor(.midnightSlate)
                .padding(14)
                .background(Color.dreamMist)
                .cornerRadius(12)
        }
    }
    
    private var targetAmountField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Amount")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            TextField("0.00", text: $targetAmount)
                .font(.system(size: 16))
                .foregroundColor(.midnightSlate)
                .keyboardType(.decimalPad)
                .padding(14)
                .background(Color.dreamMist)
                .cornerRadius(12)
        }
    }
    
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            Picker("Category", selection: $selectedCategory) {
                ForEach(SavingsGoal.GoalCategory.allCases, id: \.self) { category in
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.rawValue)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(.menu)
            .padding(14)
            .background(Color.dreamMist)
            .cornerRadius(12)
        }
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description (Optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            TextField("What does this goal mean to you?", text: $goalDescription, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(.midnightSlate)
                .lineLimit(3...6)
                .padding(14)
                .background(Color.dreamMist)
                .cornerRadius(12)
        }
    }
    
    private var dateRangeSection: some View {
        VStack(spacing: 16) {
            Text("Date Range (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                startDateToggle
                targetDateToggle
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    private var startDateToggle: some View {
        Group {
            Toggle(isOn: $showStartDatePicker) {
                Text("Set Start Date")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.softGraphite)
            }
            
            if showStartDatePicker {
                DatePicker("Start Date", selection: Binding(
                    get: { startDate ?? Date() },
                    set: { newDate in
                        startDate = newDate
                        if let target = targetDate, showTargetDatePicker {
                            let calendar = Calendar.current
                            if let daysBetween = calendar.dateComponents([.day], from: newDate, to: target).day, daysBetween < 1 {
                                targetDate = calendar.date(byAdding: .day, value: 1, to: newDate) ?? target
                            }
                        }
                    }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)
                
                if let start = startDate, let target = targetDate, showTargetDatePicker, !isValidDateRange(start: start, target: target) {
                    Text("Target date must be at least 1 day after start date")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var targetDateToggle: some View {
        Group {
            Toggle(isOn: $showTargetDatePicker) {
                Text("Set Target Date")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.softGraphite)
            }
            
            if showTargetDatePicker {
                DatePicker("Target Date", selection: Binding(
                    get: { 
                        // Default to tomorrow if no date is set (must be at least 1 day after start date or today)
                        if let date = targetDate {
                            return date
                        } else {
                            let calendar = Calendar.current
                            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                            // If start date is set, ensure target is at least 1 day after start
                            if let start = startDate, showStartDatePicker {
                                let daysBetween = calendar.dateComponents([.day], from: start, to: tomorrow).day ?? 0
                                if daysBetween < 1 {
                                    return calendar.date(byAdding: .day, value: 1, to: start) ?? tomorrow
                                }
                            }
                            return tomorrow
                        }
                    },
                    set: { newDate in
                        if let start = startDate, showStartDatePicker {
                            let calendar = Calendar.current
                            if let daysBetween = calendar.dateComponents([.day], from: start, to: newDate).day, daysBetween < 1 {
                                targetDate = calendar.date(byAdding: .day, value: 1, to: start) ?? newDate
                            } else {
                                targetDate = newDate
                            }
                        } else {
                            // If no start date, ensure target is at least tomorrow
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())
                            let selectedDay = calendar.startOfDay(for: newDate)
                            if calendar.isDate(selectedDay, inSameDayAs: today) {
                                // If user selects today, default to tomorrow
                                targetDate = calendar.date(byAdding: .day, value: 1, to: today) ?? newDate
                            } else {
                                targetDate = newDate
                            }
                        }
                    }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)
                
                if let start = startDate, let target = targetDate, showStartDatePicker, !isValidDateRange(start: start, target: target) {
                    Text("Target date must be at least 1 day after start date")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var savingsPlanSection: some View {
        VStack(spacing: 16) {
            Text("Savings Plan")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let requiredSavings = calculateRequiredSavings() {
                VStack(spacing: 12) {
                    // Required savings per week/day
                    savingsRequirementCard(requiredSavings: requiredSavings)
                    
                    // Custom amount input
                    customAmountInput
                    
                    // Show extension calculation if custom amount is less than required
                    if let customAmount = Double(customSavingsAmount), customAmount > 0 {
                        if let extensionInfo = calculateExtensionDays(customAmount: customAmount, requiredPerDay: requiredSavings.perDay) {
                            extensionWarningCard(extensionDays: extensionInfo.days, newDueDate: extensionInfo.newDate)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    private func savingsRequirementCard(requiredSavings: (perDay: Double, perWeek: Double)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Required Savings")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Per Day")
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite)
                    Text(formatCurrency(requiredSavings.perDay))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Per Week")
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite)
                    Text(formatCurrency(requiredSavings.perWeek))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.dreamMist)
        .cornerRadius(12)
    }
    
    private var customAmountInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Savings Amount (Optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            TextField("Enter amount", text: $customSavingsAmount)
                .font(.system(size: 16))
                .foregroundColor(.midnightSlate)
                .keyboardType(.decimalPad)
                .padding(14)
                .background(Color.dreamMist)
                .cornerRadius(12)
        }
    }
    
    private func extensionWarningCard(extensionDays: Double, newDueDate: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goal Extension")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    Text("This amount is less than required. Your goal would be extended by approximately \(Int(ceil(extensionDays))) day\(Int(ceil(extensionDays)) == 1 ? "" : "s").")
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("New Due Date")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.softGraphite)
                Text(formatDateForExtension(newDueDate))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.midnightSlate)
            }
            
            Button(action: {
                targetDate = newDueDate
                showTargetDatePicker = true
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 14))
                    Text("Set as Target Date")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.reverBlue)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Calculate required savings per day and per week
    private func calculateRequiredSavings() -> (perDay: Double, perWeek: Double)? {
        guard let targetDate = targetDate,
              let targetAmount = Double(targetAmount),
              targetAmount > 0 else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = self.startDate ?? now
        
        // Calculate days between start and target date (inclusive of both dates)
        // Add 1 to include both start and end dates in the count
        guard let daysBetween = calendar.dateComponents([.day], from: startDate, to: targetDate).day,
              daysBetween >= 1 else { return nil }
        
        // Calculate days including both start and end dates
        let totalDays = Double(daysBetween + 1)
        
        // For editing, account for current amount saved
        let remainingAmount = max(targetAmount - goal.currentAmount, 0)
        
        // Calculate required savings per day
        let perDay = remainingAmount / totalDays
        
        // Calculate required savings per week
        // If goal period is less than a week, show what would be saved per week at this rate
        // But cap it at the remaining goal amount to avoid showing values that exceed the goal
        let weeksInPeriod = totalDays / 7.0
        let perWeek: Double
        if weeksInPeriod >= 1.0 {
            // Goal period is a week or more: show savings per week
            perWeek = remainingAmount / weeksInPeriod
        } else {
            // Goal period is less than a week: show what would be saved per week at this daily rate
            // But don't exceed the remaining goal amount
            perWeek = min(perDay * 7.0, remainingAmount)
        }
        
        return (perDay: perDay, perWeek: perWeek)
    }
    
    // Calculate how many days a custom amount would extend the goal and the new due date
    private func calculateExtensionDays(customAmount: Double, requiredPerDay: Double) -> (days: Double, newDate: Date)? {
        guard customAmount < requiredPerDay, requiredPerDay > 0 else { return nil }
        
        guard let targetAmount = Double(targetAmount),
              targetAmount > 0,
              let targetDate = targetDate else { return nil }
        
        let calendar = Calendar.current
        let startDate = self.startDate ?? Date()
        guard let originalDays = calendar.dateComponents([.day], from: startDate, to: targetDate).day,
              originalDays > 0 else { return nil }
        
        // For editing, account for current amount saved
        let remainingAmount = max(targetAmount - goal.currentAmount, 0)
        
        // With custom amount per day, how many days would it take?
        let daysWithCustomAmount = remainingAmount / customAmount
        
        // Extension = difference
        let extensionDays = max(daysWithCustomAmount - Double(originalDays), 0)
        
        // Calculate new due date
        guard let newDate = calendar.date(byAdding: .day, value: Int(ceil(extensionDays)), to: targetDate) else {
            return nil
        }
        
        return (days: extensionDays, newDate: newDate)
    }
    
    private func formatDateForExtension(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    // MARK: - Notification Settings Section (Edit)
    
    private var editNotificationSettingsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Notifications")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Spacer()
                
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
            }
            
            if notificationsEnabled {
                VStack(spacing: 16) {
                    // Progress notification frequency
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress Updates")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.softGraphite)
                        
                        Picker("Frequency", selection: $progressNotificationFrequency) {
                            Text("Daily").tag(SavingsGoal.ProgressNotificationFrequency.daily)
                            Text("Twice Weekly").tag(SavingsGoal.ProgressNotificationFrequency.twiceWeekly)
                            Text("Weekly").tag(SavingsGoal.ProgressNotificationFrequency.weekly)
                            Text("Never").tag(SavingsGoal.ProgressNotificationFrequency.never)
                        }
                        .pickerStyle(.menu)
                        .padding(12)
                        .background(Color.dreamMist)
                        .cornerRadius(10)
                    }
                    
                    // Notification time (if not "Never")
                    if progressNotificationFrequency != .never {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notification Time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.softGraphite)
                            
                            DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .padding(12)
                                .background(Color.dreamMist)
                                .cornerRadius(10)
                        }
                    }
                    
                    // Milestone notifications
                    Toggle("Milestone Notifications (25%, 50%, 75%)", isOn: $milestoneNotificationsEnabled)
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                    
                    // Achievement notification
                    Toggle("Achievement Notification", isOn: $achievementNotificationEnabled)
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    private var photoSelectionButtons: some View {
        Group {
            Button("Take Photo") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    imagePickerSourceType = .camera
                    showImagePicker = true
                }
            }
            
            Button("Choose from Library") {
                imagePickerSourceType = .photoLibrary
                showImagePicker = true
            }
            
            if goalPhoto != nil {
                Button("Remove Photo", role: .destructive) {
                    goalPhoto = nil
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
    
    // MARK: - Helper Functions
    
    private func isValidDateRange(start: Date, target: Date) -> Bool {
        let calendar = Calendar.current
        if let daysBetween = calendar.dateComponents([.day], from: start, to: target).day {
            return daysBetween >= 1
        }
        return false
    }
    
    private func areDatesValid() -> Bool {
        if showStartDatePicker && showTargetDatePicker {
            guard let start = startDate, let target = targetDate else { return true }
            return isValidDateRange(start: start, target: target)
        }
        return true
    }
    
    private func saveGoal() {
        guard !isSaving else { return }
        guard let amount = Double(targetAmount), amount > 0 else { return }
        
        if !areDatesValid() {
            showDateValidationAlert = true
            return
        }
        
        isSaving = true
        
        var updatedGoal = goal
        updatedGoal.name = goalName
        updatedGoal.targetAmount = amount
        updatedGoal.category = selectedCategory
        updatedGoal.startDate = showStartDatePicker ? startDate : nil
        updatedGoal.targetDate = showTargetDatePicker ? targetDate : nil
        updatedGoal.description = goalDescription.isEmpty ? nil : goalDescription
        
        // Update notification settings
        updatedGoal.notificationsEnabled = notificationsEnabled
        updatedGoal.progressNotificationFrequency = progressNotificationFrequency
        updatedGoal.milestoneNotificationsEnabled = milestoneNotificationsEnabled
        updatedGoal.achievementNotificationEnabled = achievementNotificationEnabled
        updatedGoal.notificationTime = notificationsEnabled ? notificationTime : nil
        
        goalsService.updateGoal(updatedGoal)
        
        // Upload photo if one was selected
        if let photo = goalPhoto {
            uploadGoalPhoto(image: photo, goalId: goal.id)
        }
        
        dismiss()
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                isSaving = false
            }
        }
    }
    
    private func loadGoalPhoto(photoPath: String) {
        // Load from UserDefaults cache
        let cacheKey = "goal_photo_\(goal.id)"
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let image = UIImage(data: data) {
            goalPhoto = image
        }
    }
    
    private func uploadGoalPhoto(image: UIImage, goalId: String) {
        isUploadingPhoto = true
        
        Task {
            do {
                // Upload to S3 via GoalPhotoService
                let photoService = GoalPhotoService.shared
                let photoUrl = try await photoService.uploadGoalPhoto(image: image, goalId: goalId)
                
                // Also cache in UserDefaults for fast local access
                let cacheKey = "goal_photo_\(goalId)"
                let maxDimension: CGFloat = 600
                let resizedImage = max(image.size.width, image.size.height) > maxDimension
                    ? image.resized(toMaxDimension: maxDimension)
                    : image
                
                if let imageData = resizedImage.jpegData(compressionQuality: 0.8) {
                    UserDefaults.standard.set(imageData, forKey: cacheKey)
                }
                
                // Update goal with S3 photo URL
                await MainActor.run {
                    goalsService.updateGoalPhoto(goalId: goalId, photoPath: photoUrl)
                    isUploadingPhoto = false
                    print("✅ [EditGoalView] Goal photo uploaded to S3: \(photoUrl)")
                }
            } catch {
                // Fallback to UserDefaults if S3 upload fails
                print("⚠️ [EditGoalView] S3 upload failed, falling back to UserDefaults: \(error.localizedDescription)")
                
                let cacheKey = "goal_photo_\(goalId)"
                let maxDimension: CGFloat = 600
                let resizedImage = max(image.size.width, image.size.height) > maxDimension
                    ? image.resized(toMaxDimension: maxDimension)
                    : image
                
                guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
                    await MainActor.run {
                        isUploadingPhoto = false
                    }
                    return
                }
                
                UserDefaults.standard.set(imageData, forKey: cacheKey)
                
                // Update goal with local identifier
                let photoPath = "local://\(goalId)"
                await MainActor.run {
                    goalsService.updateGoalPhoto(goalId: goalId, photoPath: photoPath)
                    isUploadingPhoto = false
                    print("✅ [EditGoalView] Goal photo saved to UserDefaults (fallback): \(cacheKey)")
                }
            }
        }
    }
}

// Add Deposit View
struct AddDepositView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var goalsService: GoalsService
    let goal: SavingsGoal
    
    @State private var depositAmount: String = ""
    @State private var isSubmitting = false
    @FocusState private var isAmountFocused: Bool
    
    private var formattedTarget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: goal.targetAmount)) ?? "$0.00"
    }
    
    private var formattedCurrent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: goal.currentAmount)) ?? "$0.00"
    }
    
    private var remainingAmount: Double {
        return max(goal.targetAmount - goal.currentAmount, 0)
    }
    
    private var formattedRemaining: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: remainingAmount)) ?? "$0.00"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Goal Info Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: goal.category.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(.reverBlue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goal.name)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.midnightSlate)
                                    
                                    Text(goal.category.rawValue)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.softGraphite)
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Current Amount:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.softGraphite)
                                    Spacer()
                                    Text(formattedCurrent)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.reverBlue)
                                }
                                
                                HStack {
                                    Text("Target Amount:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.softGraphite)
                                    Spacer()
                                    Text(formattedTarget)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.midnightSlate)
                                }
                                
                                HStack {
                                    Text("Remaining:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.softGraphite)
                                    Spacer()
                                    Text(formattedRemaining)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.reverBlue)
                                }
                            }
                            
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.9, green: 0.9, blue: 0.9))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.reverBlue)
                                        .frame(width: geometry.size.width * CGFloat(goal.progress), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        
                        // Deposit Amount Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Deposit Amount")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            HStack {
                                Text("$")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.reverBlue)
                                
                                TextField("0.00", text: $depositAmount)
                                    .font(.system(size: 24, weight: .semibold))
                                    .keyboardType(.decimalPad)
                                    .focused($isAmountFocused)
                                    .onChange(of: depositAmount) { oldValue, newValue in
                                        // Filter to allow only numbers and decimal point
                                        let filtered = newValue.filter { "0123456789.".contains($0) }
                                        if filtered != newValue {
                                            depositAmount = filtered
                                        }
                                        // Ensure only one decimal point
                                        let components = filtered.components(separatedBy: ".")
                                        if components.count > 2 {
                                            depositAmount = components[0] + "." + components[1]
                                        }
                                    }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            
                            Text("Enter the amount you want to add to this goal")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.softGraphite)
                        }
                        .padding(.horizontal, 20)
                        
                        // Quick Amount Buttons
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Amounts")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.softGraphite)
                            
                            HStack(spacing: 12) {
                                ForEach([10, 25, 50, 100], id: \.self) { amount in
                                    Button(action: {
                                        depositAmount = String(amount)
                                        isAmountFocused = false
                                    }) {
                                        Text("$\(amount)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.reverBlue)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.dreamMist)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Submit Button
                        Button(action: {
                            submitDeposit()
                        }) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                }
                                Text(isSubmitting ? "Adding Deposit..." : "Add Deposit")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isValidAmount ? Color.reverBlue : Color.gray.opacity(0.3))
                            )
                        }
                        .disabled(!isValidAmount || isSubmitting)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Add Deposit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Auto-focus amount field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAmountFocused = true
                }
            }
        }
    }
    
    private var isValidAmount: Bool {
        guard let amount = Double(depositAmount), amount > 0 else { return false }
        return true
    }
    
    private func submitDeposit() {
        guard let amount = Double(depositAmount), amount > 0, !isSubmitting else { return }
        
        isSubmitting = true
        
        // Record deposit with timestamp in PlaidService
        // This will automatically add the deposit to the goal via updateGoalProgress()
        // DO NOT call addToGoal again here - it would cause double-counting
        PlaidService.shared.recordManualDeposit(amount: amount, goalId: goal.id)
        
        // Dismiss after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

// MARK: - GoalsView Header Helpers Extension

extension GoalsView {
    private var userEmail: String {
        authService.currentUser?.email ?? ""
    }
    
    private func isBetaTester() -> Bool {
        if userEmail.lowercased() == "supergeek@me.com" {
            return false
        }
        #if DEBUG
        return true
        #else
        if let receiptURL = Bundle.main.appStoreReceiptURL,
           receiptURL.lastPathComponent == "sandboxReceipt" {
            return true
        }
        return UserDefaults.standard.bool(forKey: "is_beta_tester")
        #endif
    }
    
    private func isRoseGoldFounder() -> Bool {
        return userEmail.lowercased() == "supergeek@me.com"
    }
    
    private func isBlackCardEligible() -> Bool {
        if isBetaTester() || isRoseGoldFounder() {
            return false
        }
        let isFirst100Annual = UserDefaults.standard.bool(forKey: "is_first_100_annual_user")
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        return isFirst100Annual && isAnnual
    }
    
    // MARK: - Header Background Color
    
    private var headerBackgroundGradient: LinearGradient {
        guard subscriptionService.isPremium else {
            // Free users get gray
            return LinearGradient(
                colors: [Color(red: 0.92, green: 0.97, blue: 0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        let isBeta = isBetaTester()
        let isRoseGold = isRoseGoldFounder()
        let isBlack = (isBeta || isRoseGold) ? false : isBlackCardEligible()
        
        if isRoseGold {
            return LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.65, blue: 0.55),
                    Color(red: 0.82, green: 0.58, blue: 0.48),
                    Color(red: 0.78, green: 0.52, blue: 0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isBeta {
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.4),
                    Color(red: 0.98, green: 0.90, blue: 0.35),
                    Color(red: 0.95, green: 0.85, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isBlack {
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.05),
                    Color(red: 0.08, green: 0.08, blue: 0.08),
                    Color(red: 0.06, green: 0.06, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isAnnual {
            return LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.18),
                    Color(red: 0.18, green: 0.18, blue: 0.24),
                    Color(red: 0.15, green: 0.15, blue: 0.21)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Gold (monthly)
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.88, blue: 0.55),
                    Color(red: 0.92, green: 0.78, blue: 0.45),
                    Color(red: 0.88, green: 0.70, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

#Preview {
    GoalsView()
        .environmentObject(GoalsService.shared)
}
