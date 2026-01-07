# Export Options for TestFlight Upload

**Question**: What should I select when exporting/uploading?

---

## ✅ Recommended Selections

### When Exporting/Uploading:

1. **Include Bitcode**: ❌ **No** (deprecated, not needed)
   - Apple deprecated bitcode
   - Not required for modern apps

2. **Include Symbols**: ✅ **Yes** (recommended)
   - Helps with crash reporting
   - Makes debugging easier
   - Doesn't significantly increase size

3. **Manage Frameworks**: ✅ **Automatic** (let Xcode handle it)
   - Xcode automatically manages framework embedding
   - Your app already has frameworks configured correctly
   - No manual selection needed

---

## 📦 What Xcode Does Automatically

When you select **"Automatically manage signing"**:
- ✅ Handles all framework embedding
- ✅ Signs frameworks correctly
- ✅ Includes necessary frameworks
- ✅ Excludes unnecessary ones

**You don't need to manually select frameworks** - Xcode handles it!

---

## 🎯 What to Select

### Distribution Method:
- ✅ **App Store Connect**

### Distribution Options:
- ✅ **Upload** (not Export)

### Signing:
- ✅ **Automatically manage signing**

### Export Options (if asked):
- ❌ **Include Bitcode**: No
- ✅ **Include Symbols**: Yes
- ✅ **Manage Frameworks**: Automatic (default)

---

## ⚠️ Common Confusion

**"Frameworks" option** usually refers to:
- Whether to include debug symbols (Yes)
- Whether to include bitcode (No)
- Framework management (Automatic)

**Not** about selecting which frameworks to include - that's already configured in your project!

---

## ✅ Bottom Line

**Just use the defaults**:
- ✅ Automatically manage signing
- ✅ Include symbols: Yes
- ❌ Include bitcode: No
- ✅ Everything else: Default/Automatic

**Xcode will handle frameworks automatically** - no manual selection needed!

---

**Your app is already configured correctly** - just follow the upload wizard and accept the defaults!

