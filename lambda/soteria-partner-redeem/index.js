/**
 * Lambda function to record partner discount redemptions
 * 
 * This function records when a user redeems a partner loyalty benefit,
 * tracking usage limits and providing analytics.
 * 
 * Endpoint: POST /soteria/partner/redeem
 * 
 * Request Body:
 * {
 *   "user_id": "user-123",
 *   "partner_id": "partner-123",
 *   "discount_amount": 5.00,
 *   "transaction_id": "txn-456" (optional, from partner's system)
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "redemption": {
 *     "redemption_id": "redemption-789",
 *     "user_id": "user-123",
 *     "partner_id": "partner-123",
 *     "discount_amount": 5.00,
 *     "redeemed_at": "2024-01-15T10:30:00Z",
 *     "transaction_id": "txn-456"
 *   }
 * }
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const crypto = require('crypto');

// DynamoDB table names
const TABLES = {
    partners: process.env.PARTNERS_TABLE || 'soteria-partners',
    redemptions: process.env.REDEMPTIONS_TABLE || 'soteria-partner-redemptions'
};

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
        return result.Item || null;
    } catch (error) {
        console.error('❌ [Lambda] Error getting partner:', error);
        return null;
    }
}

/**
 * Check if user can redeem (within limits)
 */
async function canUserRedeem(userId, partnerId, partner) {
    // Check if partner is active
    if (!partner || !partner.is_active) {
        return { canRedeem: false, reason: 'Partner discount is not active' };
    }
    
    // Check valid_until date
    if (partner.valid_until) {
        const validUntil = new Date(partner.valid_until);
        if (validUntil < new Date()) {
            return { canRedeem: false, reason: 'Partner loyalty benefit has expired' };
        }
    }
    
    // Check max redemptions per user
    if (partner.max_redemptions_per_user) {
        const redemptionCount = await getUserRedemptionCount(userId, partnerId);
        if (redemptionCount >= partner.max_redemptions_per_user) {
            return {
                canRedeem: false,
                reason: `Maximum redemptions (${partner.max_redemptions_per_user}) reached`
            };
        }
    }
    
    return { canRedeem: true };
}

/**
 * Get user's redemption count for a partner
 */
async function getUserRedemptionCount(userId, partnerId) {
    try {
        const params = {
            TableName: TABLES.redemptions,
            KeyConditionExpression: 'user_id = :userId',
            FilterExpression: 'partner_id = :partnerId',
            ExpressionAttributeValues: {
                ':userId': userId,
                ':partnerId': partnerId
            }
        };
        
        const result = await dynamodb.query(params).promise();
        return result.Items ? result.Items.length : 0;
    } catch (error) {
        console.error('❌ [Lambda] Error getting redemption count:', error);
        return 0;
    }
}

/**
 * Record redemption
 */
async function recordRedemption(userId, partnerId, discountAmount, transactionId) {
    const redemptionId = `redemption-${crypto.randomUUID()}`;
    const now = new Date().toISOString();
    
    const params = {
        TableName: TABLES.redemptions,
        Item: {
            redemption_id: redemptionId,
            user_id: userId,
            partner_id: partnerId,
            discount_amount: discountAmount,
            transaction_id: transactionId || null,
            redeemed_at: now,
            created_at: Date.now()
        }
    };
    
    await dynamodb.put(params).promise();
    
    return {
        redemption_id: redemptionId,
        user_id: userId,
        partner_id: partnerId,
        discount_amount: discountAmount,
        redeemed_at: now,
        transaction_id: transactionId || null
    };
}

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Recording redemption...');
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
        
        const { user_id, partner_id, discount_amount, transaction_id } = body;
        
        if (!user_id || !partner_id || discount_amount === undefined) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'user_id, partner_id, and discount_amount are required'
                })
            };
        }
        
        // Validate discount_amount (loyalty benefit amount)
        const discountAmount = parseFloat(discount_amount);
        if (isNaN(discountAmount) || discountAmount < 0) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'discount_amount must be a positive number'
                })
            };
        }
        
        // Get partner information
        const partner = await getPartner(partner_id);
        if (!partner) {
            return {
                statusCode: 404,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Partner not found'
                })
            };
        }
        
        // Check if user can redeem
        const { canRedeem, reason } = await canUserRedeem(user_id, partner_id, partner);
        if (!canRedeem) {
            return {
                statusCode: 403,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: reason || 'Redemption not allowed'
                })
            };
        }
        
        // Record redemption
        const redemption = await recordRedemption(
            user_id,
            partner_id,
            discountAmount,
            transaction_id
        );
        
        console.log(`✅ [Lambda] Redemption recorded: ${redemption.redemption_id}`);
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                redemption: redemption
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error recording redemption:', error);
        
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

