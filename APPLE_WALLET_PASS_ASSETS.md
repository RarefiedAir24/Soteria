# Apple Wallet Pass Assets Guide

## What Are Pass Assets?

Pass assets are the **image files** that appear on your Apple Wallet pass card. They make your pass visually recognizable and branded.

## Required Assets for Soteria

You need **2 image files**:

### 1. **Logo** (`logo.png`)
- **Purpose**: Brand logo displayed on the front of the pass card
- **Location**: Top-left corner of the pass
- **Size**: **180x180 pixels** (recommended)
- **Format**: PNG
- **Requirements**:
  - Square format (1:1 aspect ratio)
  - High resolution (retina display support)
  - Should be recognizable at small sizes
  - No transparency needed (will be on colored background)

**What to use**: Your Soteria logo or wordmark

### 2. **Icon** (`icon.png`)
- **Purpose**: Small icon shown in:
  - Push notifications (when pass updates)
  - Wallet app's pass list view
  - Lock screen notifications
- **Size**: 
  - **29x29 pixels** for iPhone
  - **40x40 pixels** for iPad (optional, can use 29x29)
- **Format**: PNG
- **Requirements**:
  - Square format (1:1 aspect ratio)
  - Simple, recognizable design
  - Works well at very small sizes
  - High contrast for visibility

**What to use**: Simplified version of your logo or a distinctive icon

## Optional Assets (Not Currently Used)

These are available but not required for basic passes:

- **Strip Image**: Banner image across the pass (for events, coupons)
- **Thumbnail**: Small image next to pass details
- **Background Image**: Full background for the pass

## Design Guidelines

### Logo Design Tips
- Use your existing Soteria branding
- Ensure it's readable on the pass background color (gold/platinum/black)
- Consider the card type colors:
  - **Gold**: `#FFD700` background
  - **Platinum**: `#2C3E50` background  
  - **Black**: `#000000` background

### Icon Design Tips
- Should be a simplified version of your logo
- Must be recognizable at 29x29 pixels
- High contrast (works on both light and dark backgrounds)
- Avoid fine details (won't be visible at small size)

## Current Pass Design

Based on the Lambda code, your pass will have:
- **Background Color**: Based on card type (gold/platinum/black)
- **Logo Text**: "SOTERIA" (text-based, but logo.png will also appear)
- **Foreground Color**: White text on black cards, black text on gold/platinum
- **QR Code**: Member validation barcode

## Where Assets Are Stored

Assets are uploaded to S3:
```
s3://soteria-wallet-passes/assets/
├── logo.png
└── icon.png
```

## How to Create Assets

### Option 1: Use Existing App Assets
If you have a Soteria logo already:
1. Export at 180x180px for logo
2. Export at 29x29px for icon
3. Ensure PNG format

### Option 2: Design New Assets
1. Create in design tool (Figma, Sketch, Photoshop)
2. Export at exact pixel dimensions
3. Test at small sizes to ensure readability

### Option 3: Use AI/Design Tools
- Canva (templates for Apple Wallet)
- Figma (Apple Wallet pass templates)
- Adobe Express

## Upload Instructions

Once you have the assets ready:

```bash
# Upload logo
aws s3 cp logo.png s3://soteria-wallet-passes/assets/logo.png --region us-east-1

# Upload icon
aws s3 cp icon.png s3://soteria-wallet-passes/assets/icon.png --region us-east-1
```

## Testing

After uploading:
1. The Lambda function will automatically use these assets
2. Generate a test pass via the API
3. Add to Apple Wallet on your device
4. Verify logo and icon appear correctly

## Fallback Behavior

If assets are missing:
- The Lambda will log a warning: `⚠️ Could not load pass assets, using defaults`
- The pass will still work, but without custom branding
- Apple Wallet will use default styling

## Example Asset Specifications

### logo.png
```
Dimensions: 180x180px
Format: PNG
Color Space: RGB
Background: Transparent or white (will be on colored card background)
File Size: < 50KB recommended
```

### icon.png
```
Dimensions: 29x29px (or 40x40px for iPad)
Format: PNG
Color Space: RGB
Background: Transparent
File Size: < 10KB recommended
```

## Design Resources

- [Apple Wallet Design Guidelines](https://developer.apple.com/wallet/get-started/)
- [Pass Design Best Practices](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/PassKit_PG/Creating.html)
- [Human Interface Guidelines - Wallet](https://developer.apple.com/design/human-interface-guidelines/wallet)

