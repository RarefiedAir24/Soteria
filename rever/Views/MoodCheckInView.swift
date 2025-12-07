//
//  MoodCheckInView.swift
//  rever
//
//  Daily mood check-in and reflection
//

import SwiftUI

struct MoodCheckInView: View {
    @EnvironmentObject var moodService: MoodTrackingService
    @State private var selectedMood: MoodLevel? = nil
    @State private var notes: String = ""
    @State private var triggers: [String] = []
    @State private var newTrigger: String = ""
    @State private var energyLevel: Int = 5
    @State private var showReflection: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView {
                Color.clear
                    .frame(height: 60)
                
                VStack(spacing: 24) {
                    // Current Mood Display
                    if let currentMood = moodService.currentMood {
                        VStack(spacing: 8) {
                            Text("Current Mood")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Text(currentMood.emoji)
                                .font(.system(size: 60))
                            
                            Text(currentMood.displayName)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Mood Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How are you feeling?")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(MoodLevel.allCases, id: \.self) { mood in
                                Button(action: {
                                    selectedMood = mood
                                }) {
                                    VStack(spacing: 8) {
                                        Text(mood.emoji)
                                            .font(.system(size: 40))
                                        
                                        Text(mood.displayName)
                                            .font(.system(size: 12))
                                            .foregroundColor(selectedMood == mood ? .white : .gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedMood == mood ? Color(red: 0.1, green: 0.6, blue: 0.3) : Color(red: 0.95, green: 0.95, blue: 0.95))
                                    )
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Energy Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Energy Level")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        HStack {
                            Text("Low")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Slider(value: Binding(
                                get: { Double(energyLevel) },
                                set: { energyLevel = Int($0) }
                            ), in: 1...10, step: 1)
                            
                            Text("High")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        Text("\(energyLevel)/10")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes (Optional)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        TextField("What's on your mind?", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                            )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Save Button
                    Button(action: {
                        saveMoodEntry()
                    }) {
                        Text("Save Mood Check-In")
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedMood != nil ? Color(red: 0.1, green: 0.6, blue: 0.3) : Color.gray)
                            )
                    }
                    .disabled(selectedMood == nil)
                    .padding(.horizontal, 20)
                    
                    // Daily Reflection Button
                    Button(action: {
                        showReflection = true
                    }) {
                        Text("Daily Reflection")
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.1, green: 0.6, blue: 0.3), lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Fixed Header
            VStack(spacing: 2) {
                Text("Mood Check-In")
                    .font(.system(size: 24, weight: .semibold))
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
        .sheet(isPresented: $showReflection) {
            DailyReflectionView()
                .environmentObject(moodService)
        }
    }
    
    private func saveMoodEntry() {
        guard let mood = selectedMood else { return }
        
        let entry = MoodEntry(
            mood: mood,
            notes: notes.isEmpty ? nil : notes,
            triggers: triggers.isEmpty ? nil : triggers,
            energyLevel: energyLevel
        )
        
        moodService.addMoodEntry(entry)
        
        // Reset form
        selectedMood = nil
        notes = ""
        triggers = []
        energyLevel = 5
    }
}

struct DailyReflectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var moodService: MoodTrackingService
    
    @State private var spendingFeeling: String = ""
    @State private var regrets: String = ""
    @State private var wins: String = ""
    @State private var tomorrowIntent: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("How did spending feel today?") {
                    TextField("Describe your feelings about spending today", text: $spendingFeeling, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Any Regrets?") {
                    TextField("What purchases do you regret?", text: $regrets, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Wins") {
                    TextField("What went well today?", text: $wins, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Tomorrow's Intent") {
                    TextField("What's your intention for tomorrow?", text: $tomorrowIntent, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Daily Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReflection()
                    }
                }
            }
        }
    }
    
    private func saveReflection() {
        var reflection = moodService.todayReflection ?? DailyReflection()
        reflection.spendingFeeling = spendingFeeling.isEmpty ? nil : spendingFeeling
        reflection.regrets = regrets.isEmpty ? nil : regrets.split(separator: "\n").map { String($0) }
        reflection.wins = wins.isEmpty ? nil : wins.split(separator: "\n").map { String($0) }
        reflection.tomorrowIntent = tomorrowIntent.isEmpty ? nil : tomorrowIntent
        
        moodService.updateTodayReflection(reflection)
        dismiss()
    }
}

#Preview {
    MoodCheckInView()
        .environmentObject(MoodTrackingService.shared)
}

