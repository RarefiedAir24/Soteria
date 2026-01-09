//
//  SceneItemIcon.swift
//  soteria
//
//  Unified view for rendering scene item icons (emoji, SF Symbol, or custom image)
//

import SwiftUI

struct SceneItemIcon: View {
    let item: SceneItem
    let tintColor: Color
    
    var body: some View {
        Group {
            switch item.iconType {
            case .emoji:
                // Render emoji as text (no tint applied)
                Text(item.iconName)
                    .font(.system(size: item.fontSizeForIcon))
                
            case .sfSymbol:
                // Render SF Symbol with tint color
                Image(systemName: item.iconName)
                    .font(.system(size: item.fontSizeForIcon))
                    .foregroundStyle(tintColor)
                
            case .customImage:
                // Render custom image asset in original colors (not template)
                Image(item.iconName)
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: item.fontSizeForIcon, height: item.fontSizeForIcon)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Emoji example
        SceneItemIcon(
            item: SceneItem(
                id: "test1",
                name: "Test Emoji",
                description: "Test",
                pointCost: 100,
                category: .animal,
                iconName: "🐇",
                position: .ground,
                size: .medium,
                unlockRequirement: nil
            ),
            tintColor: .blue
        )
        
        // SF Symbol example
        SceneItemIcon(
            item: SceneItem(
                id: "test2",
                name: "Test SF Symbol",
                description: "Test",
                pointCost: 100,
                category: .animal,
                iconName: "hare.fill",
                position: .ground,
                size: .medium,
                unlockRequirement: nil
            ),
            tintColor: .green
        )
        
        // Custom image example
        SceneItemIcon(
            item: SceneItem(
                id: "test3",
                name: "Test Custom",
                description: "Test",
                pointCost: 100,
                category: .animal,
                iconName: "custom_rabbit",
                position: .ground,
                size: .medium,
                unlockRequirement: nil
            ),
            tintColor: .purple
        )
    }
    .padding()
}

