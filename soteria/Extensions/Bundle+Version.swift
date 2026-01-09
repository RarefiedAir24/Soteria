//
//  Bundle+Version.swift
//  soteria
//
//  Extension to get app version and build number from bundle
//

import Foundation

extension Bundle {
    /// Get the marketing version (e.g., "1.0")
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Get the build number (e.g., "2")
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    /// Get the full version string (e.g., "1.0 (2)")
    static var fullVersionString: String {
        "\(appVersion) (\(buildNumber))"
    }
    
    /// Get version for display (e.g., "v1.0 (2)")
    static var displayVersionString: String {
        "v\(appVersion) (\(buildNumber))"
    }
}

