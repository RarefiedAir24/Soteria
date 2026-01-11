# 🧪 10X LOYALTY SYSTEM - TESTING GUIDE

**Status**: Ready for Testing
**Date**: January 10, 2026
**Testing Tool**: Enhanced `DeveloperTestingView` (Settings → Developer Testing)

---

## 📋 **TESTING CHECKLIST**

### **✅ PHASE 1: EARNING RATE (10 pts/$1)**

#### **Test 1.1: Basic Earning Rate**
```
STEPS:
1. Open Developer Testing (Settings → Developer Testing)
2. Tap "Reset All Points" (start fresh)
3. Tap "Test: Save $100 → Earn 1,000 pts"
4. Verify alert shows: "Saved $100 → Earned 1,000 points"
5. Verify Current Points shows: 1,000

EXPECTED RESULT:
✅ $100 saved = 1,000 points earned
✅ Rate: 10 pts/$1 (confirmed)

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 1.2: Goal Completion Bonus**
```
STEPS:
1. Tap "Reset All Points"
2. Tap "Test: Complete Goal → Earn 5,000 pts"
3. Verify alert shows: "Goal Completed → Earned 5,000 bonus points"
4. Verify Current Points shows: 5,000

EXPECTED RESULT:
✅ Goal completion = 5,000 bonus points
✅ Bonus: 10x increase (was 500, now 5,000)

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 1.3: Achievement Unlock Bonus**
```
STEPS:
1. Tap "Reset All Points"
2. Tap "Test: Unlock Achievement → Bonus Points"
3. Verify alert shows: "Achievement Unlocked → Earned 2,000 bonus points"
4. Verify Current Points shows: 2,000

EXPECTED RESULT:
✅ Achievement (Cat/Parrot) = 2,000 bonus points
✅ Bonus: 10x increase (was 200, now 2,000)

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 1.4: Combined Earning**
```
STEPS:
1. Tap "Scenario 2: Active Saver ($100 saved)"
2. Verify points: 1,000
3. Tap "Test: Complete Goal → Earn 5,000 pts"
4. Verify total points: 6,000
5. Tap "Test: Unlock Achievement → Bonus Points"
6. Verify total points: 8,000

EXPECTED RESULT:
✅ Multiple earning sources accumulate correctly
✅ Total = 1,000 (save) + 5,000 (goal) + 2,000 (achievement) = 8,000 pts

STATUS: [ ] Pass  [ ] Fail
```

---

### **✅ PHASE 2: GIFT CARD CATALOG ($5-$100)**

#### **Test 2.1: Verify Catalog Size**
```
STEPS:
1. Navigate to: Home → Loyalty Shop → Gift Cards tab
2. Scroll through all available cards
3. Count total cards

EXPECTED RESULT:
✅ Total cards: 28
✅ Brands: Visa, Amazon, Target, Starbucks, Walmart
✅ Denominations visible: $5, $10, $25, $50, $100

STATUS: [ ] Pass  [ ] Fail
ACTUAL COUNT: _____ cards
```

#### **Test 2.2: $5 Cards**
```
STEPS:
1. In Developer Testing, tap "Give 2,500 pts → Test $5 Card"
2. Navigate to Gift Card Shop
3. Find a $5 card (Visa, Amazon, Target, Walmart, or Starbucks)
4. Verify point cost shows: 2,500 pts
5. Verify "Redeem" button is enabled

EXPECTED RESULT:
✅ $5 cards require 2,500 pts
✅ Conversion: 500 pts = $1
✅ User has enough points to redeem

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 2.3: $10 Cards**
```
STEPS:
1. In Developer Testing, tap "Reset All Points"
2. Tap "Give 2,500 pts → Test $5 Card" TWICE (= 5,000 pts)
3. Navigate to Gift Card Shop
4. Find a $10 card
5. Verify point cost shows: 5,000 pts
6. Verify "Redeem" button is enabled

EXPECTED RESULT:
✅ $10 cards require 5,000 pts
✅ User has enough points to redeem

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 2.4: $25 Cards**
```
STEPS:
1. In Developer Testing, tap "Scenario 4: Ready for $25 Card"
2. Verify points: 12,500
3. Navigate to Gift Card Shop
4. Find a $25 card
5. Verify point cost shows: 12,500 pts
6. Verify "Redeem" button is enabled

EXPECTED RESULT:
✅ $25 cards require 12,500 pts
✅ User has enough points to redeem

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 2.5: $50 Cards (NEW!)**
```
STEPS:
1. In Developer Testing, tap "Reset All Points"
2. Tap "Give 25,000 pts → Test $50 Card"
3. Navigate to Gift Card Shop
4. Find a $50 card (Visa, Amazon, Target, or Walmart)
5. Verify point cost shows: 25,000 pts
6. Verify "Redeem" button is enabled
7. Verify card displays correctly with $50 amount

EXPECTED RESULT:
✅ $50 cards exist for: Visa, Amazon, Target, Walmart
✅ $50 cards require 25,000 pts
✅ User has enough points to redeem
✅ Card UI displays "$50" clearly

STATUS: [ ] Pass  [ ] Fail
BRANDS TESTED: [ ] Visa  [ ] Amazon  [ ] Target  [ ] Walmart
```

#### **Test 2.6: $100 Cards (NEW!)**
```
STEPS:
1. In Developer Testing, tap "Reset All Points"
2. Tap "Give 50,000 pts → Test $100 Card"
3. Navigate to Gift Card Shop
4. Find a $100 card (Visa, Amazon, Target, or Walmart)
5. Verify point cost shows: 50,000 pts
6. Verify "Redeem" button is enabled
7. Verify card displays correctly with $100 amount

EXPECTED RESULT:
✅ $100 cards exist for: Visa, Amazon, Target, Walmart
✅ $100 cards require 50,000 pts
✅ User has enough points to redeem
✅ Card UI displays "$100" clearly

STATUS: [ ] Pass  [ ] Fail
BRANDS TESTED: [ ] Visa  [ ] Amazon  [ ] Target  [ ] Walmart
```

#### **Test 2.7: Starbucks (Lower Denominations Only)**
```
STEPS:
1. Navigate to Gift Card Shop
2. Find Starbucks cards
3. Verify available denominations

EXPECTED RESULT:
✅ Starbucks has: $5, $10, $25 only
✅ Starbucks does NOT have: $50 or $100
✅ Rationale: Coffee doesn't need high-value cards

STATUS: [ ] Pass  [ ] Fail
```

---

### **✅ PHASE 3: MONTHLY CAP ($50)**

#### **Test 3.1: View Monthly Cap**
```
STEPS:
1. Open Developer Testing → "MONTHLY CAP TESTING" section
2. Verify "Monthly Cap" shows: $50
3. Verify "Redeemed This Month" shows: $0 (if new month)
4. Verify "Remaining" shows: $50

EXPECTED RESULT:
✅ Monthly cap: $50 (was $25, now doubled!)
✅ Starts at $0 redeemed
✅ Full $50 available

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 3.2: Simulate $25 Redemption**
```
STEPS:
1. In Developer Testing, tap "Simulate $25 Redemption"
2. Verify alert shows: "Simulated $25 redemption! Remaining: $25"
3. Check "Redeemed This Month": should show $25
4. Check "Remaining": should show $25

EXPECTED RESULT:
✅ $25 redeemed successfully
✅ $25 remaining (half of $50 cap)
✅ Can still redeem more

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 3.3: Hit Cap with $50 Redemption**
```
STEPS:
1. Tap "Reset Monthly Redemptions" (or start fresh)
2. Tap "Simulate $50 Redemption"
3. Verify alert shows: "Simulated $50 redemption! Remaining: $0"
4. Check "Redeemed This Month": should show $50
5. Check "Remaining": should show $0
6. Verify warning: "⚠️ Cap reached! Cannot redeem more this month."

EXPECTED RESULT:
✅ $50 redeemed successfully
✅ $0 remaining
✅ Cap reached warning displayed

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 3.4: Attempt to Exceed Cap**
```
STEPS:
1. With cap already reached ($50 redeemed)
2. Tap "Simulate $25 Redemption"
3. Verify error alert shows: "Cannot redeem! Monthly cap of $50 reached."

EXPECTED RESULT:
✅ Redemption blocked
✅ Error message clear and specific
✅ Points NOT deducted

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 3.5: Two $25 Redemptions**
```
STEPS:
1. Tap "Reset Monthly Redemptions"
2. Tap "Simulate $25 Redemption"
3. Verify remaining: $25
4. Tap "Simulate $25 Redemption" again
5. Verify remaining: $0
6. Verify cap reached warning appears

EXPECTED RESULT:
✅ First $25: Success, $25 remaining
✅ Second $25: Success, $0 remaining
✅ Cap reached after 2 redemptions
✅ Cannot redeem more

STATUS: [ ] Pass  [ ] Fail
```

---

### **✅ PHASE 4: END-TO-END REDEMPTION FLOW**

#### **Test 4.1: Redeem $5 Visa Card**
```
⚠️ NOTE: This requires Tremendous API integration!
If Tremendous is NOT set up, this will FAIL.

STEPS:
1. In Developer Testing, give yourself 2,500 pts
2. Navigate to Gift Card Shop
3. Select "$5 Visa Prepaid Card"
4. Tap "Redeem"
5. Confirm redemption
6. Wait for API response
7. Verify success message
8. Check email for gift card link

EXPECTED RESULT:
✅ Points deducted: -2,500
✅ Success message shown
✅ Gift card link received via email
✅ Transaction logged in Loyalty History

STATUS: [ ] Pass  [ ] Fail  [ ] Skipped (Tremendous not set up)
ERROR (if failed): _________________________
```

#### **Test 4.2: Redeem $50 Amazon Card**
```
⚠️ NOTE: This requires Tremendous API integration!

STEPS:
1. In Developer Testing, give yourself 25,000 pts
2. Navigate to Gift Card Shop
3. Select "$50 Amazon Gift Card"
4. Tap "Redeem"
5. Confirm redemption
6. Wait for API response
7. Verify success message
8. Check email for gift card link

EXPECTED RESULT:
✅ Points deducted: -25,000
✅ Success message shown
✅ $50 Amazon card received via email
✅ Transaction logged

STATUS: [ ] Pass  [ ] Fail  [ ] Skipped (Tremendous not set up)
```

#### **Test 4.3: Insufficient Points Error**
```
STEPS:
1. In Developer Testing, reset all points (0 pts)
2. Navigate to Gift Card Shop
3. Select any gift card (e.g., $5 card)
4. Verify "Redeem" button is DISABLED or shows error
5. Tap button (if enabled)
6. Verify error message: "Not enough points"

EXPECTED RESULT:
✅ Redeem button disabled when insufficient points
✅ Clear error message if user tries to redeem
✅ Points NOT deducted

STATUS: [ ] Pass  [ ] Fail
```

---

### **✅ PHASE 5: ACHIEVEMENT BONUSES (10X)**

#### **Test 5.1: Cat/Parrot Achievement (First Goal)**
```
STEPS:
1. Complete a goal (or simulate with Developer Testing)
2. Verify achievement unlock offer appears
3. Check bonus points: Should be 2,000 (was 200)

EXPECTED RESULT:
✅ Bonus: 2,000 points (10x increase)
✅ Cat or Parrot unlocked for free
✅ Item added to scene automatically

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 5.2: Hedgehog Achievement ($200 Saved)**
```
STEPS:
1. Save $200 total (or give 2,000 pts + simulate)
2. Check for Hedgehog achievement unlock
3. Verify bonus: 1,500 points (was 150)

EXPECTED RESULT:
✅ Bonus: 1,500 points (10x increase)
✅ Hedgehog unlocked for free

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 5.3: Dog Achievement ($500 Saved)**
```
STEPS:
1. Save $500 total (or give 5,000 pts)
2. Check for Dog achievement unlock
3. Verify bonus: 3,000 points (was 300)

EXPECTED RESULT:
✅ Bonus: 3,000 points (10x increase)
✅ Dog unlocked for free

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 5.4: Cow Achievement ($1,000 Saved)**
```
STEPS:
1. Save $1,000 total (or give 10,000 pts)
2. Check for Cow achievement unlock
3. Verify bonus: 5,000 points (was 500)

EXPECTED RESULT:
✅ Bonus: 5,000 points (10x increase)
✅ Cow unlocked for free

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 5.5: Deer Achievement ($1,500 Saved)**
```
STEPS:
1. Save $1,500 total (or give 15,000 pts)
2. Check for Deer achievement unlock
3. Verify bonus: 7,500 points (was 750)

EXPECTED RESULT:
✅ Bonus: 7,500 points (10x increase)
✅ Deer unlocked for free

STATUS: [ ] Pass  [ ] Fail
```

---

### **✅ PHASE 6: USER JOURNEY SCENARIOS**

#### **Test 6.1: New User Journey (First 3 Months)**
```
SCENARIO:
User signs up, saves $100/month for 3 months

STEPS:
1. Reset all points
2. Month 1: Give 1,000 pts (saved $100)
3. Check total: 1,000 pts
4. Month 2: Give 1,000 pts (saved $100)
5. Check total: 2,000 pts
6. Month 3: Give 1,000 pts (saved $100)
7. Check total: 3,000 pts
8. Navigate to Gift Card Shop
9. Verify user can redeem $5 card (2,500 pts)
10. Redeem $5 Visa card
11. Verify new balance: 500 pts

EXPECTED RESULT:
✅ After 3 months: First reward! ($5 card)
✅ Time to first redemption: 3 months (was 25 months with old rate!)
✅ User feels progress and value

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 6.2: Active Saver (1 Year)**
```
SCENARIO:
User saves $100/month for 12 months + completes 2 goals

STEPS:
1. Reset all points
2. Give 12,000 pts (12 months × $100 × 10 pts)
3. Give 10,000 pts (2 goals × 5,000 bonus)
4. Check total: 22,000 pts
5. Navigate to Gift Card Shop
6. Verify user can redeem:
   - One $25 card (12,500 pts) + One $10 card (5,000 pts)
   - OR multiple smaller cards

EXPECTED RESULT:
✅ Annual value: ~$35-40 in gift cards
✅ Multiple redemption options
✅ User feels substantial progress

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 6.3: Power User Journey**
```
SCENARIO:
User saves $500/month for 12 months + completes 5 goals

STEPS:
1. Reset all points
2. Give 60,000 pts (12 months × $500 × 10 pts)
3. Give 25,000 pts (5 goals × 5,000 bonus)
4. Check total: 85,000 pts
5. Navigate to Gift Card Shop
6. Verify user can redeem:
   - One $100 card (50,000 pts) + extras
   - OR multiple $50 cards

EXPECTED RESULT:
✅ Annual value: $150-170 in gift cards
✅ Can actually reach $100 card!
✅ High-value rewards feel achievable

STATUS: [ ] Pass  [ ] Fail
```

---

### **✅ PHASE 7: UI/UX VERIFICATION**

#### **Test 7.1: Points Display**
```
STEPS:
1. Navigate to: Home Screen
2. Check for loyalty points indicator
3. Verify format: "1,234 points" (comma-separated for large numbers)

EXPECTED RESULT:
✅ Points visible on Home Screen
✅ Number formatted correctly
✅ Updates in real-time when points change

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 7.2: Gift Card Shop Layout**
```
STEPS:
1. Navigate to Gift Card Shop
2. Verify layout is clean and organized
3. Check card tiles show:
   - Brand name
   - Dollar amount
   - Point cost
   - Icon
4. Scroll through all 28 cards

EXPECTED RESULT:
✅ Cards displayed in grid or list
✅ All information visible
✅ Easy to distinguish denominations
✅ No UI overlap or cutoff

STATUS: [ ] Pass  [ ] Fail
```

#### **Test 7.3: Progress Indicators**
```
STEPS:
1. Give yourself 10,000 pts
2. Navigate to Gift Card Shop
3. Check for progress indicators (e.g., "50% to next card")
4. Verify point balance prominently displayed

EXPECTED RESULT:
✅ User can see "how close" they are to rewards
✅ Motivating visual feedback
✅ Clear point balance

STATUS: [ ] Pass  [ ] Fail
```

---

## 🚨 **CRITICAL ISSUES TO WATCH FOR**

### **1. Earning Rate Issues**
```
SYMPTOM: User saves $100 but earns 100 pts (not 1,000)
CAUSE: Old earning rate (1 pt/$1) still in use
FIX: Verify LoyaltyPointsService.swift line 32: `pointsPerDollarSaved = 10.0`
```

### **2. Missing $50/$100 Cards**
```
SYMPTOM: Only see cards up to $25
CAUSE: GiftCard.swift not updated with new denominations
FIX: Verify GiftCard.swift includes $50 and $100 entries
```

### **3. Cap Not Enforced**
```
SYMPTOM: User can redeem >$50/month
CAUSE: RedemptionLimitsService not integrated
FIX: Verify redemption calls RedemptionLimitsService.canRedeemAmount()
```

### **4. Points Not Deducting**
```
SYMPTOM: User redeems card, but points don't decrease
CAUSE: LoyaltyPointsService.deductPoints() not called
FIX: Verify redemption flow calls deductPoints() AFTER successful API response
```

### **5. Tremendous API Errors**
```
SYMPTOM: Redemption fails with API error
CAUSE: Tremendous not configured or insufficient balance
FIX: Verify Tremendous account funded and API key in AWS Secrets Manager
```

---

## 📊 **TESTING RESULTS SUMMARY**

### **Copy this template to track results:**

```
TESTING SESSION
Date: ___________
Tester: ___________
Device: ___________
iOS Version: ___________

PHASE 1: EARNING RATE
✅ Test 1.1: Basic Earning Rate         [ ] Pass  [ ] Fail
✅ Test 1.2: Goal Completion Bonus      [ ] Pass  [ ] Fail
✅ Test 1.3: Achievement Unlock Bonus   [ ] Pass  [ ] Fail
✅ Test 1.4: Combined Earning           [ ] Pass  [ ] Fail

PHASE 2: GIFT CARD CATALOG
✅ Test 2.1: Verify Catalog Size        [ ] Pass  [ ] Fail  (Count: ___)
✅ Test 2.2: $5 Cards                   [ ] Pass  [ ] Fail
✅ Test 2.3: $10 Cards                  [ ] Pass  [ ] Fail
✅ Test 2.4: $25 Cards                  [ ] Pass  [ ] Fail
✅ Test 2.5: $50 Cards (NEW!)           [ ] Pass  [ ] Fail
✅ Test 2.6: $100 Cards (NEW!)          [ ] Pass  [ ] Fail
✅ Test 2.7: Starbucks (Lower Only)     [ ] Pass  [ ] Fail

PHASE 3: MONTHLY CAP
✅ Test 3.1: View Monthly Cap           [ ] Pass  [ ] Fail
✅ Test 3.2: Simulate $25 Redemption    [ ] Pass  [ ] Fail
✅ Test 3.3: Hit Cap with $50           [ ] Pass  [ ] Fail
✅ Test 3.4: Attempt to Exceed Cap      [ ] Pass  [ ] Fail
✅ Test 3.5: Two $25 Redemptions        [ ] Pass  [ ] Fail

PHASE 4: END-TO-END REDEMPTION
✅ Test 4.1: Redeem $5 Visa             [ ] Pass  [ ] Fail  [ ] Skipped
✅ Test 4.2: Redeem $50 Amazon          [ ] Pass  [ ] Fail  [ ] Skipped
✅ Test 4.3: Insufficient Points Error  [ ] Pass  [ ] Fail

PHASE 5: ACHIEVEMENT BONUSES
✅ Test 5.1: Cat/Parrot (2,000 pts)     [ ] Pass  [ ] Fail
✅ Test 5.2: Hedgehog (1,500 pts)       [ ] Pass  [ ] Fail
✅ Test 5.3: Dog (3,000 pts)            [ ] Pass  [ ] Fail
✅ Test 5.4: Cow (5,000 pts)            [ ] Pass  [ ] Fail
✅ Test 5.5: Deer (7,500 pts)           [ ] Pass  [ ] Fail

PHASE 6: USER JOURNEY SCENARIOS
✅ Test 6.1: New User (3 months)        [ ] Pass  [ ] Fail
✅ Test 6.2: Active Saver (1 year)      [ ] Pass  [ ] Fail
✅ Test 6.3: Power User Journey         [ ] Pass  [ ] Fail

PHASE 7: UI/UX VERIFICATION
✅ Test 7.1: Points Display             [ ] Pass  [ ] Fail
✅ Test 7.2: Gift Card Shop Layout      [ ] Pass  [ ] Fail
✅ Test 7.3: Progress Indicators        [ ] Pass  [ ] Fail

OVERALL PASS RATE: ___/32 tests (___%)

CRITICAL ISSUES FOUND:
1. _______________________________
2. _______________________________
3. _______________________________

NOTES:
_______________________________________
_______________________________________
_______________________________________
```

---

## ✅ **NEXT STEPS AFTER TESTING**

### **If All Tests Pass:**
1. ✅ Document test results
2. ✅ Sign up for Tremendous account
3. ✅ Fund Tremendous with $500-1,000
4. ✅ Test real redemption (Test 4.1 and 4.2)
5. ✅ Update marketing copy with new rates
6. ✅ Prepare for TestFlight launch

### **If Tests Fail:**
1. 🔍 Identify which phase failed
2. 🐛 Debug specific issue
3. 🔧 Fix and re-test
4. 📝 Document fix for future reference

---

## 🎯 **SUCCESS CRITERIA**

**The 10X upgrade is considered successful if:**
- ✅ Earning rate: $100 saved = 1,000 points (confirmed)
- ✅ Gift cards: 28 cards available ($5-$100)
- ✅ Monthly cap: $50/month enforced
- ✅ Achievement bonuses: All 10x (2,000-7,500 pts)
- ✅ First reward: Achievable in 2.5-3 months
- ✅ UI/UX: Clean, clear, motivating

**Ready to transform user engagement! 🚀**
