# Avatar S3 Storage Setup Guide

## Overview

This guide will help you set up AWS S3 storage for user avatars, enabling persistence across app reinstalls and device sync.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Existing API Gateway (soteria-api)
- Existing IAM role for Lambda execution (soteria-lambda-execution-role)

## Setup Steps

### Step 1: Create S3 Bucket

```bash
./create-s3-avatar-bucket.sh
```

This will:
- Create S3 bucket: `soteria-avatars-516141816050`
- Enable versioning
- Block public access (avatars are private)
- Set up CORS configuration
- Configure lifecycle policies

### Step 2: Set Up IAM Permissions

```bash
./setup-avatar-s3-permissions.sh
```

This will:
- Create IAM policy for S3 access
- Attach policy to Lambda execution role
- Allow Lambda functions to read/write avatars

### Step 3: Deploy Lambda Functions

```bash
./deploy-avatar-lambdas.sh
```

This will:
- Deploy `soteria-avatar-upload` Lambda function
- Deploy `soteria-avatar-download` Lambda function
- Configure environment variables (bucket name, region)

### Step 4: Connect to API Gateway

```bash
./connect-avatar-lambdas-to-api-gateway.sh
```

This will:
- Create `/soteria/avatar/upload` endpoint (POST)
- Create `/soteria/avatar/download` endpoint (GET)
- Grant API Gateway permission to invoke Lambda functions
- Deploy API to `prod` stage

## API Endpoints

After setup, you'll have:

- **Upload**: `POST https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/avatar/upload?user_id=xxx`
- **Download**: `GET https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/avatar/download?user_id=xxx`

## How It Works

### Upload Flow

1. User selects avatar in ProfileView
2. Image is resized to 200x200
3. Image is saved to UserDefaults (immediate local access)
4. Image is uploaded to S3 via Lambda function
5. Avatar URL is returned

### Download Flow

1. App checks UserDefaults for cached avatar
2. If not found, downloads from S3 via Lambda function
3. Avatar is cached in UserDefaults for future use
4. Avatar is displayed in UI

### Benefits

- ✅ Avatars persist across app reinstalls
- ✅ Avatars sync across devices
- ✅ No data loss when app is uninstalled
- ✅ Fast local caching with cloud backup

## Testing

1. Upload an avatar in ProfileView
2. Check S3 bucket: `aws s3 ls s3://soteria-avatars-516141816050/avatars/`
3. Uninstall and reinstall the app
4. Avatar should automatically download from S3

## Troubleshooting

### Avatar not uploading
- Check Lambda function logs: `aws logs tail /aws/lambda/soteria-avatar-upload --follow`
- Verify IAM permissions are attached
- Check S3 bucket exists and is accessible

### Avatar not downloading
- Check Lambda function logs: `aws logs tail /aws/lambda/soteria-avatar-download --follow`
- Verify API Gateway endpoint is deployed
- Check user_id is correct

### Permission errors
- Verify IAM policy is attached to Lambda execution role
- Check S3 bucket policy allows Lambda access
- Ensure API Gateway has permission to invoke Lambda

## Code Changes

The following files have been updated:

- `soteria/Services/AvatarService.swift` - New service for S3 operations
- `soteria/Views/ProfileView.swift` - Updated to use AvatarService
- `soteria/Views/HomeView.swift` - Updated to download from S3
- `soteria/Views/SettingsView.swift` - Updated to download from S3

All views now:
1. Load from UserDefaults first (fast, local cache)
2. Download from S3 if not found (persistence, cross-device sync)

