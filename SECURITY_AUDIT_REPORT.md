# Security Audit Report - Soteria
**Date**: January 3, 2026  
**Status**: 🚨 **CRITICAL VULNERABILITIES FOUND**

---

## 🚨 CRITICAL VULNERABILITIES

### 1. **CRITICAL: Missing User ID Authorization Validation** ⚠️ **HIGHEST PRIORITY**

**Severity**: 🔴 **CRITICAL**  
**Impact**: Any user can access, modify, or delete any other user's data

**Affected Lambda Functions:**
- `soteria-get-user-data` - Allows reading any user's data
- `soteria-sync-user-data` - Allows modifying any user's data
- `soteria-delete-user-data` - Allows deleting any user's account
- `soteria-get-dashboard` - Allows viewing any user's dashboard
- `soteria-member-number` - Allows generating member numbers for any user

**Issue**: These functions accept `user_id` from the request (query parameters or body) but **DO NOT validate** that the `user_id` matches the authenticated user from the `Authorization` token.

**Attack Scenario:**
```bash
# Attacker can access victim's data
curl "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/data?user_id=VICTIM_USER_ID&data_type=goals" \
  -H "Authorization: Bearer ATTACKER_TOKEN"

# Attacker can delete victim's account
curl -X POST "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/user/delete" \
  -H "Authorization: Bearer ATTACKER_TOKEN" \
  -d '{"user_id": "VICTIM_USER_ID"}'
```

**Fix Required:**
1. Extract user ID from the JWT token in the Authorization header
2. Validate that the `user_id` in the request matches the authenticated user
3. Reject requests where `user_id` doesn't match

**Example Fix:**
```javascript
// Add to each Lambda function
const jwt = require('jsonwebtoken');

async function getUserIdFromToken(event) {
    const authHeader = event.headers?.Authorization || event.headers?.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('Missing or invalid Authorization header');
    }
    
    const token = authHeader.substring(7);
    // Verify and decode JWT token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return decoded.sub || decoded.username; // Cognito user ID
}

// In handler:
const authenticatedUserId = await getUserIdFromToken(event);
const requestedUserId = event.queryStringParameters?.user_id || body.user_id;

if (authenticatedUserId !== requestedUserId) {
    return {
        statusCode: 403,
        body: JSON.stringify({ error: 'Forbidden: Cannot access other user\'s data' })
    };
}
```

---

### 2. **CRITICAL: Overly Permissive CORS Configuration**

**Severity**: 🟠 **HIGH**  
**Impact**: Allows requests from any origin, enabling CSRF attacks

**Issue**: All Lambda functions use:
```javascript
'Access-Control-Allow-Origin': '*'
```

This allows any website to make requests to your API, enabling:
- Cross-Site Request Forgery (CSRF) attacks
- Data exfiltration
- Unauthorized API calls from malicious websites

**Fix Required:**
```javascript
// Restrict to your app's domain(s)
const allowedOrigins = [
    'https://yourdomain.com',
    'https://app.yourdomain.com'
];

const origin = event.headers?.origin || event.headers?.Origin;
const corsOrigin = allowedOrigins.includes(origin) ? origin : allowedOrigins[0];

const headers = {
    'Access-Control-Allow-Origin': corsOrigin,
    'Access-Control-Allow-Credentials': 'true',
    // ... other headers
};
```

---

### 3. **HIGH: Unit API Token Stored in UserDefaults**

**Severity**: 🟠 **HIGH**  
**Impact**: API tokens accessible to other apps on the device

**Location**: `soteria/Services/UnitService.swift`

**Issue**: Unit API token is stored in `UserDefaults`, which is not secure:
```swift
private var apiToken: String? {
    get {
        return UserDefaults.standard.string(forKey: "unit_api_token")
    }
    set {
        UserDefaults.standard.set(token, forKey: "unit_api_token")
    }
}
```

**Fix Required**: Use iOS Keychain instead:
```swift
import Security

private var apiToken: String? {
    get {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "unit_api_token",
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            return token
        }
        return nil
    }
    set {
        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "unit_api_token"
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new
        if let token = newValue,
           let data = token.data(using: .utf8) {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "unit_api_token",
                kSecValueData as String: data
            ]
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }
}
```

---

### 4. **MEDIUM: No Rate Limiting on API Endpoints**

**Severity**: 🟡 **MEDIUM**  
**Impact**: Vulnerable to brute force attacks and DoS

**Issue**: No rate limiting implemented on:
- Authentication endpoints (signin, signup)
- Data access endpoints
- API Gateway level

**Fix Required**: Implement rate limiting at API Gateway level or use AWS WAF.

---

### 5. **MEDIUM: Error Messages May Leak Information**

**Severity**: 🟡 **MEDIUM**  
**Impact**: Error messages may reveal system internals

**Examples Found:**
- `Invalid data_type: ${data_type}. Valid types: ${Object.keys(TABLE_MAPPING).join(', ')}` - Reveals valid data types
- Full error stack traces in some responses

**Fix Required**: Return generic error messages to clients, log detailed errors server-side only.

---

### 6. **MEDIUM: No Input Sanitization**

**Severity**: 🟡 **MEDIUM**  
**Impact**: Potential injection attacks (though DynamoDB is less vulnerable than SQL)

**Issue**: User input is used directly in DynamoDB queries without sanitization.

**Fix Required**: Validate and sanitize all user inputs, especially:
- `user_id` format validation
- `data_type` whitelist validation (already done in some functions)
- String length limits
- Special character validation

---

### 7. **LOW: Plaid Credentials in Environment Variables**

**Severity**: 🟢 **LOW** (Acceptable for Lambda)  
**Impact**: Low - Lambda environment variables are encrypted at rest

**Status**: ✅ **ACCEPTABLE** - Plaid credentials are stored in Lambda environment variables, which is acceptable. However, consider using AWS Secrets Manager for better rotation capabilities.

**Recommendation**: Consider migrating to AWS Secrets Manager for:
- Automatic credential rotation
- Better audit logging
- Centralized secret management

---

## ✅ SECURITY BEST PRACTICES FOUND

### Good Practices:
1. ✅ **Plaid in Sandbox Mode** - Correctly configured for TestFlight
2. ✅ **HTTPS Only** - All API endpoints use HTTPS
3. ✅ **Cognito Authentication** - Using AWS Cognito for user authentication
4. ✅ **DynamoDB Parameterized Queries** - Using ExpressionAttributeValues (prevents injection)
5. ✅ **Input Validation** - Basic validation present (user_id, data_type required)
6. ✅ **Error Handling** - Try-catch blocks in Lambda functions
7. ✅ **CORS Preflight Handling** - Properly handles OPTIONS requests

---

## 🔧 IMMEDIATE ACTION ITEMS

### Priority 1 (Fix Before TestFlight):
1. **Add user ID validation to all Lambda functions** - Extract user ID from JWT token and validate against request
2. **Restrict CORS origins** - Change from `*` to specific allowed origins
3. **Move Unit API token to Keychain** - Replace UserDefaults with Keychain storage

### Priority 2 (Fix Soon):
4. **Implement rate limiting** - Add API Gateway throttling or AWS WAF
5. **Sanitize error messages** - Return generic errors to clients
6. **Add input validation** - Validate user_id format, string lengths, etc.

### Priority 3 (Consider):
7. **Migrate secrets to Secrets Manager** - For better rotation and management
8. **Add request logging** - Log all API requests for audit trail
9. **Implement API versioning** - For future compatibility

---

## 📋 SECURITY CHECKLIST

### Authentication & Authorization
- [ ] ✅ User authentication via Cognito
- [ ] ❌ **User ID validation in Lambda functions** - **CRITICAL FIX NEEDED**
- [ ] ❌ **Authorization token verification** - **CRITICAL FIX NEEDED**

### Data Protection
- [ ] ✅ HTTPS for all API calls
- [ ] ✅ DynamoDB encryption at rest (default)
- [ ] ❌ **CORS configuration** - **NEEDS RESTRICTION**
- [ ] ❌ **Unit token storage** - **NEEDS KEYCHAIN**

### Input Validation
- [ ] ✅ Basic required field validation
- [ ] ⚠️ Format validation (partial)
- [ ] ❌ **Length limits** - **NEEDS IMPLEMENTATION**
- [ ] ❌ **Special character validation** - **NEEDS IMPLEMENTATION**

### Error Handling
- [ ] ✅ Try-catch blocks
- [ ] ❌ **Generic error messages** - **NEEDS IMPLEMENTATION**
- [ ] ✅ Server-side logging

### Rate Limiting
- [ ] ❌ **API Gateway throttling** - **NOT CONFIGURED**
- [ ] ❌ **Per-endpoint limits** - **NOT CONFIGURED**

---

## 🛡️ RECOMMENDED SECURITY IMPROVEMENTS

### 1. Implement JWT Token Validation Utility
Create a shared Lambda layer or utility function for token validation:

```javascript
// lambda-layers/jwt-validator/index.js
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
    jwksUri: `https://cognito-idp.${process.env.AWS_REGION}.amazonaws.com/${process.env.USER_POOL_ID}/.well-known/jwks.json`
});

function getKey(header, callback) {
    client.getSigningKey(header.kid, (err, key) => {
        const signingKey = key.publicKey || key.rsaPublicKey;
        callback(null, signingKey);
    });
}

async function verifyToken(token) {
    return new Promise((resolve, reject) => {
        jwt.verify(token, getKey, {
            audience: process.env.COGNITO_CLIENT_ID,
            issuer: `https://cognito-idp.${process.env.AWS_REGION}.amazonaws.com/${process.env.USER_POOL_ID}`,
            algorithms: ['RS256']
        }, (err, decoded) => {
            if (err) reject(err);
            else resolve(decoded);
        });
    });
}

async function getUserIdFromEvent(event) {
    const authHeader = event.headers?.Authorization || event.headers?.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('Missing Authorization header');
    }
    
    const token = authHeader.substring(7);
    const decoded = await verifyToken(token);
    return decoded.sub; // Cognito user ID
}

module.exports = { getUserIdFromEvent, verifyToken };
```

### 2. Add Authorization Middleware
Create a wrapper function for Lambda handlers:

```javascript
function withAuthorization(handler) {
    return async (event) => {
        try {
            const authenticatedUserId = await getUserIdFromEvent(event);
            const requestedUserId = event.queryStringParameters?.user_id || 
                                   (event.body ? JSON.parse(event.body).user_id : null);
            
            if (requestedUserId && authenticatedUserId !== requestedUserId) {
                return {
                    statusCode: 403,
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ error: 'Forbidden' })
                };
            }
            
            // Add authenticated user ID to event
            event.authenticatedUserId = authenticatedUserId;
            return await handler(event);
        } catch (error) {
            return {
                statusCode: 401,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ error: 'Unauthorized' })
            };
        }
    };
}

// Usage:
exports.handler = withAuthorization(async (event) => {
    const userId = event.authenticatedUserId; // Use this instead of query params
    // ... rest of handler
});
```

### 3. Configure API Gateway Authorizer
Use API Gateway Lambda Authorizer to validate tokens before Lambda execution:

```javascript
// lambda-authorizer/index.js
exports.handler = async (event) => {
    const token = event.authorizationToken;
    
    try {
        const decoded = await verifyToken(token);
        return {
            principalId: decoded.sub,
            policyDocument: {
                Version: '2012-10-17',
                Statement: [{
                    Action: 'execute-api:Invoke',
                    Effect: 'Allow',
                    Resource: event.methodArn
                }]
            },
            context: {
                userId: decoded.sub
            }
        };
    } catch (error) {
        throw new Error('Unauthorized');
    }
};
```

---

## 📊 VULNERABILITY SUMMARY

| Severity | Count | Status |
|----------|-------|--------|
| 🔴 Critical | 2 | **MUST FIX** |
| 🟠 High | 1 | **SHOULD FIX** |
| 🟡 Medium | 3 | **CONSIDER FIXING** |
| 🟢 Low | 1 | **OPTIONAL** |

---

## 🎯 TESTFLIGHT READINESS

**Current Status**: ⚠️ **NOT SECURE FOR PRODUCTION**

**Recommendation**: 
- **DO NOT** launch to production with current security vulnerabilities
- Fix Critical and High severity issues before TestFlight
- At minimum, implement user ID validation before any public release

---

**Report Generated**: January 3, 2026  
**Next Review**: After implementing fixes

