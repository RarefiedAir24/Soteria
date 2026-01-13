/**
 * soteria-redeem-gift-card
 * 
 * AWS Lambda function to handle gift card redemptions via Tremendous API
 * 
 * Triggered by: API Gateway POST /redeem-gift-card
 * 
 * Flow:
 * 1. Verify user is authenticated (via Cognito)
 * 2. Check user is Premium subscriber
 * 3. Check monthly redemption cap
 * 4. Check user has enough loyalty points in DynamoDB
 * 5. Call Tremendous API to send gift card (LINK delivery)
 * 6. Deduct points from user's balance
 * 7. Update monthly cap usage
 * 8. Log redemption in DynamoDB
 * 9. Return redemption details with reward link
 */

const AWS = require('aws-sdk');
const https = require('https');

const dynamodb = new AWS.DynamoDB.DocumentClient();

// Environment variables
const USER_DATA_TABLE = process.env.USER_DATA_TABLE || 'soteria-user-data';
const REDEMPTIONS_TABLE = process.env.REDEMPTIONS_TABLE || 'soteria-gift-card-redemptions';
const MONTHLY_CAPS_TABLE = process.env.MONTHLY_CAPS_TABLE || 'soteria-monthly-redemption-caps';
const TREMENDOUS_API_KEY = process.env.TREMENDOUS_API_KEY;
const TREMENDOUS_ENV = process.env.TREMENDOUS_ENV || 'sandbox';

// Tremendous API base URL
const TREMENDOUS_BASE_URL = TREMENDOUS_ENV === 'production' 
    ? 'api.tremendous.com'
    : 'testflight.tremendous.com';

// Product mapping: Soteria gift card IDs → Tremendous product IDs
// ✅ CONFIRMED via API testing Jan 12, 2026
const PRODUCT_MAP = {
    // Amazon
    'amazon_5': 'OKMHM2X2OHYV',
    'amazon_10': 'OKMHM2X2OHYV',
    'amazon_25': 'OKMHM2X2OHYV',
    'amazon_50': 'OKMHM2X2OHYV',
    'amazon_100': 'OKMHM2X2OHYV',
    
    // Visa (Virtual)
    'visa_5': 'Q24BD9EZ332JT',
    'visa_10': 'Q24BD9EZ332JT',
    'visa_25': 'Q24BD9EZ332JT',
    'visa_50': 'Q24BD9EZ332JT',
    'visa_100': 'Q24BD9EZ332JT',
    
    // Target
    'target_5': 'SRDHFATO9KHN',
    'target_10': 'SRDHFATO9KHN',
    'target_25': 'SRDHFATO9KHN',
    'target_50': 'SRDHFATO9KHN',
    'target_100': 'SRDHFATO9KHN',
    
    // Walmart
    'walmart_5': 'DPIPLH0SRBO6',
    'walmart_10': 'DPIPLH0SRBO6',
    'walmart_25': 'DPIPLH0SRBO6',
    'walmart_50': 'DPIPLH0SRBO6',
    'walmart_100': 'DPIPLH0SRBO6',
    
    // Starbucks
    'starbucks_5': '2XG0FLQXBDCZ',
    'starbucks_10': '2XG0FLQXBDCZ',
    'starbucks_25': '2XG0FLQXBDCZ'
};

// Monthly caps by subscription tier
const MONTHLY_CAPS = {
    'premium': 250,  // $250/month for Premium ($7.99/mo)
    'tier2': 500     // $500/month for Tier 2 ($14.99/mo)
};

exports.handler = async (event) => {
    console.log('🎁 Gift card redemption request:', JSON.stringify(event, null, 2));
    
    try {
        // Parse request body
        const body = JSON.parse(event.body || '{}');
        const { userId, giftCardId, pointsToSpend, email, brand, amount } = body;
        
        // Validate inputs
        if (!userId || !giftCardId || !pointsToSpend || !email || !brand || !amount) {
            return errorResponse(400, 'Missing required fields', {
                required: ['userId', 'giftCardId', 'pointsToSpend', 'email', 'brand', 'amount']
            });
        }
        
        // 1. Verify user authentication (from API Gateway Cognito authorizer)
        const authenticatedUserId = event.requestContext?.authorizer?.claims?.sub;
        if (authenticatedUserId && authenticatedUserId !== userId) {
            console.warn('🔒 Auth mismatch:', { expected: userId, got: authenticatedUserId });
            return errorResponse(403, 'Unauthorized: User ID mismatch');
        }
        
        // 2. Check Premium status
        const isPremium = await checkPremiumStatus(userId);
        if (!isPremium) {
            console.warn('🔒 Non-premium user attempted redemption:', userId);
            return errorResponse(403, 'Premium subscription required to redeem gift cards');
        }
        
        // 3. Check monthly redemption cap
        const capCheck = await checkMonthlyCapRemaining(userId, amount);
        if (!capCheck.allowed) {
            console.warn('🚫 Monthly cap exceeded:', { userId, amount, remaining: capCheck.remaining });
            return errorResponse(400, `Monthly redemption cap exceeded. $${capCheck.remaining.toFixed(2)} remaining this month.`);
        }
        
        // 4. Get user's current loyalty points from DynamoDB
        const userPoints = await getUserLoyaltyPoints(userId);
        
        if (userPoints < pointsToSpend) {
            console.warn('💰 Insufficient points:', { userId, has: userPoints, needs: pointsToSpend });
            return errorResponse(400, 'Insufficient points', {
                available: userPoints,
                needed: pointsToSpend
            });
        }
        
        // 5. Get Tremendous product ID
        const tremendousProductId = PRODUCT_MAP[giftCardId];
        if (!tremendousProductId) {
            console.error('❌ Unknown gift card ID:', giftCardId);
            return errorResponse(400, `Invalid gift card: ${giftCardId}`);
        }
        
        // 6. Call Tremendous API to send gift card
        console.log(`📞 Calling Tremendous API: ${brand} $${amount} → ${email}`);
        console.log(`   Product ID: ${tremendousProductId}`);
        console.log(`   External ID: soteria-${userId}-${Date.now()}`);
        
        const tremendousResult = await sendGiftCardViaTremendous({
            externalId: `soteria-${userId}-${Date.now()}`,
            amount,
            currency: 'USD',
            productId: tremendousProductId,
            recipientEmail: email,
            recipientName: 'Soteria Member'
        });
        
        console.log('✅ Tremendous API success:', {
            orderId: tremendousResult.order?.id,
            rewardId: tremendousResult.reward?.id,
            link: tremendousResult.reward?.link
        });
        
        // 7. Deduct points from user's balance
        const newBalance = await deductLoyaltyPoints(userId, pointsToSpend);
        console.log(`💰 Points deducted. New balance: ${newBalance}`);
        
        // 8. Update monthly cap usage
        await incrementMonthlyCapUsage(userId, amount);
        
        // 9. Log redemption in DynamoDB
        const redemptionId = tremendousResult.reward?.id || `redemption-${Date.now()}`;
        const redemption = {
            redemptionId,
            userId,
            giftCardId,
            brand,
            amount,
            pointsSpent: pointsToSpend,
            redemptionDate: new Date().toISOString(),
            rewardLink: tremendousResult.reward?.link,
            tremendousOrderId: tremendousResult.order?.id,
            status: 'delivered',
            email,
            timestamp: new Date().toISOString()
        };
        
        await logRedemption(redemption);
        
        // 10. Return success with reward link
        return successResponse({
            success: true,
            redemptionId,
            message: `$${amount} ${brand} gift card ready!`,
            rewardLink: tremendousResult.reward?.link,
            tremendousOrderId: tremendousResult.order?.id,
            newPointsBalance: newBalance
        });
        
    } catch (error) {
        console.error('❌ Error redeeming gift card:', error);
        
        // Provide user-friendly error messages
        if (error.message.includes('Tremendous')) {
            return errorResponse(502, 'Gift card provider temporarily unavailable. Please try again.');
        }
        
        return errorResponse(500, 'Failed to redeem gift card', {
            details: error.message
        });
    }
};

/**
 * Get user's current loyalty points from DynamoDB
 */
async function getUserLoyaltyPoints(userId) {
    const params = {
        TableName: USER_DATA_TABLE,
        Key: {
            userId,
            dataType: 'loyalty_points'
        }
    };
    
    try {
        const result = await dynamodb.get(params).promise();
        
        if (!result.Item) {
            console.log(`⚠️ No loyalty data found for user ${userId}, checking 'loyalty' dataType`);
            
            // Try alternate key (backward compatibility)
            const altParams = {
                TableName: USER_DATA_TABLE,
                Key: {
                    userId,
                    dataType: 'loyalty'
                }
            };
            const altResult = await dynamodb.get(altParams).promise();
            
            if (!altResult.Item) {
                console.log(`⚠️ No loyalty data found for user ${userId} in either format`);
                return 0;
            }
            
            return altResult.Item.points || altResult.Item.totalPoints || 0;
        }
        
        return result.Item.points || result.Item.totalPoints || 0;
    } catch (error) {
        console.error('❌ Error getting user points:', error);
        return 0;
    }
}

/**
 * Deduct points from user's loyalty balance
 */
async function deductLoyaltyPoints(userId, points) {
    // Try loyalty_points first (new format)
    const params = {
        TableName: USER_DATA_TABLE,
        Key: {
            userId,
            dataType: 'loyalty_points'
        },
        UpdateExpression: 'SET points = if_not_exists(points, :zero) - :points, lastModified = :timestamp',
        ExpressionAttributeValues: {
            ':points': points,
            ':zero': 0,
            ':timestamp': new Date().toISOString()
        },
        ReturnValues: 'ALL_NEW'
    };
    
    try {
        const result = await dynamodb.update(params).promise();
        const newBalance = result.Attributes.points || 0;
        console.log(`💰 Deducted ${points} points from user ${userId}. New balance: ${newBalance}`);
        return newBalance;
    } catch (error) {
        console.error('❌ Error deducting points:', error);
        
        // Try alternate format (backward compatibility)
        const altParams = {
            TableName: USER_DATA_TABLE,
            Key: {
                userId,
                dataType: 'loyalty'
            },
            UpdateExpression: 'SET points = if_not_exists(points, :zero) - :points, lastModified = :timestamp',
            ExpressionAttributeValues: {
                ':points': points,
                ':zero': 0,
                ':timestamp': new Date().toISOString()
            },
            ReturnValues: 'ALL_NEW'
        };
        
        const altResult = await dynamodb.update(altParams).promise();
        const newBalance = altResult.Attributes.points || 0;
        console.log(`💰 Deducted ${points} points (alt format) from user ${userId}. New balance: ${newBalance}`);
        return newBalance;
    }
}

/**
 * Check if user is a Premium subscriber
 */
async function checkPremiumStatus(userId) {
    const params = {
        TableName: USER_DATA_TABLE,
        Key: {
            userId,
            dataType: 'subscription'
        }
    };
    
    try {
        const result = await dynamodb.get(params).promise();
        
        if (!result.Item) {
            console.log(`⚠️ No subscription data for user ${userId}`);
            return false;
        }
        
        const isPremium = result.Item.isPremium || result.Item.status === 'active';
        const tier = result.Item.tier || 'free';
        
        console.log(`🔑 Premium check: ${userId} → ${isPremium ? 'Premium' : 'Free'} (tier: ${tier})`);
        
        return isPremium;
    } catch (error) {
        console.error('❌ Error checking premium status:', error);
        return false;
    }
}

/**
 * Check if user has enough monthly cap remaining
 */
async function checkMonthlyCapRemaining(userId, requestedAmount) {
    const month = new Date().toISOString().substring(0, 7); // e.g., "2026-01"
    
    const params = {
        TableName: MONTHLY_CAPS_TABLE,
        Key: { userId, month }
    };
    
    try {
        const result = await dynamodb.get(params).promise();
        
        // Get user's subscription tier to determine cap
        const tierParams = {
            TableName: USER_DATA_TABLE,
            Key: {
                userId,
                dataType: 'subscription'
            }
        };
        
        const tierResult = await dynamodb.get(tierParams).promise();
        const tier = tierResult.Item?.tier || 'premium';
        const monthlyCapLimit = MONTHLY_CAPS[tier] || MONTHLY_CAPS.premium;
        
        const currentUsage = result.Item?.totalRedeemed || 0;
        const remaining = monthlyCapLimit - currentUsage;
        
        console.log(`📊 Monthly cap check: ${userId} → Used: $${currentUsage}, Remaining: $${remaining}, Limit: $${monthlyCapLimit}`);
        
        return {
            allowed: requestedAmount <= remaining,
            remaining: remaining,
            used: currentUsage,
            limit: monthlyCapLimit
        };
    } catch (error) {
        console.error('❌ Error checking monthly cap:', error);
        // On error, default to allowing (fail open for better UX)
        return {
            allowed: true,
            remaining: MONTHLY_CAPS.premium,
            used: 0,
            limit: MONTHLY_CAPS.premium
        };
    }
}

/**
 * Increment user's monthly cap usage
 */
async function incrementMonthlyCapUsage(userId, amount) {
    const month = new Date().toISOString().substring(0, 7);
    
    const params = {
        TableName: MONTHLY_CAPS_TABLE,
        Key: { userId, month },
        UpdateExpression: 'ADD totalRedeemed :amount, redemptionCount :one SET lastUpdated = :now',
        ExpressionAttributeValues: {
            ':amount': amount,
            ':one': 1,
            ':now': new Date().toISOString()
        }
    };
    
    await dynamodb.update(params).promise();
    console.log(`📈 Updated monthly cap: ${userId} → +$${amount}`);
}

/**
 * Log redemption to DynamoDB
 */
async function logRedemption(redemption) {
    const params = {
        TableName: REDEMPTIONS_TABLE,
        Item: redemption
    };
    
    await dynamodb.put(params).promise();
    console.log(`📝 Logged redemption ${redemption.redemptionId} to DynamoDB`);
}

/**
 * Send gift card via Tremendous API
 */
async function sendGiftCardViaTremendous({ externalId, amount, currency, productId, recipientEmail, recipientName }) {
    const payload = {
        external_id: externalId,
        payment: {
            funding_source_id: 'BALANCE'
        },
        reward: {
            value: {
                denomination: amount,
                currency_code: currency
            },
            delivery: {
                method: 'LINK'  // ✅ LINK delivery for instant UX
            },
            recipient: {
                name: recipientName,
                email: recipientEmail
            },
            products: [productId]
        }
    };
    
    return new Promise((resolve, reject) => {
        const data = JSON.stringify(payload);
        
        const options = {
            hostname: TREMENDOUS_BASE_URL,
            port: 443,
            path: '/api/v2/orders',
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${TREMENDOUS_API_KEY}`,
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(data)
            }
        };
        
        const req = https.request(options, (res) => {
            let body = '';
            
            res.on('data', (chunk) => {
                body += chunk;
            });
            
            res.on('end', () => {
                console.log(`📡 Tremendous API response (${res.statusCode}):`, body.substring(0, 200));
                
                if (res.statusCode === 200 || res.statusCode === 201) {
                    try {
                        const result = JSON.parse(body);
                        
                        // Extract reward details
                        const reward = result.order?.rewards?.[0] || {};
                        
                        resolve({
                            order: result.order,
                            reward: {
                                id: reward.id,
                                link: reward.delivery?.link
                            }
                        });
                    } catch (parseError) {
                        reject(new Error(`Failed to parse Tremendous response: ${parseError.message}`));
                    }
                } else {
                    reject(new Error(`Tremendous API error (${res.statusCode}): ${body}`));
                }
            });
        });
        
        req.on('error', (error) => {
            console.error('❌ Tremendous API request error:', error);
            reject(error);
        });
        
        req.write(data);
        req.end();
    });
}

/**
 * Success response helper
 */
function successResponse(data) {
    return {
        statusCode: 200,
        headers: corsHeaders(),
        body: JSON.stringify(data)
    };
}

/**
 * Error response helper
 */
function errorResponse(statusCode, message, details = {}) {
    return {
        statusCode,
        headers: corsHeaders(),
        body: JSON.stringify({
            error: message,
            ...details,
            timestamp: new Date().toISOString()
        })
    };
}

/**
 * CORS headers
 */
function corsHeaders() {
    return {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
    };
}
