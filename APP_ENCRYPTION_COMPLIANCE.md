# App Encryption Compliance - Answer Guide

**Question**: What type of encryption algorithms does your app implement?

---

## ✅ Correct Answer: "None of the algorithms mentioned above"

### Why This Answer:

Your app uses **only standard encryption** provided by Apple's operating system:

1. **HTTPS/TLS** (Standard)
   - All network communication uses HTTPS
   - AWS API calls (Cognito, Lambda)
   - Plaid API calls
   - Standard TLS encryption (provided by iOS)

2. **Keychain Services** (Apple's Encryption)
   - Storing sensitive data (tokens, credentials)
   - Uses Apple's built-in encryption
   - No custom encryption implementation

3. **No Proprietary Encryption**
   - No custom encryption algorithms
   - No proprietary encryption methods
   - Everything uses standard, Apple-provided encryption

---

## 📋 What Each Option Means

### ❌ "Encryption algorithms that are proprietary or not accepted as standard"
- **Your app**: Doesn't use this
- **Example**: Custom encryption algorithms you wrote yourself

### ❌ "Standard encryption algorithms instead of, or in addition to, using or accessing the encryption within Apple's operating system"
- **Your app**: Doesn't use this
- **Example**: Implementing your own AES/RSA instead of using Apple's

### ❌ "Both algorithms mentioned above"
- **Your app**: Doesn't use this
- **Example**: Using both proprietary and custom standard encryption

### ✅ "None of the algorithms mentioned above"
- **Your app**: Uses this ✅
- **Meaning**: Only uses encryption provided by Apple's OS (HTTPS, Keychain)

---

## 🔍 What Your App Actually Uses

### Network Encryption:
- ✅ **HTTPS/TLS** for all API calls
- ✅ Standard iOS networking (URLSession)
- ✅ AWS services (standard HTTPS)
- ✅ Plaid API (standard HTTPS)

### Data Storage Encryption:
- ✅ **Keychain** for sensitive data (Apple's encryption)
- ✅ UserDefaults for non-sensitive data

### Authentication:
- ✅ **AWS Cognito** (uses standard HTTPS/TLS)
- ✅ Standard OAuth flows

**All of these use Apple's built-in encryption** - no custom implementation!

---

## ✅ Action: Select "None of the algorithms mentioned above"

This is the correct answer for your app because:
- ✅ You only use standard HTTPS/TLS
- ✅ You use Apple's Keychain (built-in encryption)
- ✅ No proprietary encryption
- ✅ No custom encryption algorithms
- ✅ Everything is standard and Apple-provided

---

## 📝 Additional Notes

**Most apps** select "None of the algorithms mentioned above" because:
- They use HTTPS (standard)
- They use Keychain (Apple's encryption)
- They don't implement custom encryption

**This is the most common answer** and is correct for Soteria.

---

## 🎯 Summary

**Select**: ✅ **"None of the algorithms mentioned above"**

**Why**: Your app only uses standard encryption provided by Apple's operating system (HTTPS, Keychain). No proprietary or custom encryption algorithms.

**This is the correct and most common answer!**

