# 🧠 AI-POWERED GIFT CARD RECOMMENDATIONS

**Status**: ✅ COMPLETE  
**Files**:  
- `soteria/Services/GiftCardRecommendationService.swift` (NEW)
- `soteria/Views/GiftCardShopView.swift` (ENHANCED)

---

## 🎯 **WHAT IT DOES**

The AI Recommendation Service **learns from user behavior** and provides **personalized gift card suggestions** that adapt over time.

### **Key Capabilities:**

1. **🧠 Learns User Preferences**
   - Tracks which brands users redeem (Amazon, Target, Visa, etc.)
   - Remembers preferred denominations ($5, $10, $25, etc.)
   - Analyzes time patterns (morning coffee, weekend shopping)

2. **✨ Provides Smart Suggestions**
   - Prioritizes cards user is likely to want
   - Shows personalized insights ("You love Amazon!")
   - Contextual recommendations (Starbucks in the morning)

3. **📊 Continuous Learning**
   - Gets smarter with each redemption
   - Adapts to changing preferences
   - Stores last 50 redemptions for analysis

---

## 🎨 **USER EXPERIENCE**

### **First-Time User (No History)**

```
┌─────────────────────────────────┐
│  🎁 Gift Card Rewards           │
│                                 │
│  ⚡ Quick Picks                 │
│  "Redeem now!"                  │
│  ┌────┐ ┌────┐ ┌────┐          │
│  │ $5 │ │$10 │ │$25 │          │
│  │Visa│ │Visa│ │Amzn│          │
│  └────┘ └────┘ └────┘          │
│  (Sorted by amount, generic)    │
└─────────────────────────────────┘
```

### **After 3 Amazon Redemptions**

```
┌─────────────────────────────────┐
│  🎁 Gift Card Rewards           │
│                                 │
│  ✨ YOU LOVE AMAZON!            │
│  💡 We've prioritized Amazon    │
│      cards for you.             │
│                                 │
│  ⚡ Quick Picks                 │
│  "✨ Personalized for you"      │
│  ┌────┐ ┌────┐ ┌────┐          │
│  │$25 │ │$10 │ │$50 │          │
│  │Amzn│ │Amzn│ │Amzn│ ⭐       │
│  └────┘ └────┘ └────┘          │
│  (Amazon cards prioritized!)    │
└─────────────────────────────────┘
```

### **After 5 Small Denomination Redemptions ($5-$10)**

```
┌─────────────────────────────────┐
│  🎁 Gift Card Rewards           │
│                                 │
│  ✨ YOU PREFER SMALLER CARDS    │
│  💡 Perfect for frequent treats!│
│                                 │
│  ⚡ Quick Picks                 │
│  "✨ Personalized for you"      │
│  ┌────┐ ┌────┐ ┌────┐          │
│  │ $5 │ │ $5 │ │$10 │          │
│  │Amzn│ │Visa│ │Trgt│          │
│  └────┘ └────┘ └────┘          │
│  (Small cards prioritized!)     │
└─────────────────────────────────┘
```

### **After 3+ Large Denomination Redemptions ($50-$100)**

```
┌─────────────────────────────────┐
│  🎁 Gift Card Rewards           │
│                                 │
│  ✨ YOU GO BIG!                 │
│  💡 We're showing you premium   │
│      denominations.             │
│                                 │
│  ⚡ Quick Picks                 │
│  "✨ Personalized for you"      │
│  ┌────┐ ┌────┐ ┌────┐          │
│  │$100│ │$50 │ │$50 │          │
│  │Visa│ │Amzn│ │Trgt│          │
│  └────┘ └────┘ └────┘          │
│  (Premium cards prioritized!)   │
└─────────────────────────────────┘
```

---

## 🤖 **HOW THE AI WORKS**

### **Step 1: Data Collection**

Every time a user redeems a card, we record:
- Card ID
- Brand (Visa, Amazon, Target, etc.)
- Amount ($5, $10, $25, etc.)
- Timestamp (date, time, day of week)

**Example:**
```swift
RedemptionRecord {
    cardId: "amazon_25"
    brand: "Amazon"
    amount: 25.00
    timestamp: 2026-01-10 09:15:00
}
```

---

### **Step 2: Pattern Analysis**

The AI analyzes redemption history to identify patterns:

**Brand Frequency:**
```
Amazon: 5 redemptions
Visa: 3 redemptions
Target: 2 redemptions
→ User prefers Amazon
```

**Denomination Frequency:**
```
$25: 4 redemptions
$10: 3 redemptions
$5: 2 redemptions
→ User prefers $25 cards
```

**Time Patterns:**
```
9am-11am: 3 Starbucks redemptions
Saturday: 2 Target redemptions
→ Morning coffee lover, weekend shopper
```

**Average Amount:**
```
Total: $190 over 10 redemptions
Average: $19.00
→ User typically redeems mid-range cards
```

---

### **Step 3: Recommendation Scoring**

Each gift card gets a score based on multiple factors:

```
SCORE CALCULATION (max 235 points):

1. Affordability (0-100 pts)
   - Can afford: +100
   - Cannot afford: +50 * (current_points / required_points)

2. Brand Preference (0-50 pts)
   - +10 per past redemption of this brand
   - Example: 3 Amazon redemptions = +30 pts

3. Denomination Preference (0-30 pts)
   - +5 per past redemption of this amount
   - Example: 2 $25 redemptions = +10 pts

4. Average Amount Similarity (0-20 pts)
   - If card matches user's avg amount: +20
   - If close: proportional score
   - Example: User avg $20, card is $25 = +16 pts

5. Time-Based Boost (0-15 pts)
   - Morning + Starbucks = +5
   - Weekend + Target/Walmart = +4
   - Monday + Amazon = +3

6. Recency Bias (0-10 pts)
   - Recently redeemed this brand (within 7 days) = +10
   - Decays over time

TOTAL SCORE determines card ranking
```

**Example Scoring:**

```
Scenario: User has 15,000 points, prefers Amazon, redeems $25 cards

Card: $25 Amazon Gift Card (12,500 pts)
├─ Affordability: +100 (can afford)
├─ Brand (Amazon, 3 past redemptions): +30
├─ Denomination ($25, 2 past redemptions): +10
├─ Avg Match ($25 = avg): +20
├─ Time Boost (Monday): +3
└─ Recency (redeemed Amazon 3 days ago): +7
TOTAL: 170 points ⭐ TOP PICK

Card: $10 Visa Gift Card (5,000 pts)
├─ Affordability: +100 (can afford)
├─ Brand (Visa, 1 past redemption): +10
├─ Denomination ($10, 0 past redemptions): +0
├─ Avg Match ($10 ≠ $25 avg): +8
├─ Time Boost: +0
└─ Recency: +0
TOTAL: 118 points

Card: $50 Target Gift Card (25,000 pts)
├─ Affordability: +30 (60% affordable)
├─ Brand (Target, 0 past redemptions): +0
├─ Denomination ($50, 0 past redemptions): +0
├─ Avg Match ($50 ≠ $25 avg): +10
├─ Time Boost (Saturday): +4
└─ Recency: +0
TOTAL: 44 points

RANKING:
1st: $25 Amazon (170 pts) ← Shown first!
2nd: $10 Visa (118 pts)
3rd: $50 Target (44 pts)
```

---

## 🎯 **CONTEXTUAL INTELLIGENCE**

The AI makes **smart predictions** based on time and context:

### **Time-of-Day Boosts**

| Time | Brand | Boost | Reasoning |
|------|-------|-------|-----------|
| 6am-10am | Starbucks | +5 pts | Morning coffee run |
| 12pm-2pm | Any | +2 pts | Lunch time |
| 6pm-9pm | Amazon | +3 pts | Evening shopping |

### **Day-of-Week Boosts**

| Day | Brand | Boost | Reasoning |
|-----|-------|-------|-----------|
| Monday | Amazon | +3 pts | Start of week shopping |
| Saturday | Target/Walmart | +4 pts | Weekend errands |
| Sunday | Starbucks | +3 pts | Weekend treat |

### **Recency Effects**

```
Redeemed Amazon 2 days ago
→ Likely to redeem Amazon again soon
→ +10 pts to Amazon cards

Redeemed Visa 14 days ago
→ Not recently active with Visa
→ +0 pts to Visa cards
```

---

## 📊 **PERSONALIZED INSIGHTS**

The AI generates **natural language insights** based on user behavior:

### **Insight Types:**

**1. Brand Loyalty** (3+ redemptions of same brand)
```
"💡 You love Amazon! We've prioritized Amazon cards for you."
"💡 You're a Visa fan! Check out these Visa options."
```

**2. Denomination Preference** (average < $10)
```
"💡 You prefer smaller denominations. Perfect for frequent treats!"
```

**3. Denomination Preference** (average ≥ $50)
```
"💡 You go big! We're showing you premium denominations."
```

**4. New User** (no history)
```
No insight shown, generic recommendations
```

---

## 🔄 **CONTINUOUS LEARNING**

The AI improves over time:

### **Learning Timeline:**

```
Redemption 1
└─ Brand: Amazon
   └─ AI learns: User redeemed Amazon once
      └─ Effect: Slight boost to Amazon cards

Redemption 2
└─ Brand: Amazon ($25)
   └─ AI learns: User prefers Amazon, likes $25
      └─ Effect: Moderate boost to $25 Amazon cards

Redemption 3
└─ Brand: Amazon ($25, Saturday)
   └─ AI learns: Strong Amazon preference, $25 sweet spot, weekend pattern
      └─ Effect: Strong boost to $25 Amazon on weekends

Redemption 5
└─ Brand: Amazon ($25, $10, $50 mix)
   └─ AI learns: Amazon superfan, flexible amounts
      └─ Effect: All Amazon cards prioritized
      └─ Insight: "You love Amazon!" shown
```

### **Adaptation Example:**

```
WEEK 1: User redeems small Amazon cards ($5, $10)
→ AI recommends: Small Amazon cards

WEEK 2: User redeems large Visa cards ($50, $100)
→ AI adapts: Shifts to large cards, both brands

WEEK 3: User redeems mix of Target/Walmart
→ AI adapts: Diversifies recommendations

RESULT: Recommendations evolve with user preferences
```

---

## 💾 **DATA PERSISTENCE**

User preferences are **automatically saved**:

- **UserDefaults storage** (local, instant)
- **Last 50 redemptions** kept for analysis
- **Survives app restarts** (preferences preserved)
- **No server required** (works offline)

**What's Stored:**
```json
{
  "redemption_history": [
    {
      "cardId": "amazon_25",
      "brand": "Amazon",
      "amount": 25.0,
      "timestamp": "2026-01-10T09:15:00Z"
    },
    ...
  ],
  "preferences": {
    "brandFrequency": {
      "Amazon": 5,
      "Visa": 3,
      "Target": 2
    },
    "denominationFrequency": {
      "25.0": 4,
      "10.0": 3,
      "5.0": 2
    },
    "averageRedemptionAmount": 19.0,
    "timeOfDayPattern": {
      "9": 3,
      "14": 2
    },
    "dayOfWeekPattern": {
      "6": 2,
      "1": 3
    }
  }
}
```

---

## 🎨 **UI INTEGRATION**

### **Visual Indicators:**

**1. Personalized Insight Banner**
```
┌───────────────────────────────┐
│ ✨ 💡 You love Amazon!        │
│    We've prioritized Amazon   │
│    cards for you.             │
└───────────────────────────────┘
```

**2. Quick Picks Header**
```
BEFORE (no history):
⚡ Quick Picks
"Redeem now!"

AFTER (has history):
⚡ Quick Picks
"✨ Personalized for you"
```

**3. Card Badges** (future enhancement)
```
┌──────────────┐
│  $25 Amazon  │ ⭐ One of your
│  12,500 pts  │    favorites!
└──────────────┘
```

---

## 📈 **BUSINESS IMPACT**

### **Benefits:**

1. **🎯 Higher Conversion**
   - Users see cards they actually want
   - Reduced decision fatigue
   - Faster redemption = more engagement

2. **🔄 Increased Retention**
   - Personalized experience = stickiness
   - Users feel understood
   - "This app knows me!"

3. **💰 Higher Redemption Value**
   - Suggests optimal denominations
   - Encourages larger redemptions
   - Increases lifetime value

4. **📊 Valuable Insights**
   - Understand user preferences
   - Identify popular brands/amounts
   - Optimize gift card inventory

---

## 🧪 **TESTING SCENARIOS**

### **Scenario 1: New User**
```
1. User opens gift card shop
2. No history exists
3. Quick Picks shows generic cards (sorted by amount)
4. No personalized insight shown
5. ✅ PASS: Generic experience for new users
```

### **Scenario 2: Brand Loyalty**
```
1. User redeems 3 Amazon cards
2. AI learns Amazon preference
3. Refresh shop
4. Quick Picks now shows Amazon cards first
5. Insight: "You love Amazon!"
6. ✅ PASS: Brand prioritization works
```

### **Scenario 3: Denomination Preference**
```
1. User redeems 4 small cards ($5, $10)
2. AI learns small denomination preference
3. Refresh shop
4. Quick Picks shows $5 and $10 cards
5. Insight: "You prefer smaller denominations"
6. ✅ PASS: Amount prioritization works
```

### **Scenario 4: Time-Based Context**
```
1. Open shop on Saturday morning
2. AI applies weekend boost to Target/Walmart
3. AI applies morning boost to Starbucks
4. Quick Picks adapts to time context
5. ✅ PASS: Contextual recommendations work
```

### **Scenario 5: Preference Evolution**
```
1. User redeems small cards (week 1)
2. AI recommends small cards
3. User redeems large cards (week 2)
4. AI adapts to new preference
5. Quick Picks now shows large cards
6. ✅ PASS: Learning adapts over time
```

---

## ✅ **IMPLEMENTATION CHECKLIST**

- ✅ Create `GiftCardRecommendationService.swift`
- ✅ Implement redemption tracking
- ✅ Build scoring algorithm (6 factors, 235 pts max)
- ✅ Add time-based contextual boosts
- ✅ Generate personalized insights
- ✅ Integrate with `GiftCardShopView`
- ✅ Update Quick Picks to use AI recommendations
- ✅ Add personalized insight banner
- ✅ Update header to show "Personalized for you"
- ✅ Record redemptions for continuous learning
- ✅ Persist data to UserDefaults
- ✅ Load preferences on app launch

---

## 🚀 **RESULT**

**From**: Generic, one-size-fits-all gift card list  
**To**: Intelligent, adaptive, personalized shopping experience

**User Reaction:**
- 😐 Before: "Where's the card I want? *scroll*"
- 🤩 After: "Wow, it knows I love Amazon! This is MY shop!" ✨

---

**The gift card shop now has AI-powered recommendations that learn and adapt to each user!** 🧠✨
