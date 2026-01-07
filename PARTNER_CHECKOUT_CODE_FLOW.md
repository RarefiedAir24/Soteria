# Partner Checkout Code Flow

## ✅ Implementation Complete

The partner checkout code system is now implemented. Partners can provide codes that premium members use at checkout.

---

## 🔄 How It Works

### Flow
1. **Partner provides code** → Partner gives Soteria a checkout code (e.g., "SAVE10")
2. **Code stored** → Code is saved in DynamoDB with partner record (`checkout_code` field)
3. **Member views card** → Premium member opens Partner Benefits, taps partner card
4. **Card flips** → Member sees card back with checkout code displayed
5. **Member copies code** → One tap copies code to clipboard
6. **Member uses at checkout** → Member enters code at partner's POS/checkout

---

## 📱 iOS App Features

### Card Back Display
- **Large code display**: Monospaced font, easy to read
- **Copy button**: One-tap copy to clipboard
- **Copy confirmation**: Visual feedback when copied
- **Conditional display**: Only shows if partner provided a code

### UI Design
```
┌─────────────────────────────┐
│  Details                    │
│                             │
│  Checkout Code              │
│  Use this code at checkout  │
│                             │
│  ┌─────────────────────┐   │
│  │   SAVE10            │   │
│  └─────────────────────┘   │
│         [Copy]              │
│                             │
│  Terms & Conditions...     │
└─────────────────────────────┘
```

---

## 🗄️ Database Schema

### DynamoDB Table: `soteria-partners`

**New Field:**
- `checkout_code` (String, optional): Partner-provided code for members to use at checkout

**Example Partner Record:**
```json
{
  "partner_id": "demo-acme-partner",
  "name": "ACME",
  "checkout_code": "SAVE10",
  "loyalty_percentage": 10,
  "is_active": true,
  ...
}
```

---

## 🔧 Backend Updates

### Lambda Function: `soteria-partner-list`
- ✅ Now returns `checkout_code` field in partner response
- ✅ Included in both user-specific and general partner lists

### API Response
```json
{
  "success": true,
  "partners": [
    {
      "partner_id": "demo-acme-partner",
      "name": "ACME",
      "checkout_code": "SAVE10",
      "loyalty_percentage": 10,
      ...
    }
  ]
}
```

---

## 📝 Adding Codes to Partners

### Option 1: Direct DynamoDB Update
```bash
aws dynamodb update-item \
  --table-name soteria-partners \
  --key '{"partner_id": {"S": "demo-acme-partner"}}' \
  --update-expression "SET checkout_code = :code" \
  --expression-attribute-values '{":code": {"S": "SAVE10"}}'
```

### Option 2: Partner Dashboard (Future)
- Add code field to partner management form
- Partners can update their own codes
- Admin can set codes for partners

### Option 3: Partner Registration API
- Include `checkout_code` in partner registration
- Update existing partners via API

---

## ✨ Benefits

### For Partners
- ✅ **Simple**: Just provide one code
- ✅ **No Integration**: No API needed on partner side
- ✅ **Flexible**: Can change codes anytime
- ✅ **Marketing**: Can use codes in campaigns

### For Members
- ✅ **Easy Access**: Code right on the card
- ✅ **One-Tap Copy**: Quick clipboard copy
- ✅ **Clear Instructions**: "Use this code at checkout"
- ✅ **Always Available**: See code anytime

### For Soteria
- ✅ **No Complex Backend**: Just store code with partner
- ✅ **No Validation Logic**: Partner handles validation
- ✅ **Simple Maintenance**: Easy to update codes

---

## 🎯 Use Cases

### Example 1: Promotional Code
- Partner: "Coffee Shop"
- Code: "SOTERIA15"
- Members see code on card back
- Members use at checkout for 15% off

### Example 2: Membership Code
- Partner: "Gym"
- Code: "SOTERIA2024"
- Members use code to activate membership discount

### Example 3: Seasonal Code
- Partner: "Retail Store"
- Code: "HOLIDAY10"
- Partner updates code seasonally
- Members always see current code

---

## 🔄 Code Updates

### How Partners Update Codes
1. **Contact Soteria**: Partner emails/contacts to update code
2. **Admin Updates**: Soteria admin updates DynamoDB record
3. **Instant Update**: Members see new code immediately (no app update needed)

### Future: Self-Service
- Partner dashboard with code management
- Partners can update codes themselves
- Real-time updates for all members

---

## 📊 Analytics

### What We Can Track
- Which partners provide codes
- Code usage (if partner tracks)
- Partner engagement (code views)

### What We Don't Track
- Individual code redemptions (partner handles)
- Code validation (partner's responsibility)
- Code expiration (partner manages)

---

## 🚀 Next Steps

### Immediate
- ✅ iOS app displays codes
- ✅ Lambda returns codes
- ✅ Copy to clipboard works

### Future Enhancements
- [ ] Partner dashboard code management
- [ ] Code expiration dates (display on card)
- [ ] Multiple codes per partner (seasonal codes)
- [ ] Code usage analytics (if partner provides data)

---

## 💡 Example Partner Setup

### ACME Partner
```json
{
  "partner_id": "demo-acme-partner",
  "name": "ACME",
  "checkout_code": "ACME10",
  "loyalty_percentage": 10,
  "terms": "Enter code ACME10 at checkout for 10% off. Valid on all purchases.",
  "is_active": true
}
```

**Member Experience:**
1. Opens Partner Benefits
2. Sees ACME card
3. Taps card to flip
4. Sees "ACME10" code displayed
5. Taps copy button
6. Goes to ACME checkout
7. Pastes "ACME10"
8. Gets 10% discount

---

**Last Updated**: January 2026

