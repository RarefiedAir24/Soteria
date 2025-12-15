//
//  MoodTrackingService.swift
//  rever
//
//  Mood and reflection tracking for behavioral insights
//

import Foundation
import Combine

enum MoodLevel: String, Codable, CaseIterable {
    case veryHappy = "very_happy"
    case happy = "happy"
    case neutral = "neutral"
    case stressed = "stressed"
    case anxious = "anxious"
    case sad = "sad"
    
    var displayName: String {
        switch self {
        case .veryHappy: return "Very Happy"
        case .happy: return "Happy"
        case .neutral: return "Neutral"
        case .stressed: return "Stressed"
        case .anxious: return "Anxious"
        case .sad: return "Sad"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryHappy: return "😄"
        case .happy: return "😊"
        case .neutral: return "😐"
        case .stressed: return "😰"
        case .anxious: return "😟"
        case .sad: return "😢"
        }
    }
    
    // Risk level for impulse spending (0.0 = low risk, 1.0 = high risk)
    var regretRisk: Double {
        switch self {
        case .veryHappy: return 0.3
        case .happy: return 0.2
        case .neutral: return 0.4
        case .stressed: return 0.8
        case .anxious: return 0.9
        case .sad: return 0.7
        }
    }
}

struct MoodEntry: Identifiable, Codable {
    let id: String
    var date: Date
    var mood: MoodLevel
    var notes: String?
    var triggers: [String]? // What triggered this mood
    var energyLevel: Int? // 1-10 scale
    
    init(id: String = UUID().uuidString, date: Date = Date(), mood: MoodLevel, notes: String? = nil, triggers: [String]? = nil, energyLevel: Int? = nil) {
        self.id = id
        self.date = date
        self.mood = mood
        self.notes = notes
        self.triggers = triggers
        self.energyLevel = energyLevel
    }
}

struct DailyReflection: Identifiable, Codable {
    let id: String
    var date: Date
    var moodEntries: [MoodEntry]
    var spendingFeeling: String? // How did spending feel today?
    var regrets: [String]? // Any regrets?
    var wins: [String]? // Any wins?
    var tomorrowIntent: String? // Intent for tomorrow
    
    init(id: String = UUID().uuidString, date: Date = Date(), moodEntries: [MoodEntry] = [], spendingFeeling: String? = nil, regrets: [String]? = nil, wins: [String]? = nil, tomorrowIntent: String? = nil) {
        self.id = id
        self.date = date
        self.moodEntries = moodEntries
        self.spendingFeeling = spendingFeeling
        self.regrets = regrets
        self.wins = wins
        self.tomorrowIntent = tomorrowIntent
    }
}

class MoodTrackingService: ObservableObject {
    static let shared = MoodTrackingService()
    
    @Published var moodEntries: [MoodEntry] = []
    @Published var dailyReflections: [DailyReflection] = []
    @Published var currentMood: MoodLevel? = nil
    @Published var todayReflection: DailyReflection? = nil
    
    private let moodEntriesKey = "mood_entries"
    private let reflectionsKey = "daily_reflections"
    
    private init() {
        let initStart = Date()
        print("✅ [MoodTrackingService] Init started at \(initStart) (truly lazy - no work on startup)")
        // STREAMLINED: Do absolutely nothing on startup
        // Data will be loaded on-demand when user accesses mood features
        // This eliminates blocking JSON decode during app launch
        let initEnd = Date()
        print("✅ [MoodTrackingService] Initialized at \(initEnd) (total: \(initEnd.timeIntervalSince(initStart))s)")
        
        // Defer all work to background task with delay
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            // Wait 30 seconds to ensure app is fully loaded and responsive
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            await MainActor.run {
                self.loadData()
                self.loadTodayReflection()
                print("✅ [MoodTrackingService] Data loaded")
            }
        }
    }
    
    // Ensure data is loaded (call on-demand)
    func ensureDataLoaded() {
        // Only load if not already loaded
        guard moodEntries.isEmpty && dailyReflections.isEmpty else { return }
        loadData()
        loadTodayReflection()
    }
    
    // Load data from UserDefaults
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: moodEntriesKey),
           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            moodEntries = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: reflectionsKey),
           let decoded = try? JSONDecoder().decode([DailyReflection].self, from: data) {
            dailyReflections = decoded
        }
    }
    
    // Save data to UserDefaults
    private func saveMoodEntries() {
        if let encoded = try? JSONEncoder().encode(moodEntries) {
            UserDefaults.standard.set(encoded, forKey: moodEntriesKey)
        }
    }
    
    private func saveReflections() {
        if let encoded = try? JSONEncoder().encode(dailyReflections) {
            UserDefaults.standard.set(encoded, forKey: reflectionsKey)
        }
    }
    
    // Load or create today's reflection
    private func loadTodayReflection() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let existing = dailyReflections.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            todayReflection = existing
        } else {
            todayReflection = DailyReflection(date: today)
        }
    }
    
    // Add a mood entry
    func addMoodEntry(_ entry: MoodEntry) {
        moodEntries.append(entry)
        currentMood = entry.mood
        saveMoodEntries()
        
        // Update today's reflection
        if todayReflection == nil {
            loadTodayReflection()
        }
        todayReflection?.moodEntries.append(entry)
        saveTodayReflection()
    }
    
    // Update today's reflection
    func updateTodayReflection(_ reflection: DailyReflection) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let index = dailyReflections.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            dailyReflections[index] = reflection
        } else {
            dailyReflections.append(reflection)
        }
        
        todayReflection = reflection
        saveReflections()
    }
    
    // Save today's reflection
    private func saveTodayReflection() {
        guard let reflection = todayReflection else { return }
        updateTodayReflection(reflection)
    }
    
    // Get average mood for a date range
    func getAverageMoodRisk(from startDate: Date, to endDate: Date) -> Double {
        let filtered = moodEntries.filter { $0.date >= startDate && $0.date <= endDate }
        guard !filtered.isEmpty else { return 0.5 }
        
        let totalRisk = filtered.reduce(0.0) { $0 + $1.mood.regretRisk }
        return totalRisk / Double(filtered.count)
    }
    
    // Get mood pattern for a specific time of day
    func getMoodPattern(hour: Int) -> Double {
        let calendar = Calendar.current
        let filtered = moodEntries.filter {
            calendar.component(.hour, from: $0.date) == hour
        }
        guard !filtered.isEmpty else { return 0.5 }
        
        let totalRisk = filtered.reduce(0.0) { $0 + $1.mood.regretRisk }
        return totalRisk / Double(filtered.count)
    }
    
    // Get recent mood trend
    func getRecentMoodTrend(days: Int = 7) -> [MoodLevel] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recent = moodEntries.filter { $0.date >= cutoffDate }.sorted { $0.date < $1.date }
        return recent.map { $0.mood }
    }
}

