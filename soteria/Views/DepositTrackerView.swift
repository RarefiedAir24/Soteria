//
//  DepositTrackerView.swift
//  soteria
//
//  Comprehensive deposit tracker with daily, weekly, monthly, yearly views
//

import SwiftUI
#if canImport(Charts)
import Charts
#endif

struct DepositTrackerView: View {
    @ObservedObject private var plaidService = PlaidService.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPeriod: TimePeriod = .monthly
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    @State private var showPaywall = false
    
    enum TimePeriod: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
        case all = "All Time"
        
        var icon: String {
            switch self {
            case .daily: return "calendar"
            case .weekly: return "calendar.badge.clock"
            case .monthly: return "calendar.badge.plus"
            case .yearly: return "calendar.badge.exclamationmark"
            case .all: return "infinity"
            }
        }
    }
    
    // Free users limited to last 7 days, premium gets all time
    private var availablePeriods: [TimePeriod] {
        if subscriptionService.isPremium {
            return TimePeriod.allCases
        } else {
            return [.daily, .weekly] // Free tier limited to daily and weekly (within 7 days)
        }
    }
    
    private var filteredDeposits: [SavingsDeposit] {
        var deposits = plaidService.depositHistory.sorted { $0.timestamp > $1.timestamp }
        
        // Free users limited to last 7 days
        if !subscriptionService.isPremium {
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            deposits = deposits.filter { $0.timestamp >= sevenDaysAgo }
        }
        
        switch selectedPeriod {
        case .daily:
            return deposits.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) }
        case .weekly:
            let calendar = Calendar.current
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) else {
                return deposits.filter { Calendar.current.isDate($0.timestamp, equalTo: selectedDate, toGranularity: .weekOfYear) }
            }
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? selectedDate
            return deposits.filter { $0.timestamp >= weekStart && $0.timestamp <= weekEnd }
        case .monthly:
            return deposits.filter {
                Calendar.current.component(.month, from: $0.timestamp) == Calendar.current.component(.month, from: selectedDate) &&
                Calendar.current.component(.year, from: $0.timestamp) == Calendar.current.component(.year, from: selectedDate)
            }
        case .yearly:
            return deposits.filter {
                Calendar.current.component(.year, from: $0.timestamp) == Calendar.current.component(.year, from: selectedDate)
            }
        case .all:
            return deposits
        }
    }
    
    private var totalForPeriod: Double {
        filteredDeposits.reduce(0) { $0 + $1.amount }
    }
    
    private var averageForPeriod: Double {
        guard !filteredDeposits.isEmpty else { return 0 }
        return totalForPeriod / Double(filteredDeposits.count)
    }
    
    private var depositCount: Int {
        filteredDeposits.count
    }
    
    private var largestDeposit: SavingsDeposit? {
        filteredDeposits.max(by: { $0.amount < $1.amount })
    }
    
    private var chartData: [ChartDataPoint] {
        let deposits = filteredDeposits.sorted { $0.timestamp < $1.timestamp }
        
        switch selectedPeriod {
        case .daily:
            // Group by hour
            return Dictionary(grouping: deposits) { deposit in
                Calendar.current.component(.hour, from: deposit.timestamp)
            }
            .map { hour, deposits in
                ChartDataPoint(
                    label: "\(hour):00",
                    value: deposits.reduce(0) { $0 + $1.amount },
                    date: Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                )
            }
            .sorted { $0.date < $1.date }
            
        case .weekly:
            // Group by day
            return Dictionary(grouping: deposits) { deposit in
                let calendar = Calendar.current
                return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: deposit.timestamp) ?? deposit.timestamp
            }
            .map { date, deposits in
                ChartDataPoint(
                    label: dayFormatter.string(from: date),
                    value: deposits.reduce(0) { $0 + $1.amount },
                    date: date
                )
            }
            .sorted { $0.date < $1.date }
            
        case .monthly:
            // Group by week
            return Dictionary(grouping: deposits) { deposit in
                Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: deposit.timestamp)) ?? deposit.timestamp
            }
            .map { weekStart, deposits in
                ChartDataPoint(
                    label: weekFormatter.string(from: weekStart),
                    value: deposits.reduce(0) { $0 + $1.amount },
                    date: weekStart
                )
            }
            .sorted { $0.date < $1.date }
            
        case .yearly:
            // Group by month
            return Dictionary(grouping: deposits) { deposit in
                Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: deposit.timestamp)) ?? deposit.timestamp
            }
            .map { monthStart, deposits in
                ChartDataPoint(
                    label: monthFormatter.string(from: monthStart),
                    value: deposits.reduce(0) { $0 + $1.amount },
                    date: monthStart
                )
            }
            .sorted { $0.date < $1.date }
            
        case .all:
            // Group by month
            return Dictionary(grouping: deposits) { deposit in
                Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: deposit.timestamp)) ?? deposit.timestamp
            }
            .map { monthStart, deposits in
                ChartDataPoint(
                    label: monthFormatter.string(from: monthStart),
                    value: deposits.reduce(0) { $0 + $1.amount },
                    date: monthStart
                )
            }
            .sorted { $0.date < $1.date }
        }
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
    
    private var weekFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    var body: some View {
        ZStack {
            Color.mistGray
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats Card
                    headerStatsCard
                    
                    // Period Selector
                    periodSelector
                    
                    // Chart Visualization
                    if !chartData.isEmpty {
                        chartCard
                    }
                    
                    // Summary Stats
                    summaryStatsCard
                    
                    // Deposit List
                    if !filteredDeposits.isEmpty {
                        depositListCard
                    } else {
                        emptyStateCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Deposit Tracker")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showDatePicker = true
                }) {
                    Image(systemName: "calendar")
                        .foregroundColor(.reverBlue)
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedDate,
                period: selectedPeriod
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .onAppear {
            // Validate selected period for free users
            if !subscriptionService.isPremium && !availablePeriods.contains(selectedPeriod) {
                selectedPeriod = .weekly // Default to weekly for free users
            }
        }
        .onChange(of: subscriptionService.isPremium) { oldValue, newValue in
            // Validate period when subscription changes
            if !newValue && !availablePeriods.contains(selectedPeriod) {
                selectedPeriod = .weekly
            }
        }
    }
    
    // MARK: - Header Stats Card
    private var headerStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Saved")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.softGraphite)
                    
                    Text(formatCurrency(plaidService.totalSaved))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.midnightSlate)
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.reverBlue, Color.deepReverBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Deposits")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.softGraphite)
                    Text("\(plaidService.depositHistory.count)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("This Period")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.softGraphite)
                    Text(formatCurrency(totalForPeriod))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.reverBlue)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availablePeriods, id: \.self) { period in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPeriod = period
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: period.icon)
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text(period.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(selectedPeriod == period ? .white : .midnightSlate)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedPeriod == period ? Color.reverBlue : Color.white)
                            )
                            .shadow(color: selectedPeriod == period ? Color.reverBlue.opacity(0.3) : Color.black.opacity(0.05), radius: selectedPeriod == period ? 8 : 2, x: 0, y: 2)
                        }
                    }
                    
                    // Show locked periods for free users
                    if !subscriptionService.isPremium {
                        ForEach([TimePeriod.monthly, .yearly, .all], id: \.self) { period in
                            Button(action: {
                                showPaywall = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12, weight: .medium))
                                    Image(systemName: period.icon)
                                        .font(.system(size: 14, weight: .medium))
                                    
                                    Text(period.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.softGraphite)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.dreamMist)
                                )
                                .opacity(0.6)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !subscriptionService.isPremium {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text("Free users can view last 7 days. Upgrade to Plus for unlimited history.")
                        .font(.system(size: 11))
                        .foregroundColor(.softGraphite)
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Chart Card
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.reverBlue)
                
                Text("Savings Trend")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Spacer()
            }
            
            #if canImport(Charts)
            if #available(iOS 16.0, *) {
                Chart(chartData, id: \.date) { dataPoint in
                    BarMark(
                        x: .value("Period", dataPoint.label),
                        y: .value("Amount", dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.reverBlue, Color.deepReverBlue],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(8)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.mistGray)
                        AxisValueLabel()
                            .foregroundStyle(Color.softGraphite)
                            .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.mistGray)
                        AxisValueLabel()
                            .foregroundStyle(Color.softGraphite)
                            .font(.system(size: 10))
                    }
                }
            } else {
                // Fallback for iOS 15 - use custom bar chart
                CustomBarChart(data: chartData)
                    .frame(height: 200)
            }
            #else
            // Fallback if Charts framework is not available
            CustomBarChart(data: chartData)
                .frame(height: 200)
            #endif
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Summary Stats Card
    private var summaryStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.reverBlue)
                
                Text("Period Summary")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Spacer()
            }
            
            if !filteredDeposits.isEmpty {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        StatBox(
                            title: "Total",
                            value: formatCurrency(totalForPeriod),
                            icon: "dollarsign.circle.fill",
                            color: .reverBlue
                        )
                        
                        StatBox(
                            title: "Average",
                            value: formatCurrency(averageForPeriod),
                            icon: "chart.bar.xaxis",
                            color: .deepReverBlue
                        )
                    }
                    
                    HStack(spacing: 20) {
                        StatBox(
                            title: "Count",
                            value: "\(depositCount)",
                            icon: "number.circle.fill",
                            color: .comfortLavender
                        )
                        
                        if let largest = largestDeposit {
                            StatBox(
                                title: "Largest",
                                value: formatCurrency(largest.amount),
                                icon: "arrow.up.circle.fill",
                                color: .gentleRose
                            )
                        }
                    }
                }
            } else {
                Text("No deposits for this period")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.softGraphite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Deposit List Card
    private var depositListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet")
                    .font(.system(size: 20))
                    .foregroundColor(.reverBlue)
                
                Text("Deposit History")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(filteredDeposits) { deposit in
                    DepositRow(deposit: deposit)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Empty State Card
    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.softGraphite.opacity(0.5))
            
            Text("No deposits yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
            
            Text("Start saving to see your deposit history here")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.softGraphite)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Helpers
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Chart Data Point
struct ChartDataPoint {
    let label: String
    let value: Double
    let date: Date
}

// MARK: - Stat Box
struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.softGraphite)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.midnightSlate)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Deposit Row
struct DepositRow: View {
    let deposit: SavingsDeposit
    
    @State private var isExpanded = false
    @State private var showScreenshotViewer = false
    @State private var showEditDeposit = false
    @State private var depositScreenshot: UIImage? = nil
    
    private let screenshotService = DepositScreenshotService.shared
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private var typeIcon: String {
        switch deposit.type {
        case .manual: return "hand.tap.fill"
        case .plaid: return "arrow.right.circle.fill"
        case .virtual: return "cloud.fill"
        case .decisionWindow: return "clock.fill"
        case .goalDeposit: return "target"
        }
    }
    
    private var typeColor: Color {
        switch deposit.type {
        case .manual: return .reverBlue
        case .plaid: return .deepReverBlue
        case .virtual: return .comfortLavender
        case .decisionWindow: return .gentleRose
        case .goalDeposit: return .warmSand
        }
    }
    
    private var typeLabel: String {
        switch deposit.type {
        case .manual: return "Manual"
        case .plaid: return "Plaid"
        case .virtual: return "Virtual"
        case .decisionWindow: return "Decision Window"
        case .goalDeposit: return "Goal"
        }
    }
    
    private var hasScreenshot: Bool {
        deposit.screenshotPath != nil || screenshotService.loadScreenshot(for: deposit.id) != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Row (always visible)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(typeColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: typeIcon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(typeColor)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(typeLabel)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            if deposit.goalId != nil {
                                Image(systemName: "target")
                                    .font(.system(size: 10))
                                    .foregroundColor(.reverBlue)
                            }
                            
                            // Screenshot indicator
                            if hasScreenshot {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.reverBlue)
                            }
                            
                            // Reference ID indicator
                            if deposit.referenceId != nil {
                                Image(systemName: "number")
                                    .font(.system(size: 10))
                                    .foregroundColor(.reverBlue)
                            }
                        }
                        
                        Text(dateFormatter.string(from: deposit.timestamp))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.softGraphite)
                    }
                    
                    Spacer()
                    
                    // Amount
                    Text(formatCurrency(deposit.amount))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    // Expand/Collapse indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.softGraphite)
                }
                .padding(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Details (shown when expanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    // Reference ID
                    if let referenceId = deposit.referenceId, !referenceId.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "number")
                                .font(.system(size: 14))
                                .foregroundColor(.reverBlue)
                            Text("Reference ID:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.softGraphite)
                            Text(referenceId)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            Spacer()
                        }
                    }
                    
                    // Screenshot
                    if hasScreenshot {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.reverBlue)
                                Text("Receipt/Screenshot")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                Spacer()
                            }
                            
                            Button(action: {
                                loadScreenshot()
                                showScreenshotViewer = true
                            }) {
                                Group {
                                    if let screenshot = depositScreenshot {
                                        Image(uiImage: screenshot)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.mistGray)
                                            ProgressView()
                                        }
                                    }
                                }
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    
                    // Edit button (for manual deposits only)
                    if deposit.type == .manual {
                        Button(action: {
                            showEditDeposit = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                Text("Edit Deposit")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.reverBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.reverBlue.opacity(0.1))
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.mistGray.opacity(0.5))
        )
        .sheet(isPresented: $showScreenshotViewer) {
            if let screenshot = depositScreenshot {
                ScreenshotViewerView(image: screenshot, deposit: deposit)
            }
        }
        .sheet(isPresented: $showEditDeposit) {
            EditDepositView(deposit: deposit)
        }
        .onAppear {
            if isExpanded {
                loadScreenshot()
            }
        }
        .onChange(of: isExpanded) { oldValue, newValue in
            if newValue {
                loadScreenshot()
            }
        }
    }
    
    private func loadScreenshot() {
        if depositScreenshot == nil {
            depositScreenshot = screenshotService.loadScreenshot(for: deposit.id) ?? 
                                screenshotService.loadScreenshotFromUserDefaults(for: deposit.id)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Custom Bar Chart (iOS 15 fallback)
struct CustomBarChart: View {
    let data: [ChartDataPoint]
    
    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, dataPoint in
                VStack(spacing: 4) {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.reverBlue, Color.deepReverBlue],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: max(20, 200 / CGFloat(max(data.count, 1))), height: maxValue > 0 ? CGFloat(dataPoint.value / maxValue) * 180 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05), value: dataPoint.value)
                    
                    Text(dataPoint.label)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.softGraphite)
                        .rotationEffect(.degrees(-45))
                        .frame(height: 20)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let period: DepositTrackerView.TimePeriod
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select \(period.rawValue.lowercased())")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                    .padding(.top, 20)
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: period == .yearly ? [.date] : [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.reverBlue)
                }
            }
        }
    }
}

