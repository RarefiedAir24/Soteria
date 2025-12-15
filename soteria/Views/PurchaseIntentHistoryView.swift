//
//  PurchaseIntentHistoryView.swift
//  soteria
//
//  View and search all purchase intent interactions
//

import SwiftUI

struct PurchaseIntentHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var purchaseIntentService: PurchaseIntentService
    
    @State private var searchText: String = ""
    @State private var selectedFilter: FilterType = .all
    @State private var selectedTimeRange: TimeRange = .allTime
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case planned = "Planned"
        case impulse = "Impulse"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .planned: return "calendar"
            case .impulse: return "bolt"
            }
        }
    }
    
    enum TimeRange: String, CaseIterable {
        case allTime = "All Time"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case last3Months = "Last 3 Months"
        
        var dateRange: (start: Date, end: Date)? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .allTime:
                return nil
            case .today:
                let start = calendar.startOfDay(for: now)
                return (start, now)
            case .thisWeek:
                let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
                return (start, now)
            case .thisMonth:
                let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                return (start, now)
            case .last3Months:
                let start = calendar.date(byAdding: .month, value: -3, to: now) ?? now
                return (start, now)
            }
        }
    }
    
    private var filteredIntents: [PurchaseIntent] {
        var intents = purchaseIntentService.purchaseIntents
        
        // Filter by time range
        if let dateRange = selectedTimeRange.dateRange {
            intents = intents.filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
        }
        
        // Filter by type
        switch selectedFilter {
        case .all:
            break
        case .planned:
            intents = intents.filter { $0.purchaseType == .planned }
        case .impulse:
            intents = intents.filter { $0.purchaseType == .impulse }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            intents = intents.filter { intent in
                intent.purchaseType.displayName.lowercased().contains(searchLower) ||
                intent.category?.displayName.lowercased().contains(searchLower) ?? false ||
                intent.impulseMood?.displayName.lowercased().contains(searchLower) ?? false ||
                intent.appName?.lowercased().contains(searchLower) ?? false ||
                intent.notes?.lowercased().contains(searchLower) ?? false
            }
        }
        
        // Sort by date (most recent first)
        return intents.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and Filter Bar
                    VStack(spacing: 12) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.softGraphite)
                            TextField("Search interactions...", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(.midnightSlate)
                        }
                        .padding(12)
                        .background(Color.cloudWhite)
                        .cornerRadius(12)
                        
                        // Filter Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Type Filter
                                ForEach(FilterType.allCases, id: \.self) { filter in
                                    Button(action: {
                                        selectedFilter = filter
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: filter.icon)
                                                .font(.system(size: 12))
                                            Text(filter.rawValue)
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(selectedFilter == filter ? .white : .midnightSlate)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedFilter == filter ? Color.reverBlue : Color.cloudWhite)
                                        )
                                    }
                                }
                                
                                // Time Range Filter
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    Button(action: {
                                        selectedTimeRange = range
                                    }) {
                                        Text(range.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedTimeRange == range ? .white : .midnightSlate)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(selectedTimeRange == range ? Color.deepReverBlue : Color.cloudWhite)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color.mistGray)
                    
                    // Interactions List
                    if filteredIntents.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.softGraphite)
                            Text("No interactions found")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            Text("Try adjusting your filters or search")
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredIntents) { intent in
                                    PurchaseIntentCard(intent: intent)
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle("Interaction History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.deepReverBlue)
                }
            }
        }
    }
}

// MARK: - Purchase Intent Card
struct PurchaseIntentCard: View {
    let intent: PurchaseIntent
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: intent.date)
    }
    
    private var formattedAmount: String? {
        guard let amount = intent.amount else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Type Icon
                Image(systemName: intent.purchaseType == .planned ? "calendar.circle.fill" : "bolt.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(intent.purchaseType == .planned ? .reverBlue : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(intent.purchaseType.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    // Category or Mood
                    if let category = intent.category {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.displayName)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.reverBlue)
                    } else if let mood = intent.impulseMood {
                        HStack(spacing: 4) {
                            Image(systemName: mood.icon)
                                .font(.system(size: 12))
                            Text(mood.displayName)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Amount (if available)
                if let amount = formattedAmount {
                    Text(amount)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.midnightSlate)
                }
            }
            
            // Additional Info
            HStack {
                // App Name
                if let appName = intent.appName {
                    HStack(spacing: 4) {
                        Image(systemName: "app.fill")
                            .font(.system(size: 10))
                        Text(appName)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.softGraphite)
                }
                
                Spacer()
                
                // Date
                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite)
            }
            
            // Notes (if available)
            if let notes = intent.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 13))
                    .foregroundColor(.softGraphite)
                    .padding(.top, 4)
            }
            
            // Mood Notes (if available)
            if let moodNotes = intent.impulseMoodNotes, !moodNotes.isEmpty {
                Text(moodNotes)
                    .font(.system(size: 13))
                    .foregroundColor(.softGraphite)
                    .italic()
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.cloudWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    PurchaseIntentHistoryView()
        .environmentObject(PurchaseIntentService.shared)
}

