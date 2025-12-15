# AWS Cognito Quick Start

## 🚀 Quick Setup (5 Steps)

### 1. Create Cognito User Pool
```bash
./create-cognito-user-pool.sh
```
**Save:** User Pool ID and Client ID

### 2. Install Lambda Dependencies
```bash
for dir in lambda/soteria-auth-*; do
    cd "$dir" && npm install --production && cd ../..
done
```

### 3. Deploy Lambda Functions
```bash
./deploy-auth-lambdas.sh
```
**Enter:** User Pool ID and Client ID when prompted

### 4. Connect to API Gateway
```bash
./connect-auth-lambdas-to-api-gateway.sh
```
**Enter:** Your API Gateway ID when prompted

### 5. Test Authentication
```bash
# Test signup
curl -X POST https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod/soteria/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPassword123!"}'
```

## ✅ Done!

Your authentication is now set up. The iOS app will automatically use Cognito for authentication.

## 📚 Full Documentation

See `COGNITO_SETUP_COMPLETE_GUIDE.md` for detailed instructions and troubleshooting.

## 🔍 What Was Created

- **4 Lambda Functions:**
  - `soteria-auth-signup`
  - `soteria-auth-signin`
  - `soteria-auth-refresh`
  - `soteria-auth-reset-password`

- **4 API Gateway Endpoints:**
  - `POST /soteria/auth/signup`
  - `POST /soteria/auth/signin`
  - `POST /soteria/auth/refresh`
  - `POST /soteria/auth/reset-password`

- **Cognito User Pool:**
  - Pool: `soteria-users`
  - Client: `soteria-ios`

