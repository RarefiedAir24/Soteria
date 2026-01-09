//
//  LoyaltyHistoryView.swift
//  soteria
//
//  Modern loyalty points history with beautiful UI
//

import SwiftUI

struct LoyaltyHistoryView: View {
    @ObservedObject private var loyaltyService = LoyaltyPointsService.shared
    @State private var filterType: FilterType = .all
    @State private var searchText = ""
    @State private var selectedTransaction: LoyaltyTransaction?
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case earned = "Earned"
        case spent = "Spent"
        case bonus = "Bonus"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .earned: return "arrow.down.circle.fill"
            case .spent: return "arrow.up.circle.fill"
            case .bonus: return "star.fill"
            }
        }
        
        var transactionType: LoyaltyTransaction.TransactionType? {
            switch self {
            case .all: return nil
            case .earned: return .earned
            case .spent: return .spent
            case .bonus: return .bonus
            }
        }
    }
    
    private var filteredTransactions: [LoyaltyTransaction] {
        var transactions = loyaltyService.transactionHistory
        
        // Filter by type
        if let type = filterType.transactionType {
            transactions = transactions.filter { $0.type == type }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            transactions = transactions.filter { transaction in
                transaction.description.localizedCaseInsensitiveContains(searchText) ||
                transaction.formattedPoints.contains(searchText)
            }
        }
        
        return transactions
    }
    
    private var totalEarned: Int {
        loyaltyService.transactionHistory
            .filter { $0.points > 0 }
            .reduce(0) { $0 + $1.points }
    }
    
    private var totalSpent: Int {
        abs(loyaltyService.transactionHistory
            .filter { $0.points < 0 }
            .reduce(0) { $0 + $1.points })
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Balance Card
                    heroBalanceCard
                    
                    // Quick Stats Grid
                    quickStatsGrid
                    
                    // Filter Pills
                    filterPills
                    
                    // Transaction List
                    if filteredTransactions.isEmpty {
                        emptyStateView
                    } else {
                        transactionsList
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Loyalty Points")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search transactions")
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailSheet(transaction: transaction)
        }
    }
    
    // MARK: - Hero Balance Card
    
    private var heroBalanceCard: some View {
        VStack(spacing: 16) {
            // Points badge
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Available Points")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.softGraphite)
            }
            
            // Main balance
            Text("\(loyaltyService.totalPoints)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Subtitle
            Text("Redeem in the Loyalty Shop")
                .font(.caption)
                .foregroundColor(Color.softGraphite)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.05),
                                Color.yellow.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.2), Color.yellow.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
    }
    
    // MARK: - Quick Stats Grid
    
    private var quickStatsGrid: some View {
        HStack(spacing: 12) {
            // Lifetime Earned
            StatCard(
                icon: "arrow.down.circle.fill",
                iconColor: .green,
                title: "Earned",
                value: "\(loyaltyService.lifetimePointsEarned)",
                subtitle: "All time"
            )
            
            // Total Spent
            StatCard(
                icon: "arrow.up.circle.fill",
                iconColor: .red,
                title: "Spent",
                value: "\(totalSpent)",
                subtitle: "All time"
            )
            
            // Total Transactions
            StatCard(
                icon: "list.bullet.circle.fill",
                iconColor: Color.midnightSlate,
                title: "Activity",
                value: "\(loyaltyService.transactionHistory.count)",
                subtitle: "Transactions"
            )
        }
    }
    
    // MARK: - Filter Pills
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    FilterPillButton(
                        filter: filter,
                        isSelected: filterType == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            filterType = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Transactions List
    
    private var transactionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.midnightSlate)
                .padding(.horizontal, 4)
            
            LazyVStack(spacing: 12) {
                ForEach(filteredTransactions) { transaction in
                    ModernTransactionRow(transaction: transaction)
                        .onTapGesture {
                            selectedTransaction = transaction
                        }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "star.slash")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("No Transactions Yet")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.midnightSlate)
                
                Text(searchText.isEmpty
                     ? "Start earning points by saving money!\nYour activity will appear here."
                     : "No transactions match '\(searchText)'")
                    .font(.subheadline)
                    .foregroundColor(Color.softGraphite)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Helper Functions
    
    private func countForFilter(_ filter: FilterType) -> Int {
        if let type = filter.transactionType {
            return loyaltyService.transactionHistory.filter { $0.type == type }.count
        }
        return loyaltyService.transactionHistory.count
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.1))
                .cornerRadius(12)
            
            // Title
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.softGraphite)
            
            // Value
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.midnightSlate)
            
            // Subtitle
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(Color.softGraphite)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Filter Pill Button

struct FilterPillButton: View {
    let filter: LoyaltyHistoryView.FilterType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                // Count badge
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.softGraphite.opacity(0.15))
                    .cornerRadius(8)
            }
            .foregroundColor(isSelected ? .white : Color.midnightSlate)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected 
                    ? LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                      )
                    : LinearGradient(
                        colors: [Color.white, Color.white],
                        startPoint: .leading,
                        endPoint: .trailing
                      )
            )
            .cornerRadius(25)
            .shadow(
                color: isSelected ? Color.orange.opacity(0.3) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Modern Transaction Row

struct ModernTransactionRow: View {
    let transaction: LoyaltyTransaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(iconGradient.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Image(systemName: transaction.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(iconGradient)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.midnightSlate)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(transaction.relativeDate)
                        .font(.caption)
                        .foregroundColor(Color.softGraphite)
                    
                    if let source = transaction.metadata?.source {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(Color.softGraphite)
                        
                        Text(source.capitalized)
                            .font(.caption)
                            .foregroundColor(Color.softGraphite)
                    }
                }
            }
            
            Spacer()
            
            // Points with balance
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedPoints)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(pointsColor)
                
                Text("\(transaction.balanceAfter)")
                    .font(.caption2)
                    .foregroundColor(Color.softGraphite)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var iconGradient: LinearGradient {
        switch transaction.type {
        case .earned:
            return LinearGradient(
                colors: [Color.green, Color.green.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .spent:
            return LinearGradient(
                colors: [Color.red, Color.red.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .bonus:
            return LinearGradient(
                colors: [Color.orange, Color.yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .adjustment:
            return LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var pointsColor: Color {
        transaction.points > 0 ? .green : .red
    }
}

// MARK: - Transaction Detail Sheet

struct TransactionDetailSheet: View {
    let transaction: LoyaltyTransaction
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with icon
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(iconColor.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: transaction.icon)
                                .font(.system(size: 36))
                                .foregroundColor(iconColor)
                        }
                        
                        Text(transaction.description)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.midnightSlate)
                            .multilineTextAlignment(.center)
                        
                        Text(transaction.formattedPoints)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(transaction.points > 0 ? .green : .red)
                    }
                    .padding(.top, 20)
                    
                    // Details
                    VStack(spacing: 16) {
                        TransactionDetailRow(label: "Date", value: transaction.relativeDate, icon: "calendar")
                        
                        TransactionDetailRow(label: "Balance After", value: "\(transaction.balanceAfter) pts", icon: "chart.line.uptrend.xyaxis")
                        
                        if let metadata = transaction.metadata {
                            if let amount = metadata.depositAmount {
                                TransactionDetailRow(label: "Deposit Amount", value: "$\(String(format: "%.2f", amount))", icon: "dollarsign.circle")
                            }
                            
                            if let source = metadata.source {
                                TransactionDetailRow(label: "Source", value: source.capitalized, icon: "arrow.triangle.2.circlepath")
                            }
                            
                            if let streakBonus = metadata.streakBonus, streakBonus {
                                TransactionDetailRow(label: "Streak Bonus", value: "Applied ✨", icon: "flame")
                            }
                            
                            if let confidence = metadata.verificationConfidence {
                                TransactionDetailRow(label: "Verification", value: "\(Int(confidence * 100))%", icon: "checkmark.seal")
                            }
                            
                            if let itemName = metadata.itemName {
                                TransactionDetailRow(label: "Item", value: itemName, icon: "tag")
                            }
                        }
                        
                        TransactionDetailRow(label: "Transaction ID", value: String(transaction.id.prefix(12)) + "...", icon: "number")
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var iconColor: Color {
        switch transaction.type {
        case .earned: return .green
        case .spent: return .red
        case .bonus: return .orange
        case .adjustment: return .blue
        }
    }
}

// MARK: - Transaction Detail Row

struct TransactionDetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.softGraphite)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.softGraphite)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.midnightSlate)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

#Preview {
    NavigationView {
        LoyaltyHistoryView()
    }
}
