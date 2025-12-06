//
//  AuthView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.98, blue: 0.95), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)
                    
                    // Logo/Title Section
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text("REVER")
                            .font(.system(size: 42, weight: .bold, design: .default))
                            .foregroundColor(.primary)
                        
                        Text("Your behavioral finance companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.bottom, 50)
                    
                    // Form Section
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(.plain)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(focusedField == .email ? Color.green : Color.clear, lineWidth: 2)
                                        )
                                )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .password)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(focusedField == .password ? Color.green : Color.clear, lineWidth: 2)
                                        )
                                )
                        }
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Sign In/Up Button
                        Button(action: {
                            Task {
                                await performAuth()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: email.isEmpty || password.isEmpty || isLoading
                                        ? [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]
                                        : [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: (email.isEmpty || password.isEmpty || isLoading) ? Color.clear : Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.top, 8)
                        
                        // Toggle Sign In/Sign Up
                        Button(action: {
                            withAnimation {
                                isSignUp.toggle()
                                errorMessage = nil
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .foregroundColor(.secondary)
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .foregroundColor(.green)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
    }
    
    private func performAuth() async {
        isLoading = true
        errorMessage = nil
        focusedField = nil
        
        do {
            if isSignUp {
                try await authService.signUp(email: email, password: password)
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            withAnimation {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService())
}

