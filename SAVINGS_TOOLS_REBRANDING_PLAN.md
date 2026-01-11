# 🔄 PARTNER VIEW REBRANDING TO "SAVINGS TOOLS"

**Current Status**: PartnerLoyaltyView shows "discount marketplace" approach  
**Target**: Option B Framework - "Activate Proven Savings Systems"

---

## 🎯 **OPTION B FRAMEWORK REQUIREMENTS**

### **Core Message:**
**"Soteria does NOT sell discounts."**  
**"Soteria reduces unavoidable expenses by helping members activate proven savings systems."**

---

## 🔄 **CHANGES NEEDED**

### **1. REBRANDING (All Copy)**

| OLD (Discount Marketplace) | NEW (Savings Tools) |
|----------------------------|---------------------|
| "Partner Benefits" | "Savings Tools" |
| "Exclusive savings and loyalty rewards" | "Reduce unavoidable expenses" |
| "Discounts from our partners" | "Activate proven savings systems" |
| "Save money at..." | "Save on gas automatically with..." |
| "Get X% off" | "Earn cashback on purchases you're already making" |

---

### **2. TOOL CATEGORIES (Not Partner Categories)**

**OLD**: Categories like "Dining", "Shopping", "Travel"  
**NEW**: Expense categories:
- ⛽ **Gas Stations** (Upside, BPme, Fuel Rewards)
- 💊 **Prescriptions** (GoodRx)
- 🛒 **Groceries** (Future: Ibotta, Fetch)
- 🏪 **Retail** (Future: Rakuten)

---

### **3. TOOL CARDS (Not Partner Cards)**

**Each tool shows:**
- Tool name & logo
- **What it does** (not what discount you get)
- **How to activate** (clear CTA)
- **Loyalty bonus** (points for activation + usage)
- **Proof/stats** (e.g., "Average user saves $150/year on gas")

**Example Card - Upside:**
```
┌─────────────────────────────────────┐
│  ⛽ Upside                           │
│  "Earn cash back on gas"            │
│                                     │
│  🎯 What It Does:                   │
│  Automatically find the best gas    │
│  prices nearby and earn up to       │
│  25¢/gallon back                    │
│                                     │
│  💰 Your Savings:                   │
│  Avg $150/year on gas you're       │
│  already buying                     │
│                                     │
│  🌟 Loyalty Bonus:                  │
│  +1,000 pts for activation          │
│  +100 pts per $10 saved             │
│                                     │
│  [ Activate Upside ]                │
│  ↓ Opens app/web signup             │
└─────────────────────────────────────┘
```

---

### **4. NON-NEGOTIABLE RULES**

✅ **APPROVED TOOLS (Gas Only - Phase 1):**
- Upside
- BPme (BP rewards)
- Fuel Rewards (Shell)

❌ **EXCLUDED:**
- Generic "discount" offers
- Affiliate links disguised as benefits
- Anything requiring code entry at checkout
- Anything that feels like a "coupon site"

✅ **COPY RULES:**
- NEVER say "discount" or "deal"
- ALWAYS focus on "systems" and "automatic"
- NEVER promise specific percentages
- ALWAYS frame as "expenses you're already paying"

---

### **5. ACTIVATION FLOW**

**Step 1: User taps "Activate Upside"**
- Show explainer: "Upside automatically saves you money on gas"
- Show: "You'll open Upside app to sign up"
- CTA: "Continue to Upside"

**Step 2: Open Upside (external)**
- `UIApplication.shared.open(url: upsideURL)`
- User signs up in Upside app/web

**Step 3: Return to Soteria**
- User confirms activation
- Award +1,000 loyalty points
- Mark tool as "Activated"
- Show in "My Activated Tools" section

**Step 4: Track Usage (Future)**
- User reports savings manually (screenshot?)
- Award +100 pts per $10 saved
- Track total savings in Soteria

---

### **6. VIEW STRUCTURE**

**New "SavingsToolsView" Layout:**
```
┌─────────────────────────────────────┐
│  📱 SAVINGS TOOLS                   │
│  "Activate proven systems to reduce │
│   unavoidable expenses"             │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  💡 WHY USE SAVINGS TOOLS?          │
│  • Automatic savings (no coupons!)  │
│  • Expenses you're already paying   │
│  • Earn loyalty points              │
│  • Track all savings in one place   │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  ⛽ GAS STATIONS                    │
│  [ Upside Card ]                    │
│  [ BPme Card ]                      │
│  [ Fuel Rewards Card ]              │
│                                     │
│  💊 PRESCRIPTIONS (Coming Soon)     │
│  [ GoodRx Card - LOCKED ]           │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  🌟 MY ACTIVATED TOOLS              │
│  ✅ Upside - $127 saved this year   │
│  ✅ BPme - $43 saved this year      │
│                                     │
└─────────────────────────────────────┘
```

---

## 🚀 **IMPLEMENTATION OPTIONS**

### **Option A: Update Existing PartnerLoyaltyView**
- Rename to `SavingsToolsView.swift`
- Update all copy and branding
- Replace partner cards with tool cards
- Update service to `SavingsToolsService`

### **Option B: Create New SavingsToolsView**
- Build from scratch with clean code
- Keep old PartnerLoyaltyView for reference
- Cleaner implementation
- Better for testing

---

## ❓ **QUESTIONS FOR YOU**

1. **Which implementation?** Update existing or create new?
2. **Phase 1 tools?** Just gas (Upside, BPme, Fuel Rewards)?
3. **Manual or auto tracking?** Should users report savings manually or automatic API?
4. **Where to display?** 
   - HomeView card (current: `SavingsToolsHomeCard`)
   - Settings menu link?
   - New tab in MainTabView?

---

## 📝 **NEXT STEPS**

Once you confirm:
1. I'll implement the new Savings Tools view
2. Update all copy to match Option B framework
3. Create activation flow for each tool
4. Integrate loyalty points for activation
5. Add "My Activated Tools" tracking section

**Should I proceed with Option B (create new SavingsToolsView)?**
