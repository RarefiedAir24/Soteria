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
    @State private var showCategoryFilter = false
    @State private var showLocationFilter = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cloudWhite
                    .ignoresSafeArea()
                
                if partnerService.isLoading && partnerService.partners.isEmpty {
                    ProgressView("Loading partners...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if partnerService.partners.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.softGraphite)
                        
                        Text("No Partners Available")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("Check back soon for new partner loyalty benefits!")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
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
                                                HStack {
                                                    Image(systemName: "tag.fill")
                                                    Text(selectedCategory ?? "All Categories")
                                                }
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.reverBlue)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.reverBlue.opacity(0.1))
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
                                                HStack {
                                                    Image(systemName: "location.fill")
                                                    Text(selectedLocation ?? "All Locations")
                                                }
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.reverBlue)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.reverBlue.opacity(0.1))
                                                .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.vertical, 12)
                            }
                            
                            // Partner cards
                            ForEach(filteredPartners) { partner in
                                PartnerCard(partner: partner)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Partner Benefits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await partnerService.loadPartners(category: selectedCategory, location: selectedLocation)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.reverBlue)
                    }
                }
            }
            .onAppear {
                if partnerService.partners.isEmpty {
                    Task {
                        await partnerService.loadPartners()
                    }
                }
            }
            .alert("Error", isPresented: .constant(partnerService.errorMessage != nil)) {
                Button("OK") {
                    partnerService.errorMessage = nil
                }
            } message: {
                Text(partnerService.errorMessage ?? "")
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

struct PartnerCard: View {
    let partner: Partner
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(partner.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    if let description = partner.description {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 16) {
                        if let category = partner.category {
                            Label(category, systemImage: "tag.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.reverBlue)
                        }
                        
                        if let location = partner.location {
                            Label(location, systemImage: "location.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.reverBlue)
                        }
                    }
                }
                
                Spacer()
                
                // Loyalty benefit badge
                VStack(alignment: .trailing, spacing: 4) {
                    if let percentage = partner.loyaltyPercentage {
                        Text("\(Int(percentage))%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.reverBlue)
                        Text("OFF")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.reverBlue)
                            .tracking(1)
                    } else if let amount = partner.loyaltyAmount {
                        Text("$\(String(format: "%.2f", amount))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.reverBlue)
                        Text("OFF")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.reverBlue)
                            .tracking(1)
                    }
                }
                .padding(12)
                .background(Color.reverBlue.opacity(0.1))
                .cornerRadius(12)
            }
            
            if let terms = partner.terms {
                Text(terms)
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite)
                    .lineLimit(showDetails ? nil : 2)
            }
            
            if let terms = partner.terms, terms.count > 60 {
                Button(showDetails ? "Show Less" : "Show More") {
                    withAnimation {
                        showDetails.toggle()
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.reverBlue)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    PartnerLoyaltyView()
}

