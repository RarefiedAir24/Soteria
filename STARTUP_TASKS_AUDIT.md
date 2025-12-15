# 🔍 Startup Tasks Audit

## Current Tasks Starting on App Launch

### 1. RootView.onAppear
- **Task**: Purchase intent check (60-second delay)
- **Priority**: `.utility`
- **Status**: ⚠️ Can be removed - only needed when user actually tries to access blocked app

### 2. RootView.task
- **Task**: Splash screen delay (1.5 seconds)
- **Priority**: `.userInitiated`
- **Status**: ✅ Required for branding

### 3. RootView.onReceive (willEnterForeground)
- **Task**: Purchase intent check (10-second delay)
- **Priority**: `.utility`
- **Status**: ⚠️ Can be removed - redundant with onAppear

### 4. RootView.onReceive (didBecomeActive)
- **Task**: Purchase intent check (10-second delay)
- **Priority**: `.utility`
- **Status**: ⚠️ Can be removed - redundant with onAppear

### 5. QuietHoursService.init()
- **Task**: Load schedules (30-second delay)
- **Priority**: `.background`
- **Status**: ⚠️ Can be made lazy - only load when user opens Quiet Hours

### 6. DeviceActivityService.init()
- **Task**: Load monitoring state, app names, selection (5-second delay)
- **Priority**: `.background` → `.utility` for MainActor work
- **Status**: ⚠️ Can be made lazy - only load when user opens Settings

### 7. RegretRiskEngine.init()
- **Task**: Periodic assessment (deferred, not actually starting)
- **Priority**: `.background`
- **Status**: ✅ Already deferred - no work happening

### 8. HomeView.task
- **Task**: Cache environment object values (0.5-second delay)
- **Priority**: `.utility`
- **Status**: ⚠️ Can be made truly lazy - only cache when view appears

## Recommendations

### Remove Immediately:
1. **Purchase intent checks in onAppear/foreground/active** - Only check when user actually tries to access a blocked app
2. **Redundant notification handlers** - Keep only one purchase intent check mechanism

### Make Lazy (Load on Demand):
1. **QuietHoursService.loadSchedules()** - Only load when user opens Quiet Hours view
2. **DeviceActivityService data loading** - Only load when user opens Settings/App Management
3. **HomeView caching** - Only cache when HomeView actually appears (not in .task)

### Keep:
1. **Splash screen delay** - Required for branding
2. **Auth state checking** - Required for routing

## Streamlined Startup Flow

**On Launch:**
1. Show splash screen (1.5s)
2. Check auth state
3. Show appropriate view (MainTabView or AuthView)
4. **That's it!**

**On Demand (Lazy Loading):**
- Quiet Hours schedules → Load when user opens Quiet Hours
- Device Activity data → Load when user opens Settings
- HomeView data → Load when HomeView appears
- Purchase intent checks → Only when app blocking actually happens

