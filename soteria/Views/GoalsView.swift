//
//  GoalsView.swift
//  rever
//
//  Savings goals tracking (manual, no bank integration)
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var goalsService: GoalsService
    @State private var showCreateGoal = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Consistent background that extends to safe area
            Color(red: 0.95, green: 0.95, blue: 0.95)
                .ignoresSafeArea(.all, edges: .top)
            // Background
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView {
                // Spacer for fixed header
                Color.clear
                    .frame(height: 60)
                
                VStack(spacing: 24) {
                    // Goals List
                    if goalsService.goals.isEmpty {
                        // Empty State
                        VStack(spacing: 16) {
                            Image(systemName: "target")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                            
                            Text("No Savings Goals")
                                .font(.system(size: 20, weight: .semibold, design: .default))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                            
                            Text("Create a goal to start saving for trips, purchases, or emergencies")
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                showCreateGoal = true
                            }) {
                                Text("Create Goal")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.1, green: 0.6, blue: 0.3))
                                    )
                            }
                        }
                        .padding(.vertical, 60)
                    } else {
                        // Goals List
                        ForEach(goalsService.goals) { goal in
                            GoalCard(goal: goal)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Create Goal Button
                    if !goalsService.goals.isEmpty {
                        Button(action: {
                            showCreateGoal = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create New Goal")
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.1, green: 0.6, blue: 0.3))
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Fixed Header
            VStack(spacing: 2) {
                Text("Savings Goals")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Color(red: 0.92, green: 0.97, blue: 0.94)
                    .ignoresSafeArea(edges: .top)
            )
            .zIndex(100)
        }
        .sheet(isPresented: $showCreateGoal) {
            CreateGoalView()
                .environmentObject(goalsService)
        }
    }
}

struct GoalCard: View {
    @EnvironmentObject var goalsService: GoalsService
    let goal: SavingsGoal
    
    private var progressPercentage: Int {
        return Int(goal.progress * 100)
    }
    
    private var formattedCurrent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: goal.currentAmount)) ?? "$0.00"
    }
    
    private var formattedTarget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: goal.targetAmount)) ?? "$0.00"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: goal.category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text(goal.category.rawValue)
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                }
                
                Spacer()
                
                if goalsService.activeGoal?.id == goal.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(formattedCurrent)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                    
                    Text("of \(formattedTarget)")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    
                    Spacer()
                    
                    Text("\(progressPercentage)%")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.9, green: 0.9, blue: 0.9))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.1, green: 0.6, blue: 0.3))
                            .frame(width: geometry.size.width * CGFloat(goal.progress), height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Set as Active Button
            if goalsService.activeGoal?.id != goal.id {
                Button(action: {
                    goalsService.setActiveGoal(goal)
                }) {
                    Text("Set as Active Goal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct CreateGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var goalsService: GoalsService
    
    @State private var goalName: String = ""
    @State private var targetAmount: String = ""
    @State private var selectedCategory: SavingsGoal.GoalCategory = .trip
    @State private var targetDate: Date? = nil
    @State private var showDatePicker: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Goal Details") {
                    TextField("Goal Name", text: $goalName)
                    TextField("Target Amount", text: $targetAmount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(SavingsGoal.GoalCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Target Date (Optional)") {
                    Toggle("Set Target Date", isOn: $showDatePicker)
                    
                    if showDatePicker {
                        DatePicker("Target Date", selection: Binding(
                            get: { targetDate ?? Date() },
                            set: { targetDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGoal()
                    }
                    .disabled(goalName.isEmpty || targetAmount.isEmpty || Double(targetAmount) == nil)
                }
            }
        }
    }
    
    private func createGoal() {
        guard let amount = Double(targetAmount), amount > 0 else { return }
        goalsService.createGoal(
            name: goalName,
            targetAmount: amount,
            targetDate: showDatePicker ? targetDate : nil,
            category: selectedCategory
        )
        dismiss()
    }
}

#Preview {
    GoalsView()
        .environmentObject(GoalsService.shared)
}
