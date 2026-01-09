//
//  SceneItem.swift
//  soteria
//
//  Represents decorative items that can be purchased and placed in the money tree scene
//

import Foundation
import SwiftUI

struct SceneItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let pointCost: Int
    let category: ItemCategory
    let iconName: String // SF Symbol name, emoji character, or custom image asset name
    let position: ItemPosition
    let size: ItemSize
    let unlockRequirement: UnlockRequirement?
    
    enum ItemCategory: String, Codable {
        case animal
        case decoration
        case plant
    }
    
    enum ItemPosition: String, Codable {
        case ground      // On the grass
        case sky         // Floating in sky
        case tree        // On/near the tree
        case anywhere    // User can place anywhere
    }
    
    enum ItemSize: String, Codable {
        case small  // 20pt font
        case medium // 30pt font
        case large  // 40pt font
    }
    
    struct UnlockRequirement: Codable, Hashable {
        let type: RequirementType
        let value: Int
        
        enum RequirementType: String, Codable {
            case lifetimePoints  // Total points earned (not current balance)
            case goalsMet        // Number of goals completed
            case totalSaved      // Total dollars saved
            case none            // Available to everyone
        }
        
        func isMet(lifetimePoints: Int, goalsMet: Int, totalSaved: Double) -> Bool {
            switch type {
            case .lifetimePoints:
                return lifetimePoints >= value
            case .goalsMet:
                return goalsMet >= value
            case .totalSaved:
                return Int(totalSaved) >= value
            case .none:
                return true
            }
        }
    }
    
    var fontSizeForIcon: CGFloat {
        switch size {
        case .small: return 20
        case .medium: return 30
        case .large: return 40
        }
    }
    
    /// Check if iconName is an emoji (single character), SF Symbol, or custom image asset
    var iconType: IconType {
        // Check if it's an emoji (1-2 characters, no dots)
        if iconName.count <= 2 && !iconName.contains(".") {
            return .emoji
        }
        // Check if it's an SF Symbol (contains dots like "hare.fill")
        if iconName.contains(".") {
            return .sfSymbol
        }
        // Otherwise, treat as custom image asset
        return .customImage
    }
    
    var isEmoji: Bool {
        return iconType == .emoji
    }
    
    enum IconType {
        case emoji
        case sfSymbol
        case customImage
    }
}

// MARK: - Item Catalog
extension SceneItem {
    /// Complete catalog of available items
    /// ⚠️ CONTENT MANAGEMENT: Add new items here
    static let catalog: [SceneItem] = [
        // MARK: - Animals
        SceneItem(
            id: "rabbit",
            name: "Rabbit",
            description: "A cute gray rabbit sitting peacefully",
            pointCost: 100,
            category: .animal,
            iconName: "rabbit", // Gray sitting rabbit custom icon
            position: .ground,
            size: .medium,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "squirrel",
            name: "Squirrel",
            description: "A busy squirrel collecting acorns",
            pointCost: 150,
            category: .animal,
            iconName: "🐿️", // Full body chipmunk/squirrel
            position: .tree,
            size: .medium,
            unlockRequirement: SceneItem.UnlockRequirement(type: .lifetimePoints, value: 500)
        ),
        SceneItem(
            id: "dog",
            name: "Dog",
            description: "A loyal pup watching your savings grow",
            pointCost: 200,
            category: .animal,
            iconName: "🐕", // Full body dog
            position: .ground,
            size: .medium,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 500)
        ),
        SceneItem(
            id: "cat",
            name: "Cat",
            description: "A curious cat lounging by your tree",
            pointCost: 180,
            category: .animal,
            iconName: "🐈", // Full body cat
            position: .ground,
            size: .medium,
            unlockRequirement: SceneItem.UnlockRequirement(type: .lifetimePoints, value: 300)
        ),
        SceneItem(
            id: "butterfly",
            name: "Butterfly",
            description: "Colorful butterflies flutter around",
            pointCost: 75,
            category: .animal,
            iconName: "🦋", // Full butterfly
            position: .sky,
            size: .small,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "bird",
            name: "Bird",
            description: "A cheerful bird singing in your tree",
            pointCost: 120,
            category: .animal,
            iconName: "🕊️", // Full body dove
            position: .tree,
            size: .medium,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "parrot",
            name: "Parrot",
            description: "A colorful parrot perched in your tree",
            pointCost: 250,
            category: .animal,
            iconName: "🦜", // Full body parrot
            position: .tree,
            size: .medium,
            unlockRequirement: SceneItem.UnlockRequirement(type: .goalsMet, value: 1)
        ),
        SceneItem(
            id: "hedgehog",
            name: "Hedgehog",
            description: "A cute hedgehog exploring the grass",
            pointCost: 180,
            category: .animal,
            iconName: "🦔", // Full body hedgehog
            position: .ground,
            size: .small,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 200)
        ),
        SceneItem(
            id: "bee",
            name: "Bee",
            description: "Busy bees buzzing around flowers",
            pointCost: 90,
            category: .animal,
            iconName: "🐝", // Full bee
            position: .sky,
            size: .small,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "ladybug",
            name: "Ladybug",
            description: "Lucky ladybugs bring good fortune",
            pointCost: 60,
            category: .animal,
            iconName: "🐞", // Full ladybug
            position: .ground,
            size: .small,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "turtle",
            name: "Turtle",
            description: "A wise turtle moving steadily forward",
            pointCost: 150,
            category: .animal,
            iconName: "🐢", // Full body turtle
            position: .ground,
            size: .small,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "cow",
            name: "Cow",
            description: "A friendly cow grazing in your scene",
            pointCost: 250,
            category: .animal,
            iconName: "cow", // Spotted cow custom icon
            position: .ground,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 1000)
        ),
        SceneItem(
            id: "deer",
            name: "Deer",
            description: "A graceful spotted deer with antlers",
            pointCost: 300,
            category: .animal,
            iconName: "deer", // Spotted deer custom icon
            position: .ground,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 1500)
        ),
        SceneItem(
            id: "horse",
            name: "Horse",
            description: "A majestic horse galloping through your scene",
            pointCost: 350,
            category: .animal,
            iconName: "horse", // Orange horse custom icon
            position: .ground,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 2000)
        ),
        SceneItem(
            id: "bull",
            name: "Bull",
            description: "A strong bull standing proudly on your scene",
            pointCost: 280,
            category: .animal,
            iconName: "bull", // Brown bull custom icon
            position: .ground,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .goalsMet, value: 2)
        ),
        SceneItem(
            id: "llama",
            name: "Llama",
            description: "A fluffy coral-colored llama with a friendly smile",
            pointCost: 380,
            category: .animal,
            iconName: "llama", // Coral llama custom icon
            position: .ground,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .goalsMet, value: 3)
        ),
        SceneItem(
            id: "buffalo",
            name: "Buffalo",
            description: "A powerful buffalo with a shaggy mane",
            pointCost: 400,
            category: .animal,
            iconName: "buffalo", // Brown buffalo custom icon
            position: .ground,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 5000)
        ),
        SceneItem(
            id: "pig",
            name: "Pig",
            description: "A cheerful pink pig with a curly tail",
            pointCost: 220,
            category: .animal,
            iconName: "pig", // Pink pig custom icon
            position: .ground,
            size: .medium,
            unlockRequirement: SceneItem.UnlockRequirement(type: .lifetimePoints, value: 600)
        ),
        SceneItem(
            id: "donkey",
            name: "Donkey",
            description: "A hardworking gray donkey with big ears",
            pointCost: 270,
            category: .animal,
            iconName: "donkey", // Gray donkey custom icon
            position: .ground,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .goalsMet, value: 1)
        ),
        SceneItem(
            id: "goat",
            name: "Goat",
            description: "A friendly white goat with striped horns",
            pointCost: 240,
            category: .animal,
            iconName: "goat", // White goat custom icon
            position: .ground,
            size: .medium,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 800)
        ),
        SceneItem(
            id: "sheep",
            name: "Sheep",
            description: "A fluffy white sheep with soft wool",
            pointCost: 210,
            category: .animal,
            iconName: "sheep", // Fluffy sheep custom icon
            position: .ground,
            size: .medium,
            unlockRequirement: SceneItem.UnlockRequirement(type: .lifetimePoints, value: 500)
        ),
        SceneItem(
            id: "duck",
            name: "Duck",
            description: "A cheerful yellow duck waddling around",
            pointCost: 190,
            category: .animal,
            iconName: "duck", // Yellow duck custom icon
            position: .ground,
            size: .small,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 300)
        ),
        SceneItem(
            id: "snail",
            name: "Snail",
            description: "A slow-moving snail with a spiral shell",
            pointCost: 80,
            category: .animal,
            iconName: "snail", // Orange/yellow snail custom icon
            position: .ground,
            size: .small,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "chicken",
            name: "Chicken",
            description: "A cheerful white chicken pecking around",
            pointCost: 120,
            category: .animal,
            iconName: "chicken", // White chicken custom icon
            position: .ground,
            size: .small,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "hen",
            name: "Hen",
            description: "An orange hen with a red tail",
            pointCost: 150,
            category: .animal,
            iconName: "hen", // Orange hen custom icon
            position: .ground,
            size: .medium,
            unlockRequirement: SceneItem.UnlockRequirement(type: .lifetimePoints, value: 200)
        ),
        SceneItem(
            id: "rooster",
            name: "Rooster",
            description: "A proud rooster with vibrant green plumage",
            pointCost: 200,
            category: .animal,
            iconName: "rooster", // Yellow/green rooster custom icon
            position: .ground,
            size: .medium,
            unlockRequirement: SceneItem.UnlockRequirement(type: .lifetimePoints, value: 400)
        ),
        
        // MARK: - Plants
        SceneItem(
            id: "flowers",
            name: "Wildflowers",
            description: "Beautiful flowers blooming in the grass",
            pointCost: 50,
            category: .plant,
            iconName: "🌸",
            position: .ground,
            size: .small,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "sunflower",
            name: "Sunflower",
            description: "Bright sunflowers reaching for the sky",
            pointCost: 100,
            category: .plant,
            iconName: "🌻",
            position: .ground,
            size: .medium,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "tulips",
            name: "Tulips",
            description: "Colorful tulips swaying in the breeze",
            pointCost: 80,
            category: .plant,
            iconName: "🌷",
            position: .ground,
            size: .small,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "roses",
            name: "Roses",
            description: "Beautiful roses adding elegance",
            pointCost: 150,
            category: .plant,
            iconName: "🌹",
            position: .ground,
            size: .small,
            unlockRequirement: SceneItem.UnlockRequirement(type: .lifetimePoints, value: 200)
        ),
        SceneItem(
            id: "cactus",
            name: "Cactus",
            description: "A resilient cactus standing tall",
            pointCost: 120,
            category: .plant,
            iconName: "🌵",
            position: .ground,
            size: .medium,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "mushrooms",
            name: "Mushrooms",
            description: "Magical mushrooms growing near the tree",
            pointCost: 80,
            category: .plant,
            iconName: "🍄",
            position: .ground,
            size: .small,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "four_leaf_clover",
            name: "Four Leaf Clover",
            description: "Lucky clover brings good fortune",
            pointCost: 200,
            category: .plant,
            iconName: "🍀",
            position: .ground,
            size: .small,
            unlockRequirement: SceneItem.UnlockRequirement(type: .goalsMet, value: 1)
        ),
        
        // MARK: - Decorations
        SceneItem(
            id: "sparkles",
            name: "Sparkles",
            description: "Magical sparkles add shine to your scene",
            pointCost: 150,
            category: .decoration,
            iconName: "✨",
            position: .sky,
            size: .small,
            unlockRequirement: nil
        ),
        SceneItem(
            id: "rainbow",
            name: "Rainbow",
            description: "A beautiful rainbow after the rain",
            pointCost: 400,
            category: .decoration,
            iconName: "🌈",
            position: .sky,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .lifetimePoints, value: 1000)
        ),
        SceneItem(
            id: "shooting_star",
            name: "Shooting Star",
            description: "Make a wish on a shooting star",
            pointCost: 350,
            category: .decoration,
            iconName: "💫",
            position: .sky,
            size: .medium,
            unlockRequirement: SceneItem.UnlockRequirement(type: .goalsMet, value: 3)
        ),
        SceneItem(
            id: "fireflies",
            name: "Fireflies",
            description: "Glowing fireflies light up the night",
            pointCost: 200,
            category: .decoration,
            iconName: "✨",
            position: .sky,
            size: .small,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 500)
        ),
        SceneItem(
            id: "gem",
            name: "Gem",
            description: "A precious gem hidden in the grass",
            pointCost: 500,
            category: .decoration,
            iconName: "💎",
            position: .ground,
            size: .small,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 2000)
        ),
        SceneItem(
            id: "trophy",
            name: "Trophy",
            description: "Celebrate your savings achievements",
            pointCost: 600,
            category: .decoration,
            iconName: "🏆",
            position: .ground,
            size: .medium,
            unlockRequirement: SceneItem.UnlockRequirement(type: .goalsMet, value: 5)
        ),
        
        // MARK: - Premium Items
        SceneItem(
            id: "golden_bird",
            name: "Golden Eagle",
            description: "A rare golden eagle brings good fortune",
            pointCost: 1000,
            category: .animal,
            iconName: "🦅", // Full body eagle
            position: .tree,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .goalsMet, value: 5)
        ),
        SceneItem(
            id: "unicorn",
            name: "Unicorn",
            description: "A magical unicorn for legendary savers",
            pointCost: 2000,
            category: .animal,
            iconName: "🦄", // Full body unicorn
            position: .ground,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 10000)
        ),
        SceneItem(
            id: "dragon",
            name: "Dragon",
            description: "A friendly dragon guards your wealth",
            pointCost: 3000,
            category: .animal,
            iconName: "🐉", // Full body dragon
            position: .tree,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .totalSaved, value: 25000)
        ),
        SceneItem(
            id: "lion",
            name: "Lion",
            description: "The king of the savanna joins your scene",
            pointCost: 1500,
            category: .animal,
            iconName: "🦁", // Full body lion
            position: .ground,
            size: .large,
            unlockRequirement: SceneItem.UnlockRequirement(type: .goalsMet, value: 3)
        ),
    ]
    
    /// Get items by category
    static func items(in category: ItemCategory) -> [SceneItem] {
        return catalog.filter { $0.category == category }
    }
    
    /// Get unlocked items based on user progress
    static func availableItems(lifetimePoints: Int, goalsMet: Int, totalSaved: Double) -> [SceneItem] {
        return catalog.filter { item in
            item.unlockRequirement?.isMet(
                lifetimePoints: lifetimePoints,
                goalsMet: goalsMet,
                totalSaved: totalSaved
            ) ?? true
        }
    }
}

