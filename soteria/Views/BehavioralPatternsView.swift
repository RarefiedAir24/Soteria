//
//  BehavioralPatternsView.swift
//  soteria
//
//  Enhanced behavioral patterns visualization with filtering
//

import SwiftUI

struct BehavioralPatternsView: View {
    let behavioralPatterns: DeviceActivityService.BehavioralPatterns
    let categoryBreakdown: [String: Int]
    let moodBreakdown: [String: Int]
    let unblockMetrics: (totalUnblocks: Int, plannedUnblocks: Int, impulseUnblocks: Int, mostCommonCategory: String?, mostCommonMood: String?, mostRequestedAppIndex: Int?, mostRequestedAppName: String?)
    let selectedFilter: MetricsDashboardView.PatternFilter
    let onShowDetail: (MetricsDashboardView.PatternDetailType) -> Void
    let formatTimeInterval: (TimeInterval) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.reverBlue)
                
                Text("Behavioral Patterns")
                    .font(.headline)
                    .foregroundColor(Color.midnightSlate)
                
                Spacer()
            }
            
            // Summary stats
            if selectedFilter == .all {
                VStack(spacing: 12) {
                    PatternStatRow(
                        icon: "clock.fill",
                        iconColor: .blue,
                        label: "Most Active Time",
                        value: behavioralPatterns.mostCommonTimeOfDay ?? "N/A"
                    )
                    
                    PatternStatRow(
                        icon: "calendar",
                        iconColor: .blue,
                        label: "Most Active Day",
                        value: behavioralPatterns.mostCommonDayOfWeek ?? "N/A"
                    )
                    
                    PatternStatRow(
                        icon: "moon.fill",
                        iconColor: .purple,
                        label: "During Quiet Hours",
                        value: "\(String(format: "%.1f", behavioralPatterns.quietHoursPercentage))%"
                    )
                    
                    PatternStatRow(
                        icon: "checkmark.circle.fill",
                        iconColor: Color.reverBlue,
                        label: "App Usage Rate",
                        value: "\(String(format: "%.1f", behavioralPatterns.usageRate))%"
                    )
                    
                    if let avgTime = behavioralPatterns.avgTimeBetweenUnblocks {
                        PatternStatRow(
                            icon: "timer",
                            iconColor: .orange,
                            label: "Avg Time Between",
                            value: formatTimeInterval(avgTime)
                        )
                    }
                    
                    if let avgDuration = behavioralPatterns.avgUsageDuration {
                        PatternStatRow(
                            icon: "hourglass",
                            iconColor: .blue,
                            label: "Avg Usage Duration",
                            value: formatTimeInterval(avgDuration)
                        )
                    }
                    
                    PatternStatRow(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: Color.reverBlue,
                        label: "Avg Per Day",
                        value: String(format: "%.1f", behavioralPatterns.avgUnblocksPerDay)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct PatternStatRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 16))
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.midnightSlate)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Color.midnightSlate)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.reverBlue : Color.mistGray)
                )
        }
    }
}

struct PatternBreakdownCard: View {
    let title: String
    let icon: String
    let color: Color
    let breakdown: [String: Int]
    let formatLabel: (String) -> String
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.midnightSlate)
                
                Spacer()
                
                Button(action: onTap) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 12))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(color)
                }
            }
            
            // Show top 3 items with chart
            let sorted = breakdown.sorted(by: { $0.value > $1.value })
            let topItems = Array(sorted.prefix(3))
            let total = breakdown.values.reduce(0, +)
            
            VStack(spacing: 8) {
                ForEach(topItems, id: \.key) { key, count in
                    CategoryBarChartRow(
                        label: formatLabel(key),
                        count: count,
                        total: total,
                        color: color
                    )
                }
                
                if sorted.count > 3 {
                    Text("+ \(sorted.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct DayOfWeekChartCard: View {
    let breakdown: [String: Int]
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                    .font(.system(size: 18))
                
                Text("Day of Week Distribution")
                    .font(.headline)
                    .foregroundColor(Color.midnightSlate)
                
                Spacer()
                
                Button(action: onTap) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 12))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.purple)
                }
            }
            
            let sortedDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            let total = breakdown.values.reduce(0, +)
            
            VStack(spacing: 8) {
                ForEach(sortedDays, id: \.self) { day in
                    if let count = breakdown[day] {
                        CategoryBarChartRow(
                            label: day,
                            count: count,
                            total: total,
                            color: .purple
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct QuietHoursPatternCard: View {
    let quietHoursPercentage: Double
    let totalUnblocks: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 18))
                
                Text("Quiet Hours Activity")
                    .font(.headline)
                    .foregroundColor(Color.midnightSlate)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Percentage display
                VStack(spacing: 4) {
                    Text("\(String(format: "%.1f", quietHoursPercentage))%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.purple)
                    
                    Text("of unblocks during Quiet Hours")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Visual bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.mistGray)
                            .frame(height: 20)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .purple.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(quietHoursPercentage / 100.0), height: 20)
                    }
                }
                .frame(height: 20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct AppUsagePatternCard: View {
    let appsUsedCount: Int
    let appsNotUsedCount: Int
    let totalUnblocks: Int
    let usageRate: Double
    let avgUsageDuration: TimeInterval?
    let formatTimeInterval: (TimeInterval) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.reverBlue)
                    .font(.system(size: 18))
                
                Text("App Usage After Unblock")
                    .font(.headline)
                    .foregroundColor(Color.midnightSlate)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Usage rate
                VStack(spacing: 4) {
                    Text("\(String(format: "%.1f", usageRate))%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color.reverBlue)
                    
                    Text("of unblocks led to app usage")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Breakdown
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(appsUsedCount)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.reverBlue)
                        Text("Used")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(appsNotUsedCount)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.orange)
                        Text("Not Used")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Visual bar
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.reverBlue)
                            .frame(width: geometry.size.width * CGFloat(usageRate / 100.0), height: 20)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.orange)
                            .frame(width: geometry.size.width * CGFloat((100.0 - usageRate) / 100.0), height: 20)
                    }
                }
                .frame(height: 20)
                
                if let avgDuration = avgUsageDuration {
                    HStack {
                        Image(systemName: "hourglass")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                        Text("Average usage: \(formatTimeInterval(avgDuration))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct PatternDetailView: View {
    let detailType: MetricsDashboardView.PatternDetailType
    @ObservedObject var deviceActivityService: DeviceActivityService
    let startDate: Date
    let endDate: Date
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cloudWhite
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        switch detailType {
                        case .categories:
                            CategoryDetailView(
                                deviceActivityService: deviceActivityService,
                                startDate: startDate,
                                endDate: endDate
                            )
                        case .moods:
                            MoodDetailView(
                                deviceActivityService: deviceActivityService,
                                startDate: startDate,
                                endDate: endDate
                            )
                        case .timeOfDay:
                            TimeOfDayDetailView(
                                deviceActivityService: deviceActivityService,
                                startDate: startDate,
                                endDate: endDate
                            )
                        case .dayOfWeek:
                            DayOfWeekDetailView(
                                deviceActivityService: deviceActivityService,
                                startDate: startDate,
                                endDate: endDate
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(detailTypeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var detailTypeTitle: String {
        switch detailType {
        case .categories: return "Categories"
        case .moods: return "Moods"
        case .timeOfDay: return "Time of Day"
        case .dayOfWeek: return "Day of Week"
        }
    }
}

struct CategoryDetailView: View {
    @ObservedObject var deviceActivityService: DeviceActivityService
    let startDate: Date
    let endDate: Date
    
    var body: some View {
        let breakdown = deviceActivityService.getCategoryBreakdown(from: startDate, to: endDate)
        let total = breakdown.values.reduce(0, +)
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Planned Purchase Categories")
                .font(.title2)
                .fontWeight(.bold)
            
            if breakdown.isEmpty {
                Text("No category data available")
                    .foregroundColor(.gray)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(breakdown.sorted(by: { $0.value > $1.value })), id: \.key) { category, count in
                        DetailedCategoryRow(
                            label: formatCategoryName(category),
                            count: count,
                            total: total,
                            percentage: Double(count) / Double(total) * 100.0
                        )
                    }
                }
            }
        }
    }
    
    private func formatCategoryName(_ category: String) -> String {
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
}

struct MoodDetailView: View {
    @ObservedObject var deviceActivityService: DeviceActivityService
    let startDate: Date
    let endDate: Date
    
    var body: some View {
        let breakdown = deviceActivityService.getMoodBreakdown(from: startDate, to: endDate)
        let total = breakdown.values.reduce(0, +)
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Impulse Purchase Moods")
                .font(.title2)
                .fontWeight(.bold)
            
            if breakdown.isEmpty {
                Text("No mood data available")
                    .foregroundColor(.gray)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(breakdown.sorted(by: { $0.value > $1.value })), id: \.key) { mood, count in
                        DetailedCategoryRow(
                            label: formatMoodName(mood),
                            count: count,
                            total: total,
                            percentage: Double(count) / Double(total) * 100.0,
                            color: .orange
                        )
                    }
                }
            }
        }
    }
    
    private func formatMoodName(_ mood: String) -> String {
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

struct TimeOfDayDetailView: View {
    @ObservedObject var deviceActivityService: DeviceActivityService
    let startDate: Date
    let endDate: Date
    
    var body: some View {
        let patterns = deviceActivityService.getBehavioralPatterns(from: startDate, to: endDate)
        let breakdown = patterns.timeOfDayBreakdown
        let total = breakdown.values.reduce(0, +)
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Time of Day Distribution")
                .font(.title2)
                .fontWeight(.bold)
            
            if breakdown.isEmpty {
                Text("No time of day data available")
                    .foregroundColor(.gray)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(breakdown.sorted(by: { $0.value > $1.value })), id: \.key) { timeCategory, count in
                        DetailedCategoryRow(
                            label: timeCategory,
                            count: count,
                            total: total,
                            percentage: Double(count) / Double(total) * 100.0,
                            color: .blue
                        )
                    }
                }
            }
        }
    }
}

struct DayOfWeekDetailView: View {
    @ObservedObject var deviceActivityService: DeviceActivityService
    let startDate: Date
    let endDate: Date
    
    var body: some View {
        let patterns = deviceActivityService.getBehavioralPatterns(from: startDate, to: endDate)
        let breakdown = patterns.dayOfWeekBreakdown
        let total = breakdown.values.reduce(0, +)
        let sortedDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Day of Week Distribution")
                .font(.title2)
                .fontWeight(.bold)
            
            if breakdown.isEmpty {
                Text("No day of week data available")
                    .foregroundColor(.gray)
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedDays, id: \.self) { day in
                        if let count = breakdown[day] {
                            DetailedCategoryRow(
                                label: day,
                                count: count,
                                total: total,
                                percentage: Double(count) / Double(total) * 100.0,
                                color: .purple
                            )
                        }
                    }
                }
            }
        }
    }
}

struct DetailedCategoryRow: View {
    let label: String
    let count: Int
    let total: Int
    let percentage: Double
    var color: Color = Color.reverBlue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.headline)
                    .foregroundColor(Color.midnightSlate)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text("\(String(format: "%.1f", percentage))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.mistGray)
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(percentage / 100.0), height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

