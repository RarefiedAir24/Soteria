//
//  ProductLinkService.swift
//  soteria
//
//  Service to extract product information (price, name) from e-commerce URLs
//  Supports:
//  - Standard e-commerce platforms (Amazon, Nike, Target, Walmart, etc.)
//  - Travel/booking sites (TripAdvisor, Expedia, Booking.com, Airbnb, etc.)
//  - ANY cart/checkout page (fashion, electronics, vacation packages, etc.)
//  Universal cart parsing works across all industries and cart types
//

import Foundation
import UIKit

struct ProductInfo {
    let name: String?
    let price: Double?
    let currency: String
    let imageUrl: String?
    let platform: String
    
    init(name: String? = nil, price: Double? = nil, currency: String = "USD", imageUrl: String? = nil, platform: String) {
        self.name = name
        self.price = price
        self.currency = currency
        self.imageUrl = imageUrl
        self.platform = platform
    }
}

enum ProductLinkError: LocalizedError {
    case invalidURL
    case unsupportedPlatform
    case priceNotFound
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unsupportedPlatform:
            return "This e-commerce platform is not yet supported"
        case .priceNotFound:
            return "Could not find price on this page. Make sure you're on a product page or cart page."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

class ProductLinkService {
    static let shared = ProductLinkService()
    
    private init() {}
    
    /// Extract product information from an e-commerce URL
    /// Works for:
    /// - Product pages (Amazon, Nike, Target, etc.)
    /// - Cart/checkout pages (ANY cart - fashion, travel, electronics, etc.)
    /// - Booking pages (TripAdvisor, Expedia, Airbnb, etc.)
    /// - Parameter urlString: The product or cart URL
    /// - Returns: ProductInfo with price, name, etc.
    func extractProductInfo(from urlString: String) async throws -> ProductInfo {
        guard let url = URL(string: urlString) else {
            throw ProductLinkError.invalidURL
        }
        
        // Detect platform
        let platform = detectPlatform(from: url)
        
        switch platform {
        case "amazon":
            return try await extractAmazonProductInfo(from: url)
        case "nike":
            return try await extractNikeProductInfo(from: url)
        case "target", "walmart", "bestbuy", "etsy":
            // Generic extraction for other platforms
            return try await extractGenericProductInfo(from: url, platform: platform)
        case "tripadvisor", "expedia", "booking", "airbnb", "priceline", "kayak", "hotels", "vrbo":
            // Travel/booking sites - extract from cart or booking page
            return try await extractTravelCartInfo(from: url, platform: platform)
        case "cart":
            // Universal cart parsing - works for ANY cart situation:
            // Fashion, electronics, travel packages, booking carts, etc.
            return try await extractCartInfo(from: url)
        case "unknown":
            // Try universal product page extraction for any unrecognized site
            // This handles product/item URLs from any e-commerce site
            return try await extractUniversalProductInfo(from: url)
        default:
            // Fallback: try universal extraction for any unrecognized platform
            return try await extractUniversalProductInfo(from: url)
        }
    }
    
    // MARK: - Platform Detection
    
    private func detectPlatform(from url: URL) -> String {
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        
        // Standard e-commerce
        if host.contains("amazon") {
            return "amazon"
        } else if host.contains("nike") {
            return "nike"
        } else if host.contains("target") {
            return "target"
        } else if host.contains("walmart") {
            return "walmart"
        } else if host.contains("bestbuy") {
            return "bestbuy"
        } else if host.contains("etsy") {
            return "etsy"
        }
        // Travel/Booking sites
        else if host.contains("tripadvisor") {
            return "tripadvisor"
        } else if host.contains("expedia") {
            return "expedia"
        } else if host.contains("booking.com") || host.contains("booking") {
            return "booking"
        } else if host.contains("airbnb") {
            return "airbnb"
        } else if host.contains("priceline") {
            return "priceline"
        } else if host.contains("kayak") {
            return "kayak"
        } else if host.contains("hotels.com") {
            return "hotels"
        } else if host.contains("vrbo") {
            return "vrbo"
        }
        // Cart detection (checkout, cart, booking pages) - works for ANY cart situation
        else if path.contains("cart") || 
                path.contains("checkout") || 
                path.contains("check-out") ||
                path.contains("booking") || 
                path.contains("reservation") ||
                path.contains("basket") ||
                path.contains("bag") ||
                path.contains("order") ||
                path.contains("payment") ||
                path.contains("review") ||
                path.contains("summary") {
            return "cart"
        }
        // Product/item page detection - if URL looks like a product page, try universal extraction
        // This handles any product URL, even from unknown sites
        else if path.contains("product") ||
                path.contains("item") ||
                path.contains("p/") ||
                path.contains("/dp/") ||
                path.contains("/d/") ||
                path.contains("/shop/") ||
                path.contains("/buy/") ||
                path.contains("/pdp/") ||
                path.contains("pid") ||
                path.contains("sku") ||
                path.contains("id=") {
            // Looks like a product page - will use universal extraction
            return "unknown"
        }
        
        // Unknown platform - will try universal extraction as fallback
        return "unknown"
    }
    
    // MARK: - Amazon Extraction
    
    private func extractAmazonProductInfo(from url: URL) async throws -> ProductInfo {
        // Fetch HTML
        let html = try await fetchHTML(from: url)
        
        // Extract price - Amazon has multiple price selectors
        var price: Double? = nil
        var name: String? = nil
        
        // Try different price selectors (Amazon changes these frequently)
        let pricePatterns = [
            #"data-asin-price="([^"]+)""#,
            #"priceToPay"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"a-price-whole">([\d,]+)"#,
            #"priceblock_ourprice"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"a-price[^>]*>\s*\$([\d,]+\.?\d*)"#,
            #"\"price\":\"([\d,]+\.?\d*)\""#
        ]
        
        for pattern in pricePatterns {
            if let match = html.range(of: pattern, options: .regularExpression) {
                let priceString = String(html[match])
                if let extractedPrice = extractPrice(from: priceString) {
                    price = extractedPrice
                    break
                }
            }
        }
        
        // Extract product name
        let namePatterns = [
            #"productTitle"[^>]*>([^<]+)"#,
            #"id=\"productTitle\">([^<]+)"#,
            #"\"title\":\"([^\"]+)\""#
        ]
        
        for pattern in namePatterns {
            if let match = html.range(of: pattern, options: .regularExpression) {
                let nameString = String(html[match])
                name = cleanProductName(nameString)
                break
            }
        }
        
        guard let extractedPrice = price else {
            throw ProductLinkError.priceNotFound
        }
        
        return ProductInfo(
            name: name,
            price: extractedPrice,
            currency: "USD",
            imageUrl: nil,
            platform: "Amazon"
        )
    }
    
    // MARK: - Nike Extraction
    
    private func extractNikeProductInfo(from url: URL) async throws -> ProductInfo {
        let html = try await fetchHTML(from: url)
        
        var price: Double? = nil
        var name: String? = nil
        
        // Nike price patterns
        let pricePatterns = [
            #"\"price\":\"([\d,]+\.?\d*)\""#,
            #"data-testid=\"product-price\">.*?\$([\d,]+\.?\d*)"#,
            #"product-price[^>]*>.*?\$([\d,]+\.?\d*)"#
        ]
        
        for pattern in pricePatterns {
            if let match = html.range(of: pattern, options: .regularExpression) {
                let priceString = String(html[match])
                if let extractedPrice = extractPrice(from: priceString) {
                    price = extractedPrice
                    break
                }
            }
        }
        
        // Nike name patterns
        let namePatterns = [
            #"data-testid=\"product-title\">([^<]+)"#,
            #"product-title[^>]*>([^<]+)"#
        ]
        
        for pattern in namePatterns {
            if let match = html.range(of: pattern, options: .regularExpression) {
                let nameString = String(html[match])
                name = cleanProductName(nameString)
                break
            }
        }
        
        guard let extractedPrice = price else {
            throw ProductLinkError.priceNotFound
        }
        
        return ProductInfo(
            name: name,
            price: extractedPrice,
            currency: "USD",
            imageUrl: nil,
            platform: "Nike"
        )
    }
    
    // MARK: - Generic Extraction
    
    private func extractGenericProductInfo(from url: URL, platform: String) async throws -> ProductInfo {
        let html = try await fetchHTML(from: url)
        
        var price: Double? = nil
        let name: String? = nil
        
        // Generic price patterns (JSON-LD, microdata, etc.)
        let pricePatterns = [
            #"\"price\":\"([\d,]+\.?\d*)\""#,
            #"\"price\":([\d,]+\.?\d*)"#,
            #"itemprop=\"price\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"price\"[^>]*>.*?\$([\d,]+\.?\d*)"#
        ]
        
        for pattern in pricePatterns {
            if let match = html.range(of: pattern, options: .regularExpression) {
                let priceString = String(html[match])
                if let extractedPrice = extractPrice(from: priceString) {
                    price = extractedPrice
                    break
                }
            }
        }
        
        guard let extractedPrice = price else {
            throw ProductLinkError.priceNotFound
        }
        
        return ProductInfo(
            name: name,
            price: extractedPrice,
            currency: "USD",
            imageUrl: nil,
            platform: platform.capitalized
        )
    }
    
    // MARK: - Travel/Booking Cart Extraction
    
    /// Extract total price from travel/booking cart pages (TripAdvisor, Expedia, etc.)
    /// Also works for any booking/reservation-based cart (hotels, flights, packages, etc.)
    private func extractTravelCartInfo(from url: URL, platform: String) async throws -> ProductInfo {
        let html = try await fetchHTML(from: url)
        
        var totalPrice: Double? = nil
        var name: String? = nil
        
        // Travel sites often show total price in cart/checkout
        // Look for common patterns: "Total", "Grand Total", "Total Price", etc.
        let totalPricePatterns = [
            // JSON-LD structured data
            #"\"totalPrice\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"price\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"amount\":\"?([\d,]+\.?\d*)\"?"#,
            // HTML patterns
            #"total[^>]*price[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"grand[^>]*total[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"total[^>]*amount[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"total\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"id=\"total\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            // TripAdvisor specific
            #"tripTotal[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"booking-total[^>]*>.*?\$([\d,]+\.?\d*)"#,
            // Expedia specific
            #"total-price[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"price-total[^>]*>.*?\$([\d,]+\.?\d*)"#,
            // Booking.com specific
            #"totalPrice[^>]*>.*?\$([\d,]+\.?\d*)"#,
            // Generic currency patterns (USD, EUR, etc.)
            #"total[^>]*>.*?([\d,]+\.?\d*)\s*(USD|EUR|GBP|\$)"#,
            #"([\d,]+\.?\d*)\s*(USD|EUR|GBP|\$)[^<]*total"#
        ]
        
        // Try all patterns, prefer the largest number (likely the total)
        var foundPrices: [Double] = []
        for pattern in totalPricePatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(html.startIndex..., in: html)
            regex?.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
                guard let match = match,
                      match.numberOfRanges > 1,
                      let priceRange = Range(match.range(at: 1), in: html) else {
                    return
                }
                let priceString = String(html[priceRange])
                if let price = extractPrice(from: priceString), price > 0 {
                    foundPrices.append(price)
                }
            }
        }
        
        // Use the largest price found (most likely the total)
        totalPrice = foundPrices.max()
        
        // Extract booking/trip name
        let namePatterns = [
            #"booking-title[^>]*>([^<]+)"#,
            #"trip-name[^>]*>([^<]+)"#,
            #"package-name[^>]*>([^<]+)"#,
            #"\"name\":\"([^\"]+)\""#,
            #"<title>([^<]+)</title>"#
        ]
        
        for pattern in namePatterns {
            if let match = html.range(of: pattern, options: .regularExpression) {
                let nameString = String(html[match])
                name = cleanProductName(nameString)
                if name != nil && !name!.isEmpty {
                    break
                }
            }
        }
        
        guard let extractedPrice = totalPrice else {
            throw ProductLinkError.priceNotFound
        }
        
        return ProductInfo(
            name: name ?? "Travel Package",
            price: extractedPrice,
            currency: "USD",
            imageUrl: nil,
            platform: platform.capitalized
        )
    }
    
    // MARK: - Generic Cart Extraction
    
    /// Extract total price from ANY cart/checkout page (fashion, travel, electronics, etc.)
    /// This is a comprehensive parser that works across all industries and cart types
    private func extractCartInfo(from url: URL) async throws -> ProductInfo {
        let html = try await fetchHTML(from: url)
        
        var totalPrice: Double? = nil
        var name: String? = nil
        
        // COMPREHENSIVE cart price patterns - works for ANY cart/checkout page
        let cartPricePatterns = [
            // JSON-LD structured data (most reliable)
            #"\"total\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"totalPrice\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"grandTotal\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"orderTotal\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"cartTotal\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"checkoutTotal\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"amount\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"price\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"value\":\"?([\d,]+\.?\d*)\"?"#,
            // Microdata schema.org
            #"itemprop=\"price\"[^>]*content=\"?([\d,]+\.?\d*)\"?"#,
            #"itemprop=\"totalPrice\"[^>]*content=\"?([\d,]+\.?\d*)\"?"#,
            // HTML class/id patterns (common across all e-commerce platforms)
            #"class=\"total\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"id=\"total\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"cart-total\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"checkout-total\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"grand-total\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"order-total\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"summary-total\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"final-total\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"total-price\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"total-amount\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            // Data attributes (common in modern e-commerce)
            #"data-total=\"([\d,]+\.?\d*)\""#,
            #"data-price=\"([\d,]+\.?\d*)\""#,
            #"data-amount=\"([\d,]+\.?\d*)\""#,
            #"data-value=\"([\d,]+\.?\d*)\""#,
            // Text-based patterns (works for any language/format)
            #"total[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"grand[^>]*total[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"order[^>]*total[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"final[^>]*total[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"subtotal[^>]*>.*?\$([\d,]+\.?\d*)"#,
            // Currency-agnostic patterns (USD, EUR, GBP, etc.)
            #"total[^>]*>.*?([\d,]+\.?\d*)\s*(USD|EUR|GBP|CAD|AUD|\$|€|£)"#,
            #"([\d,]+\.?\d*)\s*(USD|EUR|GBP|CAD|AUD|\$|€|£)[^<]*total"#,
            // Strong patterns (likely to be the actual total)
            #"pay[^>]*total[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"due[^>]*now[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"amount[^>]*due[^>]*>.*?\$([\d,]+\.?\d*)"#,
            // React/Vue component patterns
            #"totalPrice[^>]*:[\s]*([\d,]+\.?\d*)"#,
            #"totalAmount[^>]*:[\s]*([\d,]+\.?\d*)"#,
            // Hidden input fields (common in forms)
            #"<input[^>]*name=\"total\"[^>]*value=\"([\d,]+\.?\d*)\""#,
            #"<input[^>]*name=\"amount\"[^>]*value=\"([\d,]+\.?\d*)\""#,
            #"<input[^>]*name=\"price\"[^>]*value=\"([\d,]+\.?\d*)\""#
        ]
        
        var foundPrices: [Double] = []
        var priceContexts: [String] = [] // Track context to prefer "total" over "subtotal"
        
        for pattern in cartPricePatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(html.startIndex..., in: html)
            regex?.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
                guard let match = match,
                      match.numberOfRanges > 1,
                      let priceRange = Range(match.range(at: 1), in: html) else {
                    return
                }
                let priceString = String(html[priceRange])
                if let price = extractPrice(from: priceString), price > 0 {
                    foundPrices.append(price)
                    // Extract context (the full match) to help identify if it's a total vs subtotal
                    if let fullRange = Range(match.range, in: html) {
                        let context = String(html[fullRange]).lowercased()
                        priceContexts.append(context)
                    }
                }
            }
        }
        
        // Smart price selection: prefer "total" over "subtotal", prefer larger amounts
        if foundPrices.isEmpty {
            throw ProductLinkError.priceNotFound
        }
        
        // Filter out obvious subtotals and find the best total
        var candidatePrices: [(price: Double, isTotal: Bool)] = []
        for (index, price) in foundPrices.enumerated() {
            let context = index < priceContexts.count ? priceContexts[index] : ""
            let isTotal = context.contains("total") && !context.contains("subtotal")
            candidatePrices.append((price: price, isTotal: isTotal))
        }
        
        // Prefer prices marked as "total", then largest amount
        if let totalPriceValue = candidatePrices.first(where: { $0.isTotal })?.price {
            totalPrice = totalPriceValue
        } else {
            // No clear "total" found, use largest amount (most likely the total)
            totalPrice = foundPrices.max()
        }
        
        // Extract cart/order name from various sources
        let namePatterns = [
            #"<title>([^<]+)</title>"#,
            #"cart-title[^>]*>([^<]+)"#,
            #"order-title[^>]*>([^<]+)"#,
            #"checkout-title[^>]*>([^<]+)"#,
            #"\"name\":\"([^\"]+)\""#,
            #"\"title\":\"([^\"]+)\""#,
            #"itemprop=\"name\"[^>]*content=\"([^\"]+)\""#,
            #"class=\"product-name\"[^>]*>([^<]+)"#,
            #"class=\"item-name\"[^>]*>([^<]+)"#
        ]
        
        for pattern in namePatterns {
            if let match = html.range(of: pattern, options: .regularExpression) {
                let nameString = String(html[match])
                name = cleanProductName(nameString)
                if name != nil && !name!.isEmpty && name!.count > 3 {
                    break
                }
            }
        }
        
        guard let extractedPrice = totalPrice else {
            throw ProductLinkError.priceNotFound
        }
        
        // Clean up name - remove common cart page words
        if let cleanedName = name {
            let unwantedWords = ["cart", "checkout", "order", "shopping", "bag", "basket", "-", "|"]
            var finalName = cleanedName
            for word in unwantedWords {
                finalName = finalName.replacingOccurrences(of: word, with: "", options: .caseInsensitive)
            }
            name = finalName.trimmingCharacters(in: .whitespacesAndNewlines)
            if name!.isEmpty || name!.count < 3 {
                name = "Cart Total"
            }
        } else {
            name = "Cart Total"
        }
        
        return ProductInfo(
            name: name ?? "Cart Total",
            price: extractedPrice,
            currency: "USD",
            imageUrl: nil,
            platform: "Cart"
        )
    }
    
    // MARK: - Helper Methods
    
    private func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ProductLinkError.networkError("HTTP \(response)")
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                throw ProductLinkError.networkError("Invalid encoding")
            }
            
            return html
        } catch {
            throw ProductLinkError.networkError(error.localizedDescription)
        }
    }
    
    private func extractPrice(from string: String) -> Double? {
        // Remove all non-numeric characters except decimal point
        let cleaned = string.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        // Handle comma-separated numbers
        let withoutCommas = cleaned.replacingOccurrences(of: ",", with: "")
        
        return Double(withoutCommas)
    }
    
    private func cleanProductName(_ name: String) -> String {
        // Remove HTML tags and extra whitespace
        var cleaned = name
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Limit length
        if cleaned.count > 100 {
            cleaned = String(cleaned.prefix(100)) + "..."
        }
        
        return cleaned
    }
    
    // MARK: - Savings Calculations
    
    /// Calculate required savings per day for different timeframes
    func calculateSavingsRequirements(price: Double, days: [Int] = [30, 60, 90]) -> [Int: Double] {
        var requirements: [Int: Double] = [:]
        
        for dayCount in days {
            requirements[dayCount] = price / Double(dayCount)
        }
        
        return requirements
    }
    
    /// Calculate required savings per day for a custom target date
    func calculateSavingsForTargetDate(price: Double, targetDate: Date, startDate: Date = Date()) -> Double {
        let calendar = Calendar.current
        guard let days = calendar.dateComponents([.day], from: startDate, to: targetDate).day,
              days > 0 else {
            return price / 30.0 // Default to 30 days if invalid
        }
        
        return price / Double(days)
    }
    
    // MARK: - Universal Product Page Extraction
    
    /// Extract product information from ANY product/item page URL
    /// This is a comprehensive fallback that works for any e-commerce site
    /// Handles product pages, item pages, and any URL that might contain product info
    private func extractUniversalProductInfo(from url: URL) async throws -> ProductInfo {
        let html = try await fetchHTML(from: url)
        
        var price: Double? = nil
        var name: String? = nil
        
        // COMPREHENSIVE product price patterns - works for ANY product page
        let productPricePatterns = [
            // JSON-LD structured data (most reliable, works across all sites)
            #"\"price\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"price\":([\d,]+\.?\d*)"#,
            #"\"@type\":\"Product\"[^}]*\"price\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"offers\":[^}]*\"price\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"lowPrice\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"highPrice\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"amount\":\"?([\d,]+\.?\d*)\"?"#,
            #"\"value\":\"?([\d,]+\.?\d*)\"?"#,
            // Microdata schema.org (Product schema)
            #"itemprop=\"price\"[^>]*content=\"?([\d,]+\.?\d*)\"?"#,
            #"itemprop=\"price\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"itemprop=\"lowPrice\"[^>]*content=\"?([\d,]+\.?\d*)\"?"#,
            #"itemprop=\"highPrice\"[^>]*content=\"?([\d,]+\.?\d*)\"?"#,
            // HTML class/id patterns (common across all e-commerce)
            #"class=\"price\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"id=\"price\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"product-price\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"item-price\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"sale-price\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"current-price\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"final-price\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"price-current\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            #"class=\"price-value\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            // Data attributes
            #"data-price=\"([\d,]+\.?\d*)\""#,
            #"data-amount=\"([\d,]+\.?\d*)\""#,
            #"data-value=\"([\d,]+\.?\d*)\""#,
            #"data-product-price=\"([\d,]+\.?\d*)\""#,
            // Text patterns (currency symbols) - be careful with this one
            #"<span[^>]*class=\"[^\"]*price[^\"]*\"[^>]*>.*?\$([\d,]+\.?\d*)"#,
            // Currency-agnostic patterns
            #"([\d,]+\.?\d*)\s*(USD|EUR|GBP|CAD|AUD)"#,
            // Meta tags
            #"<meta[^>]*property=\"product:price:amount\"[^>]*content=\"([\d,]+\.?\d*)\""#,
            #"<meta[^>]*name=\"price\"[^>]*content=\"([\d,]+\.?\d*)\""#,
            // Hidden inputs
            #"<input[^>]*name=\"price\"[^>]*value=\"([\d,]+\.?\d*)\""#,
            #"<input[^>]*name=\"amount\"[^>]*value=\"([\d,]+\.?\d*)\""#
        ]
        
        var foundPrices: [Double] = []
        for pattern in productPricePatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(html.startIndex..., in: html)
            regex?.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
                guard let match = match,
                      match.numberOfRanges > 1,
                      let priceRange = Range(match.range(at: 1), in: html) else {
                    return
                }
                let priceString = String(html[priceRange])
                if let extractedPrice = extractPrice(from: priceString), extractedPrice > 0 {
                    // Filter out obviously wrong prices (too small or too large)
                    if extractedPrice >= 0.01 && extractedPrice <= 1000000 {
                        foundPrices.append(extractedPrice)
                    }
                }
            }
        }
        
        // Use the most common price (likely the actual product price)
        // If multiple prices found, use median to avoid outliers
        if foundPrices.isEmpty {
            throw ProductLinkError.priceNotFound
        }
        
        // Remove outliers and use median
        let sortedPrices = foundPrices.sorted()
        let medianIndex = sortedPrices.count / 2
        price = sortedPrices[medianIndex] // Use median to avoid outliers
        
        // Extract product name from various sources
        let namePatterns = [
            #"<title>([^<]+)</title>"#,
            #"\"name\":\"([^\"]+)\""#,
            #"\"title\":\"([^\"]+)\""#,
            #"itemprop=\"name\"[^>]*content=\"([^\"]+)\""#,
            #"itemprop=\"name\"[^>]*>([^<]+)"#,
            #"class=\"product-name\"[^>]*>([^<]+)"#,
            #"class=\"item-name\"[^>]*>([^<]+)"#,
            #"class=\"product-title\"[^>]*>([^<]+)"#,
            #"class=\"item-title\"[^>]*>([^<]+)"#,
            #"<h1[^>]*>([^<]+)</h1>"#,
            #"<meta[^>]*property=\"og:title\"[^>]*content=\"([^\"]+)\""#,
            #"<meta[^>]*name=\"title\"[^>]*content=\"([^\"]+)\""#
        ]
        
        for pattern in namePatterns {
            if let match = html.range(of: pattern, options: .regularExpression) {
                let nameString = String(html[match])
                name = cleanProductName(nameString)
                if name != nil && !name!.isEmpty && name!.count > 3 {
                    break
                }
            }
        }
        
        guard let extractedPrice = price else {
            throw ProductLinkError.priceNotFound
        }
        
        // Clean up name
        if let cleanedName = name {
            let unwantedWords = ["|", " - ", "–", "—", "Home", "Shop", "Store", "Buy", "Online"]
            var finalName = cleanedName
            for word in unwantedWords {
                finalName = finalName.replacingOccurrences(of: word, with: " ", options: .caseInsensitive)
            }
            name = finalName.trimmingCharacters(in: .whitespacesAndNewlines)
            if name!.isEmpty || name!.count < 3 {
                name = "Product"
            }
        } else {
            name = "Product"
        }
        
        // Extract platform name from URL
        let platformName = url.host?.replacingOccurrences(of: "www.", with: "").capitalized ?? "Product"
        
        return ProductInfo(
            name: name ?? "Product",
            price: extractedPrice,
            currency: "USD",
            imageUrl: nil,
            platform: platformName
        )
    }
}

