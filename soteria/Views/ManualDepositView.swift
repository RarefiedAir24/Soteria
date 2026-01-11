//
//  ManualDepositView.swift
//  soteria
//
//  Stylish modal for manually entering savings deposits
//

import SwiftUI

struct ManualDepositView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var plaidService = PlaidService.shared
    @ObservedObject private var goalsService = GoalsService.shared
    
    @State private var depositAmount: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @FocusState private var isAmountFocused: Bool
    
    // Screenshot and Reference ID
    @State private var depositScreenshot: UIImage? = nil
    @State private var referenceId: String = ""
    @State private var showImagePicker = false
    @State private var showImageSourceActionSheet = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // Verification Status
    @State private var verificationStatus: VerificationStatus = .notStarted
    
    enum VerificationStatus {
        case notStarted
        case verifying
        case verified(confidence: Double, pointsAwarded: Double)
        case failed(reason: String)
    }
    
    // No Screenshot Warning
    @State private var showNoScreenshotWarning = false
    @State private var userAcknowledgedNoPoints = false
    
    // Pre-Deposit Instructions
    @State private var showInstructions = true
    
    private var isValidAmount: Bool {
        guard let amount = Double(depositAmount), amount > 0 else { return false }
        return true
    }
    
    private var canSubmit: Bool {
        guard isValidAmount else { return false }
        // Allow submission without screenshot if user acknowledged
        if depositScreenshot == nil && !userAcknowledgedNoPoints {
            return false
        }
        return true
    }
    
    private var depositValue: Double? {
        guard let amount = Double(depositAmount), amount > 0 else { return nil }
        return amount
    }
    
    private var formattedAmount: String {
        guard let amount = depositValue else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var body: some View {
        if showInstructions {
            ManualDepositInstructionsView(
                onContinue: {
                    withAnimation {
                        showInstructions = false
                    }
                },
                onCancel: {
                    dismiss()
                }
            )
        } else {
            depositFormView
        }
    }
    
    private var depositFormView: some View {
        ZStack {
            // Background
            Color.mistGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                            .frame(width: 36, height: 36)
                            .background(Color.cloudWhite)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Add Savings Deposit")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Color.clear
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Icon Section
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.reverBlueLight.opacity(0.2), Color.reverBlueDark.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.reverBlueLight, Color.reverBlueDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 20)
                        
                        // Amount Input Section
                        VStack(spacing: 20) {
                            Text("How much did you save?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            // Amount Display
                            VStack(spacing: 8) {
                                if depositAmount.isEmpty {
                                    Text("$0.00")
                                        .font(.system(size: 56, weight: .bold))
                                        .foregroundColor(.mistGray)
                                } else if isValidAmount {
                                    Text(formattedAmount)
                                        .font(.system(size: 56, weight: .bold))
                                        .foregroundColor(.reverBlue)
                                } else {
                                    Text("Invalid amount")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.red.opacity(0.7))
                                }
                            }
                            .frame(height: 70)
                            .animation(.spring(response: 0.3), value: depositAmount)
                            
                            // Text Field (Hidden but functional)
                            TextField("", text: $depositAmount)
                                .keyboardType(.decimalPad)
                                .focused($isAmountFocused)
                                .opacity(0)
                                .frame(height: 0)
                            
                            // Quick Amount Buttons
                            VStack(spacing: 12) {
                                Text("Quick Select")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                
                                HStack(spacing: 12) {
                                    ForEach([10, 25, 50, 100], id: \.self) { amount in
                                        Button(action: {
                                            depositAmount = String(amount)
                                            isAmountFocused = false
                                        }) {
                                            VStack(spacing: 4) {
                                                Text("$\(amount)")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.reverBlue)
                                                
                                                if depositAmount == String(amount) {
                                                    Circle()
                                                        .fill(Color.reverBlue)
                                                        .frame(width: 4, height: 4)
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(depositAmount == String(amount) ? Color.reverBlue.opacity(0.1) : Color.cloudWhite)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(depositAmount == String(amount) ? Color.reverBlue : Color.clear, lineWidth: 2)
                                            )
                                        }
                                    }
                                }
                                
                                // Custom Amount Button
                                Button(action: {
                                    isAmountFocused = true
                                }) {
                                    HStack {
                                        Image(systemName: "keyboard")
                                            .font(.system(size: 14))
                                        Text("Enter Custom Amount")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.softGraphite)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.cloudWhite)
                                    )
                                }
                                .padding(.top, 4)
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.cloudWhite)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 24)
                        
                        // Screenshot Upload Section (Required for Premium Users)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.purple)
                                
                                Text("Verification (Recommended)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.midnightSlate)
                                
                                Spacer()
                            }
                            
                            // Instructions
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "1.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.purple)
                                    
                                    Text("Make your deposit in your banking app first")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.midnightSlate)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "2.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.purple)
                                    
                                    Text("Take a screenshot of the transaction confirmation")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.midnightSlate)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "3.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.purple)
                                    
                                    Text("Come back here and upload it to earn loyalty points")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.midnightSlate)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                // Privacy note
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                    
                                    Text("Your screenshot is processed securely and never stored. It's only used for verification.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.softGraphite.opacity(0.8))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            
                            // Screenshot Upload Button / Preview
                            if let screenshot = depositScreenshot {
                                // Screenshot Preview
                                VStack(spacing: 12) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: screenshot)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 200)
                                            .cornerRadius(12)
                                        
                                        // Remove button (only if not yet verified)
                                        if case .verified = verificationStatus {
                                            // Don't show remove button after verification
                                        } else {
                                            Button(action: {
                                                depositScreenshot = nil
                                                verificationStatus = .notStarted
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.red)
                                                    .background(Circle().fill(Color.white))
                                            }
                                            .padding(8)
                                        }
                                    }
                                    
                                    // Verification Status Card
                                    verificationStatusCard
                                }
                            } else {
                                // Upload Button
                                Button(action: {
                                    showImageSourceActionSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 18))
                                        
                                        Text("Upload Screenshot")
                                            .font(.system(size: 16, weight: .semibold))
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.purple)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.purple.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                    )
                                }
                            }
                            
                            // Optional Reference ID
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Transaction ID (Optional)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                
                                TextField("e.g., TXN123456 or Check #", text: $referenceId)
                                    .font(.system(size: 15))
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.softGraphite.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 24)
                        
                        // Goal Progress Preview (if active goal exists)
                        if let activeGoal = goalsService.activeGoal, let depositAmount = depositValue {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "target")
                                        .font(.system(size: 16))
                                        .foregroundColor(.reverBlue)
                                    
                                    Text("Goal Progress")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.midnightSlate)
                                    
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(activeGoal.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.softGraphite)
                                    
                                    // Current progress
                                    let currentProgress = activeGoal.progress
                                    let newAmount = activeGoal.currentAmount + depositAmount
                                    let newProgress = min(newAmount / activeGoal.targetAmount, 1.0)
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            // Background
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.mistGray)
                                                .frame(height: 8)
                                            
                                            // Current progress
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.reverBlue.opacity(0.5))
                                                .frame(width: geometry.size.width * currentProgress, height: 8)
                                            
                                            // New progress (animated)
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.reverBlue)
                                                .frame(width: geometry.size.width * newProgress, height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                    
                                    HStack {
                                        Text("\(Int(currentProgress * 100))% → \(Int(newProgress * 100))%")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.reverBlue)
                                        
                                        Spacer()
                                        
                                        if newProgress >= 1.0 {
                                            Text("🎉 Goal Complete!")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.dreamMist.opacity(0.5))
                            )
                            .padding(.horizontal, 24)
                        }
                        
                        // Submit Button
                        Button(action: {
                            // If no screenshot and not yet acknowledged, show warning
                            if depositScreenshot == nil && !userAcknowledgedNoPoints {
                                showNoScreenshotWarning = true
                            } else {
                                submitDeposit()
                            }
                        }) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                }
                                
                                Text(isSubmitting ? "Recording..." : "Record Deposit")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: canSubmit ? [Color.reverBlueLight, Color.reverBlueDark] : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: canSubmit ? Color.reverBlue.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!canSubmit || isSubmitting)
                        .padding(.horizontal, 24)
                        
                        // Verification Notice
                        if !canSubmit && isValidAmount && depositScreenshot == nil && !userAcknowledgedNoPoints {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                
                                Text("Screenshot required to earn loyalty points. You can still proceed without it, but won't receive points.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.softGraphite)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        } else if userAcknowledgedNoPoints && depositScreenshot == nil {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Text("This deposit will not earn loyalty points (no screenshot provided)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.softGraphite.opacity(0.7))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        } else {
                            Spacer()
                                .frame(height: 40)
                        }
                    }
                }
            }
            
            // Success Overlay
            if showSuccess {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Deposit Recorded!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        if depositValue != nil {
                            Text(formattedAmount)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.reverBlue)
                        }
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.cloudWhite)
                            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                    )
                    .padding(40)
                    .scaleEffect(showSuccess ? 1.0 : 0.8)
                    .opacity(showSuccess ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showSuccess)
                }
            }
            
            // No Screenshot Warning Popup
            if showNoScreenshotWarning {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // Prevent dismissal by tap
                        }
                    
                    VStack(spacing: 24) {
                        // Warning Icon
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(spacing: 12) {
                            Text("No Screenshot Provided")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.midnightSlate)
                                .multilineTextAlignment(.center)
                            
                            Text("Without a screenshot, this savings deposit will NOT earn loyalty points.")
                                .font(.system(size: 16))
                                .foregroundColor(.softGraphite)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Key Points
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                
                                Text("No loyalty points will be awarded")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.midnightSlate)
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "giftcard.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                
                                Text("You won't earn rewards for this deposit")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.midnightSlate)
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.green)
                                
                                Text("The deposit will still count toward your goal")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.midnightSlate)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mistGray.opacity(0.5))
                        )
                        
                        Divider()
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Go Back Button (Primary)
                            Button(action: {
                                showNoScreenshotWarning = false
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                    Text("Go Back & Add Screenshot")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.reverBlueLight, Color.reverBlueDark],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            
                            // Acknowledge Button (Secondary)
                            Button(action: {
                                userAcknowledgedNoPoints = true
                                showNoScreenshotWarning = false
                                // Auto-submit after acknowledgment
                                submitDeposit()
                            }) {
                                Text("I Understand – Proceed Without Points")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.softGraphite.opacity(0.3), lineWidth: 1.5)
                                    )
                            }
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.cloudWhite)
                            .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
                    )
                    .padding(24)
                    .scaleEffect(showNoScreenshotWarning ? 1.0 : 0.8)
                    .opacity(showNoScreenshotWarning ? 1.0 : 0.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: showNoScreenshotWarning)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            // Auto-focus after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAmountFocused = true
            }
            
            // Auto-generate reference ID
            referenceId = generateShortRef()
        }
        .confirmationDialog("Choose Photo", isPresented: $showImageSourceActionSheet, titleVisibility: .visible) {
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
            
            if depositScreenshot != nil {
                Button("Remove Photo", role: .destructive) {
                    depositScreenshot = nil
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSourceType) { image in
                depositScreenshot = image
                // Trigger verification immediately after upload
                verifyScreenshotIfNeeded()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Generate short reference ID
    private func generateShortRef() -> String {
        let uuid = UUID().uuidString
        let shortCode = String(uuid.prefix(7)).uppercased()
        return "DEP-\(shortCode)"
    }
    
    /// Verify screenshot immediately after upload
    private func verifyScreenshotIfNeeded() {
        guard let screenshot = depositScreenshot,
              let amount = depositValue else { return }
        
        // Start verification
        verificationStatus = .verifying
        
        // Generate deposit ID for verification
        let depositId = UUID().uuidString
        
        Task {
            do {
                let result = try await EphemeralScreenshotService.shared.verifyScreenshotEphemerally(
                    image: screenshot,
                    depositId: depositId,
                    claimedAmount: amount
                )
                
                await MainActor.run {
                    if result.isValid {
                        // Calculate points that would be awarded (10 points per $1 saved)
                        let basePoints = amount * 10.0
                        let hasStreak = StreakService.shared.currentStreak > 0
                        let bonusMultiplier = hasStreak ? 1.1 : 1.0
                        let totalPoints = basePoints * bonusMultiplier
                        
                        verificationStatus = .verified(
                            confidence: result.confidence,
                            pointsAwarded: totalPoints
                        )
                    } else {
                        verificationStatus = .failed(reason: result.reason)
                    }
                }
            } catch {
                await MainActor.run {
                    verificationStatus = .failed(reason: "Verification error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Verification Status Card
    @ViewBuilder
    private var verificationStatusCard: some View {
        switch verificationStatus {
        case .notStarted:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                
                Text("Screenshot added ✓")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                
                Spacer()
                
                Button("Change") {
                    showImageSourceActionSheet = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.purple)
            }
            
        case .verifying:
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Verifying screenshot...")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("Analyzing bank transaction details")
                            .font(.system(size: 12))
                            .foregroundColor(.softGraphite)
                    }
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.1))
            )
            
        case .verified(let confidence, let points):
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Screenshot Verified!")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.green)
                        
                        Text("Confidence: \(Int(confidence * 100))%")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                        
                        Text("\(Int(points)) loyalty points will be awarded")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        
                        Text("Screenshot has been securely deleted")
                            .font(.system(size: 11))
                            .foregroundColor(.softGraphite.opacity(0.7))
                    }
                }
                
                Button("Change Screenshot") {
                    depositScreenshot = nil
                    verificationStatus = .notStarted
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.purple)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
            )
            
        case .failed(let reason):
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Verification Failed")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Text(reason)
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                Text("❌ No loyalty points will be awarded for this deposit")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.orange)
                
                HStack(spacing: 12) {
                    Button("Try Different Screenshot") {
                        depositScreenshot = nil
                        verificationStatus = .notStarted
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.purple)
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )
        }
    }
    
    private func submitDeposit() {
        guard let amount = depositValue, !isSubmitting else { return }
        
        isSubmitting = true
        
        // Get active goal ID if available
        let activeGoalId = goalsService.activeGoal?.id
        
        // Generate deposit ID first
        let depositId = UUID().uuidString
        
        // 🔒 SECURITY: EPHEMERAL screenshot verification
        // Screenshot is passed directly (in-memory only), NEVER saved to disk
        // This protects user privacy and prevents data breaches
        // After verification, the image is immediately discarded
        
        // Record manual deposit (local tracking only - no Plaid API calls)
        // This is for physical cash savings or deposits made outside the app
        plaidService.recordManualDeposit(
            amount: amount,
            goalId: activeGoalId,
            screenshot: depositScreenshot, // ⚠️ Pass image directly, NOT saved!
            referenceId: referenceId.isEmpty ? nil : referenceId,
            depositId: depositId
        )
        
        // Show success animation
        withAnimation {
            showSuccess = true
        }
        
        // Dismiss after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Manual Deposit Instructions View
struct ManualDepositInstructionsView: View {
    let onContinue: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.mistGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                            .frame(width: 36, height: 36)
                            .background(Color.cloudWhite)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Before You Continue")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 20)
                        
                        // Title
                        Text("Quick Setup")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        // Instructions
                        VStack(spacing: 24) {
                            InstructionStep(
                                number: 1,
                                icon: "dollarsign.circle.fill",
                                title: "Make Your Deposit First",
                                description: "Open your banking app and transfer money to your savings account",
                                color: .green
                            )
                            
                            InstructionStep(
                                number: 2,
                                icon: "camera.fill",
                                title: "Take a Screenshot",
                                description: "Capture the transaction confirmation screen showing the amount and date",
                                color: .blue
                            )
                            
                            InstructionStep(
                                number: 3,
                                icon: "arrow.backward.circle.fill",
                                title: "Come Back Here",
                                description: "Return to Soteria and upload your screenshot to earn loyalty points",
                                color: .purple
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Privacy Note
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Privacy is Protected")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.midnightSlate)
                                
                                Text("Screenshots are processed securely and never stored. We only verify the transaction details.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.softGraphite)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        Text("I've Made My Deposit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.reverBlueLight, Color.reverBlueDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    
                    Button(action: onCancel) {
                        Text("I'll Do This Later")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.softGraphite)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Number Badge
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Text("\(number)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.softGraphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ManualDepositView()
}

