/**
 * soteria-redeem-gift-card
 * 
 * AWS Lambda function to handle gift card redemptions via Tremendous API
 * 
 * Triggered by: API Gateway POST /redeem-gift-card
 * 
 * Flow:
 * 1. Verify user is authenticated (via Cognito)
 * 2. Check user has enough loyalty points in DynamoDB
 * 3. Call Tremendous API to send gift card
 * 4. Deduct points from user's balance
 * 5. Log redemption in DynamoDB
 * 6. Return redemption details
 */

const AWS = require('aws-sdk');
const https = require('https');

const dynamodb = new AWS.DynamoDB.DocumentClient();
const USER_DATA_TABLE = process.env.USER_DATA_TABLE || 'soteria-user-data';
const REDEMPTIONS_TABLE = process.env.REDEMPTIONS_TABLE || 'soteria-gift-card-redemptions';
const TREMENDOUS_API_KEY = process.env.TREMENDOUS_API_KEY;

exports.handler = async (event) => {
    console.log('🎁 Gift card redemption request:', JSON.stringify(event, null, 2));
    
    try {
        // Parse request body
        const body = JSON.parse(event.body || '{}');
        const { userId, giftCardId, pointsToSpend, email, brand, amount } = body;
        
        // Validate inputs
        if (!userId || !giftCardId || !pointsToSpend || !email || !brand || !amount) {
            return {
                statusCode: 400,
                headers: corsHeaders(),
                body: JSON.stringify({ 
                    error: 'Missing required fields',
                    required: ['userId', 'giftCardId', 'pointsToSpend', 'email', 'brand', 'amount']
                })
            };
        }
        
        // 1. Verify user authentication (from API Gateway authorizer)
        const authenticatedUserId = event.requestContext?.authorizer?.claims?.sub;
        if (authenticatedUserId && authenticatedUserId !== userId) {
            return {
                statusCode: 403,
                headers: corsHeaders(),
                body: JSON.stringify({ error: 'Unauthorized' })
            };
        }
        
        // 2. Get user's current loyalty points from DynamoDB
        const userPoints = await getUserLoyaltyPoints(userId);
        
        if (userPoints < pointsToSpend) {
            return {
                statusCode: 400,
                headers: corsHeaders(),
                body: JSON.stringify({ 
                    error: 'Insufficient points',
                    available: userPoints,
                    needed: pointsToSpend
                })
            };
        }
        
        // 3. Call Tremendous API to send gift card
        console.log(`📞 Calling Tremendous API for ${brand} $${amount} gift card to ${email}`);
        
        const tremendousResult = await sendGiftCardViaTremendous(
            email,
            amount,
            brand,
            giftCardId
        );
        
        console.log('✅ Tremendous API success:', tremendousResult);
        
        // 4. Deduct points from user's balance
        await deductLoyaltyPoints(userId, pointsToSpend);
        
        // 5. Log redemption in DynamoDB
        const redemptionId = tremendousResult.order?.id || `redemption-${Date.now()}`;
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
            email
        };
        
        await logRedemption(redemption);
        
        // 6. Return success
        return {
            statusCode: 200,
            headers: corsHeaders(),
            body: JSON.stringify({
                success: true,
                redemptionId,
                message: `Gift card sent to ${email}`,
                rewardLink: tremendousResult.reward?.link,
                tremendousOrderId: tremendousResult.order?.id
            })
        };
        
    } catch (error) {
        console.error('❌ Error redeeming gift card:', error);
        
        return {
            statusCode: 500,
            headers: corsHeaders(),
            body: JSON.stringify({ 
                error: 'Failed to redeem gift card',
                details: error.message
            })
        };
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
            dataType: 'loyalty'
        }
    };
    
    const result = await dynamodb.get(params).promise();
    
    if (!result.Item) {
        console.log(`⚠️ No loyalty data found for user ${userId}`);
        return 0;
    }
    
    return result.Item.points || 0;
}

/**
 * Deduct points from user's loyalty balance
 */
async function deductLoyaltyPoints(userId, points) {
    const params = {
        TableName: USER_DATA_TABLE,
        Key: {
            userId,
            dataType: 'loyalty'
        },
        UpdateExpression: 'SET points = points - :points, lastModified = :timestamp',
        ExpressionAttributeValues: {
            ':points': points,
            ':timestamp': new Date().toISOString()
        },
        ReturnValues: 'UPDATED_NEW'
    };
    
    const result = await dynamodb.update(params).promise();
    console.log(`💰 Deducted ${points} points from user ${userId}. New balance: ${result.Attributes.points}`);
    
    return result.Attributes.points;
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
async function sendGiftCardViaTremendous(email, amount, brand, giftCardId) {
    // Map gift card IDs to Tremendous campaign IDs
    const campaignMap = {
        'amazon_5': 'AMAZON5',
        'target_10': 'TARGET10',
        'starbucks_15': 'STARBUCKS15',
        'visa_25': 'VISA25'
    };
    
    const campaignId = campaignMap[giftCardId] || brand.toUpperCase();
    
    const payload = {
        payment: {
            funding_source_id: 'BALANCE' // Use your Tremendous account balance
        },
        reward: {
            value: {
                denomination: amount,
                currency_code: 'USD'
            },
            campaign_id: campaignId,
            delivery: {
                method: 'EMAIL',
                recipient: {
                    email: email,
                    name: 'Soteria Member'
                }
            }
        }
    };
    
    return new Promise((resolve, reject) => {
        const data = JSON.stringify(payload);
        
        const options = {
            hostname: 'api.tremendous.com',
            port: 443,
            path: '/api/v2/orders',
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${TREMENDOUS_API_KEY}`,
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };
        
        const req = https.request(options, (res) => {
            let body = '';
            
            res.on('data', (chunk) => {
                body += chunk;
            });
            
            res.on('end', () => {
                console.log(`📡 Tremendous API response (${res.statusCode}):`, body);
                
                if (res.statusCode === 200 || res.statusCode === 201) {
                    try {
                        const result = JSON.parse(body);
                        resolve(result);
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
 * CORS headers
 */
function corsHeaders() {
    return {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
    };
}
