# App Deletion and User Records Strategy

## Current State

### Local Data (UserDefaults)
- **Deleted on app uninstall**: ✅ Yes
  - User preferences
  - Cached avatars
  - Subscription status (local flag)
  - App selection count
  - Other local settings

### Cloud Data (AWS DynamoDB)
- **Deleted on app uninstall**: ❌ No
  - User data persists in DynamoDB tables
  - Cognito user account remains active
  - All user records remain in cloud

## Current Architecture

### Data Storage Locations

1. **UserDefaults (iOS)**
   - Avatars (images)
   - Subscription status flags
   - App selection count
   - Local preferences
   - **Status**: Cleared on app deletion ✅

2. **AWS Cognito**
   - User authentication
   - Email/password credentials
   - User ID
   - **Status**: Persists after app deletion ❌

3. **AWS DynamoDB Tables**
   - `soteria-user-data` - App names, general data
   - `soteria-purchase-intents` - Purchase intent records
   - `soteria-goals` - Savings goals
   - `soteria-regrets` - Regret entries
   - `soteria-moods` - Mood tracking data
   - `soteria-quiet-hours` - Quiet hours schedules
   - `soteria-app-usage` - App usage sessions
   - `soteria-unblock-events` - Unblock event metrics
   - **Status**: All data persists after app deletion ❌

## Design Decision: App Deletion = Account Deletion

### Rationale
- **User Intent**: When a user deletes the app, they're effectively deleting their account
- **Privacy**: Users expect their data to be deleted when they remove the app
- **Simplicity**: No need for separate "delete account" flow
- **Compliance**: Aligns with privacy expectations (GDPR, CCPA)

### Current Gap
- **Problem**: App deletion clears local data but cloud data remains
- **Impact**: User data persists in AWS even after app is deleted
- **Risk**: Privacy concerns, data accumulation, compliance issues

## Proposed Solutions

### Option 1: Automatic Cleanup on Reinstall (Recommended)
**Strategy**: When user reinstalls and signs in, check if it's a "new" account and clean up old data

**Implementation**:
1. Store a "last_sync_timestamp" in UserDefaults
2. On app reinstall, UserDefaults is cleared (timestamp lost)
3. On sign-in, check DynamoDB for existing data
4. If data exists but no local timestamp → treat as new account
5. Optionally: Delete old DynamoDB data for this user_id

**Pros**:
- Simple to implement
- Handles most cases automatically
- No backend changes needed

**Cons**:
- Doesn't clean up if user never reinstalls
- Requires user to sign in to trigger cleanup

### Option 2: Periodic Cleanup Job (Lambda)
**Strategy**: Run a scheduled Lambda function to delete "orphaned" user data

**Implementation**:
1. Add `last_activity_timestamp` to all DynamoDB records
2. Create a Lambda function that runs daily/weekly
3. Query for users with no activity in last 90 days
4. Delete all data for inactive users
5. Optionally: Delete Cognito user accounts

**Pros**:
- Automatic cleanup
- Handles all cases (even if user never reinstalls)
- Keeps database clean

**Cons**:
- Requires backend infrastructure
- May delete data for users who just haven't used app recently
- Need to define "inactive" threshold

### Option 3: Explicit Account Deletion (Manual)
**Strategy**: Add "Delete Account" option in Settings

**Implementation**:
1. Add "Delete Account" button in SettingsView
2. Show confirmation dialog
3. On confirm:
   - Delete all DynamoDB records for user_id
   - Delete Cognito user account
   - Clear local UserDefaults
   - Sign out user

**Pros**:
- User has explicit control
- Immediate cleanup
- Clear user intent

**Cons**:
- Requires user action
- Doesn't handle app deletion case
- Additional UI/UX work

### Option 4: Hybrid Approach (Recommended)
**Strategy**: Combine Option 1 + Option 3

**Implementation**:
1. Add "Delete Account" in Settings (explicit deletion)
2. On app reinstall + sign-in, detect orphaned data and clean up
3. Optional: Periodic cleanup job for very old data (90+ days)

**Pros**:
- Best of both worlds
- Handles explicit deletion
- Handles app deletion (via reinstall detection)
- Keeps database clean long-term

**Cons**:
- Most complex to implement
- Requires multiple mechanisms

## Recommended Implementation Plan

### Phase 1: Explicit Account Deletion (Immediate)
1. Add "Delete Account" button in SettingsView
2. Create Lambda function: `soteria-delete-user-data`
3. Delete all DynamoDB records for user_id
4. Delete Cognito user account
5. Clear local UserDefaults
6. Sign out user

### Phase 2: Reinstall Detection (Short-term)
1. Store `last_sync_timestamp` in UserDefaults
2. On sign-in, check if timestamp exists locally
3. If no timestamp but DynamoDB has data → treat as reinstall
4. Optionally: Prompt user to restore or start fresh
5. If user chooses "start fresh" → delete old data

### Phase 3: Periodic Cleanup (Long-term)
1. Create scheduled Lambda function
2. Query for users with no activity in 90+ days
3. Delete orphaned data
4. Optionally: Delete Cognito accounts

## Data Retention Policy

### Recommended Retention
- **Active Users**: Keep all data indefinitely
- **Inactive Users (30 days)**: Keep data, mark as inactive
- **Inactive Users (90 days)**: Delete all data
- **Deleted Accounts**: Delete immediately

### Compliance Considerations
- **GDPR**: Right to be forgotten - must delete on request
- **CCPA**: Right to deletion - must delete on request
- **Data Minimization**: Only keep data as long as necessary

## Implementation Details

### Lambda Function: `soteria-delete-user-data`

**Endpoint**: `POST /soteria/user/delete`

**Request**:
```json
{
  "user_id": "cognito_user_id"
}
```

**Actions**:
1. Delete from all DynamoDB tables:
   - `soteria-user-data`
   - `soteria-purchase-intents`
   - `soteria-goals`
   - `soteria-regrets`
   - `soteria-moods`
   - `soteria-quiet-hours`
   - `soteria-app-usage`
   - `soteria-unblock-events`
2. Delete Cognito user account
3. Return success/error

### iOS Implementation: Delete Account Flow

```swift
// In SettingsView
Button("Delete Account") {
    showDeleteAccountConfirmation = true
}
.alert("Delete Account?", isPresented: $showDeleteAccountConfirmation) {
    Button("Delete", role: .destructive) {
        Task {
            await deleteAccount()
        }
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This will permanently delete all your data. This action cannot be undone.")
}

private func deleteAccount() async {
    guard let userId = authService.currentUserId else { return }
    
    // Call Lambda to delete all data
    do {
        try await AWSDataService.shared.deleteUserData(userId: userId)
        
        // Sign out (clears local data)
        try authService.signOut()
        
        // Navigate to sign-in screen
    } catch {
        // Show error
    }
}
```

## Questions to Consider

1. **Should we delete Cognito accounts immediately?**
   - Pro: Complete cleanup
   - Con: User can't recover account if they change mind

2. **Should we offer data export before deletion?**
   - Pro: User can backup their data
   - Con: Additional complexity

3. **Should we soft-delete (mark as deleted) or hard-delete?**
   - Soft-delete: Can recover if user reinstalls within X days
   - Hard-delete: Immediate, permanent deletion

4. **What about subscription data?**
   - StoreKit subscriptions are managed by Apple
   - We can't delete Apple's records
   - Should we just ignore subscription data in cleanup?

## Next Steps

1. ✅ **Immediate**: Set premium status for supergeek@me.com
2. **Short-term**: Implement explicit "Delete Account" flow
3. **Medium-term**: Add reinstall detection
4. **Long-term**: Implement periodic cleanup job

