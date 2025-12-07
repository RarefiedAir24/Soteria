//
//  ReturnDashboardView.swift
//  rever
//
//  Return support dashboard - organized tracking of all returns
//

import SwiftUI

struct ReturnDashboardView: View {
    @EnvironmentObject var regretService: RegretLoggingService
    @State private var selectedFilter: ReturnFilter = .all
    
    enum ReturnFilter {
        case all
        case pending
        case approaching
        case expired
        case completed
    }
    
    private var filteredRegrets: [RegretEntry] {
        switch selectedFilter {
        case .all:
            return regretService.getReturnableRegrets()
        case .pending:
            return regretService.getReturnableRegrets().filter { $0.returnStatus == .notAttempted || $0.returnStatus == nil }
        case .approaching:
            return regretService.getRegretsWithApproachingDeadlines()
        case .expired:
            return regretService.getRegretsWithExpiredDeadlines()
        case .completed:
            return regretService.regretEntries.filter { $0.returnStatus == .returned }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView {
                Color.clear
                    .frame(height: 60)
                
                VStack(spacing: 24) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Return Support Dashboard")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("We provide the maximum support permitted by law")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .italic()
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Stats
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(regretService.getReturnableRegrets().count)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                Text("Pending Returns")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(regretService.getRegretsWithApproachingDeadlines().count)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.orange)
                                Text("Deadlines Approaching")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(regretService.regretEntries.filter { $0.returnStatus == .returned }.count)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.green)
                                Text("Completed")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
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
                    
                    // Filter Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterButton(title: "All", isSelected: selectedFilter == .all) {
                                selectedFilter = .all
                            }
                            FilterButton(title: "Pending", isSelected: selectedFilter == .pending) {
                                selectedFilter = .pending
                            }
                            FilterButton(title: "Approaching", isSelected: selectedFilter == .approaching) {
                                selectedFilter = .approaching
                            }
                            FilterButton(title: "Expired", isSelected: selectedFilter == .expired) {
                                selectedFilter = .expired
                            }
                            FilterButton(title: "Completed", isSelected: selectedFilter == .completed) {
                                selectedFilter = .completed
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Returns List
                    if filteredRegrets.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                            
                            Text("No Returns to Track")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                            
                            Text("All your returns are organized and tracked")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 60)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(filteredRegrets.sorted { ($0.returnDeadline ?? Date.distantFuture) < ($1.returnDeadline ?? Date.distantFuture) }) { regret in
                                ReturnDashboardCard(regret: regret)
                                    .environmentObject(regretService)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Fixed Header
            VStack(spacing: 2) {
                Text("Return Dashboard")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
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

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color(red: 0.1, green: 0.6, blue: 0.3) : Color(red: 0.95, green: 0.95, blue: 0.95))
                )
        }
    }
}

struct ReturnDashboardCard: View {
    @EnvironmentObject var regretService: RegretLoggingService
    let regret: RegretEntry
    @State private var showDetails = false
    
    private var deadlineStatus: (text: String, color: Color) {
        guard let deadline = regret.returnDeadline else {
            return ("No deadline set", .gray)
        }
        
        if regret.isDeadlineExpired {
            return ("Deadline passed", .red)
        } else if let days = regret.daysUntilDeadline {
            if days <= 1 {
                return ("\(days) day left", .red)
            } else if days <= 3 {
                return ("\(days) days left", .orange)
            } else {
                return ("\(days) days left", Color(red: 0.1, green: 0.6, blue: 0.3))
            }
        }
        return ("Deadline: \(formatDate(deadline))", .gray)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let merchant = regret.merchant {
                        Text(merchant)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    if let amount = regret.amount {
                        Text(formatCurrency(amount))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let status = regret.returnStatus {
                        Text(status.displayName)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(status == .returned ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                            )
                            .foregroundColor(status == .returned ? .green : .orange)
                    }
                    
                    Text(deadlineStatus.text)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(deadlineStatus.color)
                }
            }
            
            if let deadline = regret.returnDeadline, !regret.isDeadlineExpired {
                ProgressView(value: progressValue(deadline: deadline))
                    .tint(deadlineStatus.color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onTapGesture {
            showDetails = true
        }
        .sheet(isPresented: $showDetails) {
            RegretDetailView(regret: regret)
                .environmentObject(regretService)
        }
    }
    
    private func progressValue(deadline: Date) -> Double {
        // Calculate purchase date: 30 days before return deadline, or use regret date
        let purchaseDate = regret.returnDeadline.flatMap({ Calendar.current.date(byAdding: .day, value: -30, to: $0) }) ?? regret.date
        let totalDays = Calendar.current.dateComponents([.day], from: purchaseDate, to: deadline).day ?? 30
        let daysPassed = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
        return min(Double(daysPassed) / Double(totalDays), 1.0)
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
        return formatter.string(from: date)
    }
}

#Preview {
    ReturnDashboardView()
        .environmentObject(RegretLoggingService.shared)
}

