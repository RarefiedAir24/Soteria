# Plaid + Unit Integration Guide

Complete implementation guide for connecting external bank accounts (Plaid) to Unit deposit accounts for seamless money movement.

**📚 Official Documentation:** [Plaid + Unit Partnership Docs](https://plaid.com/docs/auth/partnerships/unit/)  
**🚀 Quick Start:** See [PLAID_UNIT_QUICK_START.md](./PLAID_UNIT_QUICK_START.md) for streamlined setup instructions.

**Reference Documentation:** [Plaid Unit Partnership](https://plaid.com/docs/auth/partnerships/unit/)

---

## 📋 **Integration Overview**

### **Flow:**
1. **User connects external bank** via Plaid Link
2. **Exchange public_token** for access_token
3. **Create processor_token** for Unit
4. **Create Unit counterparty** using processor_token
5. **Transfer money** from external bank to Unit account

### **Key Concept:**
The **processor_token** is a special token that allows Unit to securely access bank account details from Plaid without you ever handling sensitive banking information (account/routing numbers).

---

## 🔧 **Implementation Steps**

### **Step 1: Dashboard Configuration**

#### **A. Plaid Dashboard**
1. Go to [https://dashboard.plaid.com](https://dashboard.plaid.com)
2. Navigate to **Team Settings → Integrations**
3. Find **Unit** and click **"Enable"**
4. Complete your **Application Profile**:
   - Company name
   - Website
   - How your app uses bank information
5. Go to **Link Customization**
6. Set **Account Select** to **"enabled for one account"**
   - This ensures users pick exactly one account
   - The `accounts` array will always contain one account

#### **B. Unit Dashboard**
1. Go to [https://dashboard.unit.co](https://dashboard.unit.co)
2. Verify you have a **verified Unit account**
3. Get your **API token** (Settings → API Tokens)
4. Note your **Org ID** (needed for applications)

---

### **Step 2: Deploy Lambda Functions**

#### **A. Processor Token Lambda**

**Location:** `lambda/soteria-plaid-create-processor-token/`

**Files Created:**
- ✅ `index.js` - Main handler
- ✅ `auth-utils.js` - Cognito authentication
- ✅ `package.json` - Dependencies

**Deploy Steps:**
```bash
cd lambda/soteria-plaid-create-processor-token
npm install
zip -r function.zip .
```

**AWS Lambda Setup:**
1. Create Lambda function: `soteria-plaid-create-processor-token`
2. Runtime: Node.js 18.x
3. Upload `function.zip`
4. Set environment variables:
   ```
   PLAID_CLIENT_ID=<your-plaid-client-id>
   PLAID_SECRET=<your-plaid-secret>
   PLAID_ENV=sandbox (or production)
   COGNITO_USER_POOL_ID=<your-pool-id>
   COGNITO_CLIENT_ID=<your-client-id>
   PLAID_ACCOUNTS_TABLE=soteria-plaid-accounts
   ```
5. Add IAM permissions:
   - `dynamodb:UpdateItem` on `soteria-plaid-accounts`
   - `dynamodb:GetItem` on `soteria-plaid-accounts`

**API Gateway:**
- Method: POST
- Path: `/soteria/plaid/create-processor-token`
- Authorization: None (handled in Lambda)
- CORS: Enabled

#### **B. Unit Counterparty Lambda**

**Location:** `lambda/soteria-unit-create-counterparty/`

**Files Created:**
- ✅ `index.js` - Main handler
- ✅ `auth-utils.js` - Cognito authentication
- ✅ `package.json` - Dependencies

**Deploy Steps:**
```bash
cd lambda/soteria-unit-create-counterparty
npm install
zip -r function.zip .
```

**AWS Lambda Setup:**
1. Create Lambda function: `soteria-unit-create-counterparty`
2. Runtime: Node.js 18.x
3. Upload `function.zip`
4. Set environment variables:
   ```
   UNIT_API_TOKEN=<your-unit-api-token>
   UNIT_ENV=sandbox (or production)
   COGNITO_USER_POOL_ID=<your-pool-id>
   COGNITO_CLIENT_ID=<your-client-id>
   COUNTERPARTIES_TABLE=soteria-unit-counterparties
   ```
5. Add IAM permissions:
   - `dynamodb:PutItem` on `soteria-unit-counterparties`

**API Gateway:**
- Method: POST
- Path: `/soteria/unit/create-counterparty`
- Authorization: None (handled in Lambda)
- CORS: Enabled

---

### **Step 3: Create DynamoDB Table**

**Table Name:** `soteria-unit-counterparties`

**Schema:**
```
Primary Key:
  - user_id (String) - HASH
  - counterparty_id (String) - RANGE

Attributes:
  - unit_account_id (String)
  - unit_customer_id (String)
  - name (String)
  - routing_number (String)
  - account_number_last4 (String)
  - type (String) - "Checking" or "Savings"
  - permissions (String) - "DebitOnly" or "CreditOnly"
  - created_at (String) - ISO timestamp
```

**AWS CLI:**
```bash
aws dynamodb create-table \
  --table-name soteria-unit-counterparties \
  --attribute-definitions \
    AttributeName=user_id,AttributeType=S \
    AttributeName=counterparty_id,AttributeType=S \
  --key-schema \
    AttributeName=user_id,KeyType=HASH \
    AttributeName=counterparty_id,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

---

### **Step 4: Update iOS PlaidService**

**File:** `soteria/Services/PlaidService.swift`

**Add these methods:**

```swift
/// Create processor token for Unit integration
func createProcessorToken(accessToken: String, accountId: String) async throws -> String {
    guard let userId = cognitoService.getUserId() else {
        throw NSError(domain: "PlaidService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
    }
    
    guard let url = URL(string: "\(apiGatewayURL)/soteria/plaid/create-processor-token") else {
        throw NSError(domain: "PlaidService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 10.0
    
    // Get Cognito ID token for authentication
    if let idToken = try? await cognitoService.getIDToken() {
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
    }
    
    let requestBody: [String: Any] = [
        "access_token": accessToken,
        "account_id": accountId,
        "user_id": userId
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NSError(domain: "PlaidService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
    }
    
    guard (200...299).contains(httpResponse.statusCode) else {
        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
        throw NSError(domain: "PlaidService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }
    
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let processorToken = json["processor_token"] as? String else {
        throw NSError(domain: "PlaidService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse processor token"])
    }
    
    print("✅ [PlaidService] Processor token created")
    return processorToken
}
```

---

### **Step 5: Update iOS UnitService**

**File:** `soteria/Services/UnitService.swift`

**Add this method:**

```swift
/// Create Unit counterparty using Plaid processor token
func createCounterparty(
    processorToken: String,
    accountId: String,
    customerId: String,
    name: String = "External Bank Account"
) async throws -> String {
    let url = URL(string: "\(apiGatewayURL)/soteria/unit/create-counterparty")!
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 10.0
    
    // Get Cognito ID token for authentication
    if let idToken = try? await cognitoService.getIDToken() {
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
    }
    
    let requestBody: [String: Any] = [
        "processor_token": processorToken,
        "account_id": accountId,
        "customer_id": customerId,
        "counterparty_name": name
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw UnitError.invalidResponse
    }
    
    guard (200...299).contains(httpResponse.statusCode) else {
        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
        throw UnitError.apiError("Failed to create counterparty: \(errorMessage)")
    }
    
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let counterpartyId = json["counterparty_id"] as? String else {
        throw UnitError.invalidResponse
    }
    
    print("✅ [UnitService] Counterparty created: \(counterpartyId)")
    return counterpartyId
}
```

---

### **Step 6: Update Plaid Link Flow**

**Update your Plaid connection flow to include processor token creation:**

```swift
// In your PlaidConnectionView or similar
func handlePlaidSuccess(publicToken: String, metadata: SuccessMetadata) async {
    do {
        // 1. Exchange public token for access token
        try await plaidService.exchangePublicToken(publicToken)
        
        // 2. Get the selected account
        guard let account = metadata.accounts.first else {
            throw NSError(domain: "Plaid", code: -1, userInfo: [NSLocalizedDescriptionKey: "No account selected"])
        }
        
        // 3. Create processor token for Unit
        let processorToken = try await plaidService.createProcessorToken(
            accessToken: plaidService.accessToken!, // Store this from exchange
            accountId: account.id
        )
        
        // 4. Create Unit counterparty
        guard let unitAccount = unitService.currentAccount else {
            throw NSError(domain: "Unit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Unit account"])
        }
        
        let counterpartyId = try await unitService.createCounterparty(
            processorToken: processorToken,
            accountId: unitAccount.id,
            customerId: unitAccount.customerId,
            name: "\(account.name ?? "Bank") - \(account.mask ?? "****")"
        )
        
        print("✅ Counterparty created: \(counterpartyId)")
        
        // 5. Now you can initiate ACH transfers!
        
    } catch {
        print("❌ Error: \(error.localizedDescription)")
    }
}
```

---

## 🔄 **Complete User Flow**

### **1. User Opens App**
- Taps "Connect Bank Account"

### **2. Plaid Link Opens**
- User selects their bank
- Logs in with credentials
- Selects which account to connect (one account only due to Account Select setting)

### **3. Backend Processing**
```
iOS App → Lambda: exchangePublicToken
         ← access_token + account_id

iOS App → Lambda: createProcessorToken
         ← processor_token

iOS App → Lambda: createCounterparty (Unit)
         ← counterparty_id
```

### **4. Transfer Money**
Once counterparty is created, you can:
- **Pull funds** (Debit) from external bank to Unit account
- **View balance** in Unit account
- **Send money** to goals/savings

---

## 🧪 **Testing**

### **Sandbox Credentials**

**Plaid Sandbox:**
- Use any username/password
- Test institutions: `ins_109508` (Chase), `ins_109509` (Wells Fargo)
- Test routing: `021000021`
- Test account: Any 10-digit number

**Unit Sandbox:**
- API URL: `https://api.s.unit.sh`
- Test SSN: `000000001` - `000000009`
- Test amounts: Use specific amounts to trigger behaviors

### **Test Flow:**
1. Connect Plaid account in sandbox
2. Create processor token
3. Create Unit counterparty
4. Initiate test ACH debit (pull $10 from external bank)
5. Verify balance update in Unit account

---

## 📊 **Data Flow Diagram**

```
┌─────────────┐
│  iOS App    │
│   (User)    │
└──────┬──────┘
       │
       │ 1. Plaid Link Success (public_token, account_id)
       ↓
┌──────────────────────────────────┐
│  Lambda: exchange-token          │
│  ─────────────────────────       │
│  • Exchange public → access      │
│  • Store in DynamoDB             │
└──────────────┬───────────────────┘
               │ 2. access_token
               ↓
┌──────────────────────────────────┐
│  Lambda: create-processor-token  │
│  ─────────────────────────────   │
│  • Call Plaid API                │
│  • processor: 'unit'             │
│  • Store token                   │
└──────────────┬───────────────────┘
               │ 3. processor_token
               ↓
┌──────────────────────────────────┐
│  Lambda: create-counterparty     │
│  ─────────────────────────────   │
│  • Call Unit API                 │
│  • Create ACH counterparty       │
│  • Store counterparty ID         │
└──────────────┬───────────────────┘
               │ 4. counterparty_id
               ↓
┌──────────────────────────────────┐
│  Ready for ACH Transfers!        │
│  • Pull funds (Debit)            │
│  • Push funds (Credit)           │
└──────────────────────────────────┘
```

---

## ⚠️ **Important Notes**

### **Security:**
1. ✅ **Processor tokens are secure** - They only work with the specified processor (Unit)
2. ✅ **Never store raw account/routing numbers**
3. ✅ **Encrypt access_tokens** in DynamoDB (production)
4. ✅ **Use HTTPS** for all API calls
5. ✅ **Validate JWT tokens** on every Lambda call

### **Plaid Products:**
- Use **`auth`** product (not `balance`)
- Balance data comes from `/accounts/get` endpoint
- Transactions require **`transactions`** product

### **Unit Permissions:**
- `DebitOnly`: Pull funds from external bank (recommended for funding)
- `CreditOnly`: Push funds to external bank (for payouts)
- `DebitAndCredit`: Both directions

### **Account Select:**
- **Must be enabled** in Plaid Dashboard
- Ensures `metadata.accounts` contains exactly one account
- Prevents ambiguity in which account to use

---

## 📚 **References**

- [Plaid + Unit Partnership Docs](https://plaid.com/docs/auth/partnerships/unit/)
- [Plaid Auth Documentation](https://plaid.com/docs/auth/)
- [Plaid Link Parameter Reference](https://plaid.com/docs/link/parameter-reference/)
- [Unit Counterparties API](https://docs.unit.co/counterparties)
- [Unit ACH Payments API](https://docs.unit.co/payments#ach-payment)

---

## ✅ **Checklist**

- [ ] Plaid Dashboard configured
  - [ ] Unit integration enabled
  - [ ] Application Profile completed
  - [ ] Account Select set to "one account"
- [ ] Unit Dashboard configured
  - [ ] API token obtained
  - [ ] Org ID noted
- [ ] Lambda functions deployed
  - [ ] create-processor-token
  - [ ] create-counterparty
- [ ] DynamoDB table created
  - [ ] soteria-unit-counterparties
- [ ] iOS services updated
  - [ ] PlaidService.createProcessorToken()
  - [ ] UnitService.createCounterparty()
- [ ] API Gateway endpoints configured
  - [ ] /soteria/plaid/create-processor-token
  - [ ] /soteria/unit/create-counterparty
- [ ] Tested in sandbox
  - [ ] Plaid Link flow
  - [ ] Processor token creation
  - [ ] Counterparty creation
  - [ ] Test ACH transfer

---

**You're now ready to enable seamless bank account funding!** 🚀
