# Plaid + Unit Integration - Quick Start

**Based on:** [Official Plaid + Unit Documentation](https://plaid.com/docs/auth/partnerships/unit/)

---

## 🎯 **What This Does**

Enables users to:
1. Connect their external bank account (Chase, Wells Fargo, etc.) via Plaid
2. Securely link it to their Unit savings account
3. Transfer money from external bank → Unit account (ACH pull/push)

**Key Benefit:** No manual account/routing number entry. Instant verification. Bank-grade security.

---

## ✅ **Prerequisites Checklist**

### **Accounts:**
- [ ] **Plaid Account** - [Sign up](https://dashboard.plaid.com/signup)
- [ ] **Unit Account** - [Contact Unit](https://www.unit.co/contact)

### **Plaid Dashboard Setup:**
- [ ] Enable **Unit integration** (Integrations → Unit → Enable)
- [ ] Complete **Application Profile** (company name, website, etc.)
- [ ] Set **Account Select** to **"enabled for one account"** (Link Customization)
- [ ] Note your **Client ID** and **Secret** (Keys tab)

### **Unit Dashboard Setup:**
- [ ] Get your **API Token** (Settings → API Tokens)
- [ ] Note your **Org ID** (for application creation)

---

## 🚀 **Implementation (3 Steps)**

### **Step 1: Deploy Lambda Functions**

#### **A. Processor Token Lambda**

```bash
cd lambda/soteria-plaid-create-processor-token
npm install
zip -r function.zip .
```

**AWS Lambda Config:**
- Function name: `soteria-plaid-create-processor-token`
- Runtime: Node.js 18.x
- Handler: `index.handler`
- Timeout: 30 seconds
- Environment variables:
  ```
  PLAID_CLIENT_ID=your_plaid_client_id
  PLAID_SECRET=your_plaid_secret
  PLAID_ENV=sandbox
  COGNITO_USER_POOL_ID=your_pool_id
  COGNITO_CLIENT_ID=your_client_id
  PLAID_ACCOUNTS_TABLE=soteria-plaid-accounts
  ```

**IAM Permissions:**
- `dynamodb:GetItem` on `soteria-plaid-accounts`
- `dynamodb:UpdateItem` on `soteria-plaid-accounts`

**API Gateway:**
- POST `/soteria/plaid/create-processor-token`
- CORS enabled
- No authorizer (handled in code)

#### **B. Unit Counterparty Lambda**

```bash
cd lambda/soteria-unit-create-counterparty
npm install
zip -r function.zip .
```

**AWS Lambda Config:**
- Function name: `soteria-unit-create-counterparty`
- Runtime: Node.js 18.x
- Handler: `index.handler`
- Timeout: 30 seconds
- Environment variables:
  ```
  UNIT_API_TOKEN=your_unit_api_token
  UNIT_ENV=sandbox
  COGNITO_USER_POOL_ID=your_pool_id
  COGNITO_CLIENT_ID=your_client_id
  COUNTERPARTIES_TABLE=soteria-unit-counterparties
  ```

**IAM Permissions:**
- `dynamodb:PutItem` on `soteria-unit-counterparties`

**API Gateway:**
- POST `/soteria/unit/create-counterparty`
- CORS enabled
- No authorizer (handled in code)

---

### **Step 2: Create DynamoDB Table**

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

### **Step 3: Update iOS Code**

#### **A. Add to PlaidService.swift**

```swift
/// Create processor token for Unit (used after Plaid Link success)
func createProcessorToken(accountId: String) async throws -> String {
    guard let userId = cognitoService.getUserId() else {
        throw NSError(domain: "PlaidService", code: -1, 
                     userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
    }
    
    guard let url = URL(string: "\(apiGatewayURL)/soteria/plaid/create-processor-token") else {
        throw NSError(domain: "PlaidService", code: -2, 
                     userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 10.0
    
    if let idToken = try? await cognitoService.getIDToken() {
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
    }
    
    // Lambda will fetch access_token from DynamoDB
    let requestBody: [String: Any] = [
        "account_id": accountId,
        "user_id": userId
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
        throw NSError(domain: "PlaidService", code: -3, 
                     userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }
    
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let processorToken = json["processor_token"] as? String else {
        throw NSError(domain: "PlaidService", code: -4, 
                     userInfo: [NSLocalizedDescriptionKey: "Failed to parse processor token"])
    }
    
    print("✅ [PlaidService] Processor token created")
    return processorToken
}
```

#### **B. Add to UnitService.swift**

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
    
    if let idToken = try? await cognitoService.getIDToken() {
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
    }
    
    let requestBody: [String: Any] = [
        "processor_token": processorToken,
        "account_id": accountId,
        "customer_id": customerId,
        "counterparty_name": name
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
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

#### **C. Update Plaid Link Handler**

```swift
// In your PlaidConnectionView or similar
func handlePlaidSuccess(publicToken: String, metadata: LinkSuccessMetadata) async {
    do {
        showLoading = true
        
        // 1. Exchange public token (existing code)
        try await plaidService.exchangePublicToken(publicToken)
        
        // 2. Get the connected account
        guard let account = metadata.accounts.first else {
            throw NSError(domain: "Plaid", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "No account selected"])
        }
        
        // 3. Create processor token for Unit
        let processorToken = try await plaidService.createProcessorToken(
            accountId: account.id
        )
        
        // 4. Create Unit counterparty
        guard let unitAccount = unitService.currentAccount else {
            throw NSError(domain: "Unit", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "No Unit account found"])
        }
        
        let counterpartyId = try await unitService.createCounterparty(
            processorToken: processorToken,
            accountId: unitAccount.id,
            customerId: unitAccount.customerId,
            name: "\(metadata.institution.name) - \(account.mask ?? "****")"
        )
        
        // 5. Success! Now user can transfer money
        showSuccess(counterpartyId: counterpartyId)
        
        showLoading = false
        
    } catch {
        showLoading = false
        showError(error.localizedDescription)
    }
}
```

---

## 🧪 **Testing**

### **Sandbox Test:**

1. **Connect Bank in App**
   - Tap "Connect Bank Account"
   - Plaid Link opens
   - Select any institution
   - Use credentials: `user_good` / `pass_good`
   - Select a checking or savings account

2. **Verify Backend Flow**
   ```
   ✅ Public token exchanged
   ✅ Access token stored in DynamoDB
   ✅ Processor token created
   ✅ Unit counterparty created
   ✅ Ready for ACH transfers!
   ```

3. **Check CloudWatch Logs**
   - Lambda: `soteria-plaid-create-processor-token`
   - Lambda: `soteria-unit-create-counterparty`
   - Look for success messages

4. **Verify in DynamoDB**
   - Table: `soteria-plaid-accounts` → Should have `processor_token`
   - Table: `soteria-unit-counterparties` → Should have new entry

---

## 📊 **Flow Diagram**

```
User Taps "Connect Bank"
        ↓
Plaid Link Opens (iOS)
        ↓
User Authenticates & Selects Account
        ↓
onSuccess callback fires
        ↓
[1] exchangePublicToken
    - public_token → access_token
    - Store in DynamoDB
        ↓
[2] createProcessorToken
    - Fetch access_token from DynamoDB
    - Call Plaid: processor='unit'
    - Returns processor_token
    - Update DynamoDB
        ↓
[3] createCounterparty
    - Call Unit API with processor_token
    - Unit retrieves account details from Plaid
    - Returns counterparty_id
    - Store in DynamoDB
        ↓
✅ DONE! User can now fund their Unit account
```

---

## 🔑 **Key Points**

### **Security:**
- ✅ Bank credentials never touch your servers (handled by Plaid)
- ✅ Account/routing numbers never stored (handled by processor token)
- ✅ Processor tokens only work with Unit (can't be used elsewhere)
- ✅ All Lambda calls require Cognito authentication

### **User Experience:**
- ✅ **Fast**: Instant bank verification (no micro-deposits)
- ✅ **Easy**: Just login to their bank in Plaid Link
- ✅ **Secure**: Bank-grade OAuth security
- ✅ **Seamless**: 3-4 taps to connect

### **Compliance:**
- ✅ Plaid handles PCI/banking compliance
- ✅ Unit handles money movement compliance
- ✅ You just orchestrate the connection

---

## 📝 **Common Issues**

### **"Account not found" when creating processor token**
- **Cause**: Account wasn't stored during exchange step
- **Fix**: Check `soteria-plaid-accounts` table for entry

### **"Invalid processor token" from Unit**
- **Cause**: Unit integration not enabled in Plaid Dashboard
- **Fix**: Dashboard → Integrations → Enable Unit

### **"Multiple accounts returned"**
- **Cause**: Account Select not configured
- **Fix**: Dashboard → Link Customization → Set to "one account"

### **"403 Forbidden" from Unit API**
- **Cause**: Invalid Unit API token or wrong environment
- **Fix**: Verify `UNIT_API_TOKEN` and `UNIT_ENV` match

---

## 🎉 **You're Done!**

Users can now:
1. ✅ Connect any US bank account in seconds
2. ✅ Fund their Unit savings account instantly
3. ✅ Transfer money back and forth seamlessly

**Next:** Implement ACH payment flow to actually move money!

Reference: [Full Integration Guide](./PLAID_UNIT_INTEGRATION_GUIDE.md)
