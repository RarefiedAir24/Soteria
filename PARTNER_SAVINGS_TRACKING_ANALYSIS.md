# 🔍 Partner Savings Tracking - Current State & Options

## ⚠️ **CRITICAL ISSUE: NO AUTOMATIC TRACKING**

### **Current Reality:**

The code has tracking **methods** but NO automatic tracking **mechanism**.

```swift
// This method EXISTS but is never called automatically
func recordUsage(toolId: String, amountSaved: Double) {
    // Awards points, increments usage count, updates stats
}
```

**Why?**
- Upside, GoodRx are **separate apps**
- Users download them independently
- They don't "go through Soteria" to save
- We have **zero visibility** into their usage

---

## 🚫 **WHAT WE DON'T HAVE**

### **No Integration:**
- ❌ No API access to Upside/GoodRx data
- ❌ No affiliate callbacks
- ❌ No partner dashboards
- ❌ No automatic save tracking
- ❌ No analytics data

### **No Portal:**
- Users **don't** use Soteria to access savings
- They use **external apps** directly
- We're just a **referral** right now

---

## ✅ **WHAT WE DO HAVE**

### **Data Model Ready:**
```swift
struct SavingsTool {
    var totalSaved: Double      // Ready to track
    var usageCount: Int         // Ready to track
    var lastUsed: Date?         // Ready to track
    var pointsEarned: Int       // Ready to track
}
```

### **Service Methods Ready:**
```swift
// Ready to record when called
func recordUsage(toolId: String, amountSaved: Double)
```

### **UI Ready:**
```swift
// Stats display ready
│ 2,340 pts • $156 saved • 18 uses │
```

**But... NO WAY TO POPULATE THIS DATA!**

---

## 🎯 **5 OPTIONS FOR TRACKING**

### **Option 1: Self-Reporting (Honor System)**

**How It Works:**
- User saves $10 with Upside
- Opens Soteria → Savings Tools → Upside
- Taps "Record Save" button
- Enters $10
- System awards 100 loyalty points

**Pros:**
- ✅ Easy to implement (already built!)
- ✅ No partner integration needed
- ✅ Works immediately

**Cons:**
- ❌ Relies on honesty
- ❌ Easy to abuse (fake saves)
- ❌ Low reporting rate (users forget)
- ❌ No fraud protection

**Fraud Risk:** **HIGH** 🔴

---

### **Option 2: Screenshot Verification (Like Deposits)**

**How It Works:**
- User saves $10 with Upside
- Opens Soteria → Savings Tools → Upside
- Taps "Record Save"
- **Must upload screenshot** from Upside app
- AI verifies screenshot (similar to deposit verification)
- System awards points if verified

**Pros:**
- ✅ Fraud protection via AI
- ✅ No partner integration needed
- ✅ Works with any partner
- ✅ Can detect duplicates

**Cons:**
- ❌ Friction (users must screenshot)
- ❌ Not 100% foolproof
- ❌ Extra step reduces reporting

**Fraud Risk:** **MEDIUM** 🟡

**Implementation:**
- Reuse existing screenshot verification service
- Adapt for partner receipts/confirmations
- Store hashes to prevent duplicates

---

### **Option 3: Affiliate Link Tracking**

**How It Works:**
- User taps "Open Upside" in Soteria
- Opens Upside app via **unique affiliate link**
- Upside tracks saves via that link
- **IF** Upside provides callback API:
  - They send us: user saved $10
  - We record it automatically

**Pros:**
- ✅ Automatic tracking
- ✅ No user action required
- ✅ 100% accurate
- ✅ Real-time data

**Cons:**
- ❌ **Requires partner API/integration**
- ❌ Not all partners offer this
- ❌ Complex setup
- ❌ Requires signed agreements

**Fraud Risk:** **ZERO** 🟢

**Reality Check:**
- Upside has affiliate program, **BUT** unclear if they provide real-time save data
- GoodRx has affiliate program, **BUT** likely just tracks signups, not usage
- Would need to negotiate this in partnership agreements

---

### **Option 4: In-App Web Views (Session Tracking)**

**How It Works:**
- Don't send users to external apps
- Embed partner sites in **web views** inside Soteria
- Track when users open web view
- Track session duration
- **Estimate** saves based on usage

**Pros:**
- ✅ We control the experience
- ✅ Can track sessions
- ✅ No external app needed

**Cons:**
- ❌ Can't track actual save amounts
- ❌ Only estimates, not real data
- ❌ Worse UX (no native apps)
- ❌ Partners may not allow web views

**Fraud Risk:** **LOW** (but data is estimates, not real)

---

### **Option 5: Partner Dashboard Export (Manual)**

**How It Works:**
- Partners provide us **monthly dashboard access**
- We see aggregate data: "User X saved $156 this month"
- Admin manually syncs data to Soteria
- Points awarded retroactively

**Pros:**
- ✅ Accurate data
- ✅ No user friction
- ✅ Works if partners agree

**Cons:**
- ❌ **Requires partner agreement**
- ❌ Manual process
- ❌ Not real-time
- ❌ Requires admin work

**Fraud Risk:** **ZERO** 🟢

**Reality Check:**
- Very unlikely partners share user-level data
- Privacy concerns (GDPR, CCPA)
- Competitive data they protect

---

## 🎯 **RECOMMENDED APPROACH**

### **Phase 1: Launch without Partners (NOW)**
**Use:** Nothing! Feature is OFF.
- No tracking needed
- No fraud risk
- Clean launch

### **Phase 2: Soft Launch with Partners (Months 1-3)**
**Use:** Screenshot Verification (Option 2)

**Why:**
- ✅ No partner API needed
- ✅ Fraud protection
- ✅ Works immediately
- ✅ Reuses existing code

**Implementation:**
1. Add "Record Save" button to each tool in ToolSettingsView
2. Require screenshot upload
3. Verify screenshot shows partner logo + amount
4. Award points if verified
5. Track in analytics

**UX:**
```
┌─────────────────────────────────────────┐
│ ⚙️ Upside Settings                      │
│                                         │
│ YOUR STATS                              │
│ 2,340 pts • $156 saved • 18 uses        │
│                                         │
│ [📊 Record New Save]  ← New button      │
└─────────────────────────────────────────┘

Tap → Upload screenshot → Verify → Award points
```

### **Phase 3: Full Integration (Year 2)**
**Use:** Affiliate Link Tracking (Option 3)

**Why:**
- ✅ Automatic tracking
- ✅ No user friction
- ✅ 100% accurate
- ✅ Best UX

**Requirements:**
- Negotiate API access with partners
- Build integration layer
- Handle callbacks
- Real-time sync

---

## 📊 **ANALYTICS & REPORTING**

### **What to Track:**

**Per Tool:**
```javascript
{
  toolId: "upside",
  totalSaves: 156.50,
  saveCount: 18,
  averageSave: 8.69,
  pointsAwarded: 2340,
  lastUsed: "2026-01-11",
  verificationMethod: "screenshot" // or "api" or "manual"
}
```

**Per User:**
```javascript
{
  userId: "user_123",
  activatedTools: ["upside", "goodrx"],
  totalToolSavings: 223.80,
  totalToolSaves: 22,
  totalPointsFromTools: 3230,
  mostUsedTool: "upside",
  leastUsedTool: "goodrx"
}
```

**Aggregate:**
```javascript
{
  totalToolSavings: 45678.90,
  totalToolSaves: 1234,
  totalPointsAwarded: 123400,
  mostPopularTool: "upside",
  averageSavingsPerUser: 37.05,
  activationRate: 0.68, // 68% of premium users activated at least one tool
  usageRate: 0.43 // 43% of activated users actively use tools
}
```

### **Reports Needed:**

**Admin Dashboard:**
- Total savings across all users
- Total points awarded via tools
- Activation rates by tool
- Usage frequency
- Screenshot verification success rate
- Fraud detection alerts

**User Dashboard:**
- My total savings from tools
- Points earned from tools
- Usage history
- Tool-by-tool breakdown

---

## 🚨 **CRITICAL QUESTIONS FOR PARTNER NEGOTIATIONS**

### **Before Signing with Upside/GoodRx:**

1. **"Do you provide an affiliate API?"**
   - Can we track user saves programmatically?
   - Real-time or batch?

2. **"Can we track individual user savings?"**
   - Or just aggregate data?
   - Privacy implications?

3. **"What data do you share?"**
   - Save amounts?
   - Transaction IDs?
   - Timestamps?

4. **"How do we verify a user came from Soteria?"**
   - Unique referral codes?
   - Device fingerprinting?
   - Email matching?

5. **"What's your fraud detection?"**
   - How do you prevent fake saves?
   - Can we trust your data?

---

## 🛠️ **IMPLEMENTATION PLAN**

### **Step 1: Add "Record Save" Button**
- Location: ToolSettingsView
- Opens: SaveRecordingView
- Requires: Screenshot upload
- Awards: Points after verification

### **Step 2: Adapt Screenshot Verification**
- Reuse: Existing Lambda function
- Add: Partner logo detection
- Add: Amount extraction
- Add: Duplicate detection

### **Step 3: Wire Analytics**
- Track: All save recordings
- Dashboard: Admin view
- Reports: User view
- Alerts: Fraud detection

### **Step 4: Partner Integration (Future)**
- Negotiate: API access
- Build: Integration layer
- Test: Callback handling
- Deploy: Automatic tracking

---

## 📝 **REALITY CHECK**

### **Without Partner Agreements:**
- ❌ No automatic tracking
- ❌ No API access
- ❌ No real-time data
- ✅ Can use screenshot verification
- ✅ Can manually record saves
- ✅ Better than nothing

### **With Partner Agreements:**
- ✅ Automatic tracking (maybe)
- ✅ API access (maybe)
- ✅ Real-time data (maybe)
- ⚠️ Depends on what partners offer
- ⚠️ May still need screenshots as backup

---

## 🎯 **IMMEDIATE NEXT STEPS**

1. **Clarify your partner situation:**
   - Do you have ANY partner contacts?
   - Have you reached out to Upside/GoodRx?
   - What have they said about integration?

2. **Choose tracking method:**
   - Screenshot verification (no partners needed)
   - Affiliate links (needs partner API)
   - Manual recording (honor system)

3. **Build tracking UI:**
   - Add "Record Save" button
   - Build save recording flow
   - Wire to analytics

4. **Design reports:**
   - Admin dashboard mockups
   - User stats view
   - What metrics matter?

---

## 💡 **MY RECOMMENDATION**

**LAUNCH STRATEGY:**

**Phase 1 (Now - Month 3):**
- Feature stays OFF
- No partners, no tracking
- Focus on core features

**Phase 2 (Month 4-6):**
- Reach out to partners
- Ask about API access
- If NO API: Build screenshot verification
- If YES API: Build integration

**Phase 3 (Month 7+):**
- Enable feature with tracking
- Monitor usage and fraud
- Iterate based on data

**Don't build tracking until you know:**
1. If partners will integrate
2. What data they'll provide
3. How users will report saves

---

**Should I build the screenshot verification + analytics system now, or wait until you secure partners and know what data you'll have access to?** 🤔
