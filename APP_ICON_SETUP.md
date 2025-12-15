# App Icon & Splash Screen Setup Guide

## Current Status

✅ **Splash Screen**: Already configured with `soteria_logo` asset
- Location: `soteria/Views/SplashScreenView.swift`
- Uses REVER Dream gradient background
- Displays logo with animation

⚠️ **App Icon**: Asset catalog exists but needs image files added

## App Icon Setup Instructions

### Step 1: Prepare Your App Icon Images

You need to create app icon images in the following sizes:

**Required Sizes:**
- **1024x1024** (Universal - required for App Store)
- **1024x1024** (Dark appearance - optional, for dark mode)
- **1024x1024** (Tinted appearance - optional, for iOS 15+)

### Step 2: Add Images to Xcode

1. Open Xcode
2. Navigate to: `soteria/Assets.xcassets/AppIcon.appiconset`
3. You'll see 3 slots:
   - **Universal** (1024x1024) - Required
   - **Dark** (1024x1024) - Optional (for dark mode)
   - **Tinted** (1024x1024) - Optional (for iOS 15+)

4. Drag and drop your icon images into the corresponding slots:
   - Drag your main 1024x1024 icon to the "Universal" slot
   - (Optional) Drag dark mode version to "Dark" slot
   - (Optional) Drag tinted version to "Tinted" slot

### Step 3: Verify

After adding images:
- The AppIcon asset should show your images in Xcode
- Build and run the app
- Check the home screen to see your new icon

## Recommended Icon Design

Based on your REVER theme colors:
- **Primary Color**: Deep Rever Blue (#7DA2C8)
- **Secondary Color**: Midnight Slate (#1E1F23)
- **Background**: Should work on both light and dark backgrounds

### Icon Requirements:
- 1024x1024 pixels
- PNG format (no transparency for app icon)
- Square format
- Should be recognizable at small sizes (60x60 on iPhone)
- Follow Apple's Human Interface Guidelines

## Splash Screen

The splash screen is already configured and will:
- Show your `soteria_logo` asset
- Display "SOTERIA" text
- Use REVER Dream gradient background
- Show loading indicator
- Animate the logo

No additional setup needed for splash screen.

## Quick Checklist

- [ ] Create 1024x1024 app icon image
- [ ] (Optional) Create dark mode version
- [ ] (Optional) Create tinted version
- [ ] Add images to AppIcon.appiconset in Xcode
- [ ] Build and test on device
- [ ] Verify icon appears on home screen

## Notes

- The app icon asset catalog is located at: `soteria/Assets.xcassets/AppIcon.appiconset/`
- The project is configured to use `AppIcon` as the app icon name
- iOS will automatically generate all required sizes from your 1024x1024 image
- For best results, design your icon to work at small sizes (test at 60x60)

