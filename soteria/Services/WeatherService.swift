//
//  WeatherService.swift
//  soteria
//
//  Service to fetch current weather for user's location
//

import Foundation
import CoreLocation
import Combine
import SwiftUI

class WeatherService: NSObject, ObservableObject {
    static let shared = WeatherService()
    
    @Published var currentWeather: WeatherData? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let locationManager = CLLocationManager()
    private var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Lower accuracy for weather (saves battery)
    }
    
    // Request location permission and fetch weather
    func requestWeather() {
        locationAuthorizationStatus = locationManager.authorizationStatus
        
        switch locationAuthorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Location permission denied. Weather features unavailable."
        @unknown default:
            errorMessage = "Unknown location authorization status"
        }
    }
    
    // Fetch weather for given coordinates
    private func fetchWeather(latitude: Double, longitude: Double) {
        isLoading = true
        errorMessage = nil
        
        // Using wttr.in API (free, no API key required)
        // Format: https://wttr.in/{lat},{lon}?format=j1
        let urlString = "https://wttr.in/\(latitude),\(longitude)?format=j1"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            errorMessage = "Invalid weather API URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
                    print("⚠️ [WeatherService] Error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No weather data received"
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let current = json?["current_condition"] as? [[String: Any]]
                    
                    guard let condition = current?.first else {
                        self?.errorMessage = "Invalid weather data format"
                        return
                    }
                    
                    let tempC = condition["temp_C"] as? String ?? "0"
                    let conditionCode = condition["weatherCode"] as? String ?? "113" // Default: clear
                    let description = (condition["weatherDesc"] as? [[String: Any]])?.first?["value"] as? String ?? "Clear"
                    
                    self?.currentWeather = WeatherData(
                        temperature: Double(tempC) ?? 0,
                        conditionCode: conditionCode,
                        description: description
                    )
                    
                    print("✅ [WeatherService] Weather fetched: \(description), \(tempC)°C")
                } catch {
                    self?.errorMessage = "Failed to parse weather data: \(error.localizedDescription)"
                    print("⚠️ [WeatherService] Parse error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

// MARK: - CLLocationManagerDelegate
extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "Location error: \(error.localizedDescription)"
            print("⚠️ [WeatherService] Location error: \(error.localizedDescription)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
        
        switch locationAuthorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Location permission denied"
        default:
            break
        }
    }
}

// MARK: - Weather Data Model
struct WeatherData {
    let temperature: Double // Celsius
    let conditionCode: String // Weather code from API
    let description: String // Human-readable description
    
    // Map weather codes to visual themes
    var theme: WeatherTheme {
        let code = Int(conditionCode) ?? 113
        
        // Clear/Sunny
        if code == 113 {
            return .sunny
        }
        // Partly cloudy
        else if code >= 116 && code <= 119 {
            return .partlyCloudy
        }
        // Cloudy
        else if code >= 122 && code <= 143 {
            return .cloudy
        }
        // Rain
        else if code >= 176 && code <= 185 || code >= 263 && code <= 281 || code >= 293 && code <= 299 {
            return .rainy
        }
        // Snow
        else if code >= 179 && code <= 182 || code >= 227 && code <= 230 || code >= 320 && code <= 335 {
            return .snowy
        }
        // Storm
        else if code >= 200 && code <= 232 {
            return .stormy
        }
        // Fog
        else if code >= 248 && code <= 260 {
            return .foggy
        }
        // Default to sunny
        else {
            return .sunny
        }
    }
}

enum WeatherTheme {
    case sunny
    case partlyCloudy
    case cloudy
    case rainy
    case snowy
    case stormy
    case foggy
    
    var gradientColors: [Color] {
        switch self {
        case .sunny:
            return [
                Color(red: 0.95, green: 0.85, blue: 0.6), // Warm yellow
                Color(red: 0.9, green: 0.75, blue: 0.5)   // Golden
            ]
        case .partlyCloudy:
            return [
                Color(red: 0.85, green: 0.85, blue: 0.9), // Light gray-blue
                Color(red: 0.75, green: 0.8, blue: 0.85)   // Soft blue-gray
            ]
        case .cloudy:
            return [
                Color(red: 0.7, green: 0.75, blue: 0.8),   // Gray-blue
                Color(red: 0.6, green: 0.65, blue: 0.7)    // Darker gray
            ]
        case .rainy:
            return [
                Color(red: 0.6, green: 0.7, blue: 0.8),    // Blue-gray
                Color(red: 0.5, green: 0.6, blue: 0.75)    // Darker blue-gray
            ]
        case .snowy:
            return [
                Color(red: 0.9, green: 0.9, blue: 0.95),   // Light blue-white
                Color(red: 0.8, green: 0.85, blue: 0.9)   // Soft blue-gray
            ]
        case .stormy:
            return [
                Color(red: 0.5, green: 0.55, blue: 0.6),   // Dark gray
                Color(red: 0.4, green: 0.45, blue: 0.5)    // Darker gray
            ]
        case .foggy:
            return [
                Color(red: 0.75, green: 0.75, blue: 0.8),  // Light gray
                Color(red: 0.65, green: 0.65, blue: 0.7)  // Medium gray
            ]
        }
    }
    
    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .stormy: return "cloud.bolt.fill"
        case .foggy: return "cloud.fog.fill"
        }
    }
}

