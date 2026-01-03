//
//  MoneyTreeView.swift
//  soteria
//
//  Animated money tree that grows with savings deposits
//  Leaves represent savings milestones and goals - they "fill in" as your savings grows
//  This is the core "grow your money tree" concept: save money = grow tree = fill leaves
//

import SwiftUI

struct MoneyTreeView: View {
    let totalSaved: Double
    let activeGoal: SavingsGoal?
    let allGoals: [SavingsGoal]
    var onGoalLeafTapped: ((SavingsGoal) -> Void)? = nil
    
    // Default milestone leaves - all users get these
    private let defaultMilestones: [Double] = [10, 100, 500, 1000, 5000, 10000, 15000, 20000]
    
    // Generate additional milestones beyond default
    // Uses dynamic increments: $5k up to $100k, then $10k up to $250k, then $25k up to $500k, then $50k beyond
    // Always extends beyond highest goal to ensure goal leaves have milestone context
    private func generateMilestones(upTo maxValue: Double) -> [Double] {
        var milestones = defaultMilestones
        var current = 20000.0
        
        // Phase 1: $5k increments up to $100k
        while current < 100000 && current <= maxValue {
            current += 5000
            milestones.append(current)
        }
        
        // Phase 2: $10k increments from $100k to $250k
        if maxValue > 100000 {
            current = 100000
            while current < 250000 && current <= maxValue {
                current += 10000
                milestones.append(current)
            }
        }
        
        // Phase 3: $25k increments from $250k to $500k
        if maxValue > 250000 {
            current = 250000
            while current < 500000 && current <= maxValue {
                current += 25000
                milestones.append(current)
            }
        }
        
        // Phase 4: $50k increments beyond $500k
        if maxValue > 500000 {
            current = 500000
            while current <= maxValue {
                current += 50000
                milestones.append(current)
            }
        }
        
        // Cap at 100 total milestones to prevent excessive computation
        return Array(milestones.prefix(100))
    }
    
    // Growth thresholds (tree grows at these milestones) - extended for higher savings
    // Tree represents piggy bank growth, so it continues growing as savings increase
    private let growthThresholds: [Double] = [0, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000, 250000, 500000]
    
    // Calculate tree growth level (0-13, was 0-8) - tree continues growing with savings
    private var treeLevel: Int {
        for (index, threshold) in growthThresholds.enumerated().reversed() {
            if totalSaved >= threshold {
                return min(index, growthThresholds.count - 1)
            }
        }
        return 0
    }
    
    // Calculate tree height based on level - larger for better visual presentation
    private var treeHeight: CGFloat {
        let baseHeight: CGFloat = 180 // Increased from 120
        let growthPerLevel: CGFloat = 40 // Increased from 30
        return baseHeight + (CGFloat(treeLevel) * growthPerLevel)
    }
    
    // Calculate trunk width based on level - wider for better visibility
    private var trunkWidth: CGFloat {
        let baseWidth: CGFloat = 18 // Increased from 12
        let growthPerLevel: CGFloat = 3 // Increased from 2
        return baseWidth + (CGFloat(treeLevel) * growthPerLevel)
    }
    
    // Get active goals
    private var activeGoals: [SavingsGoal] {
        allGoals.filter { $0.status == .active }
    }
    
    // Cached leaves to prevent recomputation on every body evaluation
    @State private var allLeaves: [LeafData] = []
    @State private var lastTotalSaved: Double = -1
    @State private var lastGoalsHash: Int = 0
    @State private var lastActiveGoalId: String? = nil
    
    // Compute leaves hash for change detection
    private var goalsHash: Int {
        activeGoals.map { $0.id.hashValue }.reduce(0, ^)
    }
    
    // Update leaves when values change
    private func updateLeavesIfNeeded() {
        let currentGoalsHash = goalsHash
        let shouldUpdate = allLeaves.isEmpty || 
                          lastTotalSaved != totalSaved || 
                          lastGoalsHash != currentGoalsHash ||
                          lastActiveGoalId != activeGoal?.id
        
        print("🌳 [MoneyTreeView] updateLeavesIfNeeded - shouldUpdate: \(shouldUpdate), allLeaves.isEmpty: \(allLeaves.isEmpty), totalSaved changed: \(lastTotalSaved != totalSaved), goalsHash changed: \(lastGoalsHash != currentGoalsHash), activeGoal changed: \(lastActiveGoalId != activeGoal?.id)")
        
        guard shouldUpdate else {
            return // No change needed
        }
        
        var leaves: [LeafData] = []
        
        // Determine max milestone to show
        // Always extend beyond highest goal to ensure goal leaves have milestone context
        // Show milestones up to: max(current savings * 2, highest goal * 1.5, or default 20000)
        let highestGoal = activeGoals.map { $0.targetAmount }.max() ?? 0
        let maxMilestone = max(
            totalSaved * 2.0,
            highestGoal * 1.5, // Extend 50% beyond highest goal for context
            20000.0
        )
        // No hard cap - let milestones extend as needed for goals
        let allMilestones = generateMilestones(upTo: maxMilestone)
        
        // Add all default milestone leaves (always visible, but can be styled differently if not reached)
        for milestone in allMilestones {
            leaves.append(LeafData(
                value: milestone,
                type: .milestone,
                goal: nil
            ))
        }
        
        // Add goal leaves (one per goal, positioned by target amount)
        // IMPORTANT: Add ALL active goals, not just the first one
        print("🌳 [MoneyTreeView] Adding goal leaves. Active goals count: \(activeGoals.count)")
        for goal in activeGoals {
            print("🌳 [MoneyTreeView] Adding goal leaf: \(goal.name) - Target: $\(goal.targetAmount), Status: \(goal.status)")
            leaves.append(LeafData(
                value: goal.targetAmount,
                type: .goal,
                goal: goal
            ))
        }
        
        // Sort leaves by dollar value (lowest to highest)
        allLeaves = leaves.sorted { $0.value < $1.value }
        
        print("🌳 [MoneyTreeView] Total leaves: \(allLeaves.count) (Milestones: \(allMilestones.count), Goals: \(activeGoals.count))")
        
        lastTotalSaved = totalSaved
        lastGoalsHash = currentGoalsHash
        lastActiveGoalId = activeGoal?.id
    }
    
    // Check if a milestone has been reached
    private func isMilestoneReached(_ value: Double) -> Bool {
        return totalSaved >= value
    }
    
    // Tree visualization view - extracted to reduce complexity
    @ViewBuilder
    private var treeVisualization: some View {
        ZStack(alignment: .bottom) {
            // Background gradient (no sky elements here)
            treeBackgroundGradient
            groundBase
            treeStructure
            // Sky elements (sun/moon) on top so they appear above tree
            skyElementsOverlay
        }
        .frame(height: treeHeight + 200) // Increased from 80 to 200 for larger background
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 10)
        .clipped()
        .overlay(celebrationOverlay)
    }
    
    // Background gradient only (no sky elements)
    @ViewBuilder
    private var treeBackgroundGradient: some View {
        let backgroundHeight = treeHeight + 200
        GeometryReader { geometry in
            ZStack {
                // Base light blue background for day themes
                if themeService.currentTheme != .night {
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.92, blue: 0.98), // Light sky blue
                            Color(red: 0.75, green: 0.88, blue: 0.95), // Soft blue
                            Color(red: 0.7, green: 0.85, blue: 0.92)  // Deeper light blue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.6)
                }
                
                let gradientColors = themeService.currentGradient.isEmpty 
                    ? TimeTheme.afternoon.gradientColors 
                    : themeService.currentGradient
                let backgroundOpacity = themeService.currentTheme == .night ? 0.4 : 0.3
                
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(backgroundOpacity)
            }
            .frame(height: backgroundHeight)
            .frame(maxWidth: .infinity)
        }
        .frame(height: treeHeight + 200)
        .animation(.easeInOut(duration: 2.0), value: themeService.currentTheme)
    }
    
    // Sky elements overlay (sun/moon) - rendered above tree
    @ViewBuilder
    private var skyElementsOverlay: some View {
        let backgroundHeight = treeHeight + 200
        GeometryReader { geometry in
            SkyElementsView(theme: themeService.currentTheme, size: geometry.size)
                .opacity(themeService.currentTheme == .night ? 0.9 : 0.95)
        }
        .frame(height: backgroundHeight)
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false) // Don't block touches to tree
    }
    
    // Background with sky elements
    @ViewBuilder
    private var treeBackground: some View {
        let backgroundHeight = treeHeight + 200 // Increased from 80 to 200 for larger background
        GeometryReader { geometry in
            ZStack {
                // Base light blue background for day themes (similar to dark background for night)
                if themeService.currentTheme != .night {
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.92, blue: 0.98), // Light sky blue
                            Color(red: 0.75, green: 0.88, blue: 0.95), // Soft blue
                            Color(red: 0.7, green: 0.85, blue: 0.92)  // Deeper light blue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.6) // Visible light blue background for day
                }
                
                let gradientColors = themeService.currentGradient.isEmpty 
                    ? TimeTheme.afternoon.gradientColors 
                    : themeService.currentGradient
                let backgroundOpacity = themeService.currentTheme == .night ? 0.4 : 0.3
                let skyOpacity = themeService.currentTheme == .night ? 0.9 : 0.95 // Increased for day to match night visibility
                
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(backgroundOpacity)
                
                SkyElementsView(theme: themeService.currentTheme, size: geometry.size)
                    .opacity(skyOpacity)
            }
            .frame(height: backgroundHeight)
            .frame(maxWidth: .infinity)
        }
        .frame(height: treeHeight + 200) // Increased from 80 to 200
        .animation(.easeInOut(duration: 2.0), value: themeService.currentTheme)
    }
    
    // Ground/Base
    @ViewBuilder
    private var groundBase: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.8, green: 0.7, blue: 0.6), Color(red: 0.7, green: 0.6, blue: 0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 20)
            .frame(maxWidth: .infinity)
    }
    
    // Tree structure (branches, leaves, trunk)
    @ViewBuilder
    private var treeStructure: some View {
        VStack(spacing: 0) {
            ZStack {
                if animatedLevel > 0 {
                    BranchStructureView(level: animatedLevel, treeHeight: treeHeight * 0.7)
                }
                
                if !allLeaves.isEmpty {
                    ForEach(Array(allLeaves.enumerated()), id: \.element.id) { index, leafData in
                        leafViewForData(leafData: leafData, index: index)
                            .onAppear {
                                let isActive = leafData.goal?.id == activeGoal?.id
                                logActiveGoalIfNeeded(leafData: leafData, isActive: isActive)
                            }
                    }
                }
            }
            .frame(height: treeHeight * 0.7)
            .opacity(showLeaves ? 1.0 : 0.0)
            .scaleEffect(showLeaves ? 1.0 : 0.5)
            
            TrunkView(width: trunkWidth, height: treeHeight * 0.35)
        }
        .frame(height: treeHeight)
    }
    
    // Celebration overlay
    @ViewBuilder
    private var celebrationOverlay: some View {
        GeometryReader { geometry in
            if showCelebration {
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                CelebrationEffectView(treeCenter: center)
            }
        }
    }
    
    // Savings info section
    @ViewBuilder
    private var savingsInfo: some View {
        VStack(spacing: 8) {
            Text("$\(String(format: "%.2f", totalSaved))")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.reverBlue)
            
            if let next = nextMilestone {
                milestoneProgressView(next: next)
            } else {
                Text("Maximum Growth Reached! 🌳")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.reverBlue)
            }
        }
    }
    
    // Milestone progress view
    @ViewBuilder
    private func milestoneProgressView(next: Double) -> some View {
        VStack(spacing: 4) {
            Text("Next Growth: $\(String(format: "%.0f", next))")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.softGraphite)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.mistGray)
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.reverBlueLight, Color.reverBlueDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressToNextMilestone, height: 10)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progressToNextMilestone)
                }
            }
            .frame(height: 10)
        }
    }
    
    // Helper function to create leaf view - breaks up complex expression
    @ViewBuilder
    private func leafViewForData(leafData: LeafData, index: Int) -> some View {
        let isActive = leafData.goal?.id == activeGoal?.id
        let maxValue = allLeaves.last?.value ?? 1.0
        
        // Determine if leaf is reached based on total savings growth
        // This ties leaves directly to "growing your money tree" concept
        let isReached: Bool = {
            if leafData.type == .goal {
                // For goal leaves: reached when total savings has grown to include this goal's target
                // OR when the individual goal is completed
                let goalCompleted = (leafData.goal?.currentAmount ?? 0) >= leafData.value
                let savingsReached = totalSaved >= leafData.value
                return goalCompleted || savingsReached
            } else {
                // For milestone leaves: reached when total savings reaches the milestone
                return isMilestoneReached(leafData.value)
            }
        }()
        
        // Calculate progress toward this leaf (0.0 to 1.0)
        // This shows how "filled in" the leaf should be
        let progress: Double = {
            if leafData.type == .goal {
                // For goals: progress is based on total savings reaching the goal target
                // OR individual goal progress, whichever is higher
                let savingsProgress = min(totalSaved / max(leafData.value, 1.0), 1.0)
                let goalProgress = min((leafData.goal?.currentAmount ?? 0) / max(leafData.value, 1.0), 1.0)
                return max(savingsProgress, goalProgress)
            } else {
                // For milestones: progress is based on total savings
                return min(totalSaved / max(leafData.value, 1.0), 1.0)
            }
        }()
        
        LeafView(
            leafData: leafData,
            index: index,
            totalLeaves: allLeaves.count,
            treeLevel: animatedLevel,
            maxValue: maxValue,
            isReached: isReached,
            progress: progress, // Add progress for visual filling effect
            isActiveGoal: isActive,
            theme: themeService.currentTheme,
            onGoalTapped: onGoalLeafTapped
        )
    }
    
    // Log active goal detection (called separately, not in ViewBuilder)
    private func logActiveGoalIfNeeded(leafData: LeafData, isActive: Bool) {
        if isActive && leafData.type == .goal {
            print("🌟 [MoneyTreeView] Active goal leaf found: \(leafData.goal?.name ?? "unknown"), ID: \(leafData.goal?.id ?? "none")")
        }
    }
    
    // Next milestone
    private var nextMilestone: Double? {
        for threshold in growthThresholds {
            if threshold > totalSaved {
                return threshold
            }
        }
        return nil
    }
    
    // Progress to next milestone
    private var progressToNextMilestone: Double {
        guard let next = nextMilestone,
              let current = growthThresholds.last(where: { $0 <= totalSaved }) else {
            return 1.0
        }
        let range = next - current
        let progress = (totalSaved - current) / range
        return min(max(progress, 0), 1.0)
    }
    
    @State private var animatedLevel: Int = 0
    @State private var showLeaves: Bool = false
    @State private var showCelebration: Bool = false
    @State private var lastMilestoneReached: Double? = nil
    
    @StateObject private var themeService = TimeBasedThemeService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            treeVisualization
            savingsInfo
        }
        .onAppear {
            // Update leaves on appear
            print("🌳 [MoneyTreeView] onAppear - Total goals: \(allGoals.count), Active goals: \(activeGoals.count)")
            updateLeavesIfNeeded()
            
            // Update theme based on current time
            themeService.updateTheme()
            
            // Animate tree growth
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedLevel = treeLevel
            }
            
            // Show leaves after a brief delay with staggered animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showLeaves = true
                }
            }
        }
        .onChange(of: totalSaved) { oldValue, newValue in
            // Update leaves when savings change
            updateLeavesIfNeeded()
            
            // Check if a milestone was just reached
            let oldLevel = growthThresholds.lastIndex(where: { $0 <= oldValue }) ?? 0
            let newLevel = growthThresholds.lastIndex(where: { $0 <= newValue }) ?? 0
            
            if newLevel > oldLevel {
                // Milestone reached! Show celebration
                showCelebration = true
                lastMilestoneReached = growthThresholds[newLevel]
                
                // Hide celebration after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showCelebration = false
                }
            }
            
            // Animate growth when savings increase
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedLevel = treeLevel
            }
            
            // Add new leaves with animation
            if newValue > oldValue {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    showLeaves = true
                }
            }
        }
        .onChange(of: allGoals.count) { oldCount, newCount in
            // Update leaves when goals change
            updateLeavesIfNeeded()
            
            // Animate when goals are added/removed
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showLeaves = true
            }
        }
        .onChange(of: activeGoals.count) { oldCount, newCount in
            // Force update when active goals change
            print("🌳 [MoneyTreeView] Active goals count changed: \(oldCount) -> \(newCount)")
            updateLeavesIfNeeded()
            
            // Animate when goals are added/removed
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showLeaves = true
            }
        }
        .onChange(of: goalsHash) { oldHash, newHash in
            // Force update when goals themselves change (not just count)
            if oldHash != newHash {
                print("🌳 [MoneyTreeView] Goals hash changed: \(oldHash) -> \(newHash)")
                updateLeavesIfNeeded()
            }
        }
    }
}

// MARK: - Sky Elements View
struct SkyElementsView: View {
    let theme: TimeTheme
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Sun
            if theme.hasSun {
                sunView
            }
            
            // Moon - brighter and more visible
            if theme.hasMoon {
                moonView
            }
            
            // Clouds - very subtle
            if theme.hasClouds {
                cloudsView
            }
            
            // Stars (only at night) - much more visible
            if theme.hasStars {
                starsView
            }
        }
    }
    
    // MARK: - Sun View
    private var sunView: some View {
        let sunPos = theme.sunPosition
        return ZStack {
                    // Sun glow - more visible like moon glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.9, blue: 0.6).opacity(0.6), // Increased from 0.4
                                    Color(red: 1.0, green: 0.85, blue: 0.5).opacity(0.3), // Increased from 0.2
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size.width * 0.1
                            )
                        )
                        .frame(width: size.width * 0.3, height: size.width * 0.3)
                        .blur(radius: 2) // Add blur like moon for better visibility
                    
                    // Sun - brighter and more visible like the moon, taller than tree
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.95, blue: 0.7),
                                    Color(red: 1.0, green: 0.85, blue: 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size.width * 0.15, height: size.width * 0.15) // Increased from 0.12 to 0.15
                        .shadow(color: Color(red: 1.0, green: 0.9, blue: 0.6).opacity(0.6), radius: 8, x: 0, y: 0)
                }
                .position(
                    x: size.width * sunPos.x,
                    y: size.height * sunPos.y
                )
                .opacity(0.95) // Increased from 0.4 to match moon visibility
    }
    
    // MARK: - Moon View
    private var moonView: some View {
        let moonPos = theme.moonPosition
        return ZStack {
                    // Moon glow - more visible
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size.width * 0.12
                            )
                        )
                        .frame(width: size.width * 0.3, height: size.width * 0.3)
                        .blur(radius: 2)
                    
                    // Moon - brighter white, taller than tree
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.98, blue: 0.95), // Brighter white
                                    Color(red: 0.9, green: 0.9, blue: 0.85)    // Slightly off-white
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size.width * 0.15, height: size.width * 0.15) // Increased from 0.12 to 0.15
                        .overlay(
                            // Moon craters - more visible
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.75, green: 0.75, blue: 0.7))
                                    .frame(width: size.width * 0.018, height: size.width * 0.018)
                                    .offset(x: -size.width * 0.025, y: -size.width * 0.015)
                                Circle()
                                    .fill(Color(red: 0.75, green: 0.75, blue: 0.7))
                                    .frame(width: size.width * 0.015, height: size.width * 0.015)
                                    .offset(x: size.width * 0.02, y: size.width * 0.025)
                                Circle()
                                    .fill(Color(red: 0.75, green: 0.75, blue: 0.7))
                                    .frame(width: size.width * 0.012, height: size.width * 0.012)
                                    .offset(x: -size.width * 0.015, y: size.width * 0.02)
                            }
                        )
                        .shadow(color: Color.white.opacity(0.3), radius: 8, x: 0, y: 0)
                }
                .position(
                    x: size.width * moonPos.x,
                    y: size.height * moonPos.y
                )
    }
    
    // MARK: - Clouds View
    private var cloudsView: some View {
        ZStack {
            // Cloud 1
            CloudShape()
                .fill(Color.white.opacity(0.15))
                .frame(width: size.width * 0.25, height: size.width * 0.15)
                .position(
                    x: size.width * 0.2,
                    y: size.height * 0.25
                )
                .blur(radius: 2)
            
            // Cloud 2
            CloudShape()
                .fill(Color.white.opacity(0.12))
                .frame(width: size.width * 0.2, height: size.width * 0.12)
                .position(
                    x: size.width * 0.7,
                    y: size.height * 0.35
                )
                .blur(radius: 2)
            
            // Cloud 3 (smaller, distant)
            CloudShape()
                .fill(Color.white.opacity(0.1))
                .frame(width: size.width * 0.15, height: size.width * 0.1)
                .position(
                    x: size.width * 0.5,
                    y: size.height * 0.2
                )
                .blur(radius: 2)
        }
    }
    
    // MARK: - Stars View
    private var starsView: some View {
        // Define a lightweight per-star model for twinkling
        struct Star: Identifiable {
            let id = UUID()
            let index: Int
            let x: CGFloat
            let y: CGFloat
            let size: CGFloat
            let baseOpacity: Double
            let amplitude: Double
            let speed: Double
            let phase: Double
        }

        // Seeded pseudo-random generator based on index for consistent layout but varied animation
        func starForIndex(_ index: Int) -> Star {
            // Positions and size are deterministic from index (as before)
            let starX = CGFloat(Double((index * 37) % 100) / 100.0)
            let starY = CGFloat(Double((index * 23) % 80) / 100.0) + 0.05
            let starSize = CGFloat(Double(index % 4) + 1.5)

            // Pseudo-random values derived from index for animation parameters
            let seed = Double((index * 91) % 1000) / 1000.0
            let seed2 = Double((index * 57 + 23) % 1000) / 1000.0
            let seed3 = Double((index * 131 + 7) % 1000) / 1000.0

            // Base opacity between 0.55 and 0.9
            let baseOpacity = 0.55 + seed * 0.35
            // Amplitude between 0.08 and 0.22 (how much it twinkles)
            let amplitude = 0.08 + seed2 * 0.14
            // Speed between 0.7 and 1.6 seconds per cycle
            let speed = 0.7 + seed3 * 0.9
            // Phase offset (0..2π) to desynchronize stars
            let phase = seed * 2 * .pi

            return Star(index: index, x: starX, y: starY, size: starSize, baseOpacity: baseOpacity, amplitude: amplitude, speed: speed, phase: phase)
        }

        // Build stars once for this render pass
        let stars: [Star] = (0..<30).map { starForIndex($0) }

        // Animate opacity using a sine wave approximation via keyframe-like repeating animation
        return ZStack {
            ForEach(stars) { star in
                // Compute current opacity using time-based effect via animating a dummy value
                TwinklingStarView(
                    position: CGPoint(x: size.width * star.x, y: size.height * star.y),
                    size: star.size,
                    baseOpacity: star.baseOpacity,
                    amplitude: star.amplitude,
                    speed: star.speed,
                    phase: star.phase
                )
            }
        }
    }
}

// MARK: - Twinkling Star View
private struct TwinklingStarView: View {
    let position: CGPoint
    let size: CGFloat
    let baseOpacity: Double
    let amplitude: Double
    let speed: Double
    let phase: Double

    @State private var t: Double = 0.0

    var body: some View {
        // Opacity oscillates between baseOpacity - amplitude and baseOpacity + amplitude
        let currentOpacity = baseOpacity + amplitude * sin(t + phase)
        Group {
            StarShape()
                .fill(Color.white.opacity(currentOpacity))
                .frame(width: size, height: size)
                .position(x: position.x, y: position.y)
                .shadow(color: Color.white.opacity(0.5), radius: 2, x: 0, y: 0)
                .onAppear {
                    // Drive a continuous oscillation by animating `t` linearly and repeating forever.
                    withAnimation(.linear(duration: speed).repeatForever(autoreverses: false)) {
                        t = 2 * .pi
                    }
                }
                .onChange(of: speed) { _, newSpeed in
                    // Restart animation if speed changes (defensive)
                    t = 0
                    withAnimation(.linear(duration: newSpeed).repeatForever(autoreverses: false)) {
                        t = 2 * .pi
                    }
                }
        }
    }
}

// MARK: - Cloud Shape
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Create a fluffy cloud shape
        let centerX = width / 2
        let centerY = height / 2
        
        // Main cloud body (large circle)
        path.addEllipse(in: CGRect(
            x: centerX - width * 0.3,
            y: centerY - height * 0.2,
            width: width * 0.6,
            height: height * 0.8
        ))
        
        // Left puff
        path.addEllipse(in: CGRect(
            x: centerX - width * 0.4,
            y: centerY - height * 0.1,
            width: width * 0.4,
            height: height * 0.6
        ))
        
        // Right puff
        path.addEllipse(in: CGRect(
            x: centerX + width * 0.1,
            y: centerY - height * 0.1,
            width: width * 0.4,
            height: height * 0.6
        ))
        
        // Top puff
        path.addEllipse(in: CGRect(
            x: centerX - width * 0.2,
            y: centerY - height * 0.3,
            width: width * 0.4,
            height: height * 0.5
        ))
        
        return path
    }
}

// MARK: - Star Shape
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Create a 5-pointed star
        let points = 5
        let angle = Double.pi * 2 / Double(points)
        
        for i in 0..<points {
            let outerAngle = angle * Double(i) - Double.pi / 2
            let innerAngle = angle * (Double(i) + 0.5) - Double.pi / 2
            
            let outerX = center.x + CGFloat(cos(outerAngle)) * radius
            let outerY = center.y + CGFloat(sin(outerAngle)) * radius
            let innerX = center.x + CGFloat(cos(innerAngle)) * radius * 0.4
            let innerY = center.y + CGFloat(sin(innerAngle)) * radius * 0.4
            
            if i == 0 {
                path.move(to: CGPoint(x: outerX, y: outerY))
            } else {
                path.addLine(to: CGPoint(x: outerX, y: outerY))
            }
            path.addLine(to: CGPoint(x: innerX, y: innerY))
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Leaf Data Structure
struct LeafData: Identifiable {
    let id: String
    let value: Double
    let type: LeafType
    let goal: SavingsGoal?
    
    enum LeafType {
        case milestone
        case goal
    }
    
    init(value: Double, type: LeafType, goal: SavingsGoal?) {
        self.value = value
        self.type = type
        self.goal = goal
        // Create unique ID based on type and value
        if let goal = goal {
            self.id = "goal-\(goal.id)"
        } else {
            self.id = "milestone-\(Int(value))"
        }
    }
}

// MARK: - Leaf View
struct LeafView: View {
    let leafData: LeafData
    let index: Int
    let totalLeaves: Int
    let treeLevel: Int
    let maxValue: Double
    let isReached: Bool // Whether the milestone/goal has been reached
    let progress: Double // Progress toward this leaf (0.0 to 1.0) - shows how "filled in" it is
    let isActiveGoal: Bool // Whether this is the currently active goal
    let theme: TimeTheme // Current time-based theme
    var onGoalTapped: ((SavingsGoal) -> Void)? = nil
    
    // Check if theme is dark (night)
    private var isDarkTheme: Bool {
        theme == .night
    }
    
    // Position on tree based on dollar value
    // Lower values at bottom/left, higher values at top/right
    // Organize in a spiral pattern around the tree
    private var angle: Double {
        // Distribute leaves evenly around the tree (360 degrees)
        let baseAngle = (Double(index) / Double(max(totalLeaves, 1))) * 360.0
        // Add slight variation for natural look
        let variation = sin(Double(index) * 0.5) * 15.0
        return baseAngle + variation
    }
    
    private var distance: CGFloat {
        // Distance from center based on value (higher values further out) - grand oak tree spacing
        let baseDistance: CGFloat = 60 // Increased from 50 for fuller tree
        let growthPerLevel: CGFloat = 15 // Increased from 12 for more spread
        
        // Position based on value: normalize to 0-1, then scale
        let normalizedValue = min(leafData.value / max(maxValue, 1.0), 1.0)
        let valueBasedDistance = CGFloat(normalizedValue) * 45.0 // Max 45pt additional distance (increased from 35)
        
        // Add variation for natural distribution
        let variation = sin(Double(index) * 0.3) * 10.0 // More variation for fuller look
        
        return baseDistance + (CGFloat(treeLevel) * growthPerLevel) + valueBasedDistance + CGFloat(variation)
    }
    
    private var verticalOffset: CGFloat {
        // Higher values positioned slightly higher on tree
        let normalizedValue = min(leafData.value / max(maxValue, 1.0), 1.0)
        return CGFloat(normalizedValue) * -15.0 // Move up for higher values
    }
    
    private var xOffset: CGFloat {
        cos(angle * .pi / 180) * distance
    }
    
    private var yOffset: CGFloat {
        sin(angle * .pi / 180) * distance + verticalOffset
    }
    
    // Leaf size based on value (larger leaves for higher values) - grand oak tree size
    // Ensure minimum size for readability, especially for small values like $10
    private var leafSize: (width: CGFloat, height: CGFloat) {
        let baseSize: CGFloat = 55 // Increased from 42 for better readability
        let normalizedValue = min(leafData.value / max(maxValue, 1.0), 1.0)
        // Minimum multiplier ensures even small values are readable
        let sizeMultiplier = max(1.0, 1.0 + (CGFloat(normalizedValue) * 0.5)) // Up to 50% larger, but minimum 1.0
        
        if leafData.type == .goal {
            // Goal leaves: minimum 60x80, can grow larger
            let width = max(60, 60 * sizeMultiplier)
            let height = max(80, 80 * sizeMultiplier)
            return (width: width, height: height)
        } else {
            // Milestone leaves: minimum 55x70, can grow larger
            let width = max(55, baseSize * sizeMultiplier)
            let height = max(70, 70 * sizeMultiplier)
            return (width: width, height: height)
        }
    }
    
    var body: some View {
        ZStack {
            if leafData.type == .goal {
                // Goal leaf - special color with actual leaf shape
                Button(action: {
                    // Only allow tap on goal leaves (not milestone leaves)
                    print("🍃 [LeafView] Goal leaf tapped: \(leafData.goal?.name ?? "unknown")")
                    if let goal = leafData.goal {
                        print("🍃 [LeafView] Calling onGoalTapped callback for goal: \(goal.name)")
                        onGoalTapped?(goal)
                    } else {
                        print("⚠️ [LeafView] Goal leaf tapped but goal is nil!")
                    }
                }) {
                    ZStack {
                        // Custom leaf shape with gradient - fills in as savings grow
                        ZStack {
                            // Background (unfilled portion) - lighter/more transparent
                            // In night mode, make it very subtle so only filled portion shows when progress > 0
                            LeafShape()
                                .fill(
                                    LinearGradient(
                                        colors: isActiveGoal ? [
                                            Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.3), // Light blue for active
                                            Color(red: 0.1, green: 0.5, blue: 0.9).opacity(0.2)
                                        ] : isDarkTheme ? [
                                            Color(red: 0.5, green: 0.7, blue: 1.0).opacity(0.1), // Very subtle for night - only shows outline
                                            Color(red: 0.4, green: 0.6, blue: 0.95).opacity(0.05)
                                        ] : [
                                            Color.reverBlue.opacity(0.3), // Light blue
                                            Color.deepReverBlue.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: leafSize.width, height: leafSize.height)
                            
                            // Filled portion - grows as progress increases
                            LeafShape()
                                .fill(
                                    LinearGradient(
                                        colors: isReached ? [
                                            Color(red: 0.9, green: 0.7, blue: 0.1), // Gold for completed
                                            Color(red: 0.8, green: 0.6, blue: 0.0)
                                        ] : isActiveGoal ? [
                                            // Highlighted colors for active goal
                                            Color(red: 0.2, green: 0.6, blue: 1.0), // Bright blue
                                            Color(red: 0.1, green: 0.5, blue: 0.9)  // Deeper blue
                                        ] : isDarkTheme ? [
                                            // Lighter blue for night theme to stand out
                                            Color(red: 0.5, green: 0.7, blue: 1.0), // Bright light blue
                                            Color(red: 0.4, green: 0.6, blue: 0.95)  // Slightly darker light blue
                                        ] : [
                                            Color.reverBlue, // Full opacity for visibility
                                            Color.deepReverBlue
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: leafSize.width, height: leafSize.height)
                                .mask(
                                    // Mask to show only the filled portion based on progress
                                    GeometryReader { geometry in
                                        Rectangle()
                                            .frame(width: geometry.size.width * CGFloat(progress), height: geometry.size.height)
                                            .offset(x: -geometry.size.width * (1.0 - CGFloat(progress)) / 2)
                                    }
                                )
                        }
                        .frame(width: leafSize.width, height: leafSize.height)
                        .rotationEffect(.degrees(angle))
                        .overlay(
                            // Leaf vein detail
                            LeafShape()
                                .stroke(
                                    isReached ? Color(red: 0.7, green: 0.5, blue: 0.0).opacity(0.3) : Color.white.opacity(0.2),
                                    lineWidth: isActiveGoal ? 2 : 1
                                )
                                .frame(width: leafSize.width, height: leafSize.height)
                                .rotationEffect(.degrees(angle))
                        )
                        
                        // Goal name/value text and icon - larger and more readable
                        ZStack {
                            if !isReached && progress > 0.1 {
                                // Show progress percentage for leaves that are filling in
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: min(leafSize.width * 0.32, 14), weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                                    .offset(x: 0, y: -leafSize.height * 0.15)
                            }
                            
                            // Goal name/value text for goal leaves - larger and more readable
                            if let goal = leafData.goal {
                                VStack(spacing: 2) {
                                    Text(goal.name)
                                        .font(.system(size: min(leafSize.width * 0.25, 11), weight: .semibold))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.6), radius: 2, x: 0, y: 1)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    Text(formatMilestoneValue(leafData.value))
                                        .font(.system(size: min(leafSize.width * 0.35, 15), weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.6), radius: 3, x: 0, y: 1)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .offset(x: 0, y: -2)
                            }
                            
                            Image(systemName: isReached ? "checkmark.circle.fill" : (isActiveGoal ? "star.fill" : "tree.fill"))
                                .font(.system(size: isActiveGoal ? min(leafSize.width * 0.5, 20) : min(leafSize.width * 0.4, 18)))
                                .foregroundColor(isActiveGoal ? Color.yellow : .white)
                                .shadow(color: isActiveGoal ? Color.yellow.opacity(0.8) : Color.black.opacity(0.5), radius: 4, x: 0, y: 0)
                                .offset(x: 0, y: leafData.goal != nil ? leafSize.height * 0.2 : -2)
                        }
                    }
                    .frame(width: leafSize.width, height: leafSize.height)
                }
                .buttonStyle(PlainButtonStyle()) // Remove default button styling
                .contentShape(Rectangle()) // Ensure entire button area is tappable
                .offset(x: xOffset, y: yOffset)
                .shadow(
                    color: isReached 
                        ? Color(red: 0.9, green: 0.7, blue: 0.1).opacity(0.8) 
                        : isActiveGoal
                            ? Color.yellow.opacity(0.9) // Bright yellow shadow for active goal
                            : isDarkTheme 
                                ? Color(red: 0.5, green: 0.7, blue: 1.0).opacity(0.8) // Brighter shadow for night
                                : Color.reverBlue.opacity(0.6), 
                    radius: isReached ? 10 : (isActiveGoal ? 12 : (isDarkTheme ? 9 : 7)), 
                    x: 0, 
                    y: 4
                )
                .scaleEffect(isReached ? 1.1 : (isActiveGoal ? 1.15 : 1.0)) // Larger when reached or active
            } else {
                // Milestone leaf - green with actual leaf shape, fills in as savings grow
                ZStack {
                    // Background (unfilled portion) - lighter/more transparent
                    // In night mode, make it very subtle so only filled portion shows when progress > 0
                    LeafShape()
                        .fill(
                            LinearGradient(
                                colors: isDarkTheme ? [
                                    Color(red: 0.5, green: 0.9, blue: 0.55).opacity(0.1), // Very subtle for night - only shows outline
                                    Color(red: 0.45, green: 0.8, blue: 0.5).opacity(0.05)
                                ] : [
                                    Color(red: 0.3, green: 0.75, blue: 0.35).opacity(0.3), // Light green
                                    Color(red: 0.25, green: 0.65, blue: 0.3).opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: leafSize.width, height: leafSize.height)
                    
                    // Filled portion - grows as progress increases
                    LeafShape()
                        .fill(
                            LinearGradient(
                                colors: isReached ? [
                                    isDarkTheme 
                                        ? Color(red: 0.4, green: 0.85, blue: 0.5)  // Lighter green for night
                                        : Color(red: 0.2, green: 0.7, blue: 0.3), // Rich green
                                    isDarkTheme 
                                        ? Color(red: 0.35, green: 0.75, blue: 0.45)  // Lighter green for night
                                        : Color(red: 0.15, green: 0.6, blue: 0.25)
                                ] : isDarkTheme ? [
                                    Color(red: 0.5, green: 0.9, blue: 0.55), // Much lighter green for night
                                    Color(red: 0.45, green: 0.8, blue: 0.5)   // Lighter green for night
                                ] : [
                                    Color(red: 0.3, green: 0.75, blue: 0.35), // More vibrant green
                                    Color(red: 0.25, green: 0.65, blue: 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: leafSize.width, height: leafSize.height)
                        .mask(
                            // Mask to show only the filled portion based on progress
                            GeometryReader { geometry in
                                Rectangle()
                                    .frame(width: geometry.size.width * CGFloat(progress), height: geometry.size.height)
                                    .offset(x: -geometry.size.width * (1.0 - CGFloat(progress)) / 2)
                            }
                        )
                    
                    // Leaf vein detail
                    LeafShape()
                        .stroke(
                            isReached ? Color.white.opacity(0.3) : Color.white.opacity(0.15),
                            lineWidth: 0.5
                        )
                        .frame(width: leafSize.width, height: leafSize.height)
                    
                    // Value label for milestone leaves - larger for readability with better contrast
                    VStack(spacing: 3) {
                        if !isReached && progress > 0.1 {
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: min(leafSize.width * 0.32, 14), weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        }
                        Text(formatMilestoneValue(leafData.value))
                            .font(.system(size: min(leafSize.width * 0.4, 16), weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.6), radius: 3, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .offset(x: 0, y: -1)
                }
                .frame(width: leafSize.width, height: leafSize.height)
                .rotationEffect(.degrees(angle))
                .offset(x: xOffset, y: yOffset)
                .opacity(isReached ? 1.0 : (isDarkTheme ? 0.85 : 0.6)) // More visible at night
                .shadow(
                    color: isDarkTheme 
                        ? Color(red: 0.5, green: 0.9, blue: 0.55).opacity(isReached ? 0.8 : 0.5)  // Brighter green shadow for night
                        : Color.green.opacity(isReached ? 0.6 : 0.3), 
                    radius: isReached ? (isDarkTheme ? 10 : 8) : (isDarkTheme ? 7 : 5), 
                    x: 0, 
                    y: 3
                )
            }
        }
        .animation(
            .spring(response: 0.6, dampingFraction: 0.7)
                .delay(Double(index) * 0.05), // Staggered appearance
            value: progress
        )
    }
    
    private func formatMilestoneValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "$%.0fk", value / 1000)
        } else {
            return String(format: "$%.0f", value)
        }
    }
}

// MARK: - Custom Leaf Shape
struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        
        // Create a natural leaf shape (oval with pointed tip)
        path.move(to: CGPoint(x: centerX, y: height * 0.95)) // Bottom center (stem)
        
        // Left side curve
        path.addCurve(
            to: CGPoint(x: width * 0.2, y: height * 0.3),
            control1: CGPoint(x: width * 0.15, y: height * 0.7),
            control2: CGPoint(x: width * 0.1, y: height * 0.5)
        )
        
        // Top point
        path.addLine(to: CGPoint(x: centerX, y: height * 0.05))
        
        // Right side curve
        path.addCurve(
            to: CGPoint(x: centerX, y: height * 0.95),
            control1: CGPoint(x: width * 0.9, y: height * 0.5),
            control2: CGPoint(x: width * 0.85, y: height * 0.7)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Branch Structure View
struct BranchStructureView: View {
    let level: Int
    let treeHeight: CGFloat
    
    var body: some View {
        ZStack {
            // Completely redesigned branch structure - natural tree canopy pattern
            // Use straight lines with slight curves instead of C-shapes
            if level >= 1 {
                // Main branches - spread outward in a V pattern
                // Left branch - straight outward, not curved
                Path { path in
                    let centerX = treeHeight * 0.5
                    let startY = treeHeight * 0.5
                    path.move(to: CGPoint(x: centerX, y: startY))
                    path.addLine(to: CGPoint(
                        x: centerX - treeHeight * 0.25,
                        y: startY - treeHeight * 0.15
                    ))
                }
                .stroke(Color(red: 0.55, green: 0.35, blue: 0.2), lineWidth: 5)
                
                // Right branch - straight outward
                Path { path in
                    let centerX = treeHeight * 0.5
                    let startY = treeHeight * 0.5
                    path.move(to: CGPoint(x: centerX, y: startY))
                    path.addLine(to: CGPoint(
                        x: centerX + treeHeight * 0.25,
                        y: startY - treeHeight * 0.15
                    ))
                }
                .stroke(Color(red: 0.55, green: 0.35, blue: 0.2), lineWidth: 5)
                
                // Center branch - goes straight up
                Path { path in
                    let centerX = treeHeight * 0.5
                    let startY = treeHeight * 0.5
                    path.move(to: CGPoint(x: centerX, y: startY))
                    path.addLine(to: CGPoint(
                        x: centerX,
                        y: startY - treeHeight * 0.2
                    ))
                }
                .stroke(Color(red: 0.55, green: 0.35, blue: 0.2), lineWidth: 4)
            }
            
            if level >= 3 {
                // Secondary branches - branch off from main branches
                // Left side secondary branches
                Path { path in
                    let startX = treeHeight * 0.25
                    let startY = treeHeight * 0.35
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: startX - treeHeight * 0.15, y: startY - treeHeight * 0.12))
                }
                .stroke(Color(red: 0.52, green: 0.32, blue: 0.18), lineWidth: 3.5)
                
                Path { path in
                    let startX = treeHeight * 0.25
                    let startY = treeHeight * 0.35
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: startX - treeHeight * 0.1, y: startY - treeHeight * 0.15))
                }
                .stroke(Color(red: 0.52, green: 0.32, blue: 0.18), lineWidth: 3.5)
                
                // Right side secondary branches
                Path { path in
                    let startX = treeHeight * 0.75
                    let startY = treeHeight * 0.35
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: startX + treeHeight * 0.15, y: startY - treeHeight * 0.12))
                }
                .stroke(Color(red: 0.52, green: 0.32, blue: 0.18), lineWidth: 3.5)
                
                Path { path in
                    let startX = treeHeight * 0.75
                    let startY = treeHeight * 0.35
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: startX + treeHeight * 0.1, y: startY - treeHeight * 0.15))
                }
                .stroke(Color(red: 0.52, green: 0.32, blue: 0.18), lineWidth: 3.5)
                
                // Center secondary branches
                Path { path in
                    let centerX = treeHeight * 0.5
                    let startY = treeHeight * 0.3
                    path.move(to: CGPoint(x: centerX, y: startY))
                    path.addLine(to: CGPoint(x: centerX - treeHeight * 0.08, y: startY - treeHeight * 0.1))
                }
                .stroke(Color(red: 0.52, green: 0.32, blue: 0.18), lineWidth: 3.5)
                
                Path { path in
                    let centerX = treeHeight * 0.5
                    let startY = treeHeight * 0.3
                    path.move(to: CGPoint(x: centerX, y: startY))
                    path.addLine(to: CGPoint(x: centerX + treeHeight * 0.08, y: startY - treeHeight * 0.1))
                }
                .stroke(Color(red: 0.52, green: 0.32, blue: 0.18), lineWidth: 3.5)
            }
            
            if level >= 5 {
                // Tertiary branches - smaller twigs
                ForEach([-60, -40, -20, 20, 40, 60], id: \.self) { angle in
                    Path { path in
                        let centerX = treeHeight * 0.5
                        let baseY = treeHeight * 0.2
                        let radians = Double(angle) * .pi / 180
                        let length = treeHeight * 0.1
                        path.move(to: CGPoint(x: centerX, y: baseY))
                        path.addLine(to: CGPoint(
                            x: centerX + cos(radians) * length,
                            y: baseY + sin(radians) * length - treeHeight * 0.08
                        ))
                    }
                    .stroke(Color(red: 0.5, green: 0.3, blue: 0.15), lineWidth: 2.5)
                }
            }
        }
    }
}

// MARK: - Branch Path
struct BranchPath: Shape {
    let angle: Double // Angle in degrees
    let length: CGFloat
    let startY: CGFloat
    let curvature: Double // Curvature factor (-1 to 1, positive curves right, negative curves left)
    
    init(angle: Double, length: CGFloat, startY: CGFloat, curvature: Double = 0.0) {
        self.angle = angle
        self.length = length
        self.startY = startY
        self.curvature = curvature
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.width / 2
        let startPoint = CGPoint(x: centerX, y: startY)
        
        path.move(to: startPoint)
        
        // Create more natural branch curve
        let radians = angle * .pi / 180
        let endX = startPoint.x + cos(radians) * length
        let endY = startPoint.y + sin(radians) * length
        
        // Control point for curve - adjusted to create more natural branching
        // Perpendicular offset based on curvature
        let perpAngle = radians + .pi / 2
        let curveOffset = length * 0.4 * CGFloat(curvature)
        let controlX = startPoint.x + cos(radians) * length * 0.6 + cos(perpAngle) * curveOffset
        let controlY = startPoint.y + sin(radians) * length * 0.4 + sin(perpAngle) * curveOffset
        
        path.addQuadCurve(
            to: CGPoint(x: endX, y: endY),
            control: CGPoint(x: controlX, y: controlY)
        )
        
        return path
    }
}

// MARK: - Trunk View with Enhanced Texture
struct TrunkView: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // Base trunk - rich brown gradient
            RoundedRectangle(cornerRadius: width / 2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.7, green: 0.5, blue: 0.3), // Rich light brown
                            Color(red: 0.6, green: 0.4, blue: 0.25), // Medium brown
                            Color(red: 0.5, green: 0.35, blue: 0.2), // Darker brown
                            Color(red: 0.45, green: 0.3, blue: 0.18)  // Deep brown
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: width, height: height)
                .shadow(color: Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.5), radius: 6, x: 0, y: 3)
            
            // Vertical bark texture lines
            VStack(spacing: 2) {
                ForEach(0..<Int(height / 8), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.25, blue: 0.15).opacity(0.3),
                                    Color.clear,
                                    Color(red: 0.4, green: 0.25, blue: 0.15).opacity(0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width * 0.3, height: 1)
                }
            }
            
            // Horizontal bark texture (subtle rings)
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color(red: 0.35, green: 0.22, blue: 0.12).opacity(0.2))
                        .frame(width: 1, height: height * 0.4)
                }
            }
            
            // Highlight on left side for 3D effect
            RoundedRectangle(cornerRadius: width / 2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width, height: height)
            
            // Shadow on right side for depth
            RoundedRectangle(cornerRadius: width / 2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width, height: height)
        }
    }
}

// MARK: - Celebration Effect View
struct CelebrationEffectView: View {
    let treeCenter: CGPoint
    @State private var sparkles: [Sparkle] = []
    
    struct Sparkle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var scale: CGFloat
    }
    
    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)
                    .opacity(sparkle.opacity)
                    .scaleEffect(sparkle.scale)
                    .position(x: sparkle.x, y: sparkle.y)
            }
        }
        .onAppear {
            // Generate sparkles in a circle around tree center
            let radius: CGFloat = 100
            
            for i in 0..<24 {
                let angle = Double(i) * (360.0 / 24.0) * .pi / 180.0
                let x = treeCenter.x + cos(angle) * radius
                let y = treeCenter.y + sin(angle) * radius
                
                sparkles.append(Sparkle(
                    x: x,
                    y: y,
                    opacity: 1.0,
                    scale: 0.5
                ))
            }
            
            // Animate sparkles outward
            withAnimation(.easeOut(duration: 1.5)) {
                for i in sparkles.indices {
                    let angle = Double(i) * (360.0 / 24.0) * .pi / 180.0
                    sparkles[i].x = treeCenter.x + cos(angle) * radius * 2.5
                    sparkles[i].y = treeCenter.y + sin(angle) * radius * 2.5
                    sparkles[i].opacity = 0.0
                    sparkles[i].scale = 1.5
                }
            }
        }
    }
}

#Preview {
    MoneyTreeView(
        totalSaved: 150.0,
        activeGoal: SavingsGoal(
            id: "preview",
            name: "Trip to Hawaii",
            targetAmount: 2000,
            currentAmount: 500,
            category: .trip
        ),
        allGoals: [
            SavingsGoal(id: "preview", name: "Trip to Hawaii", targetAmount: 2000, currentAmount: 500, category: .trip),
            SavingsGoal(id: "preview2", name: "New Car", targetAmount: 15000, currentAmount: 3000, category: .purchase)
        ]
    )
    .padding()
    .background(Color.dreamMist)
}

