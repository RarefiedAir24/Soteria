# Plaid + Unit Implementation Checklist

**Status:** ✅ Code Complete | 🚧 Deployment Needed

---

## 📋 **Implementation Status**

### ✅ **Code (Complete)**

| Component | Status | Location |
|-----------|--------|----------|
| Link Token Creation | ✅ Exists | `lambda/soteria-plaid-create-link-token/` |
| Public Token Exchange | ✅ Exists | `lambda/soteria-plaid-exchange-token/` |
| **Processor Token Creation** | ✅ **NEW** | `lambda/soteria-plaid-create-processor-token/` |
| **Unit Counterparty Creation** | ✅ **NEW** | `lambda/soteria-unit-create-counterparty/` |
| iOS Plaid Link Integration | ✅ Exists | `soteria/Services/PlaidService.swift` |
| iOS Unit Integration | ✅ Exists | `soteria/Services/UnitService.swift` |

### 🚧 **Deployment (To Do)**

#### **A. Plaid Dashboard Configuration**

- [ ] **Step 1:** Log into [Plaid Dashboard](https://dashboard.plaid.com)
- [ ] **Step 2:** Go to **Integrations** → Find **Unit** → Click **Enable**
- [ ] **Step 3:** Go to **Team Settings** → **Application Profile** → Fill out company details
- [ ] **Step 4:** Go to **Link Customization** → Set **Account Select** to **"enabled for one account"**
- [ ] **Step 5:** Go to **Keys** → Copy your **Client ID** and **Secret** (for Lambda env vars)

#### **B. Lambda Deployment**

##### **1. Deploy `soteria-plaid-create-processor-token`**

```bash
# Package
cd lambda/soteria-plaid-create-processor-token
npm install
zip -r function.zip .

# Upload to AWS Lambda
aws lambda create-function \
  --function-name soteria-plaid-create-processor-token \
  --runtime nodejs18.x \
  --handler index.handler \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role \
  --zip-file fileb://function.zip \
  --timeout 30 \
  --environment Variables="{
    PLAID_CLIENT_ID=your_client_id,
    PLAID_SECRET=your_secret,
    PLAID_ENV=sandbox,
    COGNITO_USER_POOL_ID=your_pool_id,
    COGNITO_CLIENT_ID=your_client_id,
    PLAID_ACCOUNTS_TABLE=soteria-plaid-accounts
  }"
```

- [ ] Function created
- [ ] Environment variables set
- [ ] IAM permissions added (`dynamodb:GetItem`, `dynamodb:UpdateItem`)
- [ ] API Gateway endpoint created: `POST /soteria/plaid/create-processor-token`
- [ ] CORS configured on endpoint
- [ ] Test invocation successful

##### **2. Deploy `soteria-unit-create-counterparty`**

```bash
# Package
cd lambda/soteria-unit-create-counterparty
npm install
zip -r function.zip .

# Upload to AWS Lambda
aws lambda create-function \
  --function-name soteria-unit-create-counterparty \
  --runtime nodejs18.x \
  --handler index.handler \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role \
  --zip-file fileb://function.zip \
  --timeout 30 \
  --environment Variables="{
    UNIT_API_TOKEN=your_unit_token,
    UNIT_ENV=sandbox,
    COGNITO_USER_POOL_ID=your_pool_id,
    COGNITO_CLIENT_ID=your_client_id,
    COUNTERPARTIES_TABLE=soteria-unit-counterparties
  }"
```

- [ ] Function created
- [ ] Environment variables set
- [ ] IAM permissions added (`dynamodb:PutItem`)
- [ ] API Gateway endpoint created: `POST /soteria/unit/create-counterparty`
- [ ] CORS configured on endpoint
- [ ] Test invocation successful

#### **C. DynamoDB Table**

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

- [ ] Table created
- [ ] Proper IAM permissions assigned to Lambda

#### **D. iOS Code Updates**

- [ ] Add `createProcessorToken()` to `PlaidService.swift` (see Quick Start guide)
- [ ] Add `createCounterparty()` to `UnitService.swift` (see Quick Start guide)
- [ ] Update Plaid Link success handler to call new methods
- [ ] Test end-to-end flow in Xcode

---

## 🧪 **Testing Checklist**

### **Sandbox Testing:**

1. **Plaid Link Flow**
   - [ ] Open app, tap "Connect Bank Account"
   - [ ] Plaid Link modal appears
   - [ ] Select any institution (e.g., "Chase")
   - [ ] Enter credentials: `user_good` / `pass_good`
   - [ ] Select a checking or savings account
   - [ ] onSuccess callback fires

2. **Backend Flow**
   - [ ] Public token exchanged successfully
   - [ ] Access token stored in `soteria-plaid-accounts`
   - [ ] Processor token created successfully
   - [ ] Processor token stored in DynamoDB
   - [ ] Unit counterparty created successfully
   - [ ] Counterparty ID stored in `soteria-unit-counterparties`

3. **Verify in AWS Console**
   - [ ] CloudWatch Logs show successful Lambda executions
   - [ ] DynamoDB `soteria-plaid-accounts` has `processor_token` field
   - [ ] DynamoDB `soteria-unit-counterparties` has new entry

4. **Verify in App**
   - [ ] Success message displayed to user
   - [ ] Bank account shows as "Connected"
   - [ ] User can proceed to fund their Unit account

---

## 📊 **Complete Flow Verification**

```
✅ Step 1: User opens Plaid Link
✅ Step 2: User authenticates with bank
✅ Step 3: User selects account
✅ Step 4: public_token received
✅ Step 5: Exchange public_token → access_token
✅ Step 6: Store access_token in DynamoDB
✅ Step 7: Create processor_token for Unit
✅ Step 8: Store processor_token in DynamoDB
✅ Step 9: Call Unit API with processor_token
✅ Step 10: Unit retrieves account details from Plaid
✅ Step 11: Unit creates counterparty
✅ Step 12: Store counterparty_id in DynamoDB
✅ Step 13: Display success to user
```

---

## 🎯 **Success Criteria**

You'll know the integration is working when:

1. ✅ User can connect their bank in < 30 seconds
2. ✅ No manual account/routing number entry needed
3. ✅ Bank account instantly verified (no micro-deposits)
4. ✅ User can initiate ACH transfers to/from Unit account
5. ✅ All CloudWatch logs show success messages
6. ✅ All DynamoDB tables populated correctly

---

## 🔧 **Troubleshooting**

### **"Unit integration not enabled"**
- **Fix:** Plaid Dashboard → Integrations → Enable Unit

### **"Account Select returned multiple accounts"**
- **Fix:** Plaid Dashboard → Link Customization → Set to "one account"

### **"Access token not found"**
- **Fix:** Check `soteria-plaid-accounts` table for user entry
- Ensure exchange token Lambda successfully stored it

### **"Invalid processor token"**
- **Fix:** Verify `processor: 'unit'` is set correctly in Lambda
- Check that Plaid account is enabled for Unit integration

### **"Unit API 403 Forbidden"**
- **Fix:** Verify `UNIT_API_TOKEN` is correct
- Ensure `UNIT_ENV` matches your Unit account (sandbox vs production)

---

## 📚 **Reference Documentation**

| Document | Purpose |
|----------|---------|
| `PLAID_UNIT_QUICK_START.md` | Streamlined setup guide |
| `PLAID_UNIT_INTEGRATION_GUIDE.md` | Comprehensive technical details |
| [Plaid + Unit Official Docs](https://plaid.com/docs/auth/partnerships/unit/) | Official Plaid documentation |
| [Unit Counterparties API](https://docs.unit.co/counterparties) | Official Unit documentation |

---

## 🚀 **Next Steps After Deployment**

Once the integration is working:

1. **Implement ACH Transfers**
   - Pull funds from counterparty → Unit account
   - Push funds from Unit account → counterparty

2. **Add UI for Bank Management**
   - View connected banks
   - Remove/update banks
   - Set default funding source

3. **Production Migration**
   - Switch `PLAID_ENV` to `production`
   - Switch `UNIT_ENV` to `production`
   - Update with production credentials
   - Test with real bank accounts

4. **Monitoring & Analytics**
   - Set up CloudWatch alarms for failures
   - Track connection success rates
   - Monitor ACH transfer volumes

---

## ✅ **Final Verification**

Before marking complete:

- [ ] All Lambda functions deployed and tested
- [ ] All DynamoDB tables created
- [ ] All Plaid Dashboard settings configured
- [ ] iOS code updated and tested
- [ ] End-to-end sandbox test successful
- [ ] Documentation reviewed and understood
- [ ] Production migration plan documented

---

**Status:** Ready for deployment! 🎉
