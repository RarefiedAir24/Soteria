# Avatar Storage Solution - AWS S3 Implementation

## Current Issue

- Avatars are stored only in UserDefaults (local cache)
- Uninstalling the app clears UserDefaults → avatar is lost
- Firebase Storage is disabled (no cloud backup)
- Settings page state is also lost on uninstall

## Solution: AWS S3 Avatar Storage

### Implementation Plan

1. **Create S3 Bucket** for avatar storage
2. **Create Lambda Function** to handle avatar upload/download
3. **Update ProfileView** to upload to S3
4. **Update HomeView/SettingsView** to download from S3 if UserDefaults is empty

### Benefits

- ✅ Avatars persist across app reinstalls
- ✅ Avatars sync across devices
- ✅ No data loss when app is uninstalled
- ✅ Consistent with AWS infrastructure

### Alternative: Quick Fix (Temporary)

For now, users need to re-upload their avatar after uninstalling. This is expected behavior until S3 storage is implemented.

## Settings Page Reset

Settings are also stored in UserDefaults:
- `cachedSelectedAppsCount`
- `isMonitoringActive`
- `appNamesMapping`
- `quietHoursSchedules`

These will also be lost on uninstall. We should consider syncing critical settings to DynamoDB as well.

