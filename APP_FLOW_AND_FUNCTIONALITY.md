# Soteria App Flow & Functionality

## 📱 App Launch Flow

### 1. Initial Launch
```
App Starts
    ↓
Firebase Initialization
    ↓
RootView Checks Authentication
    ↓
┌─────────────────┬─────────────────┐
│ Not Authenticated│  Authenticated  │
│   ↓              │      ↓           │
│  AuthView        │  MainTabView     │
│  (Sign In/Up)    │  (Home/Goals/Settings)│
└─────────────────┴─────────────────┘
```

### 2. Authentication Flow
- **AuthView**: Sign in or create account
- **Firebase Auth**: Email/password authentication
- **After Auth**: Automatically shows MainTabView

## 🏠 Main App Structure

### Tab Navigation (3 Tabs)
1. **Home** - Dashboard with behavioral insights
2. **Goals** - Savings goals tracking
3. **Settings** - App configuration and management

## 🎯 Core Features & Flow

### 1. App Selection & Monitoring Setup

**Location**: Settings → App Monitoring

**Flow**:
1. User taps "Select Apps to Monitor"
2. System Family Activity Picker opens (Apple's native interface)
3. User selects apps to block/monitor
4. **Free Tier**: Limited to 1 app
5. **Premium**: Unlimited apps
6. After selection → App Naming screen (optional)
7. User names each app for easier tracking
8. Monitoring can be enabled/disabled via toggle

**What Happens**:
- Selected apps are stored in `DeviceActivityService`
- App names are saved (UserDefaults + AWS if enabled)
- Monitoring state persists across app launches

### 2. Quiet Hours (Financial Quiet Mode)

**Location**: Settings → Quiet Hours

**Flow**:
1. User creates a schedule (time range + days of week)
2. **Free Tier**: 1 schedule, view-only (can toggle on/off)
3. **Premium**: Unlimited schedules, full editing
4. When schedule is active → Apps are automatically blocked

**What Happens**:
- `QuietHoursService` monitors time continuously
- When schedule time matches → Activates blocking
- `DeviceActivityService` applies blocking via `ManagedSettingsStore`
- Apps show custom blocking screen (`PurchaseIntentPromptView`)

### 3. App Blocking Flow (When User Tries to Open Blocked App)

**Trigger**: User opens a blocked app during Quiet Hours

**Flow**:
```
User Opens Blocked App
    ↓
iOS Family Controls Intercepts
    ↓
DeviceActivityMonitorExtension Detects
    ↓
Sends Notification to Open SOTERIA
    ↓
PurchaseIntentPromptView Appears
    ↓
User Sees Custom Blocking Screen:
    - "Is this a planned purchase or impulse?"
    - If Planned: Select category (gift, necessity, etc.)
    - If Impulse: Select mood (lonely, bored, stressed, etc.)
    - Optional: Enter estimated amount
    ↓
User Chooses:
    - "Continue Block" → Apps stay blocked, protection moment recorded
    - "Unblock & Shop" → Apps unblocked for 15 minutes, intent tracked
    ↓
Behavioral Data Recorded:
    - Purchase type (planned/impulse)
    - Category or mood
    - Time of day, day of week
    - Unblock frequency
    - App usage after unblock
```

### 4. Behavioral Tracking (Automatic)

**What's Tracked Automatically** (No User Input):
- **Unblock Events**: Every time user requests unblock
  - Timestamp
  - Purchase type (planned/impulse)
  - Category (if planned)
  - Mood (if impulse)
  - Time of day, day of week
  - Unblock count today/this week
  - Time since last unblock
  - Was app actually used after unblock?
  - How long was app used?

- **App Usage Sessions**: When user actually uses unblocked app
  - Start time
  - End time
  - Duration
  - Inactivity detection

- **Behavioral Patterns**: Calculated from events
  - Most common time of day
  - Most common day of week
  - Impulse vs planned ratio
  - App usage rate
  - Average time between unblocks
  - Quiet hours percentage

### 5. Smart Auto-Protection (Premium - Automatic)

**How It Works**:
- Checks every 5 minutes for risk patterns
- Uses **only automatic data** (no user input):
  - Late night (10pm-2am)
  - Weekend patterns
  - High unblock frequency (3+ in 1 hour)
  - High impulse ratio (60%+ impulse purchases)
  - Rapid unblock patterns (<30 min apart)
  - Quiet Hours disabled during risky times

**Auto-Activation**:
- When risk score >= 0.8 → Automatically creates 2-hour protection window
- Completely seamless - no prompts, no user action needed
- Named: "Auto-Protection: High Risk Detected"

### 6. HomeView Dashboard

**Displays**:
- **Protection Moments**: Count of times user chose protection
- **Behavioral Stats**: 
  - Unblock requests this week
  - Impulse rate percentage
- **Risk Alert**: If current risk level is high
- **Your Insights Card**: Summary of behavioral patterns
  - Total unblocks
  - Planned vs Impulse breakdown
  - Most active time of day
  - App usage rate
  - Link to full metrics

### 7. Metrics Dashboard

**Location**: Home → "View Full Metrics" or Settings → "View Metrics"

**Displays**:
- **Unblock Metrics**: Total, planned, impulse counts
- **Behavioral Patterns**: 
  - Time of day distribution
  - Day of week distribution
  - Category breakdown (planned purchases)
  - Mood breakdown (impulse purchases)
  - Quiet hours impact
  - App usage patterns
- **Time Range Filter**:
  - Free: Today, This Week
  - Premium: Today, This Week, This Month, All Time

### 8. PauseView (Manual Entry)

**Trigger**: User opens SOTERIA while Quiet Hours are active

**Flow**:
1. Shows "SOTERIA Moment" screen
2. Asks: "Is this a planned purchase or impulse?"
3. If Planned:
   - Select category (gift, necessity, etc.)
   - Enter estimated amount (optional)
   - Select mood
   - "Unblock & Shop" or "Continue Block"
4. If Impulse:
   - Select mood (lonely, bored, stressed, etc.)
   - Enter estimated amount (optional)
   - "Continue Block" (primary action)
   - "Unblock & Shop" (after mood selection)

**What Happens**:
- Protection moment recorded (count increments)
- Amount saved (if entered) - user-reported estimate
- Purchase intent tracked for behavioral analysis

## 🔄 User Journey Examples

### Journey 1: First-Time User
```
1. Launch App → AuthView
2. Sign Up → Create Account
3. MainTabView Appears
4. Settings → Select 1 App (Free)
5. Settings → Create 1 Quiet Hours Schedule (Free)
6. Enable Monitoring Toggle
7. Quiet Hours activate at scheduled time
8. User tries to open blocked app
9. PurchaseIntentPromptView appears
10. User chooses "Continue Block"
11. Protection moment recorded
12. HomeView shows updated stats
```

### Journey 2: Premium User with Auto-Protection
```
1. User has Premium subscription
2. Smart Auto-Protection enabled
3. User unblocks 3 times in 1 hour at 11pm
4. System detects: Late night + High activity
5. Risk score = 1.0 (>= 0.8)
6. Auto-activates Quiet Hours for 2 hours
7. Apps automatically blocked
8. User tries to open app → Blocked
9. Protection happens seamlessly
```

### Journey 3: Behavioral Insights
```
1. User uses app for 1 week
2. System tracks all unblock events automatically
3. HomeView shows "Your Insights" card
4. User taps "View Full Metrics"
5. Sees patterns:
   - Most unblocks on Friday nights
   - 70% are impulse purchases
   - Stressed mood most common
   - Apps used 40% of the time after unblock
6. User gains awareness of patterns
```

## 🆓 Free vs Premium

### Free Tier
- ✅ 1 Quiet Hours schedule (view-only, can toggle)
- ✅ 1 app to monitor
- ✅ Basic behavioral tracking
- ✅ Metrics: Today & This Week only
- ✅ Protection moments tracking
- ❌ No editing of Quiet Hours
- ❌ No Smart Auto-Protection
- ❌ No cloud sync
- ❌ No advanced analytics

### Premium Tier
- ✅ Unlimited Quiet Hours schedules (full editing)
- ✅ Unlimited apps to monitor
- ✅ Smart Auto-Protection (automatic)
- ✅ Advanced analytics (all time ranges)
- ✅ Cloud sync (AWS DynamoDB)
- ✅ Export data
- ✅ Predictive alerts

## 🔐 Data Storage

### Local (UserDefaults)
- App names
- Unblock events
- App usage sessions
- Quiet Hours schedules
- Monitoring state
- Protection moments count

### Cloud (AWS DynamoDB - Optional/Premium)
- Syncs all local data
- Multi-device access
- Backup and restore

### Authentication
- Firebase Auth (email/password)
- User ID used for AWS data sync

## 🎨 Key UI Screens

1. **AuthView**: Sign in/Sign up
2. **HomeView**: Dashboard with insights
3. **GoalsView**: Savings goals
4. **SettingsView**: Configuration
5. **QuietHoursView**: Schedule management
6. **AppSelectionView**: Select apps to monitor
7. **AppNamingView**: Name selected apps
8. **AppManagementView**: Manage app names
9. **MetricsDashboardView**: Full behavioral analytics
10. **PurchaseIntentPromptView**: Custom blocking screen
11. **PauseView**: Manual protection moment
12. **PaywallView**: Premium subscription

## 🔄 Background Processes

### Continuous Monitoring
- **QuietHoursService**: Checks time every minute
- **RegretRiskEngine**: Assesses risk every 15 minutes
- **DeviceActivityService**: Tracks app usage in real-time
- **Smart Auto-Protection** (Premium): Checks every 5 minutes

### Notifications
- Shopping session ended → Prompt to log purchase
- High risk detected → Suggest enabling Quiet Hours
- Auto-protection activated → Inform user

## 🎯 Core Philosophy

**Behavioral Intervention Tool** (Not Financial Tracker)
- Creates friction before spending
- Builds awareness of patterns
- Provides automatic insights
- Emphasizes prevention over tracking
- Manual entry is optional
- Focus on protection moments, not dollar amounts

