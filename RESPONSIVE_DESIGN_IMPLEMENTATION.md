# Responsive Design Implementation

## Overview
The app now includes responsive sizing utilities to ensure proper scaling on different iPhone screen sizes, including iPhone Pro (smaller) and iPhone Pro Max (larger).

## Screen Size Categories

### Large Screens (≥ 926 points)
- iPhone Pro Max, iPhone 14 Pro Max, etc.
- Uses full-size values

### Medium Screens (844-925 points)
- iPhone Pro, iPhone 14 Pro, iPhone 13, etc.
- Uses ~90% of large screen values

### Small Screens (< 844 points)
- iPhone SE, iPhone 8, iPhone 12 mini, etc.
- Uses ~85% of medium screen values

## Responsive Utilities

### ResponsiveSize Helper
Located in `soteria/Extensions/View+Responsive.swift`

**Usage:**
```swift
// Font sizes
.font(.system(size: ResponsiveSize.font(large: 28, medium: 26, small: 24)))

// Padding
.padding(.horizontal, ResponsiveSize.padding(large: 40, medium: 32, small: 24))

// Spacing
VStack(spacing: ResponsiveSize.spacing(large: 24, medium: 20, small: 16))
```

## Updated Views

### ✅ AuthView_Simplified
- Logo font size: 42 → 38 → 34
- Top padding: 80 → 60 → 40
- Horizontal padding: 32 → 28 → 24
- Spacing: 40 → 32 → 24

### ✅ DecisionWindowSetupFlow
- Title font sizes: 28 → 26 → 24
- Body font sizes: 16 → 15 → 14
- Button font sizes: 18 → 17 → 16
- Horizontal padding: 40 → 32 → 24
- Vertical padding: 40 → 32 → 24
- Spacing: 24 → 20 → 16

## Benefits

1. **Better Fit**: Content fits properly on smaller screens without overflow
2. **Readability**: Font sizes scale appropriately for screen size
3. **Touch Targets**: Buttons and interactive elements remain appropriately sized
4. **Consistent Experience**: Users get a polished experience regardless of device

## Testing Recommendations

Test on:
- iPhone SE (smallest)
- iPhone 12/13/14 (medium)
- iPhone Pro Max (largest)

Verify:
- All text is readable
- Buttons are easily tappable
- No content is cut off
- Spacing feels balanced

