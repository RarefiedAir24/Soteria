//
//  MetricsDashboardView.swift
//  soteria
//
//  Dashboard to view app blocking and usage metrics
//

import SwiftUI

struct MetricsDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showPaywall = false
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedPatternFilter: PatternFilter = .all
    @State private var showPatternDetail: PatternDetailType? = nil
    
    // Free tier: Limited to last 7 days
    // Premium: All time ranges available
    private var availableTimeRanges: [TimeRange] {
        if subscriptionService.isPremium {
            return TimeRange.allCases
        } else {
            return [.today, .week] // Free tier limited to today and this week
        }
    }
    
    // Ensure selected time range is valid for current tier
    private func validateTimeRange() {
        if !availableTimeRanges.contains(selectedTimeRange) {
            selectedTimeRange = .week // Default to week if premium feature was selected
        }
    }
    
    enum PatternFilter: String, CaseIterable {
        case all = "All Patterns"
        case categories = "Categories"
        case moods = "Moods"
        case timeOfDay = "Time of Day"
        case dayOfWeek = "Day of Week"
        case quietHours = "Quiet Hours"
        case usage = "App Usage"
    }
    
    enum PatternDetailType: Identifiable {
        case categories
        case moods
        case timeOfDay
        case dayOfWeek
        
        var id: String {
            switch self {
            case .categories: return "categories"
            case .moods: return "moods"
            case .timeOfDay: return "timeOfDay"
            case .dayOfWeek: return "dayOfWeek"
            }
        }
    }
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cloudWhite
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time range selector
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Time Range", selection: $selectedTimeRange) {
                                ForEach(availableTimeRanges, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            // Validate time range on appear
                            .onAppear {
                                validateTimeRange()
                            }
                            .onChange(of: subscriptionService.isPremium) { oldValue, newValue in
                                validateTimeRange()
                            }
                            
                            if !subscriptionService.isPremium {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    Text("Premium: Unlock 'This Month' and 'All Time'")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Button("Upgrade") {
                                        showPaywall = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(Color.reverBlue)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Pattern filter selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(PatternFilter.allCases, id: \.self) { filter in
                                    FilterChip(
                                        title: filter.rawValue,
                                        isSelected: selectedPatternFilter == filter,
                                        action: {
                                            selectedPatternFilter = filter
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 8)
                        
                        // Unblock Metrics
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Unblock Requests")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.midnightSlate)
                            
                            let unblockMetrics = deviceActivityService.getUnblockMetrics()
                            let (startDate, endDate) = getDateRange()
                            let behavioralPatterns = deviceActivityService.getBehavioralPatterns(from: startDate, to: endDate)
                            let categoryBreakdown = deviceActivityService.getCategoryBreakdown(from: startDate, to: endDate)
                            let moodBreakdown = deviceActivityService.getMoodBreakdown(from: startDate, to: endDate)
                            
                            VStack(spacing: 12) {
                                MetricCard(
                                    title: "Total Unblocks",
                                    value: "\(unblockMetrics.totalUnblocks)",
                                    icon: "lock.open.fill",
                                    color: .orange
                                )
                                
                                HStack(spacing: 12) {
                                    MetricCard(
                                        title: "Planned",
                                        value: "\(unblockMetrics.plannedUnblocks)",
                                        icon: "calendar.circle.fill",
                                        color: Color.reverBlue
                                    )
                                    
                                    MetricCard(
                                        title: "Impulse",
                                        value: "\(unblockMetrics.impulseUnblocks)",
                                        icon: "bolt.circle.fill",
                                        color: .orange
                                    )
                                }
                                
                                if let mostRequested = unblockMetrics.mostRequestedAppName {
                                    MetricCard(
                                        title: "Most Requested App",
                                        value: mostRequested,
                                        icon: "star.fill",
                                        color: .yellow
                                    )
                                }
                                
                                // Behavioral Patterns Section - Enhanced with filtering
                                BehavioralPatternsView(
                                    behavioralPatterns: behavioralPatterns,
                                    categoryBreakdown: categoryBreakdown,
                                    moodBreakdown: moodBreakdown,
                                    unblockMetrics: unblockMetrics,
                                    selectedFilter: selectedPatternFilter,
                                    onShowDetail: { type in
                                        showPatternDetail = type
                                    },
                                    formatTimeInterval: formatTimeInterval
                                )
                                
                                // Show filtered patterns based on selection
                                if selectedPatternFilter == .all || selectedPatternFilter == .categories {
                                    if !categoryBreakdown.isEmpty {
                                        PatternBreakdownCard(
                                            title: "Planned Purchase Categories",
                                            icon: "calendar.circle.fill",
                                            color: Color.reverBlue,
                                            breakdown: categoryBreakdown,
                                            formatLabel: formatCategoryName,
                                            onTap: {
                                                showPatternDetail = .categories
                                            }
                                        )
                                    }
                                }
                                
                                if selectedPatternFilter == .all || selectedPatternFilter == .moods {
                                    if !moodBreakdown.isEmpty {
                                        PatternBreakdownCard(
                                            title: "Impulse Purchase Moods",
                                            icon: "bolt.circle.fill",
                                            color: .orange,
                                            breakdown: moodBreakdown,
                                            formatLabel: formatMoodName,
                                            onTap: {
                                                showPatternDetail = .moods
                                            }
                                        )
                                    }
                                }
                                
                                if selectedPatternFilter == .all || selectedPatternFilter == .timeOfDay {
                                    if !behavioralPatterns.timeOfDayBreakdown.isEmpty {
                                        PatternBreakdownCard(
                                            title: "Time of Day Distribution",
                                            icon: "clock.fill",
                                            color: .blue,
                                            breakdown: behavioralPatterns.timeOfDayBreakdown,
                                            formatLabel: { $0 },
                                            onTap: {
                                                showPatternDetail = .timeOfDay
                                            }
                                        )
                                    }
                                }
                                
                                if selectedPatternFilter == .all || selectedPatternFilter == .dayOfWeek {
                                    if !behavioralPatterns.dayOfWeekBreakdown.isEmpty {
                                        DayOfWeekChartCard(
                                            breakdown: behavioralPatterns.dayOfWeekBreakdown,
                                            onTap: {
                                                showPatternDetail = .dayOfWeek
                                            }
                                        )
                                    }
                                }
                                
                                if selectedPatternFilter == .all || selectedPatternFilter == .quietHours {
                                    QuietHoursPatternCard(
                                        quietHoursPercentage: behavioralPatterns.quietHoursPercentage,
                                        totalUnblocks: unblockMetrics.totalUnblocks
                                    )
                                }
                                
                                if selectedPatternFilter == .all || selectedPatternFilter == .usage {
                                    AppUsagePatternCard(
                                        appsUsedCount: behavioralPatterns.appsUsedCount,
                                        appsNotUsedCount: behavioralPatterns.appsNotUsedCount,
                                        totalUnblocks: unblockMetrics.totalUnblocks,
                                        usageRate: behavioralPatterns.usageRate,
                                        avgUsageDuration: behavioralPatterns.avgUsageDuration,
                                        formatTimeInterval: formatTimeInterval
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // App Usage Metrics
                        VStack(alignment: .leading, spacing: 16) {
                            Text("App Usage")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.midnightSlate)
                            
                            let usageStats = getUsageStats()
                            
                            if usageStats.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "chart.bar")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    
                                    Text("No usage data yet")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(Array(usageStats.sorted(by: { $0.value.totalTime > $1.value.totalTime })), id: \.key) { appIndex, stats in
                                        UsageCard(
                                            appName: stats.appName,
                                            totalTime: stats.totalTime,
                                            sessionCount: stats.sessionCount
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(subscriptionService)
            }
            .sheet(item: $showPatternDetail) { detailType in
                PatternDetailView(
                    detailType: detailType,
                    deviceActivityService: deviceActivityService,
                    startDate: getDateRange().start,
                    endDate: getDateRange().end
                )
            }
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    // Note: We use deviceActivityService.getUnblockMetrics() directly in the view
    // This function is no longer needed but kept for backward compatibility
    
    private func getDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch selectedTimeRange {
        case .today:
            startDate = calendar.startOfDay(for: now)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .all:
            startDate = Date.distantPast
        }
        
        return (startDate, now)
    }
    
    private func getUsageStats() -> [Int: (totalTime: TimeInterval, sessionCount: Int, appName: String)] {
        let (startDate, endDate) = getDateRange()
        return deviceActivityService.getAppUsage(from: startDate, to: endDate)
    }
    
    private func formatCategoryName(_ category: String) -> String {
        // Map category keys to display names
        let categoryMap: [String: String] = [
            "gift_shopping": "Gift Shopping",
            "necessity": "Necessity",
            "replacement": "Replacement",
            "planned_expense": "Planned Expense",
            "subscription": "Subscription",
            "event": "Event",
            "birthday": "Birthday",
            "anniversary": "Anniversary",
            "holiday": "Holiday",
            "other": "Other"
        ]
        return categoryMap[category] ?? category.capitalized
    }
    
    private func formatMoodName(_ mood: String) -> String {
        // Map mood keys to display names
        let moodMap: [String: String] = [
            "lonely": "Lonely",
            "bored": "Bored",
            "stressed": "Stressed",
            "depressed": "Depressed",
            "anxious": "Anxious",
            "excited": "Excited",
            "happy": "Happy",
            "other": "Other"
        ]
        return moodMap[mood] ?? mood.capitalized
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.midnightSlate)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
}

struct CategoryBarChartRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(Color.midnightSlate)
                
                Spacer()
                
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.mistGray)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct UsageCard: View {
    let appName: String
    let totalTime: TimeInterval
    let sessionCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: "app.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.reverBlue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(appName)
                    .font(.headline)
                    .foregroundColor(Color.midnightSlate)
                
                HStack(spacing: 16) {
                    Label(formatTime(totalTime), systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Label("\(sessionCount) session\(sessionCount == 1 ? "" : "s")", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    MetricsDashboardView()
        .environmentObject(DeviceActivityService.shared)
}

