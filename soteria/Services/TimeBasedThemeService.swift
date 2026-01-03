//
//  TimeBasedThemeService.swift
//  soteria
//
//  Service to provide dynamic time-based themes for the money tree background
//

import Foundation
import SwiftUI
import Combine
import UIKit

class TimeBasedThemeService: ObservableObject {
    static let shared = TimeBasedThemeService()
    
    @Published var currentTheme: TimeTheme = .afternoon
    @Published var currentGradient: [Color] = []
    
    private var themeUpdateTimer: Timer?
    
    private init() {
        // Initialize with current theme
        updateTheme()
        // Ensure gradient is set even if theme didn't change
        if currentGradient.isEmpty {
            currentGradient = currentTheme.gradientColors
        }
        startThemeMonitoring()
    }
    
    deinit {
        themeUpdateTimer?.invalidate()
    }
    
    // Update theme based on current time
    func updateTheme() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        let newTheme: TimeTheme
        switch hour {
        case 5..<7:
            newTheme = .dawn
        case 7..<12:
            newTheme = .morning
        case 12..<17:
            newTheme = .afternoon
        case 17..<19:
            newTheme = .evening
        case 19..<21:
            newTheme = .sunset
        default: // 21-5 (9pm to 5am)
            newTheme = .night
        }
        
        if newTheme != currentTheme {
            currentTheme = newTheme
            currentGradient = newTheme.gradientColors
            print("🌅 [TimeBasedThemeService] Theme updated to: \(newTheme.name) (hour: \(hour))")
        } else {
            currentGradient = newTheme.gradientColors
        }
    }
    
    // Monitor time changes and update theme accordingly
    private func startThemeMonitoring() {
        // Update immediately
        updateTheme()
        
        // Update every hour to catch theme transitions
        themeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { [weak self] _ in
            self?.updateTheme()
        }
        
        // Also update when app becomes active (in case user was away for a while)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTheme()
        }
    }
}

// MARK: - Time Theme Enum
enum TimeTheme: String {
    case dawn
    case morning
    case afternoon
    case evening
    case sunset
    case night
    
    var name: String {
        switch self {
        case .dawn: return "Dawn"
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .sunset: return "Sunset"
        case .night: return "Night"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .dawn:
            // Soft pink and orange sunrise
            return [
                Color(red: 1.0, green: 0.85, blue: 0.75),  // Soft peach
                Color(red: 0.95, green: 0.7, blue: 0.6),  // Warm pink-orange
                Color(red: 0.9, green: 0.65, blue: 0.55)  // Deeper coral
            ]
        case .morning:
            // Bright, fresh morning sky
            return [
                Color(red: 0.95, green: 0.9, blue: 0.85), // Light cream
                Color(red: 0.85, green: 0.9, blue: 0.95), // Soft sky blue
                Color(red: 0.75, green: 0.85, blue: 0.95)  // Light blue
            ]
        case .afternoon:
            // Clear, vibrant daytime
            return [
                Color(red: 0.9, green: 0.95, blue: 1.0),  // Bright sky blue
                Color(red: 0.8, green: 0.9, blue: 0.98),  // Clear blue
                Color(red: 0.7, green: 0.85, blue: 0.95)  // Deeper blue
            ]
        case .evening:
            // Warm, golden afternoon
            return [
                Color(red: 0.95, green: 0.88, blue: 0.75), // Warm gold
                Color(red: 0.9, green: 0.8, blue: 0.65),   // Golden yellow
                Color(red: 0.85, green: 0.75, blue: 0.6)   // Amber
            ]
        case .sunset:
            // Rich sunset colors
            return [
                Color(red: 1.0, green: 0.75, blue: 0.6),  // Bright orange
                Color(red: 0.95, green: 0.65, blue: 0.55), // Coral
                Color(red: 0.85, green: 0.55, blue: 0.5)   // Deep rose
            ]
        case .night:
            // Deep, peaceful night - darker with more contrast for moon/stars visibility
            return [
                Color(red: 0.12, green: 0.15, blue: 0.22),  // Dark blue-gray
                Color(red: 0.08, green: 0.1, blue: 0.18),   // Darker blue-gray
                Color(red: 0.05, green: 0.07, blue: 0.12)   // Very dark navy
            ]
        }
    }
    
    var icon: String {
        switch self {
        case .dawn: return "sunrise.fill"
        case .morning: return "sun.max.fill"
        case .afternoon: return "sun.max.circle.fill"
        case .evening: return "sun.horizon.fill"
        case .sunset: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }
    
    // Visual elements for each theme
    var hasSun: Bool {
        switch self {
        case .dawn, .morning, .afternoon, .evening, .sunset: return true
        case .night: return false
        }
    }
    
    var hasMoon: Bool {
        switch self {
        case .night: return true
        default: return false
        }
    }
    
    var hasClouds: Bool {
        switch self {
        case .dawn, .morning, .afternoon, .evening: return true
        case .sunset, .night: return false
        }
    }
    
    var hasStars: Bool {
        switch self {
        case .night: return true
        default: return false
        }
    }
    
    var sunPosition: (x: CGFloat, y: CGFloat) {
        switch self {
        case .dawn: return (0.15, 0.25) // Upper left, low on horizon
        case .morning: return (0.25, 0.2) // Upper left, rising
        case .afternoon: return (0.5, 0.15) // Top center, high in sky
        case .evening: return (0.75, 0.2) // Upper right, setting
        case .sunset: return (0.85, 0.25) // Upper right, low setting
        case .night: return (0, 0) // Not visible
        }
    }
    
    var moonPosition: (x: CGFloat, y: CGFloat) {
        switch self {
        case .night: return (0.85, 0.2) // Upper right corner
        default: return (0, 0) // Not visible
        }
    }
}

