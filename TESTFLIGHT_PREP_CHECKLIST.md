# TestFlight Prep Checklist for Soteria

## ✅ What You Can Do NOW (Before Organization Approval)

### 1. Xcode Build Configuration

#### Version Numbers
- [x] **Marketing Version**: 1.0 (already set)
- [x] **Build Number**: 1 (already set)
- [ ] **Plan versioning strategy**: 
  - Marketing version = user-facing (1.0, 1.1, 2.0)
  - Build number = increments with each upload (1, 2, 3...)

#### Build Settings
- [x] **Bundle ID**: `io.montebay.soteria` ✅
- [x] **Display Name**: "Soteria" ✅
- [x] **Development Team**: `4P5YXTJ7U7` ✅
- [ ] **App Icon**: Add 1024x1024 icon to `Assets.xcassets/AppIcon.appiconset`
- [ ] **Code Signing**: Verify "Automatic" is selected
- [ ] **Provisioning Profile**: Will auto-generate when uploading

### 2. App Store Connect Preparation

#### App Information (Can prepare text now)
- [ ] **App Name**: "Soteria"
- [ ] **Subtitle**: "Grow Your Money Tree" (optional, 30 chars max)
- [ ] **Category**: 
  - Primary: Finance
  - Secondary: Lifestyle (optional)
- [ ] **App Description** (4000 chars max):
  ```
  Soteria helps you build better financial habits through intentional moments of pause. 
  
  🌳 GROW YOUR MONEY TREE
  Watch your savings grow with a beautiful, visual money tree that represents your goals and milestones.
  
  💰 GOAL-BASED SAVINGS
  Set savings goals with photos, target dates, and progress tracking. See your money tree fill in as you save.
  
  ⏰ DECISION WINDOWS
  Set intentional moments to pause before spending. Choose to save, protect, or reflect.
  
  🛡️ PROTECTION HOURS
  Get gentle reminders during times when you're most likely to make impulse purchases.
  
  🤝 SHARED GOALS
  Invite friends and family to save together for shared purchases.
  
  🎯 MICRO-COMMITMENTS
  Build daily and weekly savings habits with streak tracking.
  
  Soteria is privacy-first, non-judgmental, and designed to help you make better financial decisions—one moment at a time.
  ```

- [ ] **Keywords** (100 chars max): "savings, goals, money, finance, budgeting, habits, financial wellness"
- [ ] **Support URL**: Your website or support page
- [ ] **Marketing URL**: Your website (optional)
- [ ] **Privacy Policy URL**: Required for TestFlight

#### Screenshots (Prepare now, upload after approval)
- [ ] **iPhone 6.7" Display** (1290 x 2796 pixels) - 3-10 screenshots
- [ ] **iPhone 6.5" Display** (1242 x 2688 pixels) - 3-10 screenshots  
- [ ] **iPhone 5.5" Display** (1242 x 2208 pixels) - 3-10 screenshots
- [ ] **iPad Pro 12.9"** (2048 x 2732 pixels) - 3-10 screenshots (if supporting iPad)

**Screenshot Ideas:**
1. Money Tree home screen
2. Goal creation/editing
3. Decision Window prompt
4. Deposit tracker
5. Settings/Protection Hours
6. Goal detail view with progress
7. Welcome/onboarding screen

#### App Preview Videos (Optional but recommended)
- [ ] **iPhone 6.7"** (1290 x 2796, 15-30 seconds)
- [ ] **iPhone 6.5"** (1242 x 2688, 15-30 seconds)

### 3. Privacy & Compliance

#### Privacy Details (Required)
- [ ] **Privacy Policy URL**: Must be accessible
- [ ] **Data Collection**:
  - [ ] Financial Information (for Plaid integration)
  - [ ] Location (for time-based themes)
  - [ ] Photos (for goal photos)
  - [ ] User Content (goals, commitments)
  - [ ] Identifiers (user ID, device ID)
  - [ ] Usage Data (app interactions)

#### Age Rating
- [ ] **Content Rating**: 4+ (Everyone)
- [ ] **Reasons**: 
  - No objectionable content
  - Financial information (but educational)
  - No violence, profanity, or mature themes

### 4. TestFlight Specific

#### Test Information
- [ ] **What to Test** (2000 chars max):
  ```
  Thank you for testing Soteria! Please test:
  
  🔗 PLAID INTEGRATION
  - Connect a bank account (use Plaid sandbox test credentials)
  - Make a test deposit
  - Verify deposits appear in deposit tracker
  
  🏦 UNIT ACCOUNT CREATION
  - Create your dedicated savings account
  - Verify account credentials are provided
  
  💰 GOAL CREATION
  - Create a goal with a photo
  - Try pasting a product/cart URL
  - Set target date and amount
  
  🌳 MONEY TREE
  - View your money tree visualization
  - Click on goal leaves to see details
  - Watch leaves fill in as you save
  
  ⏰ DECISION WINDOWS
  - Set up a Decision Window
  - Test the prompt when it appears
  - Try different actions (save, protect, pause)
  
  🛡️ PROTECTION HOURS
  - Create a Protection Hours schedule
  - Verify notifications appear during scheduled times
  
  📊 DEPOSIT TRACKER
  - View deposit history
  - Check daily/weekly/monthly views
  
  🎯 MICRO-COMMITMENTS
  - Create a daily or weekly commitment
  - Make a deposit and verify streak updates
  
  Please report any bugs, crashes, or issues you encounter!
  ```

- [ ] **Feedback Email**: Your support email
- [ ] **Beta App Description**: Same as Test Information

### 5. Build Preparation

#### Archive Build
- [ ] **Select "Any iOS Device"** (not simulator)
- [ ] **Product → Archive**
- [ ] **Wait for archive to complete**
- [ ] **Verify build shows in Organizer**

#### Upload to App Store Connect
- [ ] **Distribute App**
- [ ] **Select "App Store Connect"**
- [ ] **Upload** (will process on Apple's servers)
- [ ] **Wait for processing** (15-60 minutes typically)

### 6. App Icon (Critical - Do This Now)

#### Requirements
- [ ] **1024x1024 pixels**
- [ ] **PNG format**
- [ ] **No transparency**
- [ ] **Square format**
- [ ] **Recognizable at small sizes**

#### Add to Xcode
1. Open `soteria/Assets.xcassets/AppIcon.appiconset`
2. Drag 1024x1024 icon to "Universal" slot
3. (Optional) Add dark mode version
4. Build and verify icon appears on device

### 7. Version History Planning

#### Version 1.0 (Current TestFlight)
- Initial release
- Core features: Money Tree, Goals, Decision Windows, Protection Hours
- Plaid integration (sandbox)
- Unit account creation

#### Future Versions (Plan ahead)
- [ ] Version 1.1: Bug fixes, improvements
- [ ] Version 1.2: New features (AI recommendations, etc.)
- [ ] Version 2.0: Major updates

### 8. TestFlight Groups

#### Internal Testing (Up to 100 users)
- [ ] Create internal test group
- [ ] Add team members
- [ ] Upload build
- [ ] Test internally first

#### External Testing (Up to 10,000 users)
- [ ] Create external test group
- [ ] Add testers (via email or public link)
- [ ] Submit for Beta App Review (required for external)
- [ ] Wait for review (24-48 hours typically)

### 9. Beta App Review (For External Testing)

#### Required Information
- [ ] **App Description**: Same as App Store description
- [ ] **Beta App Information**: What to test (see above)
- [ ] **Contact Information**: Your email/phone
- [ ] **Demo Account** (if needed): Test credentials
- [ ] **Notes**: Any special instructions

### 10. Legal & Compliance

#### Required Documents
- [ ] **Privacy Policy**: Must be live and accessible
- [ ] **Terms of Service**: Recommended
- [ ] **End User License Agreement**: Optional (Apple provides default)

#### Financial Compliance
- [ ] **Plaid**: Sandbox credentials configured
- [ ] **Unit**: Sandbox API token configured
- [ ] **Subscriptions**: StoreKit configured (Products.storekit)

## ⏳ What to Wait For (After Organization Approval)

### Immediate After Approval
- [ ] Verify organization account in App Store Connect
- [ ] Check team ID matches (may need to update in Xcode)
- [ ] Create app listing in App Store Connect
- [ ] Upload first build

### Can Do Now (Prepare, Upload Later)
- ✅ All text content (descriptions, keywords)
- ✅ Screenshot designs (create, upload after approval)
- ✅ App icon (add to Xcode now)
- ✅ Version planning
- ✅ TestFlight notes
- ✅ Privacy policy (publish on website)

## 🚀 Quick Start After Approval

1. **Log into App Store Connect**
2. **My Apps → + (New App)**
3. **Fill in app information** (use prepared text)
4. **Upload build** from Xcode
5. **Add screenshots** (use prepared images)
6. **Set up TestFlight groups**
7. **Submit for Beta App Review** (external testing)
8. **Invite testers**

## 📝 Notes

- **App Store Connect Access**: You may be able to access App Store Connect now (even with individual account) to prepare content
- **Build Upload**: Can only upload after organization approval
- **Screenshots**: Can prepare designs now, upload after approval
- **Privacy Policy**: Must be live before TestFlight external testing
- **Beta Review**: Required for external testing, not for internal

## ✅ Current Status

- **Version**: 1.0 (Build 1)
- **Bundle ID**: `io.montebay.soteria` ✅
- **Display Name**: "Soteria" ✅
- **Team ID**: `4P5YXTJ7U7` ✅
- **App Icon**: ⚠️ Needs 1024x1024 image
- **Organization Account**: ⏳ Pending approval

---

**Next Steps**: 
1. Add app icon to Xcode
2. Prepare all text content
3. Design screenshots
4. Wait for organization approval
5. Upload build and submit to TestFlight


