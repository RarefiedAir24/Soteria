# Header Structure Analysis

## GoalsView and SettingsView Structure

### Layout:
```
ZStack(alignment: .top) {
    // Background colors
    Color.mistGray.ignoresSafeArea(.all, edges: .top)
    Color.cloudWhite.ignoresSafeArea()
    
    // ScrollView with spacer at top
    ScrollView {
        Color.clear.frame(height: 60)  // Spacer for fixed header
        VStack(spacing: 24) {
            // Content...
        }
    }
    
    // Fixed Header (positioned AFTER ScrollView in ZStack)
    VStack(spacing: 2) {
        Text("Savings Goals" / "Settings")
            .font(.system(size: 24, weight: .semibold))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 6)
    .background(Color(red: 0.92, green: 0.97, blue: 0.94).ignoresSafeArea(edges: .top))
    .zIndex(100)
}
```

### Key Points:
- Header is **fixed** at top (doesn't scroll)
- ScrollView has **60pt spacer** at top to account for header
- Header is positioned **AFTER** ScrollView in ZStack (overlays on top)
- Header height: ~36pt (24pt text + 6pt top + 6pt bottom padding)
- ScrollView content starts **60pt** from top

---

## HomeView Structure (Current - INCORRECT)

### Layout:
```
ZStack(alignment: .top) {
    // Background colors
    Color.mistGray.ignoresSafeArea(.all, edges: .top)
    Color.cloudWhite.ignoresSafeArea()
    
    // ScrollView
    ScrollView {
        VStack(spacing: 0) {
            usernameAvatarBanner  // ❌ WRONG: This is in ScrollView
            VStack(spacing: .spacingSection) {
                // Content...
            }
        }
        .padding(.top, 36)  // Only accounts for rose gold header
    }
    
    // Fixed Header (rose gold)
    VStack(spacing: 0) {
        cardStatusHeader  // Rose gold header
    }
    .zIndex(1000)
}
```

### Problems:
1. **Username/avatar banner is in ScrollView** - This causes it to scroll, but it's positioned incorrectly
2. **ScrollView padding is only 36pt** - This accounts for rose gold header, but username/avatar banner is also in ScrollView, so it overlaps
3. **Username/avatar banner should be positioned directly below rose gold header** - Currently it's the first item in ScrollView with only 36pt padding, so it's too close/overlapping

---

## HomeView Structure (CORRECT - What it should be)

### Layout:
```
ZStack(alignment: .top) {
    // Background colors
    Color.mistGray.ignoresSafeArea(.all, edges: .top)
    Color.cloudWhite.ignoresSafeArea()
    
    // ScrollView with spacer
    ScrollView {
        Color.clear.frame(height: 36 + usernameAvatarBannerHeight)  // Spacer for both headers
        VStack(spacing: .spacingSection) {
            // Content starts here...
        }
    }
    
    // Fixed Headers (positioned AFTER ScrollView in ZStack)
    VStack(spacing: 0) {
        cardStatusHeader  // Rose gold header (36pt)
        usernameAvatarBanner  // Username/avatar banner (scrolls with content)
    }
    .zIndex(1000)
}
```

### OR (if username/avatar should scroll):

```
ZStack(alignment: .top) {
    // Background colors
    Color.mistGray.ignoresSafeArea(.all, edges: .top)
    Color.cloudWhite.ignoresSafeArea()
    
    // ScrollView
    ScrollView {
        VStack(spacing: 0) {
            usernameAvatarBanner  // First item, scrolls
            VStack(spacing: .spacingSection) {
                // Content...
            }
        }
        .padding(.top, 36)  // Accounts for rose gold header
    }
    
    // Fixed Header (rose gold only)
    VStack(spacing: 0) {
        cardStatusHeader  // Rose gold header (36pt)
    }
    .zIndex(1000)
}
```

### Key Points:
- Rose gold header: **Fixed** at top (36pt height)
- Username/avatar banner: **Scrolls** with content
- ScrollView padding: **36pt** (just rose gold header)
- Username/avatar banner starts **directly below** rose gold header (at 36pt from top)

---

## Differences Summary

| Aspect | Goals/Settings | HomeView (Current) | HomeView (Should Be) |
|--------|---------------|-------------------|---------------------|
| Header position | Fixed, overlays ScrollView | Fixed, overlays ScrollView | Fixed, overlays ScrollView |
| ScrollView spacer | 60pt Color.clear | 36pt padding | 36pt padding |
| Username/avatar | N/A | In ScrollView (wrong position) | In ScrollView (first item) |
| Header height | ~36pt | ~36pt | ~36pt |
| Content start | 60pt from top | 36pt + banner height | 36pt + banner height |

---

## Solution

The username/avatar banner should be:
1. **First item in ScrollView** (so it scrolls)
2. **Positioned with 36pt top padding** (to sit directly below rose gold header)
3. **Not overlapping** the rose gold header

The current issue is that the padding might be incorrect or the banner height is causing overlap.

