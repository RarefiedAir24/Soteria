//
//  TimingRecommendationCard.swift
//  soteria
//
//  UI component for displaying timing recommendations
//  Shows in Decision Windows settings or as a low-priority card on Home
//

import SwiftUI

struct TimingRecommendationCard: View {
    let recommendation: TimingRecommendation
    let onUpdateTime: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.reverBlue)
                
                Text(recommendation.userFacingCopy.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Spacer()
            }
            
            Text(recommendation.userFacingCopy.body)
                .font(.system(size: 14))
                .foregroundColor(.softGraphite)
            
            HStack(spacing: 12) {
                Button(action: onUpdateTime) {
                    Text("Update time")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.reverBlue)
                        .cornerRadius(8)
                }
                
                Button(action: onDismiss) {
                    Text("Not now")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.softGraphite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.dreamMist)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    TimingRecommendationCard(
        recommendation: TimingRecommendation(
            windowId: "test",
            recommendedTime: "16:30",
            confidence: 0.72,
            reasonCode: .higherEngagement,
            userFacingCopy: UserFacingCopy(
                title: "Small tweak?",
                body: "You tend to respond more around 4:30 PM. Want to move your Decision Window?"
            )
        ),
        onUpdateTime: {},
        onDismiss: {}
    )
    .padding()
}

