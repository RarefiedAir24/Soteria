//
//  View+Responsive.swift
//  soteria
//
//  Responsive sizing utilities for different screen sizes
//

import SwiftUI

// Helper to safely get screen bounds
private func getScreenBounds() -> CGRect {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        return window.bounds
    }
    // Fallback to UIScreen.main (deprecated but safe for iOS 15+)
    return UIScreen.main.bounds
}

extension View {
    /// Returns a responsive font size based on screen height
    /// - Parameters:
    ///   - large: Font size for large screens (iPhone Pro Max, etc.)
    ///   - medium: Font size for medium screens (iPhone Pro, etc.)
    ///   - small: Font size for small screens (iPhone SE, etc.)
    func responsiveFont(large: CGFloat, medium: CGFloat? = nil, small: CGFloat? = nil) -> CGFloat {
        let screenHeight = getScreenBounds().height
        let mediumSize = medium ?? large * 0.9
        let smallSize = small ?? mediumSize * 0.9
        
        // iPhone Pro Max and larger: 926+ points
        if screenHeight >= 926 {
            return large
        }
        // iPhone Pro and standard: 844-925 points
        else if screenHeight >= 844 {
            return mediumSize
        }
        // iPhone SE and smaller: < 844 points
        else {
            return smallSize
        }
    }
    
    /// Returns responsive padding based on screen height
    /// - Parameters:
    ///   - large: Padding for large screens
    ///   - medium: Padding for medium screens (defaults to large * 0.85)
    ///   - small: Padding for small screens (defaults to medium * 0.85)
    func responsivePadding(large: CGFloat, medium: CGFloat? = nil, small: CGFloat? = nil) -> CGFloat {
        let screenHeight = getScreenBounds().height
        let mediumPadding = medium ?? large * 0.85
        let smallPadding = small ?? mediumPadding * 0.85
        
        if screenHeight >= 926 {
            return large
        } else if screenHeight >= 844 {
            return mediumPadding
        } else {
            return smallPadding
        }
    }
    
    /// Returns responsive spacing based on screen height
    func responsiveSpacing(large: CGFloat, medium: CGFloat? = nil, small: CGFloat? = nil) -> CGFloat {
        return responsivePadding(large: large, medium: medium, small: small)
    }
}

// MARK: - Responsive Size Helper
struct ResponsiveSize {
    static var screenHeight: CGFloat {
        getScreenBounds().height
    }
    
    static var isSmallScreen: Bool {
        screenHeight < 844 // iPhone SE, iPhone 8, etc.
    }
    
    static var isMediumScreen: Bool {
        screenHeight >= 844 && screenHeight < 926 // iPhone Pro, iPhone 14, etc.
    }
    
    static var isLargeScreen: Bool {
        screenHeight >= 926 // iPhone Pro Max, etc.
    }
    
    /// Get responsive font size
    static func font(large: CGFloat, medium: CGFloat? = nil, small: CGFloat? = nil) -> CGFloat {
        let mediumSize = medium ?? large * 0.9
        let smallSize = small ?? mediumSize * 0.9
        
        if isLargeScreen {
            return large
        } else if isMediumScreen {
            return mediumSize
        } else {
            return smallSize
        }
    }
    
    /// Get responsive padding
    static func padding(large: CGFloat, medium: CGFloat? = nil, small: CGFloat? = nil) -> CGFloat {
        let mediumPadding = medium ?? large * 0.85
        let smallPadding = small ?? mediumPadding * 0.85
        
        if isLargeScreen {
            return large
        } else if isMediumScreen {
            return mediumPadding
        } else {
            return smallPadding
        }
    }
    
    /// Get responsive spacing
    static func spacing(large: CGFloat, medium: CGFloat? = nil, small: CGFloat? = nil) -> CGFloat {
        return padding(large: large, medium: medium, small: small)
    }
}

