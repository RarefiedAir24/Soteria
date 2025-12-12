//
//  CustomTabBar.swift
//  soteria
//
//  Custom tab bar to replace TabView for lazy loading
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            TabBarButton(
                icon: "house.fill",
                label: "Home",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            Spacer()
            
            // Goals Tab
            TabBarButton(
                icon: "target",
                label: "Goals",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            Spacer()
            
            // Settings Tab
            TabBarButton(
                icon: "gearshape.fill",
                label: "Settings",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.mistGray)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.reverBlue : Color.softGraphite)
                
                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.reverBlue : Color.softGraphite)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(0))
        .previewLayout(.sizeThatFits)
}

