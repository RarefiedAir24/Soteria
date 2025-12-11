# Question for Plaid Support: LinkKit Integration Issues

## Subject
**LinkKit Framework Integration: dyld Crash and Duplicate Embedding with CocoaPods**

## Context
We're integrating Plaid LinkKit v3.1.1 into an iOS app using CocoaPods and encountering two critical issues:

### Issue 1: dyld Crash at App Startup
- **Error**: `dyld`__abort_with_payload` crash occurs when the app launches
- **Timing**: Happens during framework loading by the dynamic linker, BEFORE any Swift code runs
- **Environment**: iOS 15.0+, Xcode latest, both simulator and physical device
- **Integration Method**: CocoaPods (`pod 'Plaid', '~> 3.0'`)
- **Bundle ID**: `io.montebay.soteria`
- **Environment**: Sandbox
- **Client ID**: `69352338b821ae002254a4e1`

### Issue 2: Duplicate Framework Embedding
- **Error**: "Multiple commands produce LinkKit.framework" build error
- **Cause**: LinkKit is being embedded both by:
  1. CocoaPods `[CP] Embed Pods Frameworks` script phase
  2. Manual entry in Xcode General tab → "Frameworks, Libraries, and Embedded Content"
- **Current Workaround**: Modified Podfile post_install hook to exclude LinkKit from CocoaPods embed script, but CocoaPods regenerates output file lists that still reference LinkKit

## What We've Tried

### For dyld Crash:
1. ✅ Added `NSCameraUsageDescription` to Info.plist (as per Plaid docs)
2. ✅ Set LinkKit to "Embed & Sign" in Xcode General tab
3. ✅ Verified Bitcode is disabled (Enable Bitcode = NO)
4. ✅ Confirmed iOS deployment target is 15.0+
5. ⚠️ Attempted conditional imports (`#if canImport(LinkKit)`) - doesn't prevent dyld from loading framework at startup
6. ⚠️ Tried lazy loading - framework still loads at app startup due to CocoaPods linking

### For Duplicate Embedding:
1. ✅ Modified `Pods-soteria-frameworks.sh` to skip LinkKit in `install_framework()` function
2. ✅ Commented out direct `install_framework` calls for LinkKit
3. ✅ Removed LinkKit from output file lists in Podfile post_install hook
4. ❌ CocoaPods regenerates output file lists, causing the duplicate error to persist

## Questions for Plaid Support

### 1. dyld Crash
- **Q**: Is there a known issue with LinkKit v3.1.1 causing dyld crashes at app startup?
- **Q**: Are there specific Xcode build settings or CocoaPods configurations required to prevent this?
- **Q**: Should LinkKit be weakly linked or lazily loaded to prevent startup crashes?
- **Q**: Are there any Info.plist keys or entitlements required beyond `NSCameraUsageDescription`?
- **Q**: Is there a recommended integration method (CocoaPods vs SPM vs manual) that avoids this issue?

### 2. Duplicate Embedding with CocoaPods
- **Q**: What's the recommended way to integrate LinkKit with CocoaPods when you need "Embed & Sign"?
- **Q**: Should LinkKit be manually added to "Frameworks, Libraries, and Embedded Content" or managed entirely by CocoaPods?
- **Q**: How do we prevent CocoaPods from trying to embed LinkKit if we're managing it manually?
- **Q**: Is there a CocoaPods configuration or Podfile setting that handles this correctly?

### 3. Best Practices
- **Q**: What's the official recommended integration method for LinkKit in iOS apps?
- **Q**: Are there any known compatibility issues with:
  - CocoaPods dynamic frameworks (`use_frameworks!`)
  - Xcode 15+ / iOS 15+
  - Specific build settings or configurations?
- **Q**: Should we use a different version of LinkKit (e.g., v3.0.x instead of v3.1.1)?

### 4. Alternative Approaches
- **Q**: Would switching to Swift Package Manager (SPM) instead of CocoaPods resolve these issues?
- **Q**: Is manual framework integration (downloading XCFramework directly) recommended over package managers?
- **Q**: Are there any sample projects or integration guides that demonstrate the correct setup?

## Technical Details

### Podfile Configuration
```ruby
platform :ios, '15.0'

target 'soteria' do
  use_frameworks!
  pod 'Plaid', '~> 3.0'
end
```

### Xcode Settings
- **Framework Embedding**: "Embed & Sign" (manually set in General tab)
- **Bitcode**: Disabled (NO)
- **Deployment Target**: iOS 15.0
- **LinkKit Version**: 3.1.1 (via CocoaPods)

### Error Details
- **dyld Crash**: `Thread 1: signal SIGABRT` at `dyld`__abort_with_payload`
- **Build Error**: "Multiple commands produce LinkKit.framework" from `[CP] Embed Pods Frameworks` script

## Request
Could you please provide:
1. Guidance on resolving the dyld crash at app startup
2. Best practices for integrating LinkKit with CocoaPods
3. Recommended approach to prevent duplicate embedding
4. Any known issues or workarounds for LinkKit v3.1.1

Thank you for your assistance!

---

**App Details:**
- App Name: Soteria
- Bundle ID: `io.montebay.soteria`
- Platform: iOS 15.0+
- Integration: CocoaPods
- LinkKit Version: 3.1.1
- Environment: Sandbox
- Client ID: `69352338b821ae002254a4e1`

