# Plaid Dashboard - Pre-Call Verification (5 Minutes)

**Do this NOW before your call:**

---

## ✅ **Check #1: Integrations (CRITICAL)**

**Where:** Dashboard → **Integrations**

**What to look for:**
```
┌─────────────────────────────┐
│ Unit                        │
│ [Enabled ✅] or [Enable]    │
│                             │
│ Partner for deposit accounts│
└─────────────────────────────┘
```

**Status:**
- [ ] **Enabled** (green checkmark) - GOOD! ✅
- [ ] **Not enabled** - ASK PLAID TO ENABLE ❗

**Screenshot this page!**

---

## ✅ **Check #2: Application Profile**

**Where:** Dashboard → **Team Settings** → **Application Profile**

**What to fill out (if not done):**
- [ ] Company/App Name: `Soteria`
- [ ] Company Website: `your_website.com`
- [ ] App Logo: (upload if you have one)
- [ ] Privacy Policy URL: (if you have one)
- [ ] Support Contact: `your_email@example.com`

**Why:** Required for Link to work properly. Banks need to show this to users.

**Status:**
- [ ] All fields complete ✅
- [ ] Missing fields - COMPLETE NOW ❗

---

## ✅ **Check #3: Link Customization**

**Where:** Dashboard → **Link Customization**

**What to set:**

### **Account Select** (CRITICAL FOR UNIT!)
```
Account Select: [enabled for one account ▼]
```
- [ ] Set to: **"enabled for one account"** ✅
- [ ] Currently: **"disabled"** or other - ASK PLAID TO CHANGE ❗

**Why:** Your app expects exactly ONE account. Multiple accounts will break your flow.

### **Products** (should already be set)
```
Products:
☑ Auth
☐ Transactions (optional)
☐ Identity (optional)
```

**Status:**
- [ ] **Auth** is checked ✅
- [ ] Nothing checked - SELECT AUTH ❗

---

## ✅ **Check #4: Keys**

**Where:** Dashboard → **Keys**

**What you should see:**

```
Sandbox
  client_id: 123abc...
  secret: ***hidden*** [Show]

Development  
  client_id: 456def...
  secret: ***hidden*** [Show]

Production (NEW!)
  client_id: 789ghi...
  secret: ***hidden*** [Show]
```

**Action:**
- [ ] Click **[Show]** next to Production Secret
- [ ] Copy Production Client ID: `_________________________`
- [ ] Copy Production Secret: `_________________________`
- [ ] **DO NOT** commit these to git or share publicly!

**Note:** If you don't see "Production" keys, that's your #1 question for Plaid!

---

## ✅ **Check #5: Webhooks (Optional but Recommended)**

**Where:** Dashboard → **Webhooks**

**What to set:**
```
Webhook URL: https://your-api-gateway.amazonaws.com/soteria/plaid/webhook

Events:
☑ INITIAL_UPDATE
☑ HISTORICAL_UPDATE
☑ DEFAULT_UPDATE
☑ TRANSACTIONS_REMOVED
```

**Status:**
- [ ] Webhook configured ✅
- [ ] Not configured - CAN ADD LATER (not blocking)

---

## 📋 **Pre-Call Summary**

**Before the call, verify:**

| Item | Location | Status |
|------|----------|--------|
| Unit integration | Integrations | ☐ Enabled |
| Application Profile | Team Settings | ☐ Complete |
| Account Select | Link Customization | ☐ "one account" |
| Auth product | Link Customization | ☐ Checked |
| Production keys | Keys | ☐ Visible |

---

## 🚨 **If Anything is NOT Set Up:**

**Don't panic!** This is what the call is for.

**On the call, say:**
> "I checked the dashboard before the call. I noticed [ITEM] is not configured. Can you help me set that up?"

**They will either:**
1. Enable it for you during the call
2. Give you instructions on how to enable it
3. Explain why it's already set up and you're looking in the wrong place

---

## 🎯 **The #1 Most Important Check**

### **Production Keys**

If you see this:
```
✅ Production
   client_id: 789ghi...
   secret: ***hidden***
```

**You're good to go!** Production is active.

If you DON'T see "Production" section:
```
❌ Only showing:
   - Sandbox
   - Development
```

**First question on the call:**
> "I don't see Production keys in my dashboard. Can you activate those for me?"

---

## ⏰ **Timeline**

- **Now (5 min):** Check all 5 items above
- **During call (15 min):** Get any missing items enabled
- **After call (15 min):** Deploy to Production

**Total:** ~35 minutes from now to live! 🚀

---

## 📸 **Screenshots to Take** (Optional but Helpful)

1. **Integrations page** - showing Unit status
2. **Link Customization page** - showing Account Select
3. **Keys page** - showing you have Production keys (hide the actual secret!)

**Why:** If Plaid asks "what do you see?" you can quickly screen share or describe it.

---

**Ready for the call!** ✅

**Quick Reference:** `PLAID_CALL_QUICK_REF.md`  
**Full Prep:** `PLAID_PRODUCTION_CALL_PREP.md`
