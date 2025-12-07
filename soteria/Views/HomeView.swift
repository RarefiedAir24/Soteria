//
//  HomeView.swift
//  rever
//
//  Home view with behavioral insights
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var savingsService: SavingsService
    @EnvironmentObject var quietHoursService: QuietHoursService
    @EnvironmentObject var regretRiskEngine: RegretRiskEngine
    @EnvironmentObject var moodService: MoodTrackingService
    @EnvironmentObject var regretService: RegretLoggingService
    
    private var userEmail: String {
        authService.currentUser?.email?.components(separatedBy: "@").first ?? "there"
    }
    
    private var formattedTotalSaved: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: savingsService.totalSaved)) ?? "$0.00"
    }
    
    private var formattedLastSaved: String {
        guard let lastSaved = savingsService.lastSavedAmount else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: lastSaved)) ?? "$0.00"
    }
    
    private var riskLevelColor: Color {
        guard let risk = regretRiskEngine.currentRisk else { return .gray }
        if risk.riskLevel >= 0.7 {
            return .red
        } else if risk.riskLevel >= 0.4 {
            return .orange
        } else {
            return Color(red: 0.1, green: 0.6, blue: 0.3)
        }
    }
    
    private var riskLevelText: String {
        guard let risk = regretRiskEngine.currentRisk else { return "Unknown" }
        if risk.riskLevel >= 0.7 {
            return "High Risk"
        } else if risk.riskLevel >= 0.4 {
            return "Moderate Risk"
        } else {
            return "Low Risk"
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Regret Risk Alert Card
                    if let risk = regretRiskEngine.currentRisk, risk.riskLevel >= 0.4 {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: risk.riskLevel >= 0.7 ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(riskLevelColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(riskLevelText)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    
                                    if let recommendation = risk.recommendation {
                                        Text(recommendation)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            if !risk.factors.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(risk.factors, id: \.self) { factor in
                                            Text(factor.displayName)
                                                .font(.system(size: 12))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(riskLevelColor.opacity(0.1))
                                                )
                                                .foregroundColor(riskLevelColor)
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
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                    }
                    
                    // Quiet Mode Status Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: quietHoursService.isQuietModeActive ? "moon.fill" : "moon")
                                .font(.system(size: 24))
                                .foregroundColor(quietHoursService.isQuietModeActive ? Color(red: 0.1, green: 0.6, blue: 0.3) : .gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quietHoursService.isQuietModeActive ? "Financial Quiet Mode Active" : "Financial Quiet Mode Inactive")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
                                if quietHoursService.isQuietModeActive {
                                    Text("Your sanctuary is protecting you")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                } else if let schedule = quietHoursService.currentActiveSchedule {
                                    Text(schedule.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                } else {
                                    Text("Protection available when you need it")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, quietHoursService.isQuietModeActive || (regretRiskEngine.currentRisk?.riskLevel ?? 0) >= 0.4 ? 0 : 60)
                    
                    // Total Saved Card - Hero Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Protected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        
                        Text(formattedTotalSaved)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                        
                        Text("by choosing protection over impulse")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.95, green: 0.98, blue: 0.95),
                                        Color(red: 0.92, green: 0.97, blue: 0.92)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    
                    // Stats Row
                    HStack(spacing: 16) {
                        // SOTERIA Moments Card
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SOTERIA Moments")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            
                            Text("\(savingsService.soteriaMomentsCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        
                        // Last Saved Card
                        if savingsService.lastSavedAmount != nil {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Last Saved")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                
                                Text(formattedLastSaved)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Mood Insights Card
                    if let currentMood = moodService.currentMood {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(currentMood.emoji)
                                    .font(.system(size: 32))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current Mood")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    
                                    Text(currentMood.displayName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Regret Summary Card
                    if regretService.recentRegretCount > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("This Week's Regrets")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    
                                    Text("\(regretService.recentRegretCount)")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Fixed Header
            VStack(spacing: 2) {
                Text("Hi, \(userEmail)")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                
                Text("Welcome back")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Color(red: 0.92, green: 0.97, blue: 0.94)
                    .ignoresSafeArea(edges: .top)
            )
            .zIndex(100)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService())
        .environmentObject(SavingsService())
        .environmentObject(QuietHoursService.shared)
        .environmentObject(RegretRiskEngine.shared)
        .environmentObject(MoodTrackingService.shared)
        .environmentObject(RegretLoggingService.shared)
}
