# Contingency Plan for Non-Scanning Scenarios

## Problem Statement

If a partner cannot scan the barcode/QR code (due to technical issues, damaged card, poor lighting, etc.), we need a fallback method for manual member verification.

## Proposed Solution: Member ID in Signature Box

### Option 1: Shortened Member ID (Recommended)
**Location**: Far right of signature box, below username

**Format**: 
- Use a shortened, human-readable version of the user ID
- Example: `SOT-1234-5678` or `SOT-ABC123`
- 8-12 characters total for easy manual entry

**Pros**:
- Easy to read and type
- Professional appearance
- Can be validated server-side
- Unique per user

**Cons**:
- Requires mapping logic (short ID → full user ID)
- Need to ensure uniqueness

### Option 2: Full User ID (Simpler)
**Location**: Far right of signature box, below username

**Format**:
- Display the formatted UID (already used on front of card)
- Example: `1234-5678-9ABC-DEF0` (with 5th block removed as currently done)

**Pros**:
- No mapping needed - direct lookup
- Already displayed on front of card
- Consistent with existing design

**Cons**:
- Longer string (harder to type)
- Less "premium" looking
- More prone to typos

### Option 3: Member Number (Database-Generated)
**Location**: Far right of signature box, below username

**Format**:
- Generate a unique 6-8 digit member number when user becomes premium
- Example: `1234567` or `SOT-123456`
- Store in user profile in DynamoDB

**Pros**:
- Short and easy to type
- Professional member number feel
- Can be sequential or random
- Most "credit card-like"

**Cons**:
- Requires database field addition
- Need to generate and store on signup
- Migration needed for existing users

## Recommended Approach: Hybrid Solution

**Display**: Shortened Member ID in signature box
**Backend**: Support both short ID and full UID for validation

### Implementation Details

1. **Card Display**:
   - Username on left side of signature box (as currently)
   - Short Member ID on right side of signature box
   - Format: `SOT-XXXX` where XXXX is a 4-6 character code derived from user ID

2. **ID Generation**:
   - Create a deterministic short ID from full user ID
   - Use first 4-6 characters of a hash of the user ID
   - Ensure uniqueness (add check digit if needed)
   - Example: `SOT-A3B7` or `SOT-1234`

3. **Backend Validation**:
   - Update `/soteria/partner/validate-member` endpoint
   - Accept either:
     - QR/barcode data (JSON)
     - Short Member ID (string)
     - Full User ID (string)
   - Lookup user by either identifier

4. **Partner Scanner UI**:
   - Add "Manual Entry" option
   - Text field for Member ID
   - Validate same way as QR code

## Visual Layout

```
┌─────────────────────────────────────────┐
│  [Barcode in Magnetic Stripe]          │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ JOHN DOE          SOT-A3B7      │   │
│  │ (signature style)  (member ID)  │   │
│  └─────────────────────────────────┘   │
│              SIGNATURE                  │
│                                         │
│         [Apple Wallet Button]           │
└─────────────────────────────────────────┘
```

## Questions to Consider

1. **ID Format Preference**:
   - Short alphanumeric (SOT-A3B7) - more premium feel
   - Numeric only (SOT-1234) - easier to type
   - Mixed (SOT-A3B7) - balance of both

2. **Length**:
   - 6 characters (SOT-123) - shortest, easiest
   - 8 characters (SOT-1234) - more unique
   - 10 characters (SOT-12345) - maximum uniqueness

3. **Prefix**:
   - Include "SOT" prefix for brand recognition
   - Or just numbers/letters for cleaner look

4. **Position**:
   - Far right of signature box (recommended)
   - Below signature box as separate line
   - Small text above signature box

5. **Styling**:
   - Match username font (signature style)
   - Or use monospace font for clarity
   - Size: 12-14pt for readability

## Backend Changes Needed

1. **Update Validation Endpoint**:
   ```javascript
   // Accept multiple input formats
   if (event.body.qr_data) {
       // Parse QR code JSON
   } else if (event.body.member_id) {
       // Lookup by short member ID
   } else if (event.body.user_id) {
       // Lookup by full user ID
   }
   ```

2. **ID Mapping Table** (Optional):
   - Create DynamoDB table: `soteria-member-ids`
   - Store: `member_id` (short) → `user_id` (full)
   - Or use deterministic algorithm (no table needed)

3. **Partner Scanner Update**:
   - Add manual entry field
   - Update validation API call

## Recommendation

**Go with Option 1 (Shortened Member ID)** with these specs:
- Format: `SOT-XXXX` where XXXX is 4 uppercase alphanumeric characters
- Position: Far right of signature box, aligned right
- Font: Monospace, 12pt, matching card color scheme
- Generation: Deterministic hash-based (no database needed)
- Example: `SOT-A3B7`

This provides:
- ✅ Easy manual entry (8 characters total)
- ✅ Professional appearance
- ✅ No database migration needed
- ✅ Works with existing validation endpoint
- ✅ Consistent with premium card aesthetic

## Next Steps

1. **Confirm approach** with you
2. **Implement ID generation** function
3. **Update card back** to display member ID
4. **Update validation endpoint** to accept member ID
5. **Update partner scanner** with manual entry option

---

**What are your thoughts on this approach?** Should we proceed with the shortened member ID, or would you prefer a different format/approach?

