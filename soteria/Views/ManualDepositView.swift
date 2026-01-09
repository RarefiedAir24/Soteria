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
    
    private var isValidAmount: Bool {
        guard let amount = Double(depositAmount), amount > 0 else { return false }
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
                            submitDeposit()
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
                                    colors: isValidAmount ? [Color.reverBlueLight, Color.reverBlueDark] : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: isValidAmount ? Color.reverBlue.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!isValidAmount || isSubmitting)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
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
        }
        .onAppear {
            // Auto-focus after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAmountFocused = true
            }
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
            }
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

#Preview {
    ManualDepositView()
}

