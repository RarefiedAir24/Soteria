# Hybrid Account Deletion Implementation

## ✅ Phase 1: Explicit Account Deletion (COMPLETED)

### Implementation
1. **Lambda Function**: `soteria-delete-user-data`
   - Deletes all user data from 8 DynamoDB tables
   - Deletes Cognito user account
   - Returns success/error response

2. **iOS Implementation**:
   - Added "Delete Account" button in SettingsView
   - Confirmation alert with detailed warning
   - Calls `AWSDataService.deleteUserData()`
   - Clears local UserDefaults
   - Signs out user
   - Automatically navigates to sign-in screen

3. **API Endpoint**:
   - `POST /soteria/user/delete`
   - Requires user_id in request body
   - Authenticated via Cognito ID token

### Files Created/Modified
- `lambda/soteria-delete-user-data/index.js` - Lambda function
- `lambda/soteria-delete-user-data/package.json` - Dependencies
- `soteria/Services/AWSDataService.swift` - Added `deleteUserData()` method
- `soteria/Views/SettingsView.swift` - Added Delete Account button and flow
- `deploy-delete-user-data-lambda.sh` - Deployment script
- `connect-delete-user-data-to-api-gateway.sh` - API Gateway connection script

### Deployment Steps
```bash
# 1. Deploy Lambda function
./deploy-delete-user-data-lambda.sh

# 2. Connect to API Gateway
./connect-delete-user-data-to-api-gateway.sh

# 3. Grant Lambda permission to delete Cognito users
# (Add Cognito admin permissions to Lambda role)
```

## ✅ Phase 2: Reinstall Detection (COMPLETED)

### Implementation
1. **Timestamp Tracking**:
   - Store `last_sync_timestamp` in UserDefaults
   - Set on app startup if user has valid tokens
   - Update whenever data is synced to AWS

2. **Detection Logic**:
   - On app startup: Check if `last_sync_timestamp` exists
   - If no timestamp but user has valid tokens → might be reinstall
   - Set timestamp immediately to mark as active session

3. **Future Enhancement**:
   - On sign-in, check DynamoDB for existing data
   - If data exists but no local timestamp → prompt user
   - Option: "Restore data" or "Start fresh"
   - If "Start fresh" → delete old DynamoDB data

### Files Modified
- `soteria/Services/AuthService.swift` - Added timestamp check on startup
- `soteria/Services/AWSDataService.swift` - Update timestamp on sync

## 🔄 Phase 3: Periodic Cleanup (TODO)

### Planned Implementation
1. **Scheduled Lambda Function**: `soteria-cleanup-inactive-users`
   - Runs daily/weekly via EventBridge
   - Queries DynamoDB for users with no activity in 90+ days
   - Deletes all data for inactive users
   - Optionally deletes Cognito accounts

2. **Activity Tracking**:
   - Add `last_activity_timestamp` to all DynamoDB records
   - Update on every data sync
   - Use for cleanup queries

### Implementation Notes
- Use EventBridge (CloudWatch Events) for scheduling
- Query all tables for last activity
- Batch delete operations
- Log all deletions for audit trail

## Data Deletion Flow

### Explicit Deletion (User Action)
1. User taps "Delete Account" in Settings
2. Confirmation alert shown
3. User confirms deletion
4. iOS app calls `AWSDataService.deleteUserData()`
5. Lambda function:
   - Deletes from all 8 DynamoDB tables
   - Deletes Cognito user account
6. iOS app:
   - Clears UserDefaults
   - Signs out user
   - Navigates to sign-in screen

### Reinstall Detection (Automatic)
1. User deletes app (clears UserDefaults)
2. User reinstalls app
3. User signs in with same email
4. App detects no `last_sync_timestamp`
5. App checks DynamoDB for existing data
6. If data exists → prompt user
7. User chooses: "Restore" or "Start Fresh"
8. If "Start Fresh" → delete old data

### Periodic Cleanup (Automated)
1. Scheduled Lambda runs daily
2. Queries for users with no activity in 90+ days
3. Deletes all data for inactive users
4. Optionally deletes Cognito accounts
5. Logs all deletions

## Security Considerations

### Lambda Permissions
- DynamoDB: Delete permissions on all tables
- Cognito: `cognito-idp:AdminDeleteUser` permission
- CloudWatch: Logging permissions

### API Gateway
- Requires authentication (Cognito ID token)
- CORS enabled for iOS app
- Rate limiting recommended

### Data Privacy
- Immediate deletion (no soft-delete)
- No data retention after deletion
- Complies with GDPR/CCPA requirements

## Testing Checklist

### Phase 1 Testing
- [ ] Deploy Lambda function
- [ ] Connect to API Gateway
- [ ] Test delete account flow in app
- [ ] Verify DynamoDB data is deleted
- [ ] Verify Cognito account is deleted
- [ ] Verify local data is cleared
- [ ] Verify user is signed out

### Phase 2 Testing
- [ ] Test reinstall detection
- [ ] Verify timestamp is set on startup
- [ ] Verify timestamp is updated on sync
- [ ] Test "Start Fresh" flow (when implemented)

### Phase 3 Testing
- [ ] Deploy scheduled Lambda
- [ ] Test cleanup query logic
- [ ] Verify inactive users are deleted
- [ ] Verify active users are preserved

## Next Steps

1. **Deploy Phase 1**:
   ```bash
   ./deploy-delete-user-data-lambda.sh
   ./connect-delete-user-data-to-api-gateway.sh
   ```

2. **Grant Cognito Permissions**:
   - Add `cognito-idp:AdminDeleteUser` to Lambda role
   - Test deletion flow

3. **Implement Phase 3** (when ready):
   - Create scheduled Lambda function
   - Set up EventBridge rule
   - Test cleanup logic

4. **Enhance Phase 2** (optional):
   - Add "Restore data" vs "Start fresh" prompt
   - Implement restore flow

