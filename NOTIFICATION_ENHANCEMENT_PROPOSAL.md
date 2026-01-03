# Notification System Enhancement Proposal

## Issues Identified

1. **Notifications only fire on first app launch** - DeviceActivity events fire once per interval
2. **No app logo in notifications** - User wants to see the monitored app's icon
3. **Rate limiting too aggressive** - 5 seconds prevents legitimate notifications

## Solutions Implemented

### ✅ Phase 1: Quick Fixes (Implemented)

1. **Reduced Rate Limiting**: Changed from 5 seconds to 1 second
   - Allows notifications on every legitimate app launch
   - Still prevents spam if app opens/closes rapidly

2. **App Icon**: iOS automatically shows Soteria's app icon in notifications
   - Icon comes from `Assets.xcassets/AppIcon.appiconset`
   - Cannot show monitored app's icon directly (iOS limitation)
   - **Note**: To show monitored app icon, we'd need to use image attachments (future enhancement)

### 🔄 Phase 2: Enhanced Detection (Recommended)

**Problem**: DeviceActivity events only fire once per monitoring interval. Once an event fires, it doesn't fire again until the interval resets.

**Solution**: Use shorter monitoring intervals that reset more frequently.

**Current Behavior**:
- Monitoring interval: 8pm-10pm (2 hours)
- Event fires once at 8:05pm when Amazon opens
- Event doesn't fire again until next day at 8pm

**Proposed Behavior**:
- Break long intervals into 5-minute chunks
- Each chunk is a separate monitoring interval
- Events reset every 5 minutes, allowing them to fire again
- Notifications can appear on every app launch

**Implementation**:
```swift
// Instead of one long interval (8pm-10pm)
// Create multiple short intervals (8:00-8:05, 8:05-8:10, etc.)
// Events reset when each interval starts
```

**Pros**:
- ✅ Works with existing DeviceActivity system
- ✅ Reliable - events reset every 5 minutes
- ✅ Allows notifications on every app launch
- ✅ No major code changes needed

**Cons**:
- ⚠️ More frequent interval resets (minor overhead)
- ⚠️ Slightly more complex schedule management

### 🔮 Phase 3: Advanced Features (Future)

1. **App Icon Attachments**: Add monitored app's icon as notification attachment
2. **Rich Notifications**: Add images, actions, and interactive elements
3. **Smart Timing**: Adjust notification timing based on user behavior

## Implementation Status

- ✅ Phase 1: Rate limiting reduced (1 second)
- ⏳ Phase 2: Shorter intervals (to be implemented)
- ⏳ Phase 3: Advanced features (future)

## Testing Plan

1. **Test Rate Limiting**:
   - Open Amazon → Notification appears ✅
   - Close and immediately reopen → No notification (rate limited) ✅
   - Wait 2 seconds and reopen → Notification appears ✅

2. **Test Event Reset** (after Phase 2):
   - Open Amazon at 8:00pm → Notification appears ✅
   - Close Amazon
   - Reopen Amazon at 8:03pm → Notification appears ✅ (event reset at 8:05pm)
   - Reopen Amazon at 8:07pm → Notification appears ✅ (event reset at 8:10pm)

## Next Steps

1. ✅ Implement Phase 1 (rate limiting) - DONE
2. ⏳ Implement Phase 2 (shorter intervals) - IN PROGRESS
3. ⏳ Test with real device
4. ⏳ Implement Phase 3 (advanced features) - FUTURE

