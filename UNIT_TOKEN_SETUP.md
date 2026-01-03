# Unit API Token Setup

## Token Configuration

Your Unit API token has been configured. The token is stored securely in the app.

## Token Details

- **Environment**: Sandbox
- **Organization**: Soteria
- **Scopes**: Full API access (accounts, customers, payments, transactions, webhooks, etc.)

## How to Use

### 1. Initialize in App

Add this to your app initialization (e.g., in `SoteriaApp.swift` or `RootView.swift`):

```swift
// Set Unit API token on app launch
UnitService.shared.setAPIToken("v2.public.eyJyb2xlIjoiYWRtaW4iLCJyb2xlcyI6WyJhZG1pbiJdLCJ1c2VySWQiOiI0Njk0MiIsInN1YiI6InN1cGVyZ2Vla0BtZS5jb20iLCJleHAiOiIyMDI2LTEyLTI1VDIwOjIwOjI4LjE0OFoiLCJqdGkiOiI1NjIzMjEiLCJvcmdJZCI6Ijg1OTkiLCJzY29wZSI6ImFwcGxpY2F0aW9ucyBhcHBsaWNhdGlvbnMtd3JpdGUgY3VzdG9tZXJzIGN1c3RvbWVycy13cml0ZSBjdXN0b21lci10YWdzLXdyaXRlIGN1c3RvbWVyLXRva2VuLXdyaXRlIGFjY291bnRzIGFjY291bnRzLXdyaXRlIGNhcmRzIGNhcmRzLXNlbnNpdGl2ZSB0cmFuc2FjdGlvbnMgYXV0aG9yaXphdGlvbnMgc3RhdGVtZW50cyBwYXltZW50cyBwYXltZW50cy13cml0ZSBwYXltZW50cy13cml0ZS1jb3VudGVycGFydHkgcGF5bWVudHMtd3JpdGUtbGlua2VkLWFjY291bnQgYWNoLXBheW1lbnRzLXdyaXRlIHdpcmUtcGF5bWVudHMtd3JpdGUgcmVwYXltZW50cyBwYXltZW50cy13cml0ZS1hY2gtZGViaXQgY291bnRlcnBhcnRpZXMgYmF0Y2gtcmVsZWFzZXMgYmF0Y2gtcmVsZWFzZXMtd3JpdGUgbGlua2VkLWFjY291bnRzIHdlYmhvb2tzIHdlYmhvb2tzLXdyaXRlIGV2ZW50cyBldmVudHMtd3JpdGUgYXV0aG9yaXphdGlvbi1yZXF1ZXN0cyBhdXRob3JpemF0aW9uLXJlcXVlc3RzLXdyaXRlIGNhc2gtZGVwb3NpdHMgY2FzaC1kZXBvc2l0cy13cml0ZSBjaGVjay1kZXBvc2l0cyBjaGVjay1kZXBvc2l0cy13cml0ZSByZWNlaXZlZC1wYXltZW50cyBkaXNwdXRlcyBjaGFyZ2ViYWNrcyByZXdhcmRzIGNoZWNrLXBheW1lbnRzIGNyZWRpdC1kZWNpc2lvbnMgbGVuZGluZy1wcm9ncmFtcyBjYXJkLWZyYXVkLWNhc2VzIGNyZWRpdC1hcHBsaWNhdGlvbnMgdGF4IHRheC13cml0ZSBmb3JtcyBmb3Jtcy1zZW5zaXRpdmUgd2lyZS1kcmF3ZG93bnMiLCJvcmciOiJTb3RlcmlhIiwic291cmNlSXAiOiIiLCJ1c2VyVHlwZSI6Im9yZyIsImlzVW5pdFBpbG90IjpmYWxzZSwiaXNQYXJlbnRPcmciOmZhbHNlfWTAKjltvgvOm3Yubjuzj8ubIjo7jYvMnEPCxDaYRzb9uh-05JLBxvU0rsPFHp8ee51Cnk-me54S0jAfh2HpggM")
```

### 2. Check Configuration

```swift
if UnitService.shared.isConfigured {
    print("✅ Unit API is configured")
} else {
    print("⚠️ Unit API token not set")
}
```

## API Usage Examples

### Create Customer
```swift
let customerId = try await UnitService.shared.createCustomer(
    firstName: "John",
    lastName: "Doe",
    email: "john@example.com",
    ssn: "123-45-6789",
    dateOfBirth: Date(),
    address: UnitAddress(
        street: "123 Main St",
        city: "San Francisco",
        state: "CA",
        postalCode: "94102",
        country: "US"
    )
)
```

### Create Account
```swift
let account = try await UnitService.shared.createDepositAccount(
    customerId: customerId,
    userId: "user-123"
)
```

### Make Goal Deposit
```swift
let transactionId = try await UnitService.shared.createGoalDeposit(
    accountId: account.id,
    amount: 50.00,
    goalId: "hawaii-trip-123",
    goalName: "Trip to Hawaii"
)
```

### Get Goal Balance
```swift
let balance = try await UnitService.shared.getGoalBalance(
    accountId: account.id,
    goalId: "hawaii-trip-123"
)
print("Goal balance: $\(balance)")
```

## Security Notes

⚠️ **Important**: 
- Token is currently stored in UserDefaults (acceptable for sandbox)
- For production, move to Keychain for better security
- Token is in `.gitignore` to prevent accidental commits
- Token expires: **2026-12-25T20:20:28.148Z**

## Token Expiration

Your token expires on **December 25, 2026**. Before expiration:
1. Generate a new token in Unit dashboard
2. Update the token via `UnitService.shared.setAPIToken(newToken)`

## Next Steps

1. ✅ Token configured
2. ⏳ Test customer creation
3. ⏳ Test account creation
4. ⏳ Test transaction tagging
5. ⏳ Test goal balance calculation
6. ⏳ Move to production when ready

