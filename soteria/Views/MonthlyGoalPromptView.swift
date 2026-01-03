//
//  MonthlyGoalPromptView.swift
//  soteria
//
//  Prompt shown after 3 save transfers asking if user wants to turn it into a monthly goal
//

import SwiftUI

struct MonthlyGoalPromptView: View {
    @Environment(\.dismiss) var dismiss
    // NOTE: SavingsReminderService removed - functionality consolidated into Decision Notifications
    
    let onYes: () -> Void
    let onNo: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.reverBlue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 40))
                    .foregroundColor(.reverBlue)
            }
            .padding(.top, 20)
            
            // Title
            Text("Want to turn this into a monthly goal?")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.midnightSlate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Description
            Text("You've made 3 saves! Set up a monthly savings reminder to keep your momentum going.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.softGraphite)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    onYes()
                    dismiss()
                }) {
                    Text("Yes, Set Up Monthly Goal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.reverBlue)
                        )
                }
                
                Button(action: {
                    onNo()
                    dismiss()
                }) {
                    Text("Not Now")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.softGraphite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(Color.white)
    }
}

#Preview {
    MonthlyGoalPromptView(
        onYes: {},
        onNo: {}
    )
}

