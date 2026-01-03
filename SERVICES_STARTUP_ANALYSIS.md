# Services Startup Analysis

## Current Startup Flow
1. **Splash Screen** (1.5s) - No services accessed ✅
2. **AuthView_Simplified** - No services accessed ✅
3. **After Auth** → **OnboardingSurveyWrapper** - Accesses `OnboardingSurveyService.shared` via `@StateObject`
4. **After Onboarding** → **MainTabView** → **HomeView** - Accesses `PlaidService.shared` and `GoalsService.shared` immediately

## Services Accessed During Startup

### ❌ NOT NEEDED FOR STARTUP (Can be deferred):

1. **PlaidService** ⚠️
   - **Currently accessed:** In `HomeView` via `@ObservedObject private var plaidService = PlaidService.shared`
   - **When accessed:** Immediately when HomeView is created (after authentication)
   - **Can be deferred:** YES - Only needed when user views savings data or connects bank account
   - **Fix:** Make it lazy, only access when user opens savings section

2. **GoalsService** ⚠️
   - **Currently accessed:** In `HomeView` via `@ObservedObject private var goalsService = GoalsService.shared`
   - **When accessed:** Immediately when HomeView is created (after authentication)
   - **Can be deferred:** YES - Only needed when user views goals
   - **Fix:** Make it lazy, only access when user opens goals section

3. **DeviceActivityService** ✅
   - **Currently accessed:** Only when Settings tab is selected (lazy)
   - **Status:** Already deferred correctly

4. **QuietHoursService** ✅
   - **Currently accessed:** Only when Settings tab is selected (lazy)
   - **Status:** Already deferred correctly

5. **SubscriptionService** ✅
   - **Currently accessed:** Only when Settings tab is selected (lazy)
   - **Status:** Already deferred correctly

### ✅ NEEDED FOR STARTUP:

1. **OnboardingSurveyService**
   - **When accessed:** After authentication, via `@StateObject` in `OnboardingSurveyWrapper`
   - **Status:** This is fine - only accessed after user signs in

2. **AuthService**
   - **When accessed:** Only when user tries to sign in (lazy)
   - **Status:** Already deferred correctly

## Recommendations

### Immediate Fixes:
1. **Make PlaidService lazy in HomeView** - Only access when user actually needs savings data
2. **Make GoalsService lazy in HomeView** - Only access when user actually needs goals data
3. **Keep other services lazy** - They're already deferred correctly

### Result:
- **Startup:** Only OnboardingSurveyService (after auth) - minimal impact
- **After auth:** Services load on-demand when user navigates to specific sections
- **Much faster startup** - No blocking service initialization

