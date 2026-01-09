# Meta Yellow Card - First 100 TestFlight Users Implementation

## Overview
Implemented a feature where the first 100 unique users who sign up in TestFlight receive a congratulations message and are upgraded to the "Meta Yellow Card" (yellow premium card theme). User 101 and beyond do NOT get the Meta Yellow Card.

---

## Implementation Details

### 1. Backend (Lambda) - Signup Tracking

**File**: `lambda/soteria-auth-signup/index.js`

**Changes**:
- Added DynamoDB client for counter tracking
- Accepts `isTestFlight` flag in signup request
- Tracks TestFlight signups using an atomic counter in DynamoDB
- Returns `isFirst100TestFlightUser: true/false` in response

**Counter Logic**:
- Uses DynamoDB table `soteria-counters` (or `COUNTER_TABLE` env var)
- Counter key: `testflight_signup_counter`
- Atomically increments counter using `ADD` operation
- If counter <= 100: user gets Meta Yellow Card
- If counter > 100: user does NOT get Meta Yellow Card

**DynamoDB Table Structure**:
```javascript
{
  counter_key: "testflight_signup_counter",
  count: 1-100+ (number),
  updated_at: "ISO timestamp"
}
```

---

### 2. Frontend - Signup Flow

**Files Modified**:
- `soteria/Services/CognitoAuthService.swift`
- `soteria/Services/AuthService.swift`
- `soteria/Views/AuthView_Simplified.swift`

**Changes**:
- `CognitoAuthService.signUp()` now accepts `isTestFlight` parameter
- Automatically detects TestFlight environment (sandboxReceipt)
- Passes `isTestFlight` flag to Lambda
- Returns `Bool` indicating if user is in first 100
- Stores `is_first_100_testflight_user` flag in UserDefaults

**Email Confirmation Flow**:
- If email confirmation is required, the `isFirst100TestFlightUser` flag is included in the error userInfo
- Flag is stored when confirmation screen is shown
- Celebration is shown after successful confirmation and sign-in

---

### 3. Card Theme Logic

**Files Modified**:
- `soteria/Views/HomeView.swift`
- `soteria/Views/SettingsView.swift`
- `soteria/Views/GoalsView.swift`
- `soteria/Views/Shared/PremiumHeaderView.swift`

**Updated `isBetaTester()` Logic**:
```swift
1. Check if user is in first 100 TestFlight signups
   → If yes: return true (gets Meta Yellow Card)
   
2. Check if running in TestFlight (but NOT first 100)
   → If yes: return false (does NOT get Meta Yellow Card)
   
3. Check DEBUG mode
   → Debug builds don't get Meta Yellow Card unless they're first 100
   
4. Check UserDefaults flag (for manual testing)
   → Can be set manually for testing
```

**Result**:
- First 100 TestFlight users: Get Meta Yellow Card (yellow theme)
- TestFlight users 101+: Do NOT get Meta Yellow Card (regular theme)
- Production users: Regular theme based on subscription

---

### 4. Celebration View

**File**: `soteria/Views/MetaYellowCardCelebrationView.swift` (NEW)

**Features**:
- Full-screen overlay with confetti and balloons
- "Congratulations!" banner
- Message: "You're one of the first 100 TestFlight users!"
- "You've been upgraded to the Meta Yellow Card"
- Yellow-themed design matching the card
- "Get Started" button to dismiss

**Integration**:
- Shown via `ShowMetaYellowCardCelebration` notification
- Displayed in `HomeView` as an overlay
- Triggered after successful signup or email confirmation

---

## User Flow

### First 100 TestFlight Users:
1. User signs up in TestFlight
2. Lambda increments counter (1-100)
3. Lambda returns `isFirst100TestFlightUser: true`
4. App stores `is_first_100_testflight_user = true` in UserDefaults
5. User sees Meta Yellow Card celebration
6. User's card displays with yellow theme (Meta Yellow Card)

### TestFlight Users 101+:
1. User signs up in TestFlight
2. Lambda increments counter (101+)
3. Lambda returns `isFirst100TestFlightUser: false`
4. App stores `is_first_100_testflight_user = false` in UserDefaults
5. User does NOT see celebration
6. User's card displays with regular theme (not yellow)

---

## DynamoDB Setup Required

**Table Name**: `soteria-counters` (or set `COUNTER_TABLE` environment variable)

**Table Structure**:
- **Partition Key**: `counter_key` (String)
- **Attributes**:
  - `counter_key`: String (e.g., "testflight_signup_counter")
  - `count`: Number (starts at 0, increments with each signup)
  - `updated_at`: String (ISO timestamp)

**Lambda IAM Permissions Required**:
```json
{
  "Effect": "Allow",
  "Action": [
    "dynamodb:UpdateItem",
    "dynamodb:PutItem",
    "dynamodb:GetItem"
  ],
  "Resource": "arn:aws:dynamodb:*:*:table/soteria-counters"
}
```

---

## Testing

### Test First 100 Users:
1. Set up DynamoDB table `soteria-counters`
2. Sign up in TestFlight (first user)
3. Verify counter increments to 1
4. Verify user sees celebration
5. Verify user gets Meta Yellow Card

### Test User 101+:
1. Sign up 100 users (counter = 100)
2. Sign up 101st user
3. Verify counter increments to 101
4. Verify user does NOT see celebration
5. Verify user does NOT get Meta Yellow Card

### Manual Testing:
- Set `UserDefaults.standard.set(true, forKey: "is_first_100_testflight_user")` to test celebration
- Set `UserDefaults.standard.set(false, forKey: "is_first_100_testflight_user")` to test regular theme

---

## Notes

- **Counter Persistence**: Counter is stored in DynamoDB, so it persists across Lambda invocations
- **Atomic Operations**: Uses DynamoDB `ADD` operation for atomic increments (no race conditions)
- **Error Handling**: If counter fails, signup still succeeds (graceful degradation)
- **TestFlight Detection**: Automatically detects TestFlight via `sandboxReceipt` check
- **Email Confirmation**: Flag is preserved through email confirmation flow

---

## Files Changed

1. `lambda/soteria-auth-signup/index.js` - Counter tracking
2. `soteria/Services/CognitoAuthService.swift` - Pass TestFlight flag
3. `soteria/Services/AuthService.swift` - Store first 100 flag
4. `soteria/Views/AuthView_Simplified.swift` - Handle celebration
5. `soteria/Views/HomeView.swift` - Show celebration, update isBetaTester()
6. `soteria/Views/SettingsView.swift` - Update isBetaTester()
7. `soteria/Views/GoalsView.swift` - Update isBetaTester()
8. `soteria/Views/Shared/PremiumHeaderView.swift` - Update isBetaTester()
9. `soteria/Views/MetaYellowCardCelebrationView.swift` - NEW celebration view

---

## Next Steps

1. **Create DynamoDB Table**: Set up `soteria-counters` table with partition key `counter_key`
2. **Update Lambda IAM Role**: Add DynamoDB permissions for counter table
3. **Set Environment Variable** (optional): `COUNTER_TABLE=soteria-counters` in Lambda
4. **Test**: Sign up first user in TestFlight and verify celebration appears
5. **Monitor**: Check CloudWatch logs for counter increments

---

**Status**: ✅ Implementation Complete - Ready for Testing

