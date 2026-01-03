# Partner Discount & QR Code Architecture

## Overview
Premium member cards now include QR code functionality for partner discount validation and Apple Wallet integration. This enables Soteria to partner with businesses to offer exclusive discounts to premium members.

## Current Implementation

### ✅ QR Code Generation
- **Service**: `QRCodeService.swift`
- **Location**: Displayed on premium cards (bottom right, next to card type)
- **Content**: JSON payload containing:
  - `user_id`: Unique user identifier
  - `card_type`: gold, platinum, or black
  - `member_since`: ISO8601 formatted sign-up date
  - `app`: "soteria"
  - `version`: "1.0"

### ✅ QR Code Display
- **Component**: `PremiumCardQRCode` in `PremiumCardComponents.swift`
- **Size**: 80x80 pixels with white background and rounded corners
- **Styling**: Adapts to card type (black/platinum/gold)
- **Generation**: Automatically generates when card appears

### 🔄 Apple Wallet Integration (Foundation)
- **Service**: `AppleWalletService.swift`
- **Status**: Framework in place, requires backend implementation
- **Requirements**:
  - Apple Developer certificate for pass signing
  - Web service endpoint for pass updates
  - Push notification setup for pass updates

## Partner Discount System Architecture

### Phase 1: QR Code Validation (Current)
```
User shows QR code → Partner scans → Validates membership → Applies discount
```

**QR Code Payload Structure:**
```json
{
  "user_id": "abc123-def456-ghi789",
  "card_type": "gold|platinum|black",
  "member_since": "2024-01-15T10:30:00Z",
  "app": "soteria",
  "version": "1.0"
}
```

### Phase 2: Backend Validation API (Required)
**Endpoint**: `POST /api/partner/validate-member`

**Request:**
```json
{
  "user_id": "abc123-def456-ghi789",
  "card_type": "gold",
  "partner_id": "partner_xyz",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Response:**
```json
{
  "valid": true,
  "member_tier": "gold",
  "discount_percentage": 10,
  "expires_at": "2024-12-31T23:59:59Z"
}
```

### Phase 3: Partner Portal (Future)
- Partner dashboard to:
  - Register as a partner
  - Set discount percentages per tier
  - View redemption analytics
  - Manage discount codes/campaigns

### Phase 4: Apple Wallet Pass (Future)
**Pass Structure:**
- **Type**: Store Card
- **Fields**:
  - Member Name
  - Card Type (Gold/Platinum/Black)
  - Member Since Date
  - QR Code (barcode)
  - Partner Discounts (dynamic list)

**Pass Updates:**
- Push notifications when new partners added
- Automatic pass refresh
- Location-based partner discovery

## Implementation Roadmap

### ✅ Completed
1. QR code generation service
2. QR code display on premium cards
3. Apple Wallet service foundation

### 🔄 Next Steps (Priority Order)

#### 1. Backend API for Validation
**Required Endpoints:**
- `POST /api/partner/validate-member` - Validate QR code scan
- `GET /api/partner/list` - Get available partner discounts
- `POST /api/partner/redeem` - Record discount redemption

**Database Schema:**
```sql
-- Partners table
CREATE TABLE partners (
  id UUID PRIMARY KEY,
  name VARCHAR(255),
  category VARCHAR(100),
  logo_url TEXT,
  created_at TIMESTAMP
);

-- Partner Discounts table
CREATE TABLE partner_discounts (
  id UUID PRIMARY KEY,
  partner_id UUID REFERENCES partners(id),
  card_type VARCHAR(20), -- gold, platinum, black
  discount_percentage INT,
  valid_from TIMESTAMP,
  valid_until TIMESTAMP,
  is_active BOOLEAN
);

-- Redemptions table
CREATE TABLE discount_redemptions (
  id UUID PRIMARY KEY,
  user_id UUID,
  partner_id UUID REFERENCES partners(id),
  discount_id UUID REFERENCES partner_discounts(id),
  amount_saved DECIMAL(10,2),
  redeemed_at TIMESTAMP
);
```

#### 2. Partner Scanner App/Web Portal
**Options:**
- **Option A**: Partner web portal with QR scanner
- **Option B**: Partner mobile app
- **Option C**: Integration with existing POS systems

**Scanner Requirements:**
- Scan QR code
- Validate membership in real-time
- Show discount percentage
- Record redemption

#### 3. Apple Wallet Pass Creation
**Requirements:**
- Apple Developer account with Pass Type ID
- Pass signing certificate
- Web service for pass updates
- Push notification certificates

**Pass Template:**
- Use PKPass library or manual .pkpass bundle creation
- Include QR code as barcode
- Dynamic partner list field
- Location-based partner discovery

#### 4. Partner Onboarding Flow
- Partner registration form
- Discount tier configuration
- Terms & conditions
- Payment processing (if charging partners)

## Security Considerations

### QR Code Security
1. **Token-based validation**: Add time-limited tokens to QR codes
2. **Encryption**: Encrypt sensitive data in QR payload
3. **Rate limiting**: Prevent QR code replay attacks
4. **Audit logging**: Track all validation attempts

### Backend Security
1. **API authentication**: Partner API keys
2. **Rate limiting**: Prevent abuse
3. **Fraud detection**: Monitor unusual redemption patterns
4. **Data privacy**: GDPR compliance for user data

## Example Partner Categories

### Potential Partners
- **Retail**: Clothing stores, electronics, home goods
- **Dining**: Restaurants, cafes, food delivery
- **Services**: Gyms, salons, car services
- **Entertainment**: Movies, concerts, events
- **Travel**: Hotels, airlines, car rentals

### Discount Tiers Example
- **Gold Members**: 5-10% off
- **Platinum Members**: 10-15% off
- **Black Members (Founders)**: 15-20% off

## User Experience Flow

### For Members
1. Open Soteria app
2. View premium card with QR code
3. Show QR code at partner location
4. Partner scans → discount applied
5. (Future) Add card to Apple Wallet for quick access

### For Partners
1. Register as partner
2. Set discount percentages
3. Receive QR scanner (web/mobile)
4. Scan member QR codes
5. Validate and apply discount
6. View redemption analytics

## Technical Integration Points

### Current Code Locations
- **QR Code Service**: `soteria/Services/QRCodeService.swift`
- **Apple Wallet Service**: `soteria/Services/AppleWalletService.swift`
- **Card Component**: `soteria/Views/PremiumCardComponents.swift` (PremiumCardQRCode)
- **Card Display**: `soteria/Views/HomeView.swift` (premiumMemberCard function)

### Future Integration Points
- **Partner API Client**: New service for partner API calls
- **Pass Update Service**: Handles Apple Wallet pass updates
- **Partner Discovery**: Location-based partner finder
- **Redemption History**: View past discount redemptions

## Next Steps to Complete

1. **Backend Development** (Critical)
   - Create validation API endpoint
   - Set up partner database
   - Implement security measures

2. **Partner Scanner** (Critical)
   - Build web or mobile scanner
   - Integrate with validation API
   - Test QR code scanning

3. **Apple Wallet** (Enhancement)
   - Set up Pass Type ID
   - Create pass template
   - Implement pass update service

4. **Partner Onboarding** (Business)
   - Create partner registration flow
   - Build partner dashboard
   - Set up payment processing

## Benefits

### For Soteria
- **Revenue**: Partner fees for listing
- **Retention**: Exclusive perks increase premium value
- **Growth**: Partner network drives new signups
- **Brand**: Premium positioning with exclusive benefits

### For Partners
- **Customer Acquisition**: Access to premium members
- **Analytics**: Track redemption patterns
- **Marketing**: Co-marketing opportunities
- **Loyalty**: Build relationships with high-value customers

### For Members
- **Value**: Exclusive discounts justify premium cost
- **Convenience**: QR code easy to use
- **Discovery**: Find new partner businesses
- **Savings**: Real money saved on purchases

