//
//  PartnerLoyaltyView.swift
//  soteria
//
//  View for displaying available partner loyalty benefits
//

import SwiftUI

struct PartnerLoyaltyView: View {
    @ObservedObject private var partnerService = PartnerLoyaltyService.shared
    @State private var selectedCategory: String? = nil
    @State private var selectedLocation: String? = nil
    @State private var flippedPartnerId: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.cloudWhite
                    .ignoresSafeArea()
                
                if partnerService.isLoading && partnerService.partners.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .softGraphite))
                            .scaleEffect(1.2)
                        Text("Loading partner benefits...")
                            .font(.system(size: 16))
                            .foregroundColor(.softGraphite)
                    }
                } else if partnerService.partners.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.softGraphite.opacity(0.5))
                        
                        Text("No Partner Benefits Available")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("Check back soon for exclusive loyalty benefits and savings opportunities!")
                            .font(.system(size: 15))
                            .foregroundColor(.softGraphite)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .lineSpacing(4)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Partner Benefits")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.midnightSlate)
                                
                                Text("Exclusive savings and loyalty rewards from our partners")
                                    .font(.system(size: 15))
                                    .foregroundColor(.softGraphite)
                                    .lineSpacing(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Filter chips
                            if !availableCategories.isEmpty || !availableLocations.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        if !availableCategories.isEmpty {
                                            Menu {
                                                Button("All Categories") {
                                                    selectedCategory = nil
                                                }
                                                ForEach(availableCategories, id: \.self) { category in
                                                    Button(category) {
                                                        selectedCategory = category
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "tag.fill")
                                                        .font(.system(size: 12))
                                                    Text(selectedCategory ?? "All Categories")
                                                        .font(.system(size: 14, weight: .medium))
                                                }
                                                .foregroundColor(.softGraphite)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.softGraphite.opacity(0.1))
                                                .cornerRadius(20)
                                            }
                                        }
                                        
                                        if !availableLocations.isEmpty {
                                            Menu {
                                                Button("All Locations") {
                                                    selectedLocation = nil
                                                }
                                                ForEach(availableLocations, id: \.self) { location in
                                                    Button(location) {
                                                        selectedLocation = location
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "location.fill")
                                                        .font(.system(size: 12))
                                                    Text(selectedLocation ?? "All Locations")
                                                        .font(.system(size: 14, weight: .medium))
                                                }
                                                .foregroundColor(.softGraphite)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.softGraphite.opacity(0.1))
                                                .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            // Partner cards
                            ForEach(filteredPartners) { partner in
                                FlipPartnerCard(
                                    partner: partner,
                                    isFlipped: flippedPartnerId == partner.partnerId,
                                    onTap: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            if flippedPartnerId == partner.partnerId {
                                                flippedPartnerId = nil
                                            } else {
                                                flippedPartnerId = partner.partnerId
                                            }
                                        }
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                            
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await partnerService.loadPartners(category: selectedCategory, location: selectedLocation)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.softGraphite)
                    }
                }
            }
            .task {
                if partnerService.partners.isEmpty {
                    await partnerService.loadPartners()
                }
            }
            .alert("Error", isPresented: Binding(
                get: { partnerService.errorMessage != nil },
                set: { if !$0 { partnerService.errorMessage = nil } }
            )) {
                Button("OK") {
                    partnerService.errorMessage = nil
                }
            } message: {
                if let error = partnerService.errorMessage {
                    Text(error)
                } else {
                    Text("An error occurred")
                }
            }
        }
    }
    
    private var filteredPartners: [Partner] {
        var filtered = partnerService.partners
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let location = selectedLocation {
            filtered = filtered.filter { $0.location == location }
        }
        
        return filtered
    }
    
    private var availableCategories: [String] {
        Array(Set(partnerService.partners.compactMap { $0.category })).sorted()
    }
    
    private var availableLocations: [String] {
        Array(Set(partnerService.partners.compactMap { $0.location })).sorted()
    }
}

struct FlipPartnerCard: View {
    let partner: Partner
    let isFlipped: Bool
    let onTap: () -> Void
    
    private var isActive: Bool {
        guard let validUntil = partner.validUntil else { return partner.isActive }
        return partner.isActive && validUntil > Date()
    }
    
    private var daysRemaining: Int? {
        guard let validUntil = partner.validUntil else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: validUntil)
        return components.day
    }
    
    private var formattedValidUntil: String? {
        guard let validUntil = partner.validUntil else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: validUntil)
    }
    
    private var hasBrickAndMortar: Bool {
        partner.hasBrickAndMortar ?? (partner.location != nil && !partner.location!.isEmpty)
    }
    
    var body: some View {
        ZStack {
            // Front of card
            if !isFlipped {
                CardFront(partner: partner, isActive: isActive, daysRemaining: daysRemaining, formattedValidUntil: formattedValidUntil)
                    .rotation3DEffect(.degrees(0), axis: (x: 0, y: 1, z: 0))
                    .opacity(isFlipped ? 0 : 1)
            }
            
            // Back of card
            if isFlipped {
                CardBack(partner: partner, hasBrickAndMortar: hasBrickAndMortar, isActive: isActive)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(isFlipped ? 1 : 0)
            }
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct CardFront: View {
    let partner: Partner
    let isActive: Bool
    let daysRemaining: Int?
    let formattedValidUntil: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row with logo
            HStack(alignment: .top, spacing: 16) {
                // Partner logo (if available)
                if let logoUrl = partner.logoUrl, !logoUrl.isEmpty {
                    AsyncImage(url: URL(string: logoUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 60, height: 60)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.softGraphite.opacity(0.1), lineWidth: 1)
                                )
                        case .failure:
                            // Fallback to icon if image fails to load
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.softGraphite.opacity(0.5))
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.softGraphite.opacity(0.1))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Default icon when no logo
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.softGraphite.opacity(0.5))
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.softGraphite.opacity(0.1))
                        )
                }
                
                // Partner info
                VStack(alignment: .leading, spacing: 8) {
                    // Partner name - full width now
                    Text(partner.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.midnightSlate)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    if let description = partner.description {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                            .lineLimit(3)
                    }
                    
                    // Category and location tags
                    HStack(spacing: 12) {
                        if let category = partner.category {
                            Label(category, systemImage: "tag.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.softGraphite)
                        }
                        
                        if let location = partner.location {
                            Label(location, systemImage: "location.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.softGraphite)
                        }
                    }
                }
                
                Spacer()
                
                // Benefit badge
                VStack(alignment: .center, spacing: 4) {
                    if let percentage = partner.loyaltyPercentage {
                        Text("\(Int(percentage))%")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.softGraphite)
                        Text("OFF")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.softGraphite)
                            .tracking(1)
                    } else if let amount = partner.loyaltyAmount {
                        Text("$\(String(format: "%.0f", amount))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.softGraphite)
                        Text("OFF")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.softGraphite)
                            .tracking(1)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.softGraphite.opacity(0.1))
                )
            }
            
            // Active dates and key info
            VStack(alignment: .leading, spacing: 8) {
                if let validUntil = formattedValidUntil {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                        Text("Valid until: \(validUntil)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.softGraphite)
                            
                        if let days = daysRemaining, days > 0 {
                            Text("(\(days) days left)")
                                .font(.system(size: 13))
                                .foregroundColor(.softGraphite.opacity(0.7))
                        }
                    }
                }
                
                if let maxRedemptions = partner.maxRedemptionsPerUser {
                    HStack(spacing: 8) {
                        Image(systemName: "number.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                        Text("Max \(maxRedemptions) redemption\(maxRedemptions == 1 ? "" : "s") per user")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                    }
                }
            }
            .padding(.top, 8)
            
            // Tap to flip hint
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11))
                    Text("Tap to view details")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.softGraphite.opacity(0.6))
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(
            ZStack {
                // Titanium/metallic card background with premium gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: isActive ? [
                                Color(red: 0.95, green: 0.95, blue: 0.97),
                                Color(red: 0.92, green: 0.92, blue: 0.94),
                                Color(red: 0.88, green: 0.88, blue: 0.90)
                            ] : [
                                // Darker colors for inactive (like light went out)
                                Color(red: 0.65, green: 0.65, blue: 0.67),
                                Color(red: 0.60, green: 0.60, blue: 0.62),
                                Color(red: 0.55, green: 0.55, blue: 0.57)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Metallic sheen overlay (darker for inactive)
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: isActive ? [
                                Color.white.opacity(0.3),
                                Color.clear,
                                Color.white.opacity(0.1)
                            ] : [
                                Color.black.opacity(0.2),
                                Color.clear,
                                Color.black.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Premium metallic border (darker for inactive)
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: isActive ? [
                                Color(red: 0.7, green: 0.7, blue: 0.75).opacity(0.6),
                                Color(red: 0.5, green: 0.5, blue: 0.55).opacity(0.4),
                                Color(red: 0.7, green: 0.7, blue: 0.75).opacity(0.6)
                            ] : [
                                Color(red: 0.4, green: 0.4, blue: 0.45).opacity(0.5),
                                Color(red: 0.3, green: 0.3, blue: 0.35).opacity(0.4),
                                Color(red: 0.4, green: 0.4, blue: 0.45).opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                
                // Inner highlight for depth (darker for inactive)
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isActive ? Color.white.opacity(0.4) : Color.black.opacity(0.3),
                        lineWidth: 0.5
                    )
                    .padding(1)
                
                // Subtle neon green LED glow for active cards (luxurious and refined)
                if isActive {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.85, blue: 0.5).opacity(0.5),
                                    Color(red: 0.0, green: 0.75, blue: 0.4).opacity(0.4),
                                    Color(red: 0.0, green: 0.85, blue: 0.5).opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.0
                        )
                        .shadow(color: Color(red: 0.0, green: 0.85, blue: 0.5).opacity(0.3), radius: 4, x: 0, y: 0)
                        .shadow(color: Color(red: 0.0, green: 0.85, blue: 0.5).opacity(0.2), radius: 6, x: 0, y: 0)
                }
            }
        )
        .shadow(color: Color.black.opacity(isActive ? 0.15 : 0.08), radius: isActive ? 20 : 12, x: 0, y: isActive ? 8 : 4)
        .shadow(color: Color.black.opacity(isActive ? 0.08 : 0.04), radius: isActive ? 8 : 4, x: 0, y: isActive ? 4 : 2)
        .shadow(color: Color(red: 0.3, green: 0.3, blue: 0.35).opacity(isActive ? 0.2 : 0.1), radius: 4, x: 0, y: 2)
    }
}

struct CardBack: View {
    let partner: Partner
    let hasBrickAndMortar: Bool
    let isActive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Details")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.midnightSlate)
                Spacer()
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.softGraphite)
            }
            
            Divider()
            
            // Fine print / Terms
            if let terms = partner.terms, !terms.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Terms & Conditions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    ScrollView {
                        Text(terms)
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxHeight: 200)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Terms & Conditions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    Text("No additional terms specified. Standard partner loyalty program terms apply.")
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                        .lineSpacing(4)
                }
            }
            
            Divider()
            
            // Action buttons
            VStack(spacing: 12) {
                if hasBrickAndMortar {
                    // Find nearest location button
                    Button(action: {
                        openMapsForLocation()
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                                .font(.system(size: 16))
                            Text("Find Nearest Location")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.softGraphite)
                        )
                    }
                }
                
                if let website = partner.website, !website.isEmpty {
                    // Visit website button
                    Button(action: {
                        openWebsite(urlString: website)
                    }) {
                        HStack {
                            Image(systemName: "safari.fill")
                                .font(.system(size: 16))
                            Text("Visit Website")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.softGraphite)
                        )
                    }
                } else if !hasBrickAndMortar {
                    // If no brick and mortar and no website, show message
                    Text("Contact partner for more information")
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            
            // Tap to flip back hint
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11))
                    Text("Tap to flip back")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.softGraphite.opacity(0.6))
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(
            ZStack {
                // Titanium/metallic card background with premium gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: isActive ? [
                                Color(red: 0.95, green: 0.95, blue: 0.97),
                                Color(red: 0.92, green: 0.92, blue: 0.94),
                                Color(red: 0.88, green: 0.88, blue: 0.90)
                            ] : [
                                // Darker colors for inactive (like light went out)
                                Color(red: 0.65, green: 0.65, blue: 0.67),
                                Color(red: 0.60, green: 0.60, blue: 0.62),
                                Color(red: 0.55, green: 0.55, blue: 0.57)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Metallic sheen overlay (darker for inactive)
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: isActive ? [
                                Color.white.opacity(0.3),
                                Color.clear,
                                Color.white.opacity(0.1)
                            ] : [
                                Color.black.opacity(0.2),
                                Color.clear,
                                Color.black.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Premium metallic border (darker for inactive)
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: isActive ? [
                                Color(red: 0.7, green: 0.7, blue: 0.75).opacity(0.6),
                                Color(red: 0.5, green: 0.5, blue: 0.55).opacity(0.4),
                                Color(red: 0.7, green: 0.7, blue: 0.75).opacity(0.6)
                            ] : [
                                Color(red: 0.4, green: 0.4, blue: 0.45).opacity(0.5),
                                Color(red: 0.3, green: 0.3, blue: 0.35).opacity(0.4),
                                Color(red: 0.4, green: 0.4, blue: 0.45).opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                
                // Inner highlight for depth (darker for inactive)
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isActive ? Color.white.opacity(0.4) : Color.black.opacity(0.3),
                        lineWidth: 0.5
                    )
                    .padding(1)
                
                // Subtle neon green LED glow for active cards (luxurious and refined)
                if isActive {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.85, blue: 0.5).opacity(0.5),
                                    Color(red: 0.0, green: 0.75, blue: 0.4).opacity(0.4),
                                    Color(red: 0.0, green: 0.85, blue: 0.5).opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.0
                        )
                        .shadow(color: Color(red: 0.0, green: 0.85, blue: 0.5).opacity(0.3), radius: 4, x: 0, y: 0)
                        .shadow(color: Color(red: 0.0, green: 0.85, blue: 0.5).opacity(0.2), radius: 6, x: 0, y: 0)
                }
            }
        )
        .shadow(color: Color.black.opacity(isActive ? 0.15 : 0.08), radius: isActive ? 20 : 12, x: 0, y: isActive ? 8 : 4)
        .shadow(color: Color.black.opacity(isActive ? 0.08 : 0.04), radius: isActive ? 8 : 4, x: 0, y: isActive ? 4 : 2)
        .shadow(color: Color(red: 0.3, green: 0.3, blue: 0.35).opacity(isActive ? 0.2 : 0.1), radius: 4, x: 0, y: 2)
    }
    
    private func openMapsForLocation() {
        // For ACME demo partner, use the specific address
        let searchQuery: String
        if partner.partnerId == "demo-acme-partner" {
            searchQuery = "8205 NW 9th Court Plantation FL 33322"
        } else {
            searchQuery = "\(partner.name) \(partner.location ?? "")"
        }
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Try Apple Maps first
        if let url = URL(string: "http://maps.apple.com/?q=\(encodedQuery)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to Google Maps
        if let url = URL(string: "comgooglemaps://?q=\(encodedQuery)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to web-based Google Maps
        if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedQuery)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite(urlString: String) {
        var urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add https:// if no scheme is present
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://\(urlString)"
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    PartnerLoyaltyView()
}
