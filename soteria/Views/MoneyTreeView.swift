//
//  MoneyTreeView.swift
//  soteria
//
//  Modern, sleek money tree that fills from bottom to top
//  Clear lines show progress and dollar values
//

import SwiftUI
import Combine

struct MoneyTreeView: View {
    let totalSaved: Double
    let activeGoal: SavingsGoal?
    let allGoals: [SavingsGoal]
    var onGoalLeafTapped: ((SavingsGoal) -> Void)? = nil
    var isEditMode: Bool = false // Edit mode for placing/moving items
    
    @StateObject private var themeService = TimeBasedThemeService.shared
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect() // Update every minute
    
    var body: some View {
        ZStack {
            // Background scene with sky and ground
            VStack(spacing: 0) {
                // Sky gradient (top 65% of view)
                LinearGradient(
                    colors: themeService.currentGradient.isEmpty ? 
                        [Color(red: 0.9, green: 0.95, blue: 1.0), Color(red: 0.8, green: 0.9, blue: 0.98)] :
                        themeService.currentGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(maxHeight: .infinity) // Sky takes remaining space
                
                // Horizon line
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .frame(height: 2)
                
                // Ground (bottom 35% of view)
                LinearGradient(
                    colors: themeService.currentTheme == .night ? [
                        Color(red: 0.15, green: 0.25, blue: 0.35),  // Blue-tinted grass at night
                        Color(red: 0.12, green: 0.22, blue: 0.32)
                    ] : [
                        Color(red: 0.5, green: 0.75, blue: 0.3),  // Bright grass green
                        Color(red: 0.45, green: 0.7, blue: 0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 175) // Ground portion
            }
            .cornerRadius(12)
            
            // Time-based visual elements (stars, moon, sun, clouds)
            if themeService.currentTheme.hasMoon {
                // Full moon - positioned high in the sky
                let moonPos = themeService.currentTheme.moonPosition
                ZStack {
                    // Moon glow
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    // Main moon body
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.95, blue: 0.97),
                                    Color(red: 0.85, green: 0.85, blue: 0.88)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 45, height: 45)
                    
                    // Moon craters (subtle texture)
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 8, height: 8)
                        .offset(x: -8, y: -5)
                    
                    Circle()
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 6, height: 6)
                        .offset(x: 10, y: 8)
                    
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 5, height: 5)
                        .offset(x: 5, y: -10)
                }
                .offset(x: moonPos.x * 150 - 75, y: -150) // Higher in the sky, above tree canopy
            }
            
            if themeService.currentTheme.hasStars {
                // Stars scattered across the sky portion only (stable positions with shimmer)
                let starPositions: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
                    (-120, -150, 6), (-80, -130, 5), (-40, -110, 7), (0, -140, 5),
                    (40, -120, 6), (80, -150, 5), (120, -130, 7), (-100, -100, 5),
                    (-60, -170, 6), (20, -110, 5), (60, -140, 7), (-140, -130, 5),
                    (100, -100, 6), (-20, -160, 5), (140, -120, 7), (-80, -180, 5),
                    (40, -160, 6), (-120, -90, 5), (80, -170, 7), (-40, -130, 5)
                ]
                ForEach(Array(starPositions.enumerated()), id: \.offset) { index, pos in
                    ShimmeringStar(size: pos.size, delay: Double(index) * 0.1)
                        .offset(x: pos.x, y: pos.y)
                }
            }
            
            if themeService.currentTheme.hasSun {
                // Sun - moves across sky based on time of day (updates every minute)
                let sunPos = themeService.currentTheme.sunPosition
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: currentTime)
                let minute = calendar.component(.minute, from: currentTime)
                
                // Calculate smooth sun position based on exact time
                let sunX: CGFloat = {
                    // Sun moves from left (dawn) to right (sunset) throughout the day
                    if hour >= 5 && hour < 7 {
                        // Dawn: 5-7am, moves from 0.1 to 0.2
                        let progress = CGFloat(hour - 5) + CGFloat(minute) / 60.0
                        return 0.1 + (progress / 2.0) * 0.1
                    } else if hour >= 7 && hour < 12 {
                        // Morning: 7am-12pm, moves from 0.2 to 0.5
                        let progress = CGFloat(hour - 7) + CGFloat(minute) / 60.0
                        return 0.2 + (progress / 5.0) * 0.3
                    } else if hour >= 12 && hour < 17 {
                        // Afternoon: 12pm-5pm, moves from 0.5 to 0.75
                        let progress = CGFloat(hour - 12) + CGFloat(minute) / 60.0
                        return 0.5 + (progress / 5.0) * 0.25
                    } else if hour >= 17 && hour < 19 {
                        // Evening: 5pm-7pm, moves from 0.75 to 0.85
                        let progress = CGFloat(hour - 17) + CGFloat(minute) / 60.0
                        return 0.75 + (progress / 2.0) * 0.1
                    } else if hour >= 19 && hour < 21 {
                        // Sunset: 7pm-9pm, moves from 0.85 to 0.95
                        let progress = CGFloat(hour - 19) + CGFloat(minute) / 60.0
                        return 0.85 + (progress / 2.0) * 0.1
                    } else {
                        return sunPos.x
                    }
                }()
                
                let sunY: CGFloat = {
                    // Sun rises in morning, peaks at noon, sets in evening
                    // Reduced values to position sun higher in sky (further from tree)
                    if hour >= 5 && hour < 12 {
                        // Rising: from 0.2 (dawn) to 0.08 (noon) - starts higher
                        let progress = CGFloat(hour - 5) + CGFloat(minute) / 60.0
                        return 0.2 - (progress / 7.0) * 0.12
                    } else if hour >= 12 && hour < 19 {
                        // Setting: from 0.08 (noon) to 0.15 (evening) - stays high
                        let progress = CGFloat(hour - 12) + CGFloat(minute) / 60.0
                        return 0.08 + (progress / 7.0) * 0.07
                    } else {
                        return sunPos.y
                    }
                }()
                
                ZStack {
                    // Sun glow
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 70, height: 70)
                    
                    // Sun
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                }
                .offset(x: sunX * 150 - 75, y: (sunY * 150) - 160) // Higher in sky, clear of tree canopy
                .animation(.easeInOut(duration: 0.5), value: sunX)
            }
            
            if themeService.currentTheme.hasClouds {
                // Clouds in sky portion only
                let cloudPositions: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
                    (-100, -100, 40), (80, -140, 35), (-20, -120, 38)
                ]
                ForEach(Array(cloudPositions.enumerated()), id: \.offset) { index, pos in
                    Image(systemName: "cloud.fill")
                        .font(.system(size: pos.size))
                        .foregroundColor(.white.opacity(0.6))
                        .offset(x: pos.x, y: pos.y)
                }
            }
            
            // Money Tree - positioned on the ground, growing up into the sky
            GeometryReader { geometry in
                let treeWidth: CGFloat = min(geometry.size.width * 0.5, 200)
                let treeHeight: CGFloat = geometry.size.height * 0.62 // Taller tree reaching toward stars
                // Ground Y position calculated at 0.65 * geometry.size.height (not used but kept for reference)
                
                ZStack {
                    // Tree positioned with base just above bottom, canopy reaches high
                    MoneyTreeShape(
                        treeWidth: treeWidth,
                        treeHeight: treeHeight,
                        totalSaved: totalSaved,
                        allGoals: allGoals,
                        onGoalTapped: onGoalLeafTapped
                    )
                    // Position: trunk base at bottom, canopy top stops just below stars
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.65)
                    
                    // Purchased Scene Items (animals, decorations)
                    PurchasedSceneItems(geometry: geometry, isEditMode: isEditMode)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400, maxHeight: 500)
        .cornerRadius(12)
        .clipped()
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            currentTime = Date()
        }
    }
}

// Shimmering star view with animation
struct ShimmeringStar: View {
    let size: CGFloat
    let delay: Double
    @State private var isShimmering = false
    
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: size))
            .foregroundColor(.white)
            .opacity(isShimmering ? 0.4 : 1.0)
            .scaleEffect(isShimmering ? 0.8 : 1.0)
            .animation(
                Animation.easeInOut(duration: Double.random(in: 1.5...2.5))
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isShimmering
            )
            .onAppear {
                isShimmering = true
            }
    }
}

// Money Tree Shape with cloud-like canopy and progressive fill
struct MoneyTreeShape: View {
    let treeWidth: CGFloat
    let treeHeight: CGFloat
    let totalSaved: Double
    let allGoals: [SavingsGoal]
    var onGoalTapped: ((SavingsGoal) -> Void)?
    
    // MARK: - Tree Scaling Logic
    // Calculate max value for the tree scale - adaptive to user's actual savings
    // This determines the "top" of the tree and how progress fills from bottom to top
    private var maxValue: Double {
        let highestGoal = allGoals.map { $0.targetAmount }.max() ?? 0
        
        // SCENARIO 1: New users with no goals and minimal savings
        // Purpose: Show immediate progress to motivate new users
        if highestGoal == 0 && totalSaved < 1000 {
            return 1000 // Start with $1k scale - saving $100 shows ~23% tree fill
        }
        
        // SCENARIO 2: User has small goals ($0-$5k)
        // Purpose: Keep tree scale tight to goals for maximum visual progress
        else if highestGoal > 0 && highestGoal <= 5000 {
            return max(highestGoal * 1.1, 5000) // 10% buffer above goal, minimum $5k scale
        }
        
        // SCENARIO 3: User has larger goals (>$5k)
        // Purpose: Show goal clearly with breathing room above it
        else if highestGoal > 0 {
            return highestGoal * 1.15 // 15% buffer above highest goal
        }
        
        // SCENARIO 4: No goals set, user is saving
        // Purpose: Grow tree dynamically but cap it to encourage goal setting
        else {
            // Scale at 2x current savings to show progress while leaving room to grow
            let dynamicScale = max(totalSaved * 2.0, 1000)
            
            // ⚠️ KEY TUNING PARAMETER: $10k cap without goals
            // Why: Encourages users to set goals once they reach ~$5k in savings
            // To adjust: Increase cap (e.g., $25k) if users commonly save more without goals
            //            Decrease cap (e.g., $5k) to push goal setting earlier
            return min(dynamicScale, 10000)
        }
    }
    
    // MARK: - Fill Progress Calculation
    // Converts dollar amount to visual fill percentage (0.0 to 1.0)
    // Uses power curve to make early progress more motivating
    private var fillProgress: Double {
        let linearProgress = min(totalSaved / maxValue, 1.0)
        
        // ⚠️ KEY TUNING PARAMETER: Power curve exponent (currently 0.55)
        // Lower values (e.g., 0.5) = MORE early progress visibility
        // Higher values (e.g., 0.7) = LESS early progress boost, more linear
        // Current setting shows:
        //   - $100 of $1,000 → ~23% fill (vs 10% linear)
        //   - $500 of $5,000 → ~18% fill (vs 10% linear)
        //   - $1,000 of $10,000 → ~16% fill (vs 10% linear)
        return pow(linearProgress, 0.55)
    }
    
    // Trunk occupies bottom 40% of tree height
    private var trunkFillProgress: Double {
        if fillProgress <= 0.4 {
            return fillProgress / 0.4 // 0 to 1 for trunk portion
        }
        return 1.0 // Trunk fully filled
    }
    
    // Canopy occupies top 60% of tree height
    private var canopyFillProgress: Double {
        if fillProgress <= 0.4 {
            return 0.0 // Not started yet
        }
        return (fillProgress - 0.4) / 0.6 // 0 to 1 for canopy portion
    }
    
    var body: some View {
        ZStack {
            // OUTLINE LAYER (white/unfilled)
            ZStack {
                // Trunk outline (unfilled)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: treeWidth * 0.25, height: treeHeight * 0.4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .offset(y: treeHeight * 0.3)
                
                // Canopy outline (unfilled) - cloud shapes
                ZStack {
                    // Bottom layer
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: treeWidth * 0.35, height: treeWidth * 0.35)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2.5))
                            .offset(x: CGFloat(i - 2) * treeWidth * 0.25, y: treeHeight * 0.08)
                    }
                    
                    // Middle layer
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: treeWidth * 0.32, height: treeWidth * 0.32)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2.5))
                            .offset(x: (CGFloat(i) - 2.5) * treeWidth * 0.22, y: -treeHeight * 0.08)
                    }
                    
                    // Upper middle layer (NEW - for more height)
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: treeWidth * 0.3, height: treeWidth * 0.3)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2.5))
                            .offset(x: CGFloat(i - 2) * treeWidth * 0.21, y: -treeHeight * 0.18)
                    }
                    
                    // Top layer
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: treeWidth * 0.28, height: treeWidth * 0.28)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2.5))
                            .offset(x: CGFloat(i - 2) * treeWidth * 0.2, y: -treeHeight * 0.28)
                    }
                    
                    // Upper layer
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: treeWidth * 0.26, height: treeWidth * 0.26)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2.5))
                            .offset(x: (CGFloat(i) - 1.5) * treeWidth * 0.19, y: -treeHeight * 0.36)
                    }
                    
                    // Peak clouds
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: treeWidth * 0.24, height: treeWidth * 0.24)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2.5))
                            .offset(x: CGFloat(i - 1) * treeWidth * 0.18, y: -treeHeight * 0.43)
                    }
                }
                .offset(y: -treeHeight * 0.05)
            }
            
            // FILL LAYER (colored, masked from bottom up)
            ZStack {
                // Trunk fill (brown)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.55, green: 0.35, blue: 0.2))
                    .frame(width: treeWidth * 0.25, height: treeHeight * 0.4)
                    .mask(
                        Rectangle()
                            .frame(height: treeHeight * 0.4 * trunkFillProgress)
                            .offset(y: treeHeight * 0.4 * (1 - trunkFillProgress) / 2)
                    )
                    .offset(y: treeHeight * 0.3)
                
                // Canopy fill (money green)
                ZStack {
                    // Bottom layer
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color(red: 0.2, green: 0.7, blue: 0.3))
                            .frame(width: treeWidth * 0.35, height: treeWidth * 0.35)
                            .offset(x: CGFloat(i - 2) * treeWidth * 0.25, y: treeHeight * 0.08)
                    }
                    
                    // Middle layer
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(Color(red: 0.2, green: 0.7, blue: 0.3))
                            .frame(width: treeWidth * 0.32, height: treeWidth * 0.32)
                            .offset(x: (CGFloat(i) - 2.5) * treeWidth * 0.22, y: -treeHeight * 0.08)
                    }
                    
                    // Upper middle layer (NEW - for more height)
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color(red: 0.2, green: 0.7, blue: 0.3))
                            .frame(width: treeWidth * 0.3, height: treeWidth * 0.3)
                            .offset(x: CGFloat(i - 2) * treeWidth * 0.21, y: -treeHeight * 0.18)
                    }
                    
                    // Top layer
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color(red: 0.2, green: 0.7, blue: 0.3))
                            .frame(width: treeWidth * 0.28, height: treeWidth * 0.28)
                            .offset(x: CGFloat(i - 2) * treeWidth * 0.2, y: -treeHeight * 0.28)
                    }
                    
                    // Upper layer
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(Color(red: 0.2, green: 0.7, blue: 0.3))
                            .frame(width: treeWidth * 0.26, height: treeWidth * 0.26)
                            .offset(x: (CGFloat(i) - 1.5) * treeWidth * 0.19, y: -treeHeight * 0.36)
                    }
                    
                    // Peak clouds
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color(red: 0.2, green: 0.7, blue: 0.3))
                            .frame(width: treeWidth * 0.24, height: treeWidth * 0.24)
                            .offset(x: CGFloat(i - 1) * treeWidth * 0.18, y: -treeHeight * 0.43)
                    }
                }
                .offset(y: -treeHeight * 0.05)
                .mask(
                    Rectangle()
                        .frame(height: treeHeight * 0.6 * canopyFillProgress)
                        .offset(y: treeHeight * 0.6 * (1 - canopyFillProgress) / 2 - treeHeight * 0.05)
                )
            }
            
            // VALUE MARKERS
            ForEach(generateMilestones(), id: \.self) { value in
                let yPos = milestonePosition(for: value)
                
                HStack(spacing: 4) {
                    // Left line
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 15, height: 1.5)
                    
                    // Value label
                    Text(formatValue(value))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(4)
                    
                    // Right line
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 15, height: 1.5)
                }
                .offset(y: yPos)
            }
            
            // GOAL MARKERS
            ForEach(allGoals.filter { $0.targetAmount <= maxValue }, id: \.id) { goal in
                let yPos = milestonePosition(for: goal.targetAmount)
                
                Button(action: {
                    onGoalTapped?(goal)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(goal.name)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.2, green: 0.5, blue: 0.8))
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white, lineWidth: 2)
                    )
                }
                .offset(x: treeWidth * 0.45, y: yPos)
            }
            
            // Grass tufts at base
            ForEach(0..<3, id: \.self) { i in
                GrassTuft()
                    .fill(Color(red: 0.25, green: 0.45, blue: 0.2))
                    .frame(width: 20, height: 15)
                    .overlay(
                        GrassTuft()
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                    .offset(
                        x: CGFloat(i - 1) * 30 - 10,
                        y: treeHeight * 0.48
                    )
            }
        }
        .frame(width: treeWidth, height: treeHeight)
    }
    
    // Calculate Y position for a given dollar value
    private func milestonePosition(for value: Double) -> CGFloat {
        let progress = value / maxValue
        // Bottom of tree (trunk base) to top
        return treeHeight * 0.5 - (CGFloat(progress) * treeHeight)
    }
    
    // MARK: - Milestone Generation
    // Generate dollar value markers displayed on the tree
    // Adaptive spacing based on tree scale to avoid clutter
    private func generateMilestones() -> [Double] {
        var milestones: [Double] = []
        let max = maxValue
        
        // ⚠️ TUNING GUIDE: Milestone Increments
        // Smaller increments = more markers = more progress feedback
        // Larger increments = fewer markers = cleaner display
        // Current settings balance motivation with readability
        
        if max <= 1000 {
            // $50 increments: $50, $100, $150... up to $1k
            milestones = stride(from: 50.0, through: max, by: 50).map { $0 }
        } else if max <= 2500 {
            // $250 increments: $250, $500, $750... up to $2.5k
            milestones = stride(from: 250.0, through: max, by: 250).map { $0 }
        } else if max <= 5000 {
            // $500 increments: $500, $1k, $1.5k... up to $5k
            milestones = stride(from: 500.0, through: max, by: 500).map { $0 }
        } else if max <= 10000 {
            // $1k increments: $1k, $2k, $3k... up to $10k
            milestones = stride(from: 1000.0, through: max, by: 1000).map { $0 }
        } else if max <= 25000 {
            // $2.5k increments: $2.5k, $5k, $7.5k... up to $25k
            milestones = stride(from: 2500.0, through: max, by: 2500).map { $0 }
        } else if max <= 50000 {
            // $5k increments: $5k, $10k, $15k... up to $50k
            milestones = stride(from: 5000.0, through: max, by: 5000).map { $0 }
        } else if max <= 100000 {
            // $10k increments: $10k, $20k, $30k... up to $100k
            milestones = stride(from: 10000.0, through: max, by: 10000).map { $0 }
        } else if max <= 250000 {
            // $25k increments: $25k, $50k, $75k... up to $250k
            milestones = stride(from: 25000.0, through: max, by: 25000).map { $0 }
        } else if max <= 500000 {
            // $50k increments: $50k, $100k, $150k... up to $500k
            milestones = stride(from: 50000.0, through: max, by: 50000).map { $0 }
        } else {
            // $100k increments: $100k, $200k, $300k... above $500k
            milestones = stride(from: 100000.0, through: max, by: 100000).map { $0 }
        }
        
        // ⚠️ KEY TUNING PARAMETER: Maximum milestone markers (currently 15)
        // Increase: More markers = better granularity but potential clutter
        // Decrease: Fewer markers = cleaner but less progress feedback
        return Array(milestones.prefix(15))
    }
    
    // Format value for display
    private func formatValue(_ value: Double) -> String {
        if value >= 1000000 {
            return String(format: "$%.1fM", value / 1000000)
        } else if value >= 1000 {
            return String(format: "$%.0fk", value / 1000)
        } else {
            return String(format: "$%.0f", value)
        }
    }
}

// Simple grass tuft shape
struct GrassTuft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Three grass blades
        path.move(to: CGPoint(x: width * 0.2, y: height))
        path.addLine(to: CGPoint(x: width * 0.15, y: 0))
        
        path.move(to: CGPoint(x: width * 0.5, y: height))
        path.addLine(to: CGPoint(x: width * 0.5, y: 0))
        
        path.move(to: CGPoint(x: width * 0.8, y: height))
        path.addLine(to: CGPoint(x: width * 0.85, y: 0))
        
        return path
    }
}

// MARK: - Purchased Scene Items Display
struct PurchasedSceneItems: View {
    let geometry: GeometryProxy
    let isEditMode: Bool
    @StateObject private var sceneManager = SceneManager.shared
    
    var body: some View {
        ZStack {
            // Display all placed items
            ForEach(sceneManager.visiblePlacements) { placement in
                if let item = SceneItem.catalog.first(where: { $0.id == placement.itemId }) {
                    DraggableSceneItemView(
                        item: item,
                        placement: placement,
                        geometry: geometry,
                        isEditMode: isEditMode
                    )
                }
            }
        }
    }
}

// MARK: - Draggable Scene Item
struct DraggableSceneItemView: View {
    let item: SceneItem
    let placement: SceneItemPlacement
    let geometry: GeometryProxy
    let isEditMode: Bool
    
    @StateObject private var sceneManager = SceneManager.shared
    @StateObject private var themeService = TimeBasedThemeService.shared
    @State private var dragOffset: CGSize = .zero
    @State private var isAnimating = false
    @State private var isInDragMode = false // Local drag mode enabled by long press
    
    var body: some View {
        SceneItemIcon(item: item, tintColor: colorForItem)
            .scaleEffect(x: placement.isFlipped ? -1 : 1, y: 1) // Flip horizontally if isFlipped
            .scaleEffect(dragOffset != .zero ? 1.2 : (isAnimating && !isEditMode ? 1.1 : 1.0))
            .animation(
                isEditMode ? nil : Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...1)),
                value: isAnimating
            )
            .offset(x: absoluteXPosition, y: absoluteYPosition)
            .opacity(dragOffset != .zero ? 0.8 : (isEditMode || isInDragMode ? 0.9 : itemOpacity))
            .overlay(
                // Drag mode indicator
                Group {
                    if isEditMode || isInDragMode {
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: item.fontSizeForIcon + 10, height: item.fontSizeForIcon + 10)
                        
                        // Exit drag mode button
                        if isInDragMode {
                            Button(action: {
                                withAnimation {
                                    isInDragMode = false
                                }
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                    .background(Circle().fill(Color.white))
                            }
                            .offset(x: item.fontSizeForIcon / 2 + 15, y: -item.fontSizeForIcon / 2 - 15)
                        }
                    }
                }
            )
            .onTapGesture {
                // Quick tap to flip orientation
                if !isInDragMode && !isEditMode {
                    sceneManager.toggleFlip(placementId: placement.id)
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                // Long press to enable drag mode
                withAnimation {
                    isInDragMode = true
                }
            }
            .gesture(
                (isEditMode || isInDragMode) ? DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        // Calculate new normalized position
                        let newX = (absoluteXPosition + value.translation.width + geometry.size.width / 2) / geometry.size.width
                        let newY = (absoluteYPosition + value.translation.height + geometry.size.height / 2) / geometry.size.height
                        
                        let newPosition = SceneItemPlacement.PlacementPosition(x: newX, y: newY)
                        sceneManager.updateItemPosition(placement.id, to: newPosition)
                        dragOffset = .zero
                        
                        // Auto-exit drag mode after positioning
                        withAnimation {
                            isInDragMode = false
                        }
                    } : nil
            )
            .onAppear {
                isAnimating = true
            }
    }
    
    // Convert normalized position to absolute screen position
    private var absoluteXPosition: CGFloat {
        let normalizedX = placement.position.x
        // Center is 0, left is negative, right is positive
        return (normalizedX * geometry.size.width) - (geometry.size.width / 2) + dragOffset.width
    }
    
    private var absoluteYPosition: CGFloat {
        let normalizedY = placement.position.y
        // Center is 0, top is negative, bottom is positive
        return (normalizedY * geometry.size.height) - (geometry.size.height / 2) + dragOffset.height
    }
    
    // Opacity adjusts based on time of day
    private var itemOpacity: Double {
        switch themeService.currentTheme {
        case .night:
            return 0.8 // Slightly dimmed at night
        case .sunset, .evening:
            return 0.9 // Transitioning
        default:
            return 1.0 // Full brightness during day
        }
    }
    
    // Dynamic color based on item type and time of day
    // Note: For custom images and emojis, this tint is only used if rendering as template
    private var colorForItem: Color {
        let isNight = themeService.currentTheme == .night
        let isEvening = themeService.currentTheme == .evening || themeService.currentTheme == .sunset
        
        switch item.category {
        case .animal:
            // Animals - Brown during day, cooler/darker at night
            return isNight ? Color(red: 0.3, green: 0.25, blue: 0.3) :
                   isEvening ? Color(red: 0.5, green: 0.35, blue: 0.25) :
                   Color(red: 0.6, green: 0.4, blue: 0.2)
            
        case .decoration:
            // Decorations - Colorful, slightly dimmed at night
            if item.id == "fireflies" {
                // Fireflies - Glow brighter at night!
                return isNight ? Color(red: 1.0, green: 0.9, blue: 0.3) :
                       Color(red: 0.8, green: 0.7, blue: 0.2)
            } else {
                return isNight ? Color(red: 0.5, green: 0.4, blue: 0.6) :
                       Color(red: 0.7, green: 0.5, blue: 0.8)
            }
            
        case .plant:
            // Plants - Green, darker and cooler at night
            return isNight ? Color(red: 0.2, green: 0.35, blue: 0.25) :
                   Color(red: 0.3, green: 0.7, blue: 0.3)
        }
    }
}
