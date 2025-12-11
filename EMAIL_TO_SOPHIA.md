# Email Response to Sophia from Plaid

## Draft Response

Hi Sophia,

Thanks for reaching out! Looking forward to our call today as well.

**Soteria** is a behavioral finance app for iOS that helps users build awareness around their spending habits and save money automatically. Here's how we're planning to use Plaid:

### Our Use Case

**Primary Function:**
- Users connect their checking and savings accounts via Plaid Link
- When users choose to "protect" themselves from an impulse purchase (by keeping apps blocked), they can opt to automatically transfer a small amount (e.g., $5-$25) from checking to savings
- This creates a "commitment device" - turning moments of self-control into tangible savings

**Key Features:**
1. **Account Connection** - Users connect checking + savings accounts (or just checking if they don't have savings)
2. **Automatic Transfers** - When users unblock apps but choose to save money, we initiate transfers via Plaid Transfer API (checking → savings)
3. **Balance Reading** - We read account balances to show users their savings progress (read-only)
4. **Virtual Savings Mode** - For users without savings accounts, we track "protected" amounts until they create a savings account

### What We Need from Plaid

1. **Plaid Link** - For secure account connection
2. **Transfer API** - To initiate ACH transfers (checking → savings)
3. **Balance API** - To read account balances for progress tracking
4. **Accounts API** - To detect account types (checking vs. savings)

### Important Notes

- **We never hold or control user money** - All transfers are between the user's own accounts
- **We only initiate transfers** - Users must explicitly confirm each transfer
- **Read-only balance access** - We only read balances to display progress, never modify accounts
- **Target users**: Individual consumers (not businesses)
- **Platform**: iOS mobile app
- **Current status**: We have sandbox access and are ready to test

### Questions for Our Call

- What's required for Transfer API production access?
- Can Plaid help users create savings accounts if they only have checking?
- What's the pricing structure for transfers and balance reads?
- Timeline for production access approval?

Happy to discuss more details on the call!

Best,
Frank

