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
    @State private var showCreateGoal = false
    
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
                    if !goalsService.activeGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Goals")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                                .padding(.horizontal, 20)
                            
                            ForEach(goalsService.activeGoals) { goal in
                                GoalCard(goal: goal)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            goalsService.deleteGoal(goal)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Historical Goals Section
                    if !goalsService.archivedGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Historical Goals")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                                .padding(.horizontal, 20)
                            
                            ForEach(goalsService.archivedGoals.sorted(by: { ($0.completedDate ?? $0.createdDate) > ($1.completedDate ?? $1.createdDate) })) { goal in
                                GoalCard(goal: goal)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            goalsService.deleteArchivedGoal(goal)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Empty State
                    if goalsService.goals.isEmpty && goalsService.archivedGoals.isEmpty {
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
                                showCreateGoal = true
                            }) {
                                Text("Create Goal")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.deepReverBlue)
                                    )
                            }
                        }
                        .padding(.vertical, 60)
                    } else {
                        // Goals List
                        ForEach(goalsService.goals) { goal in
                            GoalCard(goal: goal)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Create Goal Button
                    if !goalsService.activeGoals.isEmpty || !goalsService.archivedGoals.isEmpty {
                        Button(action: {
                            showCreateGoal = true
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
                Text("Savings Goals")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundColor(Color.midnightSlate)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Color(red: 0.92, green: 0.97, blue: 0.94)
                    .ignoresSafeArea(edges: .top)
            )
            .zIndex(100)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowCreateGoal"))) { _ in
            print("✅ [GoalsView] Received ShowCreateGoal notification - showing create goal view")
            showCreateGoal = true
        }
        .sheet(isPresented: $showCreateGoal) {
            CreateGoalView()
                .environmentObject(goalsService)
                .environmentObject(authService)
        }
        .task {
            // FIXED: Load goals immediately when GoalsView appears
            // This fixes the delay where goals weren't loading until 30 seconds after app launch
            // GoalsService.init() defers loading to prevent startup delays, but we need to load on-demand
            print("🟢 [GoalsView] .task started - ensuring goals are loaded")
            goalsService.ensureDataLoaded()
            print("🟢 [GoalsView] Goals loaded (if not already loaded)")
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
            return .reverBlue
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
            // Goal Photo (if available) - lazy loaded
            if let photo = goalPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if goal.photoPath != nil && !isLoadingPhoto {
                // Placeholder while loading
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dreamMist)
                    .frame(height: 180)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                    )
                    .onAppear {
                        loadGoalPhoto()
                    }
            }
            
            HStack {
                Image(systemName: goal.category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color.reverBlue)
                
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
                        .foregroundColor(Color.reverBlue)
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
                        .foregroundColor(.reverBlue)
                    Text(countdown)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.reverBlue)
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
                        .foregroundColor(Color.reverBlue)
                    
                    Text("of \(formattedTarget)")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(Color.softGraphite)
                    
                    Spacer()
                    
                    Text("\(progressPercentage)%")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(Color.reverBlue)
                }
                
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
                                .fill(Color.reverBlue)
                        )
                    }
                    
                    if goalsService.activeGoal?.id != goal.id {
                        Button(action: {
                            goalsService.setActiveGoal(goal)
                        }) {
                            Text("Set as Active")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.reverBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                                )
                        }
                    }
                    
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
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // Lazy load goal photo from Firebase Storage (only when card appears)
    private func loadGoalPhoto() {
        guard goal.photoPath != nil,
              !isLoadingPhoto else { return }
        
        isLoadingPhoto = true
        
        // First try UserDefaults cache
        let cacheKey = "goal_photo_\(goal.id)"
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let image = UIImage(data: data) {
            goalPhoto = image
            isLoadingPhoto = false
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
        //                     isLoadingPhoto = false
        //                 }
        //             }
        //         } catch {
        //             print("ℹ️ [GoalCard] Goal photo not found in Firebase Storage: \(photoPath)")
        //             await MainActor.run {
        //                 isLoadingPhoto = false
        //             }
        //         }
        //     }
        // } else {
        //     isLoadingPhoto = false
        // }
        isLoadingPhoto = false
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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        goalPhotoSection
                        goalDetailsSection
                        dateRangeSection
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
                        createGoal()
                    }
                    .disabled(isCreateButtonDisabled)
                    .foregroundColor(.deepReverBlue)
                    .fontWeight(.semibold)
                }
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
                    set: { startDate = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)
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
                    get: { targetDate ?? Date() },
                    set: { targetDate = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)
            }
        }
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
    
    private func createGoal() {
        // Prevent duplicate creation
        guard !isCreatingGoal else { return }
        guard let amount = Double(targetAmount), amount > 0 else { return }
        
        // Set flag to prevent duplicate calls
        isCreatingGoal = true
        
        // Prepare optional values to simplify expression
        let goalStartDate = showStartDatePicker ? startDate : nil
        let goalTargetDate = showTargetDatePicker ? targetDate : nil
        let goalDescriptionText = goalDescription.isEmpty ? nil : goalDescription
        
        // Create goal and get the created goal with its ID
        let createdGoal = goalsService.createGoal(
            name: goalName,
            targetAmount: amount,
            startDate: goalStartDate,
            targetDate: goalTargetDate,
            category: selectedCategory,
            photoPath: nil, // Will be set after upload
            description: goalDescriptionText
        )
        
        // Upload photo if one was selected (async, doesn't block goal creation)
        if let photo = goalPhoto {
            uploadGoalPhoto(image: photo, goalId: createdGoal.id)
        }
        
        // Dismiss after a small delay to ensure goal is created
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    private func uploadGoalPhoto(image: UIImage, goalId: String) {
        isUploadingPhoto = true
        
        Task {
            // Image is already resized when selected, but ensure it's within our standard
            // Standard size for goal photos: 600px max dimension (maintains aspect ratio)
            let maxDimension: CGFloat = 600
            let resizedImage = max(image.size.width, image.size.height) > maxDimension
                ? image.resized(toMaxDimension: maxDimension)
                : image
            
            guard resizedImage.jpegData(compressionQuality: 0.8) != nil else {
                await MainActor.run {
                    isUploadingPhoto = false
                }
                return
            }
            
            // TEMPORARILY DISABLED: Firebase Storage - testing if it's causing crash
            // Upload to Firebase Storage
            // if let userId = authService.currentUser?.uid {
            //     let photoPath = "goals/\(userId)/\(goalId).jpg"
            //     let storageRef = Storage.storage().reference().child(photoPath)
            //     
            //     do {
            //         let metadata = StorageMetadata()
            //         metadata.contentType = "image/jpeg"
            //         metadata.cacheControl = "public,max-age=3600"
            //         
            //         _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            //         
            //         // Update goal with photo path
            //         await MainActor.run {
            //             goalsService.updateGoalPhoto(goalId: goalId, photoPath: photoPath)
            //             isUploadingPhoto = false
            //             print("✅ [CreateGoalView] Goal photo uploaded to Firebase Storage: \(photoPath)")
            //         }
            //     } catch {
            //         print("⚠️ [CreateGoalView] Failed to upload goal photo: \(error.localizedDescription)")
            //         await MainActor.run {
            //             isUploadingPhoto = false
            //         }
            //     }
            // } else {
            //     await MainActor.run {
            //         isUploadingPhoto = false
            //     }
            // }
            await MainActor.run {
                isUploadingPhoto = false
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
        
        // Add deposit to goal
        goalsService.addToGoal(goalId: goal.id, amount: amount)
        
        // Dismiss after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

#Preview {
    GoalsView()
        .environmentObject(GoalsService.shared)
}
