# Fix: Logging Rate Limit Warnings

**Issue**: "Message send exceeds rate-limit threshold and will be dropped"

**Cause**: App is logging too frequently (more than 32 messages per second)

---

## 🔍 What's Happening

iOS limits logging to **32 messages per second** (32hz). When your app exceeds this, iOS drops messages and shows warnings.

**These warnings are harmless** but indicate excessive logging that should be reduced.

---

## 🐛 Common Causes

### 1. Logging in Loops
**Problem**: `print()` statements inside loops that run frequently
**Example**:
```swift
for item in items {
    print("Processing item: \(item)") // ❌ Too many prints
}
```

### 2. Logging in Timer Callbacks
**Problem**: Logging every time a timer fires
**Example**:
```swift
Timer.scheduledTimer { _ in
    print("Timer fired") // ❌ Fires too frequently
}
```

### 3. Logging in Scroll/Animation Callbacks
**Problem**: Logging during scroll or animation updates
**Example**:
```swift
.onChange(of: scrollOffset) { _ in
    print("Scroll offset: \(scrollOffset)") // ❌ Fires constantly
}
```

### 4. Logging in View Updates
**Problem**: Logging in `body` or view update methods
**Example**:
```swift
var body: some View {
    print("View updated") // ❌ Called too frequently
    return Text("Hello")
}
```

---

## ✅ Solutions

### Solution 1: Remove Debug Logs
**Remove** `print()` statements that aren't needed:
- Debug logs that were left in
- Verbose logging in production code
- Logging in frequently-called functions

### Solution 2: Use Conditional Logging
**Only log in debug builds**:
```swift
#if DEBUG
print("Debug info: \(value)")
#endif
```

### Solution 3: Rate Limit Logging
**Add rate limiting** to frequent logs:
```swift
private var lastLogTime: Date?
private let minLogInterval: TimeInterval = 1.0 // 1 second

func logIfNeeded(_ message: String) {
    let now = Date()
    if let last = lastLogTime, now.timeIntervalSince(last) < minLogInterval {
        return // Skip if too soon
    }
    lastLogTime = now
    print(message)
}
```

### Solution 4: Use Log Levels
**Only log important messages**:
- Remove verbose/info logs
- Keep only error/warning logs
- Use proper log levels

---

## 🔍 Where to Look

### Common Problem Areas:

1. **Services with Timers**:
   - `ProtectionHoursService`
   - `QuietHoursService`
   - `RegretRiskEngine`

2. **View Update Methods**:
   - `HomeView.body`
   - Scroll handlers
   - Animation callbacks

3. **Frequent Callbacks**:
   - `onChange` handlers
   - `onReceive` handlers
   - Timer callbacks

---

## 🎯 Quick Fix

### Immediate Action:
1. **Search for `print(` in your code**
2. **Remove or comment out** debug logs
3. **Keep only** error/warning logs
4. **Use `#if DEBUG`** for development logs

### Example:
```swift
// ❌ Bad (logs too frequently)
print("Scroll offset: \(offset)")

// ✅ Good (only in debug)
#if DEBUG
print("Scroll offset: \(offset)")
#endif

// ✅ Better (rate limited)
if shouldLog() {
    print("Important event")
}
```

---

## ⚠️ Note

**These warnings are not critical** - they don't break functionality. But reducing logging will:
- ✅ Improve performance
- ✅ Reduce console noise
- ✅ Prevent rate limit warnings
- ✅ Make real errors easier to see

---

## 📋 Action Items

1. **Search codebase** for `print(` statements
2. **Remove** unnecessary debug logs
3. **Wrap** remaining logs in `#if DEBUG`
4. **Rate limit** any logs in loops/timers

---

**These warnings are harmless but indicate excessive logging that should be cleaned up!**

