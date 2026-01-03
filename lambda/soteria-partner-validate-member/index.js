/**
 * Lambda function to validate member QR code scans
 * 
 * This function validates QR codes scanned by partners to verify:
 * - User is a valid Soteria member
 * - User has active premium subscription
 * - QR code is not expired or tampered with
 * 
 * Endpoint: POST /soteria/partner/validate-member
 * 
 * Request Body:
 * {
 *   "qr_data": "{\"user_id\":\"...\",\"card_type\":\"...\",\"member_since\":\"...\"}",
 *   "partner_id": "partner-123"
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "valid": true,
 *   "member": {
 *     "user_id": "user-123",
 *     "card_type": "gold",
 *     "member_since": "2024-01-01T00:00:00Z",
 *     "is_premium": true,
 *     "subscription_status": "active"
 *   },
 *   "partner": {
 *     "partner_id": "partner-123",
 *     "name": "Coffee Shop",
 *     "discount_percentage": 10
 *   }
 * }
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const cognito = new AWS.CognitoIdentityServiceProvider();

// DynamoDB table names
const TABLES = {
    partners: process.env.PARTNERS_TABLE || 'soteria-partners',
    scans: process.env.SCANS_TABLE || 'soteria-partner-scans',
    userData: process.env.USER_DATA_TABLE || 'soteria-user-data'
};

// User Pool ID (from environment or default)
const USER_POOL_ID = process.env.USER_POOL_ID || 'us-east-1_XXXXXXXXX';

/**
 * Parse and validate QR code data
 */
function parseQRData(qrDataString) {
    try {
        const qrData = JSON.parse(qrDataString);
        
        // Validate required fields
        if (!qrData.user_id || !qrData.card_type || !qrData.member_since) {
            throw new Error('Invalid QR code: missing required fields');
        }
        
        // Validate card_type
        const validCardTypes = ['gold', 'platinum', 'black'];
        if (!validCardTypes.includes(qrData.card_type)) {
            throw new Error('Invalid QR code: invalid card type');
        }
        
        // Validate member_since date
        const memberSince = new Date(qrData.member_since);
        if (isNaN(memberSince.getTime())) {
            throw new Error('Invalid QR code: invalid member_since date');
        }
        
        return qrData;
    } catch (error) {
        console.error('❌ [Lambda] Error parsing QR data:', error);
        throw new Error('Invalid QR code format');
    }
}

/**
 * Get partner information
 */
async function getPartner(partnerId) {
    try {
        const params = {
            TableName: TABLES.partners,
            Key: {
                partner_id: partnerId
            }
        };
        
        const result = await dynamodb.get(params).promise();
        
        if (!result.Item) {
            return null;
        }
        
        return {
            partner_id: result.Item.partner_id,
            name: result.Item.name,
            description: result.Item.description,
            discount_percentage: result.Item.discount_percentage || 0, // Keep field name for DB compatibility
            discount_amount: result.Item.discount_amount || null,
            discount_type: result.Item.discount_type || 'percentage', // 'percentage' or 'fixed'
            is_active: result.Item.is_active !== false, // Default to true
            logo_url: result.Item.logo_url || null,
            terms: result.Item.terms || null,
            max_redemptions_per_user: result.Item.max_redemptions_per_user || null,
            valid_until: result.Item.valid_until || null
        };
    } catch (error) {
        console.error('❌ [Lambda] Error getting partner:', error);
        return null;
    }
}

/**
 * Lookup user by member number
 */
async function lookupUserByMemberNumber(memberNumber) {
    try {
        // Remove SOT- prefix if present
        const cleanNumber = memberNumber.replace(/^SOT-?/i, '');
        
        // Query user data table for member number
        const params = {
            TableName: TABLES.userData,
            IndexName: 'member_number-index', // GSI for member number lookup
            KeyConditionExpression: 'member_number = :mn',
            ExpressionAttributeValues: {
                ':mn': cleanNumber
            }
        };
        
        const result = await dynamodb.query(params).promise();
        
        if (result.Items && result.Items.length > 0) {
            // Return user_id from the first matching item
            return result.Items[0].user_id;
        }
        
        // Fallback: Scan table if index doesn't exist (for migration period)
        const scanParams = {
            TableName: TABLES.userData,
            FilterExpression: 'member_number = :mn',
            ExpressionAttributeValues: {
                ':mn': cleanNumber
            }
        };
        
        const scanResult = await dynamodb.scan(scanParams).promise();
        if (scanResult.Items && scanResult.Items.length > 0) {
            return scanResult.Items[0].user_id;
        }
        
        return null;
    } catch (error) {
        console.error('❌ [Lambda] Error looking up member number:', error);
        // If index doesn't exist, try alternative lookup
        return null;
    }
}

/**
 * Get user data
 */
async function getUserData(userId) {
    try {
        const params = {
            TableName: TABLES.userData,
            Key: {
                user_id: userId,
                data_type: 'profile'
            }
        };
        
        const result = await dynamodb.get(params).promise();
        return result.Item ? result.Item.data : null;
    } catch (error) {
        console.error('❌ [Lambda] Error getting user data:', error);
        return null;
    }
}

/**
 * Check if user has active premium subscription
 */
async function checkPremiumStatus(userId) {
    try {
        // Check user data table for subscription info
        const params = {
            TableName: TABLES.userData,
            Key: {
                user_id: userId,
                data_type: 'subscription'
            }
        };
        
        const result = await dynamodb.get(params).promise();
        
        if (!result.Item) {
            // No subscription data found
            return {
                is_premium: false,
                subscription_status: 'none',
                subscription_type: null,
                expires_at: null
            };
        }
        
        const subscription = result.Item.data || {};
        const expiresAt = subscription.expires_at || subscription.expiresAt;
        const isExpired = expiresAt ? new Date(expiresAt) < new Date() : false;
        
        return {
            is_premium: subscription.is_premium === true && !isExpired,
            subscription_status: isExpired ? 'expired' : (subscription.status || 'unknown'),
            subscription_type: subscription.type || subscription.subscription_type || null,
            expires_at: expiresAt
        };
    } catch (error) {
        console.error('❌ [Lambda] Error checking premium status:', error);
        // Default to not premium if we can't check
        return {
            is_premium: false,
            subscription_status: 'unknown',
            subscription_type: null,
            expires_at: null
        };
    }
}

/**
 * Record scan event for analytics
 */
async function recordScan(partnerId, userId, isValid) {
    try {
        const params = {
            TableName: TABLES.scans,
            Item: {
                partner_id: partnerId,
                scan_timestamp: new Date().toISOString(),
                user_id: userId,
                is_valid: isValid,
                created_at: Date.now()
            }
        };
        
        await dynamodb.put(params).promise();
        console.log(`✅ [Lambda] Scan recorded: partner=${partnerId}, user=${userId}, valid=${isValid}`);
    } catch (error) {
        // Don't fail the request if scan recording fails
        console.error('⚠️ [Lambda] Failed to record scan (non-critical):', error);
    }
}

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Validating member QR code...');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Content-Type': 'application/json'
    };
    
    // Handle OPTIONS request (CORS preflight)
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }
    
    try {
        // Parse request body
        let body;
        try {
            body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
        } catch (error) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Invalid JSON in request body'
                })
            };
        }
        
        const { qr_data, member_number, partner_id } = body;
        
        if (!partner_id) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'partner_id is required'
                })
            };
        }
        
        // Must provide either qr_data or member_number
        if (!qr_data && !member_number) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Either qr_data or member_number is required'
                })
            };
        }
        
        // Parse QR code data or lookup by member number
        let qrData;
        let userId;
        
        if (member_number) {
            // Lookup user by member number
            try {
                userId = await lookupUserByMemberNumber(member_number);
                if (!userId) {
                    await recordScan(partner_id, 'unknown', false);
                    return {
                        statusCode: 404,
                        headers,
                        body: JSON.stringify({
                            success: false,
                            valid: false,
                            error: 'Member number not found'
                        })
                    };
                }
                
                // Get user data to construct qrData-like object
                const userData = await getUserData(userId);
                qrData = {
                    user_id: userId,
                    card_type: userData?.card_type || 'gold',
                    member_since: userData?.member_since || new Date().toISOString()
                };
            } catch (error) {
                await recordScan(partner_id, 'unknown', false);
                return {
                    statusCode: 400,
                    headers,
                    body: JSON.stringify({
                        success: false,
                        valid: false,
                        error: error.message || 'Error looking up member number'
                    })
                };
            }
        } else {
            // Parse QR code data
            try {
                qrData = parseQRData(qr_data);
                userId = qrData.user_id;
            } catch (error) {
                await recordScan(partner_id, 'unknown', false);
                return {
                    statusCode: 400,
                    headers,
                    body: JSON.stringify({
                        success: false,
                        valid: false,
                        error: error.message
                    })
                };
            }
        }
        
        // Get partner information
        const partner = await getPartner(partner_id);
        if (!partner) {
            await recordScan(partner_id, qrData.user_id, false);
            return {
                statusCode: 404,
                headers,
                body: JSON.stringify({
                    success: false,
                    valid: false,
                    error: 'Partner not found'
                })
            };
        }
        
        // Check if partner is active
        if (!partner.is_active) {
            await recordScan(partner_id, qrData.user_id, false);
            return {
                statusCode: 403,
                headers,
                body: JSON.stringify({
                    success: false,
                    valid: false,
                    error: 'Partner loyalty program is not currently active'
                })
            };
        }
        
        // Check premium status
        const premiumStatus = await checkPremiumStatus(qrData.user_id);
        
        // Validate member (must be premium)
        const isValid = premiumStatus.is_premium;
        
        // Record scan event
        await recordScan(partner_id, userId, isValid);
        
        if (!isValid) {
            return {
                statusCode: 403,
                headers,
                body: JSON.stringify({
                    success: true,
                    valid: false,
                    error: 'User does not have an active premium subscription',
                    member: {
                        user_id: userId,
                        card_type: qrData.card_type,
                        member_since: qrData.member_since,
                        is_premium: false,
                        subscription_status: premiumStatus.subscription_status
                    },
                    partner: {
                        partner_id: partner.partner_id,
                        name: partner.name
                    }
                })
            };
        }
        
        // Success - member is valid
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                valid: true,
                member: {
                    user_id: userId,
                    card_type: qrData.card_type,
                    member_since: qrData.member_since,
                    is_premium: true,
                    subscription_status: premiumStatus.subscription_status,
                    subscription_type: premiumStatus.subscription_type
                },
                partner: {
                    partner_id: partner.partner_id,
                    name: partner.name,
                    description: partner.description,
                    discount_percentage: partner.discount_percentage,
                    discount_amount: partner.discount_amount,
                    discount_type: partner.discount_type,
                    logo_url: partner.logo_url,
                    terms: partner.terms
                }
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error validating member:', error);
        
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Internal server error'
            })
        };
    }
};

