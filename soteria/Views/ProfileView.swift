//
//  ProfileView.swift
//  soteria
//
//  User profile management with account settings, Plaid integration, and preferences
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage
import UIKit

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) var dismiss
    
    // PlaidService is optional to prevent startup delays
    @State private var plaidService: PlaidService? = PlaidService.shared
    
    @State private var showChangePassword = false
    @State private var showPlaidConnection = false
    @State private var showSavingsSettings = false
    @State private var showAvatarPicker = false
    @State private var showImagePicker = false
    @State private var showImageSourceActionSheet = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var avatarImage: UIImage? = nil
    @State private var isUploadingAvatar = false
    
    // Password change
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordError: String? = nil
    @State private var isChangingPassword = false
    
    private var userEmail: String {
        authService.currentUser?.email ?? "No email"
    }
    
    private var userName: String {
        authService.currentUser?.displayName ?? authService.currentUser?.email?.components(separatedBy: "@").first ?? "User"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    // Avatar - Entire circle is clickable
                    Button(action: {
                        showImageSourceActionSheet = true
                    }) {
                        ZStack {
                            if let avatarImage = avatarImage {
                                Image(uiImage: avatarImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                // Default avatar
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.reverBlueDark, Color.reverBlueLight],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    Text(String(userName.prefix(1)).uppercased())
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Camera icon overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.6))
                                        
                                        if isUploadingAvatar {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(width: 40, height: 40)
                                    .padding(8)
                                }
                            }
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Name and Email
                    VStack(spacing: 4) {
                        Text(userName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color.midnightSlate)
                        
                        Text(userEmail)
                            .font(.system(size: 14))
                            .foregroundColor(Color.softGraphite)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Account Settings Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Settings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.midnightSlate)
                        .padding(.horizontal, 20)
                    
                    // Change Password
                    Button(action: {
                        showChangePassword = true
                    }) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.reverBlue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Change Password")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.midnightSlate)
                                
                                Text("Update your account password")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.softGraphite)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.softGraphite)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mistGray)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Subscription Status
                    HStack {
                        Image(systemName: subscriptionService.isPremium ? "crown.fill" : "crown")
                            .font(.system(size: 16))
                            .foregroundColor(subscriptionService.isPremium ? Color(red: 1.0, green: 0.84, blue: 0.0) : Color.softGraphite)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(subscriptionService.isPremium ? "Premium Member" : "Free Plan")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.midnightSlate)
                            
                            Text(subscriptionService.isPremium ? "Full access to all features" : "Upgrade for unlimited apps")
                                .font(.system(size: 13))
                                .foregroundColor(Color.softGraphite)
                        }
                        
                        Spacer()
                        
                        if !subscriptionService.isPremium {
                            Button("Upgrade") {
                                // Handle upgrade
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.reverBlue)
                            )
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.mistGray)
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.top, 8)
                
                // Banking & Savings Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Banking & Savings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.midnightSlate)
                        .padding(.horizontal, 20)
                    
                    // Connect Bank Account
                    if plaidService?.connectedAccounts.isEmpty ?? true {
                        Button(action: {
                            showPlaidConnection = true
                        }) {
                            HStack {
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.reverBlue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Connect Bank Account")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.midnightSlate)
                                    
                                    Text("Enable automatic savings transfers")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.softGraphite)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.softGraphite)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.mistGray)
                            )
                        }
                        .padding(.horizontal, 20)
                    } else {
                        // Connected Accounts
                        if let plaid = plaidService, !plaid.connectedAccounts.isEmpty {
                            Button(action: {
                                showSavingsSettings = true
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.green)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(plaid.connectedAccounts.count) Account\(plaid.connectedAccounts.count == 1 ? "" : "s") Connected")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color.midnightSlate)
                                        
                                        if let checkingAccount = plaid.checkingAccount {
                                            Text("\(checkingAccount.name) ••••\(checkingAccount.mask)")
                                                .font(.system(size: 13))
                                                .foregroundColor(Color.softGraphite)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color.softGraphite)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.mistGray)
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 8)
                
                // App Preferences Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preferences")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.midnightSlate)
                        .padding(.horizontal, 20)
                    
                    // Notification Settings
                    NavigationLink(destination: Text("Notification Settings")) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.reverBlue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notifications")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.midnightSlate)
                                
                                Text("Manage notification preferences")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.softGraphite)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.softGraphite)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mistGray)
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 8)
                
                // Danger Zone
                VStack(alignment: .leading, spacing: 16) {
                    Text("Danger Zone")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                    
                    // Sign Out
                    Button(action: {
                        try? authService.signOut()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text("Sign Out")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
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
            
            if avatarImage != nil {
                Button("Remove Photo", role: .destructive) {
                    removeAvatar()
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSourceType) { image in
                avatarImage = image
                uploadAvatar(image: image)
            }
        }
        .photosPicker(isPresented: $showAvatarPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { oldValue, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        avatarImage = image
                        uploadAvatar(image: image)
                    }
                }
            }
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showPlaidConnection) {
            if let plaid = plaidService {
                PlaidConnectionView()
                    .environmentObject(plaid)
            }
        }
        .sheet(isPresented: $showSavingsSettings) {
            if let plaid = plaidService {
                SavingsSettingsView()
                    .environmentObject(plaid)
            }
        }
        .task {
            loadAvatar()
        }
    }
    
    private func loadAvatar() {
        // First try to load from UserDefaults (fast, local cache)
        if let data = UserDefaults.standard.data(forKey: "user_avatar"),
           let image = UIImage(data: data) {
            avatarImage = image
        }
        
        // Then try to load from Firebase Storage (async, for cross-device sync)
        if let userId = authService.currentUser?.uid {
            Task {
                let storageRef = Storage.storage().reference().child("avatars/\(userId).jpg")
                
                do {
                    let data = try await storageRef.data(maxSize: 5 * 1024 * 1024) // 5MB max
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            avatarImage = image
                            // Update UserDefaults cache
                            if let imageData = image.jpegData(compressionQuality: 0.8) {
                                UserDefaults.standard.set(imageData, forKey: "user_avatar")
                            }
                        }
                        print("✅ [ProfileView] Avatar loaded from Firebase Storage")
                    }
                } catch {
                    // Avatar doesn't exist in Firebase Storage yet, or error loading
                    // This is fine - UserDefaults might have it, or user hasn't uploaded one
                    print("ℹ️ [ProfileView] Avatar not found in Firebase Storage (this is OK)")
                }
            }
        }
    }
    
    private func uploadAvatar(image: UIImage) {
        isUploadingAvatar = true
        
        Task {
            // Resize image to reasonable size (200x200 for avatar)
            let resizedImage = image.resized(to: CGSize(width: 200, height: 200))
            
            guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
                await MainActor.run {
                    isUploadingAvatar = false
                }
                return
            }
            
            // Save to UserDefaults for immediate local access
            UserDefaults.standard.set(imageData, forKey: "user_avatar")
            
            // Upload to Firebase Storage for persistence across devices
            if let userId = authService.currentUser?.uid {
                do {
                    let storageRef = Storage.storage().reference().child("avatars/\(userId).jpg")
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    metadata.cacheControl = "public,max-age=3600"
                    
                    _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
                    print("✅ [ProfileView] Avatar uploaded to Firebase Storage")
                } catch {
                    // Check if it's a permission/rule error vs file not found
                    let errorDescription = error.localizedDescription
                    if errorDescription.contains("does not exist") {
                        // This might be a permissions issue - try without metadata
                        do {
                            let storageRef = Storage.storage().reference().child("avatars/\(userId).jpg")
                            _ = try await storageRef.putDataAsync(imageData)
                            print("✅ [ProfileView] Avatar uploaded to Firebase Storage (without metadata)")
                        } catch {
                            print("⚠️ [ProfileView] Failed to upload avatar to Firebase Storage: \(error.localizedDescription)")
                            print("ℹ️ [ProfileView] Avatar saved to UserDefaults only - check Firebase Storage rules")
                        }
                    } else {
                        print("⚠️ [ProfileView] Failed to upload avatar to Firebase Storage: \(errorDescription)")
                        print("ℹ️ [ProfileView] Avatar saved to UserDefaults only")
                    }
                    // Continue anyway - UserDefaults has the image
                }
            }
            
            await MainActor.run {
                isUploadingAvatar = false
            }
        }
    }
    
    private func removeAvatar() {
        avatarImage = nil
        UserDefaults.standard.removeObject(forKey: "user_avatar")
        
        // Also remove from Firebase Storage
        if let userId = authService.currentUser?.uid {
            Task {
                let storageRef = Storage.storage().reference().child("avatars/\(userId).jpg")
                try? await storageRef.delete()
                print("✅ [ProfileView] Avatar removed from Firebase Storage")
            }
        }
    }
}

// MARK: - Change Password View

struct ChangePasswordView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordError: String? = nil
    @State private var isChangingPassword = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                } header: {
                    Text("Password Requirements")
                } footer: {
                    Text("Password must be at least 6 characters long")
                }
                
                if let error = passwordError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                    }
                }
                
                Section {
                    Button(action: changePassword) {
                        HStack {
                            Spacer()
                            if isChangingPassword {
                                ProgressView()
                            } else {
                                Text("Change Password")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isChangingPassword || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Password Changed", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been successfully changed.")
            }
        }
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else {
            passwordError = "New passwords do not match"
            return
        }
        
        guard newPassword.count >= 6 else {
            passwordError = "Password must be at least 6 characters"
            return
        }
        
        passwordError = nil
        isChangingPassword = true
        
        Task {
            do {
                // Re-authenticate user first (Firebase requires this)
                guard let email = authService.currentUser?.email else {
                    await MainActor.run {
                        passwordError = "User not authenticated"
                        isChangingPassword = false
                    }
                    return
                }
                
                let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
                try await authService.currentUser?.reauthenticate(with: credential)
                
                // Change password
                try await authService.currentUser?.updatePassword(to: newPassword)
                
                await MainActor.run {
                    isChangingPassword = false
                    showSuccess = true
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                }
            } catch {
                await MainActor.run {
                    isChangingPassword = false
                    passwordError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

// MARK: - Image Picker (Camera/Photo Library)

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true // Allow cropping
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        
        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                onImagePicked(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                onImagePicked(originalImage)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthService())
            .environmentObject(SubscriptionService.shared)
    }
}

