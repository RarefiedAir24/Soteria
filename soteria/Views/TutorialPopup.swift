//
//  TutorialPopup.swift
//  soteria
//
//  Reusable tutorial popup component with dismiss and permanent hide options
//

import SwiftUI

struct TutorialPopup: View {
    let title: String
    let content: AnyView
    let userDefaultsKey: String // Key for storing permanent hide preference
    
    @Binding var isPresented: Bool
    @State private var hidePermanently: Bool = false
    
    var body: some View {
        if isPresented && !isPermanentlyHidden {
            ZStack {
                // Background overlay
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                
                // Popup content
                VStack(spacing: 0) {
                    // Header with title and close button
                    HStack {
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.softGraphite)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Content - Scrollable
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 0) {
                            content
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                        }
                    }
                    .frame(maxHeight: 450)
                    .scrollIndicators(.visible)
                    
                    // Footer with "Don't show again" option
                    VStack(spacing: 12) {
                        Divider()
                        
                        HStack {
                            Button(action: {
                                hidePermanently = true
                                UserDefaults.standard.set(true, forKey: userDefaultsKey)
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: hidePermanently ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 18))
                                    Text("Don't show again")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.softGraphite)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Got it!")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.softGraphite, Color.midnightSlate],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .frame(maxWidth: 340)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 20)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .zIndex(1000)
        }
    }
    
    private var isPermanentlyHidden: Bool {
        UserDefaults.standard.bool(forKey: userDefaultsKey)
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

// MARK: - Tutorial Content Views

struct HomeScreenTutorialContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Money Tree Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "tree.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.softGraphite)
                        .frame(width: 40, height: 40)
                    
                    Text("Growing Your Money Tree")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
                
                Text("Your Money Tree is a living visualization of your savings journey! Every time you save money, watch your tree grow taller and stronger.")
                    .font(.system(size: 14))
                    .foregroundColor(.softGraphite)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("How it grows:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.softGraphite)
                        Text("Each deposit makes your tree grow taller")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.softGraphite)
                        Text("Leaves fill in as you reach savings milestones ($10, $100, $500, etc.)")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.softGraphite)
                        Text("Your savings goals appear as special leaves on the tree")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.softGraphite)
                        Text("The more you save, the more your tree flourishes!")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.leading, 4)
            }
            
            Divider()
            
            // Save Methods Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.softGraphite)
                        .frame(width: 40, height: 40)
                    
                    Text("How to Save")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    TutorialMethodRow(
                        icon: "link.circle.fill",
                        title: "Connect Your Bank",
                        description: "Link your bank account to automatically track transfers to your savings account."
                    )
                    
                    TutorialMethodRow(
                        icon: "dollarsign.circle.fill",
                        title: "Manual Deposit",
                        description: "Record cash deposits or transfers from external accounts manually."
                    )
                    
                    TutorialMethodRow(
                        icon: "target",
                        title: "Goal Deposits",
                        description: "Add deposits directly to your active savings goal to track progress."
                    )
                }
            }
            
            Divider()
            
            // Tips Section
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 Tip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Text("Set up a savings goal to stay motivated and track your progress toward specific targets!")
                    .font(.system(size: 13))
                    .foregroundColor(.softGraphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dreamMist.opacity(0.5))
            )
        }
        .padding(.vertical, 8)
    }
}

struct GoalsTutorialContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // What are Goals Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 24))
                        .foregroundColor(.softGraphite)
                        .frame(width: 40, height: 40)
                    
                    Text("What are Goals?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
                
                Text("Savings goals help you save for specific things like vacations, emergencies, or big purchases. Each goal has a target amount and optional deadline to keep you motivated.")
                    .font(.system(size: 14))
                    .foregroundColor(.softGraphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
            
            // Setting Up Goals Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.softGraphite)
                        .frame(width: 40, height: 40)
                    
                    Text("Setting Up Goals")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    TutorialStepRow(
                        number: 1,
                        title: "Tap the + button",
                        description: "Create a new goal from the Goals screen."
                    )
                    
                    TutorialStepRow(
                        number: 2,
                        title: "Enter goal details",
                        description: "Set a name, target amount, category, and optional dates."
                    )
                    
                    TutorialStepRow(
                        number: 3,
                        title: "Add a photo (optional)",
                        description: "Visualize your goal with a photo to stay motivated."
                    )
                    
                    TutorialStepRow(
                        number: 4,
                        title: "Set notifications",
                        description: "Get reminders to track your progress and celebrate milestones."
                    )
                }
            }
            
            Divider()
            
            // Tips Section
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 Tips")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("• Set one goal as 'Active' to focus your savings")
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                    
                    Text("• Add deposits to your active goal to see progress")
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                    
                    Text("• Goals appear as leaves on your Money Tree")
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dreamMist.opacity(0.5))
            )
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Helper Views

struct TutorialMethodRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.softGraphite)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.softGraphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TutorialStepRow: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.softGraphite.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.softGraphite)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.softGraphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

