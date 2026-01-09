//
//  AdminPartnerManagementView.swift
//  soteria
//
//  Admin-only view for managing partner information including logos
//

import SwiftUI
import PhotosUI

// Helper function for safe screen bounds access
private func getScreenWidth() -> CGFloat {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        return window.bounds.width
    }
    return UIScreen.main.bounds.width
}

struct AdminPartnerManagementView: View {
    @ObservedObject private var partnerService = PartnerLoyaltyService.shared
    @EnvironmentObject var authService: AuthService
    @State private var partners: [Partner] = []
    @State private var isLoading = false
    @State private var selectedPartner: Partner? = nil
    @State private var showLogoPicker = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var logoImage: UIImage? = nil
    @State private var isUploadingLogo = false
    @State private var errorMessage: String? = nil
    @State private var isDeleting = false
    
    private var userEmail: String {
        let email = authService.currentUser?.email ?? ""
        print("🔵 [AdminPartnerManagementView] Current email: '\(email)'")
        return email
    }
    
    private var isAdmin: Bool {
        // Only supergeek@me.com can access admin features
        let email = userEmail.lowercased()
        let isAdminUser = email == "supergeek@me.com"
        print("🔵 [AdminPartnerManagementView] isAdmin check: email='\(email)', isAdmin=\(isAdminUser)")
        return isAdminUser
    }
    
    var body: some View {
        Group {
            if !isAdmin {
                // Non-admin users see access denied
                VStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.softGraphite.opacity(0.5))
                    
                    Text("Access Denied")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    Text("This feature is only available to administrators.")
                        .font(.system(size: 16))
                        .foregroundColor(.softGraphite)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .onAppear {
                    print("🔵 [AdminPartnerManagementView] Access denied view appeared")
                }
            } else {
                NavigationView {
                ZStack {
                    Color.cloudWhite
                        .ignoresSafeArea()
                    
                    if isLoading {
                        ProgressView("Loading partners...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .softGraphite))
                    } else if partners.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.softGraphite.opacity(0.5))
                            
                            Text("No Partners")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            Text("Partners will appear here for management.")
                                .font(.system(size: 15))
                                .foregroundColor(.softGraphite)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Show inactive/expired partners first (for deletion)
                                let inactivePartners = partners.filter { partner in
                                    guard let validUntil = partner.validUntil else {
                                        return !partner.isActive
                                    }
                                    return !partner.isActive || validUntil < Date()
                                }
                                
                                let activePartners = partners.filter { partner in
                                    guard let validUntil = partner.validUntil else {
                                        return partner.isActive
                                    }
                                    return partner.isActive && validUntil >= Date()
                                }
                                
                                if !inactivePartners.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Inactive/Expired Partners")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.softGraphite)
                                            .padding(.horizontal, 20)
                                        
                                        ForEach(inactivePartners) { partner in
                                            AdminPartnerCard(
                                                partner: partner,
                                                onEditLogo: {
                                                    selectedPartner = partner
                                                    showLogoPicker = true
                                                },
                                                onDelete: {
                                                    Task {
                                                        await deletePartner(partnerId: partner.partnerId)
                                                    }
                                                }
                                            )
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                    .padding(.top, 20)
                                }
                                
                                if !activePartners.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Active Partners")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.softGraphite)
                                            .padding(.horizontal, 20)
                                        
                                        ForEach(activePartners) { partner in
                                            AdminPartnerCard(
                                                partner: partner,
                                                onEditLogo: {
                                                    selectedPartner = partner
                                                    showLogoPicker = true
                                                },
                                                onDelete: nil // Active partners can't be deleted via swipe
                                            )
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                    .padding(.top, inactivePartners.isEmpty ? 20 : 30)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
                .navigationTitle("Partner Management")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            Task {
                                await loadPartners()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.softGraphite)
                        }
                    }
                }
                .task {
                    print("🔵 [AdminPartnerManagementView] Loading partners...")
                    await loadPartners()
                }
                .onAppear {
                    print("🔵 [AdminPartnerManagementView] NavigationView appeared, isAdmin: \(isAdmin), email: \(userEmail)")
                }
                .photosPicker(isPresented: $showLogoPicker, selection: $selectedPhoto, matching: .images)
                .onChange(of: selectedPhoto) { oldValue, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                logoImage = image
                                if let partner = selectedPartner {
                                    uploadLogo(image: image, for: partner)
                                }
                            }
                        }
                    }
                }
                .alert("Error", isPresented: .constant(errorMessage != nil)) {
                    Button("OK") {
                        errorMessage = nil
                    }
                } message: {
                    if let error = errorMessage {
                        Text(error)
                    }
                }
                }
            }
        }
    }
    
    private func loadPartners() async {
        await MainActor.run {
            isLoading = true
        }
        
        await partnerService.loadPartners()
        
        await MainActor.run {
            partners = partnerService.partners
            isLoading = false
        }
    }
    
    private func uploadLogo(image: UIImage, for partner: Partner) {
        // TODO: Implement logo upload to S3 and update partner record in DynamoDB
        // This would require:
        // 1. Upload image to S3 (partner-logos bucket)
        // 2. Get public URL
        // 3. Update partner record in DynamoDB with new logo_url
        // 4. Call Lambda function to update partner
        
        isUploadingLogo = true
        errorMessage = nil
        
        // Placeholder - implement actual upload logic
        Task {
            // Simulate upload delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isUploadingLogo = false
                // For now, just show a message
                errorMessage = "Logo upload functionality will be implemented. This requires S3 upload and DynamoDB update."
            }
        }
    }
    
    private func deletePartner(partnerId: String) async {
        await MainActor.run {
            isDeleting = true
            errorMessage = nil
        }
        
        do {
            try await partnerService.deletePartner(partnerId: partnerId)
            await MainActor.run {
                partners.removeAll { $0.partnerId == partnerId }
                isDeleting = false
            }
        } catch {
            await MainActor.run {
                isDeleting = false
                errorMessage = error.localizedDescription
            }
            print("❌ [AdminPartnerManagementView] Error deleting partner: \(error.localizedDescription)")
        }
    }
}

struct AdminPartnerCard: View {
    let partner: Partner
    let onEditLogo: () -> Void
    let onDelete: (() -> Void)?
    
    @State private var offset: CGFloat = 0
    @State private var checkoutCode: String = ""
    @State private var isEditingCode: Bool = false
    @State private var isSavingCode: Bool = false
    @State private var showCodeSaved: Bool = false
    @ObservedObject private var partnerService = PartnerLoyaltyService.shared
    
    private let deleteThreshold: CGFloat = -100
    
    private var isInactiveOrExpired: Bool {
        guard let validUntil = partner.validUntil else {
            return !partner.isActive
        }
        return !partner.isActive || validUntil < Date()
    }
    
    private func saveCheckoutCode() async {
        isSavingCode = true
        showCodeSaved = false
        
        // Normalize code (uppercase, trim)
        let normalizedCode = checkoutCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let codeToSave = normalizedCode.isEmpty ? nil : normalizedCode
        
        do {
            _ = try await partnerService.updatePartner(
                partnerId: partner.partnerId,
                checkoutCode: codeToSave
            )
            
            await MainActor.run {
                isSavingCode = false
                showCodeSaved = true
                
                // Hide success message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showCodeSaved = false
                }
            }
        } catch {
            await MainActor.run {
                isSavingCode = false
                print("❌ [AdminPartnerCard] Error saving checkout code: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button background (shows when swiping)
            if let onDelete = onDelete, isInactiveOrExpired {
                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(Color.red)
                    }
                }
            }
            
            // Card content
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    // Logo display
                    if let logoUrl = partner.logoUrl, !logoUrl.isEmpty {
                        AsyncImage(url: URL(string: logoUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 80, height: 80)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.softGraphite.opacity(0.2), lineWidth: 1)
                                    )
                            case .failure:
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.softGraphite.opacity(0.5))
                                    .frame(width: 80, height: 80)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.softGraphite.opacity(0.1))
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.softGraphite.opacity(0.5))
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.softGraphite.opacity(0.1))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(partner.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        if let description = partner.description {
                            Text(description)
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                                .lineLimit(2)
                        }
                        
                        if let category = partner.category {
                            Text(category)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.softGraphite)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.softGraphite.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    
                    Spacer()
                }
                
                // Checkout Code Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Checkout Code")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    HStack(spacing: 12) {
                        TextField("Enter code (e.g., SAVE10)", text: $checkoutCode)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.midnightSlate)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.softGraphite.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.softGraphite.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .disabled(isSavingCode)
                        
                        if isSavingCode {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .softGraphite))
                        } else if showCodeSaved {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 72.0/255.0, green: 187.0/255.0, blue: 120.0/255.0))
                        } else {
                            Button(action: {
                                Task {
                                    await saveCheckoutCode()
                                }
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                            }
                            .foregroundColor(checkoutCode == (partner.checkoutCode ?? "") ? Color.softGraphite.opacity(0.3) : Color.softGraphite)
                            .disabled(checkoutCode == (partner.checkoutCode ?? "") || checkoutCode.isEmpty)
                        }
                    }
                    
                    if showCodeSaved {
                        Text("Code saved! All cards will update.")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 72.0/255.0, green: 187.0/255.0, blue: 120.0/255.0))
                    }
                }
                .padding(.top, 8)
                
                // Edit logo button (admin only)
                Button(action: onEditLogo) {
                    HStack {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 14))
                        Text("Edit Logo")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.softGraphite)
                    )
                }
                .padding(.top, 8)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
        }
        .offset(x: offset)
        .onAppear {
            // Initialize checkout code from partner
            checkoutCode = partner.checkoutCode ?? ""
        }
        .onChange(of: partner.checkoutCode) { oldValue, newValue in
            // Update if partner changes externally
            checkoutCode = newValue ?? ""
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if let onDelete = onDelete, isInactiveOrExpired {
                        // Only allow swiping left (negative offset)
                        if value.translation.width < 0 {
                            offset = value.translation.width
                        }
                    }
                }
                .onEnded { value in
                    if let onDelete = onDelete, isInactiveOrExpired {
                        if value.translation.width < deleteThreshold {
                            // Swiped far enough - trigger delete
                            withAnimation(.spring()) {
                                offset = -getScreenWidth()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDelete()
                            }
                        } else {
                            // Spring back
                            withAnimation(.spring()) {
                                offset = 0
                            }
                        }
                    }
                }
        )
    }
}

#Preview {
    AdminPartnerManagementView()
        .environmentObject(AuthService())
}

