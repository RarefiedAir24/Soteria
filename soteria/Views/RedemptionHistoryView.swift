//
//  RedemptionHistoryView.swift
//  soteria
//
//  View for displaying user's partner loyalty redemption history
//

import SwiftUI

struct RedemptionHistoryView: View {
    @ObservedObject private var partnerService = PartnerLoyaltyService.shared
    @State private var selectedPartner: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cloudWhite
                    .ignoresSafeArea()
                
                if partnerService.redemptions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.softGraphite)
                        
                        Text("No Redemptions Yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("Start using your partner loyalty benefits to see your redemption history here!")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Summary card
                            VStack(spacing: 12) {
                                Text("Total Savings")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.softGraphite)
                                
                                Text("$\(String(format: "%.2f", totalSavings))")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.reverBlue)
                                
                                Text("\(partnerService.redemptions.count) redemption\(partnerService.redemptions.count == 1 ? "" : "s")")
                                    .font(.system(size: 12))
                                    .foregroundColor(.softGraphite)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(
                                LinearGradient(
                                    colors: [Color.reverBlueLight.opacity(0.1), Color.reverBlueDark.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(18)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Redemption list
                            ForEach(filteredRedemptions) { redemption in
                                RedemptionRow(redemption: redemption)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Redemption History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("All Partners") {
                            selectedPartner = nil
                        }
                        ForEach(uniquePartners, id: \.self) { partnerId in
                            if let partner = partnerService.partners.first(where: { $0.partnerId == partnerId }) {
                                Button(partner.name) {
                                    selectedPartner = partnerId
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.reverBlue)
                    }
                }
            }
        }
    }
    
    private var filteredRedemptions: [Redemption] {
        if let partnerId = selectedPartner {
            return partnerService.redemptions.filter { $0.partnerId == partnerId }
        }
        return partnerService.redemptions
    }
    
    private var totalSavings: Double {
        partnerService.redemptions.reduce(0) { $0 + $1.loyaltyAmount }
    }
    
    private var uniquePartners: [String] {
        Array(Set(partnerService.redemptions.map { $0.partnerId }))
    }
}

struct RedemptionRow: View {
    let redemption: Redemption
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.reverBlue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "ticket.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.reverBlue)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(redemption.partnerName ?? "Partner")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Text(redemption.redeemedAt, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite)
                
                if let transactionId = redemption.transactionId {
                    Text("Transaction: \(transactionId)")
                        .font(.system(size: 11))
                        .foregroundColor(.softGraphite)
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text("-$\(String(format: "%.2f", redemption.loyaltyAmount))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.reverBlue)
                
                Text("Saved")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.softGraphite)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    RedemptionHistoryView()
}

