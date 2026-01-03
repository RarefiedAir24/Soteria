//
//  EditDepositView.swift
//  soteria
//
//  Edit deposit screenshot and reference ID
//

import SwiftUI

struct EditDepositView: View {
    let deposit: SavingsDeposit
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var plaidService = PlaidService.shared
    
    @State private var depositScreenshot: UIImage? = nil
    @State private var referenceId: String
    @State private var isSaving = false
    @State private var showImagePicker = false
    @State private var showImageSourceActionSheet = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    private let screenshotService = DepositScreenshotService.shared
    private let apiService = DepositScreenshotAPIService.shared
    
    init(deposit: SavingsDeposit) {
        self.deposit = deposit
        _referenceId = State(initialValue: deposit.referenceId ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Deposit Info
                        VStack(spacing: 12) {
                            Text("Deposit Details")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.midnightSlate)
                            
                            Text(formatCurrency(deposit.amount))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.reverBlue)
                            
                            Text(formatDate(deposit.timestamp))
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cloudWhite)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Reference ID Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reference ID")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            TextField("e.g., Transaction #12345", text: $referenceId)
                                .font(.system(size: 14))
                                .foregroundColor(.midnightSlate)
                                .padding(14)
                                .background(Color.dreamMist)
                                .cornerRadius(10)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            Text("Optional: Enter a reference ID from your bank records")
                                .font(.system(size: 12))
                                .foregroundColor(.softGraphite)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cloudWhite)
                        )
                        .padding(.horizontal, 20)
                        
                        // Screenshot Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Receipt/Screenshot")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            if let screenshot = depositScreenshot {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: screenshot)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    Button(action: {
                                        depositScreenshot = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                    .padding(8)
                                }
                            } else {
                                Button(action: {
                                    showImageSourceActionSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 18))
                                        Text("Add Screenshot or Photo")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.reverBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.reverBlue.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.reverBlue.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            
                            Text("Optional: Add a screenshot or photo of your receipt")
                                .font(.system(size: 12))
                                .foregroundColor(.softGraphite)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cloudWhite)
                        )
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        Button(action: {
                            saveChanges()
                        }) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                }
                                
                                Text(isSaving ? "Saving..." : "Save Changes")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color.reverBlueLight, Color.reverBlueDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Edit Deposit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.reverBlue)
                }
            }
            .onAppear {
                loadScreenshot()
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
    }
    
    private func loadScreenshot() {
        depositScreenshot = screenshotService.loadScreenshot(for: deposit.id) ?? 
                            screenshotService.loadScreenshotFromUserDefaults(for: deposit.id)
    }
    
    private func saveChanges() {
        isSaving = true
        
        // Update screenshot if changed
        if let screenshot = depositScreenshot {
            // Save new screenshot
            if screenshotService.saveScreenshot(screenshot, for: deposit.id) != nil {
                screenshotService.saveScreenshotToUserDefaults(screenshot, for: deposit.id)
            }
        } else {
            // Remove screenshot if deleted
            screenshotService.deleteScreenshot(for: deposit.id)
            UserDefaults.standard.removeObject(forKey: "deposit_screenshot_\(deposit.id)")
        }
        
        // Update deposit in history with new reference ID
        // Note: Since SavingsDeposit is a struct with let properties, we can't modify it directly
        // We'll need to replace it in the array. However, saveState() is private.
        // For now, we'll update the reference ID by replacing the deposit in the array
        // The screenshot path is already updated via the screenshot service
        if let index = plaidService.depositHistory.firstIndex(where: { $0.id == deposit.id }) {
            // Create updated deposit
            let updatedDeposit = SavingsDeposit(
                amount: deposit.amount,
                type: deposit.type,
                goalId: deposit.goalId,
                source: deposit.source,
                screenshotPath: depositScreenshot != nil ? deposit.id : nil,
                referenceId: referenceId.isEmpty ? nil : referenceId,
                id: deposit.id
            )
            
            // Replace in array
            plaidService.depositHistory[index] = updatedDeposit
            
            // Save to UserDefaults manually (since saveState() is private)
            if let encoded = try? JSONEncoder().encode(plaidService.depositHistory) {
                UserDefaults.standard.set(encoded, forKey: "deposit_history")
            }
        }
        
        isSaving = false
        dismiss()
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

