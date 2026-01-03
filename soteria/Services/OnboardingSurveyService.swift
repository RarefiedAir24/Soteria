//
//  OnboardingSurveyService.swift
//  soteria
//
//  Stores user onboarding survey responses
//

import Foundation
import Combine

class OnboardingSurveyService: ObservableObject {
    static let shared: OnboardingSurveyService = {
        // CRITICAL: Don't access StartupDiagnostics.shared during initialization
        // This blocks MainActor even if the service is accessed lazily
        // All logging is deferred to prevent blocking
        let service = OnboardingSurveyService()
        // StartupDiagnostics.shared.logServiceAccess("OnboardingSurveyService", startTime: startTime)
        return service
    }()
    
    @Published var hasCompletedSurvey: Bool = false
    
    // Survey responses
    @Published var shopsOnline: Bool = false
    @Published var estimatedDailySpending: Double = 0.0
    @Published var estimatedWeeklySpending: Double = 0.0
    @Published var savingChallenges: [String] = [] // Changed to array to support multiple selections (up to 3)
    @Published var reminderWouldHelp: Bool = false
    @Published var comfortableDailySavings: Double = 0.0
    
    private let hasCompletedSurveyKey = "has_completed_onboarding_survey"
    private let shopsOnlineKey = "onboarding_shops_online"
    private let estimatedDailySpendingKey = "onboarding_estimated_daily_spending"
    private let estimatedWeeklySpendingKey = "onboarding_estimated_weekly_spending"
    private let savingChallengeKey = "onboarding_saving_challenge"
    private let reminderWouldHelpKey = "onboarding_reminder_would_help"
    private let comfortableDailySavingsKey = "onboarding_comfortable_daily_savings"
    
    private init() {
        // Load survey data immediately on init (UserDefaults reads are fast and non-blocking)
        // This ensures hasCompletedSurvey is set correctly for navigation decisions
        loadSurveyData()
    }
    
    private var hasInitialized = false
    
    func startInitialization() {
        guard !hasInitialized else { return }
        hasInitialized = true
        // Data already loaded in init(), but this method is kept for consistency
        loadSurveyData()
    }
    
    func loadSurveyData() {
        hasCompletedSurvey = UserDefaults.standard.bool(forKey: hasCompletedSurveyKey)
        shopsOnline = UserDefaults.standard.bool(forKey: shopsOnlineKey)
        estimatedDailySpending = UserDefaults.standard.double(forKey: estimatedDailySpendingKey)
        estimatedWeeklySpending = UserDefaults.standard.double(forKey: estimatedWeeklySpendingKey)
        // Load challenges as array (comma-separated string for backward compatibility)
        if let challengeString = UserDefaults.standard.string(forKey: savingChallengeKey), !challengeString.isEmpty {
            savingChallenges = challengeString.components(separatedBy: "|")
        } else {
            savingChallenges = []
        }
        reminderWouldHelp = UserDefaults.standard.bool(forKey: reminderWouldHelpKey)
        comfortableDailySavings = UserDefaults.standard.double(forKey: comfortableDailySavingsKey)
    }
    
    func saveSurveyData() {
        UserDefaults.standard.set(hasCompletedSurvey, forKey: hasCompletedSurveyKey)
        UserDefaults.standard.set(shopsOnline, forKey: shopsOnlineKey)
        UserDefaults.standard.set(estimatedDailySpending, forKey: estimatedDailySpendingKey)
        UserDefaults.standard.set(estimatedWeeklySpending, forKey: estimatedWeeklySpendingKey)
        // Save challenges as pipe-separated string
        UserDefaults.standard.set(savingChallenges.joined(separator: "|"), forKey: savingChallengeKey)
        UserDefaults.standard.set(reminderWouldHelp, forKey: reminderWouldHelpKey)
        UserDefaults.standard.set(comfortableDailySavings, forKey: comfortableDailySavingsKey)
    }
    
    func completeSurvey() {
        hasCompletedSurvey = true
        saveSurveyData()
        
        // NOTE: Auto-configure savings reminders removed - SavingsReminderService removed (functionality consolidated into Decision Notifications)
        // Users can now set up Decision Notifications manually if they want reminders
    }
    
    // Update survey data without resetting completion flag (for editing after completion)
    func updateSurveyData(
        shopsOnline: Bool,
        estimatedDailySpending: Double,
        estimatedWeeklySpending: Double,
        savingChallenges: [String],
        reminderWouldHelp: Bool,
        comfortableDailySavings: Double
    ) {
        self.shopsOnline = shopsOnline
        self.estimatedDailySpending = estimatedDailySpending
        self.estimatedWeeklySpending = estimatedWeeklySpending
        self.savingChallenges = savingChallenges
        self.reminderWouldHelp = reminderWouldHelp
        self.comfortableDailySavings = comfortableDailySavings
        
        // Save updated data (completion flag remains true)
        saveSurveyData()
        
        // NOTE: configureSavingsFromSurvey removed - SavingsReminderService removed (functionality consolidated into Decision Notifications)
    }
    
    // NOTE: configureSavingsFromSurvey removed - SavingsReminderService removed (functionality consolidated into Decision Notifications)
    // Users can now set up Decision Notifications manually if they want reminders
}

