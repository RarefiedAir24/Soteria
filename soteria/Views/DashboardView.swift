//
//  DashboardView.swift
//  soteria
//
//  Fresh, minimal dashboard for testing startup performance
//

import SwiftUI
// TEMPORARILY DISABLED: Firebase import - testing if it's causing crash
// import FirebaseAuth

struct DashboardView: View {
    @State private var userName: String = "User"
    @State private var isLoading = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // REVER background
            Color.mistGray
                .ignoresSafeArea(.all, edges: .top)
            Color.cloudWhite
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView
                        .padding(.top, 60)
                        .padding(.horizontal, 20)
                    
                    // Simple metrics card
                    metricsCard
                        .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            loadUserInfo()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.softGraphite)
                Text(userName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.reverBlue)
            }
            Spacer()
        }
    }
    
    // MARK: - Metrics Card
    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dashboard")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.reverBlue)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    metricRow(label: "Status", value: "Ready")
                    metricRow(label: "Version", value: "1.0")
                    metricRow(label: "User", value: userName)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.softGraphite)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.reverBlue)
        }
    }
    
    // MARK: - Data Loading
    private func loadUserInfo() {
        // TEMPORARILY DISABLED: Firebase Auth - testing if it's causing crash
        // CRITICAL: Access Firebase Auth asynchronously to prevent blocking
        // Don't access Auth.auth().currentUser synchronously - it can block MainActor
        // Task.detached(priority: .userInitiated) {
        //     // Access Firebase Auth in background thread (it's thread-safe)
        //     let firebaseUser = Auth.auth().currentUser
        //     let email = firebaseUser?.email?.components(separatedBy: "@").first ?? "User"
        //     
        //     // Update UI on MainActor (non-blocking)
        //     await MainActor.run {
        //         self.userName = email
        //         self.isLoading = false
        //         print("🟢 [DashboardView] User info loaded: \(email)")
        //     }
        // }
        
        // Set default values when Firebase is disabled
        userName = "User"
        isLoading = false
    }
}

#Preview {
    DashboardView()
}

