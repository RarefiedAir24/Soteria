# API Optimization Recommendations for App Startup

## Current State Analysis

### ✅ Already Using API
- **Dashboard API** (`/soteria/dashboard`) - Pre-computes:
  - `totalSaved` ✅
  - `currentStreak` ✅
  - `longestStreak` ✅
  - `activeGoal` (simplified) ✅
  - `recentRegretCount` ✅
  - `currentRisk` ✅
  - `isQuietModeActive` ✅
  - `soteriaMomentsCount` ✅

### ⚠️ Still Loading from UserDefaults (JSON decode)
These services still load from UserDefaults on-demand, which requires JSON decoding:

1. **GoalsService** - Loads full goals array from UserDefaults
   - Currently: Dashboard API returns simplified goal, but HomeView still calls `goalsService.ensureDataLoaded()`
   - **Recommendation**: Expand Dashboard API to return full goal data

2. **MoodTrackingService** - Loads mood entries and reflections from UserDefaults
   - Currently: Not in Dashboard API
   - **Recommendation**: Add `currentMood` and `recentMoodCount` to Dashboard API

3. **RegretLoggingService** - Loads full regrets array from UserDefaults
   - Currently: Dashboard API returns `recentRegretCount` only
   - **Recommendation**: Already optimized (only count needed for dashboard)

4. **PurchaseIntentService** - Loads purchase intents from UserDefaults
   - Currently: Not in Dashboard API
   - **Recommendation**: Add `recentPurchaseIntentsCount` to Dashboard API

5. **QuietHoursService** - Loads schedules from UserDefaults
   - Currently: Dashboard API returns `isQuietModeActive` only
   - **Recommendation**: Already optimized (only status needed for dashboard)

6. **StreakService** - Calculates streak locally
   - Currently: Dashboard API already computes this
   - **Recommendation**: ✅ Already optimized

## Recommended Optimizations

### 1. Expand Dashboard API Response (HIGH PRIORITY)

**Current Dashboard API returns:**
```json
{
  "totalSaved": 150.00,
  "currentStreak": 5,
  "longestStreak": 10,
  "activeGoal": { /* simplified */ },
  "recentRegretCount": 2,
  "currentRisk": "medium",
  "isQuietModeActive": false,
  "soteriaMomentsCount": 15
}
```

**Recommended Expanded Response:**
```json
{
  "totalSaved": 150.00,
  "currentStreak": 5,
  "longestStreak": 10,
  "activeGoal": { 
    /* FULL goal data, not simplified */
    "id": "goal-123",
    "name": "Vacation",
    "currentAmount": 500.00,
    "targetAmount": 2000.00,
    "progress": 0.25,
    "createdAt": 1234567890,
    "deadline": 1234567890,
    "category": "travel"
  },
  "recentRegretCount": 2,
  "currentRisk": "medium",
  "isQuietModeActive": false,
  "soteriaMomentsCount": 15,
  "currentMood": "good",  // NEW
  "recentMoodCount": 7,   // NEW - moods logged in last 7 days
  "recentPurchaseIntentsCount": 3,  // NEW - purchase intents in last 7 days
  "lastUpdated": 1703123456789
}
```

### 2. Remove `ensureDataLoaded()` Calls (HIGH PRIORITY)

**Current Code (HomeView.swift:404):**
```swift
if dashboardData.activeGoal != nil {
    // Load full goal from GoalsService (it has all properties we need)
    let goalsService = GoalsService.shared
    goalsService.ensureDataLoaded()  // ❌ This triggers UserDefaults JSON decode
    self.activeGoal = goalsService.activeGoal
}
```

**Optimized Code:**
```swift
// Dashboard API now returns full goal data, no need to load from GoalsService
if let goalData = dashboardData.activeGoal {
    self.activeGoal = SavingsGoal(
        id: goalData.id,
        name: goalData.name,
        targetAmount: goalData.targetAmount,
        currentAmount: goalData.currentAmount,
        // ... map all fields from API
    )
}
```

### 3. Create "Bootstrap" API Endpoint (MEDIUM PRIORITY)

A single API call that returns ALL essential data for app startup:

**Endpoint:** `GET /soteria/bootstrap?user_id={userId}`

**Response:**
```json
{
  "success": true,
  "data": {
    "dashboard": { /* full dashboard data */ },
    "user": {
      "email": "user@example.com",
      "username": "user",
      "avatarUrl": "https://..." // if stored in S3
    },
    "settings": {
      "isPremium": true,
      "subscriptionTier": "premium"
    }
  }
}
```

**Benefits:**
- Single API call instead of multiple
- Faster than multiple sequential calls
- Can be cached as single unit

### 4. Optimize Service Initialization (LOW PRIORITY)

**Current:** Services defer loading with 30-second delay
**Better:** Services should:
1. Never load from UserDefaults on startup
2. Only load from API
3. Use UserDefaults as cache (read-only on startup)
4. Sync UserDefaults in background after API call

## Implementation Priority

### Phase 1: Quick Wins (1-2 hours)
1. ✅ Expand Dashboard API to return full goal data
2. ✅ Remove `ensureDataLoaded()` calls for goals in HomeView
3. ✅ Add `currentMood` and `recentMoodCount` to Dashboard API

### Phase 2: Medium Effort (2-4 hours)
1. ✅ Add `recentPurchaseIntentsCount` to Dashboard API
2. ✅ Update HomeView to use Dashboard API data directly (no service calls)
3. ✅ Update all card views to use Dashboard API data
   - ✅ MoodCardView - Uses API data
   - ✅ InteractionsCardView - Uses API count, only loads service if count > 0
   - ✅ RiskCardView - Uses API currentRisk string
   - ✅ QuietModeCardView - Uses API isQuietModeActive

### Phase 3: Advanced (4-8 hours)
1. ✅ Create Bootstrap API endpoint
2. ✅ Refactor services to be API-first (UserDefaults as cache only)
3. ✅ Implement background sync for UserDefaults

## Expected Performance Improvements

### Current Startup Flow:
1. Load cached dashboard data (instant) ✅
2. Call Dashboard API (async, non-blocking) ✅
3. **Call `goalsService.ensureDataLoaded()`** (triggers JSON decode) ❌
4. **Call `streakService.ensureDataLoaded()`** (triggers UserDefaults read) ❌
5. **Call `moodService.ensureDataLoaded()`** (triggers JSON decode) ❌

### Optimized Startup Flow:
1. Load cached dashboard data (instant) ✅
2. Call Dashboard API (async, non-blocking) ✅
3. Use API data directly (no service calls) ✅
4. Background sync to UserDefaults (non-blocking) ✅

**Expected Improvement:** Remove 3-5 JSON decode operations from startup path

## Code Changes Needed

### 1. Lambda Function (`lambda/soteria-get-dashboard/index.js`)
- Expand `getActiveGoal()` to return full goal data
- Add `getCurrentMood()` function
- Add `getRecentMoodCount()` function
- Add `getRecentPurchaseIntentsCount()` function

### 2. Swift Services
- Remove `ensureDataLoaded()` calls from HomeView
- Create mapping functions to convert API data to Swift models
- Update services to sync from API instead of loading from UserDefaults

### 3. HomeView.swift
- Remove all `ensureDataLoaded()` calls
- Use Dashboard API data directly
- Map API goal data to `SavingsGoal` model

