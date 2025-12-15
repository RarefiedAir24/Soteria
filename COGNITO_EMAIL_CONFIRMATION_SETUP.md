# Cognito Email Confirmation Setup

## Current Status

✅ **Signup is working!** The API successfully creates users in Cognito.

⚠️ **Email confirmation is required** - Users need to confirm their email before they can sign in.

## Two Options

### Option 1: Auto-Confirm Users (Development/Testing)

For easier testing during development, you can configure Cognito to auto-confirm users:

```bash
# This requires updating the User Pool to not require email verification
# Note: This is typically done via AWS Console or by creating a new User Pool
```

**Via AWS Console:**
1. Go to AWS Cognito → User Pools → `soteria-users`
2. Go to "Sign-up experience" → "Attributes"
3. Under "Email", uncheck "Require email verification"
4. Save changes

**Or create a new User Pool without email verification:**
```bash
aws cognito-idp create-user-pool \
  --pool-name soteria-users-dev \
  --policies "PasswordPolicy={MinimumLength=8,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true}" \
  --username-attributes email \
  --region us-east-1
```

### Option 2: Handle Email Confirmation in App (Production)

The app now handles the `requiresConfirmation` response. When a user signs up:

1. They see: "Account created! Please check your email to confirm your account, then sign in."
2. They receive an email with a confirmation code
3. They need to enter the code to confirm (this flow needs to be implemented)
4. After confirmation, they can sign in

## Current Behavior

When you sign up:
- ✅ User is created in Cognito
- ✅ Email confirmation code is sent
- ✅ App shows: "Account created! Please check your email to confirm your account, then sign in."
- ⚠️ User needs to confirm email before signing in

## Testing Without Email Confirmation

For quick testing, you can manually confirm a user via AWS CLI:

```bash
# Confirm a user (replace USERNAME with the email)
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id us-east-1_099POP0Rf \
  --username USERNAME \
  --region us-east-1
```

Then the user can sign in normally.

## Next Steps

1. **For Development:** Configure User Pool to auto-confirm (Option 1)
2. **For Production:** Implement email confirmation code entry flow in the app (Option 2)

## Signup is Working! ✅

The signup endpoint is fully functional. The only remaining step is handling email confirmation.

