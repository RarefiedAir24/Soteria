# Unit Account Transfer Information

## Overview

When users create a Unit account, they receive **account credentials** (account number and routing number) that can be used for external transfers, even if they don't use Plaid.

## Transfer Options

### Option 1: Plaid (Automatic)
- Users connect their bank account via Plaid
- Transfers are initiated automatically from the app
- No manual entry required
- **Source account** (user's bank) → **Unit account** (dedicated savings)

### Option 2: Manual External Transfer (Account Credentials)
- Unit provides **account number** and **routing number** when account is created
- Users can use these credentials in their bank's app/website
- Users set up external transfer in their bank:
  1. Add Unit account as external recipient
  2. Enter Unit account number and routing number
  3. Verify with micro-deposits (if required by bank)
  4. Transfer funds manually

## Account Credentials

When a Unit account is created, the API returns:
```swift
UnitAccount(
    id: "account-id",
    accountNumber: "1234567890",  // User's Unit account number
    routingNumber: "021000021",   // Unit's routing number
    customerId: "customer-id"
)
```

## User Experience

### In-App Display
After account creation, show users:
- ✅ Account number
- ✅ Routing number
- ✅ Instructions: "Use these credentials to set up external transfers in your bank's app"

### Transfer Flow
1. **With Plaid**: 
   - User connects bank → App initiates transfer → Funds move to Unit account
   
2. **Without Plaid**:
   - User gets account credentials → User sets up transfer in their bank → Funds move to Unit account

## Implementation Notes

- Store account credentials securely (Keychain for production)
- Display credentials in Settings or Account section
- Provide clear instructions for manual setup
- Both methods feed into the same Unit account
- All deposits are tagged with `goal_id` for tracking

## Security

- Account credentials are sensitive - store securely
- Don't display in logs or error messages
- Only show to authenticated user
- Consider masking account number (show last 4 digits only)

