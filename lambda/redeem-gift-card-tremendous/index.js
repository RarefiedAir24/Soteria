/**
 * Lambda Function: Redeem Gift Card via Tremendous
 * 
 * Handles gift card redemption requests from Soteria iOS app
 * Integrates with Tremendous API to deliver real gift cards
 */

const https = require('https');
const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Environment configuration
const TREMENDOUS_API_KEY = process.env.TREMENDOUS_API_KEY;
const TREMENDOUS_ENV = process.env.TREMENDOUS_ENV || 'sandbox';
const TREMENDOUS_BASE_URL = TREMENDOUS_ENV === 'production' 
  ? 'api.tremendous.com'
  : 'testflight.tremendous.com';

const REDEMPTIONS_TABLE = process.env.REDEMPTIONS_TABLE || 'soteria-gift-card-redemptions';
const MONTHLY_CAPS_TABLE = process.env.MONTHLY_CAPS_TABLE || 'soteria-monthly-redemption-caps';

// Product mapping: Soteria gift card IDs → Tremendous product IDs
// ✅ CONFIRMED via API testing Jan 12, 2026
const PRODUCT_MAP = {
  // Amazon - Product ID: OKMHM2X2OHYV
  'amazon_5': 'OKMHM2X2OHYV',
  'amazon_10': 'OKMHM2X2OHYV',
  'amazon_25': 'OKMHM2X2OHYV',
  'amazon_50': 'OKMHM2X2OHYV',
  'amazon_100': 'OKMHM2X2OHYV',
  
  // Visa (Virtual) - Product ID: Q24BD9EZ332JT
  'visa_5': 'Q24BD9EZ332JT',
  'visa_10': 'Q24BD9EZ332JT',
  'visa_25': 'Q24BD9EZ332JT',
  'visa_50': 'Q24BD9EZ332JT',
  'visa_100': 'Q24BD9EZ332JT',
  
  // Target - Product ID: SRDHFATO9KHN
  'target_5': 'SRDHFATO9KHN',
  'target_10': 'SRDHFATO9KHN',
  'target_25': 'SRDHFATO9KHN',
  'target_50': 'SRDHFATO9KHN',
  'target_100': 'SRDHFATO9KHN',
  
  // Walmart - Product ID: DPIPLH0SRBO6
  'walmart_5': 'DPIPLH0SRBO6',
  'walmart_10': 'DPIPLH0SRBO6',
  'walmart_25': 'DPIPLH0SRBO6',
  'walmart_50': 'DPIPLH0SRBO6',
  'walmart_100': 'DPIPLH0SRBO6',
  
  // Starbucks - Product ID: 2XG0FLQXBDCZ
  'starbucks_5': '2XG0FLQXBDCZ',
  'starbucks_10': '2XG0FLQXBDCZ',
  'starbucks_25': '2XG0FLQXBDCZ'
};

/**
 * Main Lambda handler
 */
exports.handler = async (event) => {
  console.log('Redemption request received:', JSON.stringify(event, null, 2));
  
  try {
    // 1. Parse and validate request
    const body = JSON.parse(event.body);
    const { userId, giftCardId, pointsToSpend, email, brand, amount } = body;
    
    if (!userId || !giftCardId || !pointsToSpend || !email || !brand || !amount) {
      return errorResponse(400, 'Missing required fields');
    }
    
    // 2. Verify user from JWT token
    const userIdFromToken = event.requestContext?.authorizer?.claims?.sub;
    if (!userIdFromToken || userId !== userIdFromToken) {
      console.error('Auth mismatch:', { userId, userIdFromToken });
      return errorResponse(403, 'Unauthorized: User ID mismatch');
    }
    
    // 3. Verify Premium status
    // TODO: Implement checkPremiumStatus (query Cognito or DynamoDB)
    const isPremium = await checkPremiumStatus(userId);
    if (!isPremium) {
      console.warn('Non-premium user attempted redemption:', userId);
      return errorResponse(403, 'Premium subscription required');
    }
    
    // 4. Verify points balance
    // TODO: Implement getUserPoints (query DynamoDB user points)
    const userPoints = await getUserPoints(userId);
    if (userPoints < pointsToSpend) {
      console.warn('Insufficient points:', { userId, has: userPoints, needs: pointsToSpend });
      return errorResponse(400, `Insufficient points. Need ${pointsToSpend}, have ${userPoints}`);
    }
    
    // 5. Check monthly cap
    const monthlyCapResult = await checkMonthlyCapRemaining(userId, amount);
    if (!monthlyCapResult.allowed) {
      console.warn('Monthly cap exceeded:', { userId, amount, remaining: monthlyCapResult.remaining });
      return errorResponse(400, `Monthly cap exceeded. $${monthlyCapResult.remaining.toFixed(2)} remaining this month.`);
    }
    
    // 6. Get Tremendous product ID
    const tremendousProduct = PRODUCT_MAP[giftCardId];
    if (!tremendousProduct) {
      console.error('Unknown gift card ID:', giftCardId);
      return errorResponse(400, `Invalid gift card: ${giftCardId}`);
    }
    
    // 7. Create order in Tremendous
    console.log('Creating Tremendous order:', { giftCardId, amount, product: tremendousProduct });
    
    const tremendousOrder = await createTremendousOrder({
      externalId: `soteria-${userId}-${Date.now()}`,
      amount: amount,
      currency: 'USD',
      product: tremendousProduct,
      recipientEmail: email,
      recipientName: 'Soteria User'
    });
    
    console.log('Tremendous order created:', tremendousOrder.id);
    
    // 8. Log redemption to DynamoDB
    await logRedemption({
      redemptionId: tremendousOrder.reward.id,
      userId,
      giftCardId,
      brand,
      amount,
      pointsSpent: pointsToSpend,
      tremendousOrderId: tremendousOrder.id,
      rewardLink: tremendousOrder.reward.delivery.link,
      status: 'delivered',
      timestamp: new Date().toISOString()
    });
    
    // 9. Update monthly cap usage
    await incrementMonthlyCapUsage(userId, amount);
    
    // 10. Deduct points from user balance
    // TODO: Implement deductPoints (update DynamoDB user points)
    await deductPoints(userId, pointsToSpend);
    
    console.log('Redemption successful:', {
      userId,
      redemptionId: tremendousOrder.reward.id,
      amount
    });
    
    // 11. Return success
    return successResponse({
      success: true,
      redemptionId: tremendousOrder.reward.id,
      tremendousOrderId: tremendousOrder.id,
      rewardLink: tremendousOrder.reward.delivery.link,
      message: `$${amount} ${brand} gift card sent to ${email}!`
    });
    
  } catch (error) {
    console.error('Redemption error:', error);
    
    // Provide user-friendly error messages
    if (error.message.includes('Tremendous')) {
      return errorResponse(502, 'Gift card provider temporarily unavailable. Please try again.');
    }
    
    return errorResponse(500, `Internal error: ${error.message}`);
  }
};

/**
 * Call Tremendous API to create order
 */
async function createTremendousOrder({ externalId, amount, currency, product, recipientEmail, recipientName }) {
  const payload = {
    external_id: externalId,
    payment: {
      funding_source_id: 'BALANCE' // TODO: Confirm with Tremendous on Wednesday
    },
    reward: {
      value: {
        denomination: amount,
        currency_code: currency
      },
      delivery: {
        method: 'LINK'
      },
      recipient: {
        name: recipientName,
        email: recipientEmail
      },
      products: [product]
    }
  };
  
  const payloadStr = JSON.stringify(payload);
  
  const options = {
    hostname: TREMENDOUS_BASE_URL,
    path: '/api/v2/orders',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${TREMENDOUS_API_KEY}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payloadStr)
    }
  };
  
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', chunk => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log('Tremendous API response:', res.statusCode, data);
        
        if (res.statusCode === 200 || res.statusCode === 201) {
          try {
            const response = JSON.parse(data);
            resolve(response.order);
          } catch (e) {
            reject(new Error(`Failed to parse Tremendous response: ${e.message}`));
          }
        } else {
          reject(new Error(`Tremendous API error ${res.statusCode}: ${data}`));
        }
      });
    });
    
    req.on('error', (e) => {
      reject(new Error(`Tremendous request failed: ${e.message}`));
    });
    
    req.write(payloadStr);
    req.end();
  });
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
  console.log('Redemption logged to DynamoDB:', redemption.redemptionId);
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
  
  const result = await dynamodb.get(params).promise();
  
  // Get user's monthly cap (Premium = $250, Tier 2 = $500)
  // TODO: Look up user's subscription tier
  const monthlyCapLimit = 250; // Default Premium cap
  
  const currentUsage = result.Item?.totalRedeemed || 0;
  const remaining = monthlyCapLimit - currentUsage;
  
  return {
    allowed: requestedAmount <= remaining,
    remaining: remaining,
    used: currentUsage,
    limit: monthlyCapLimit
  };
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
  console.log('Monthly cap updated:', { userId, month, amount });
}

/**
 * Check Premium status
 * TODO: Implement based on your Cognito attributes or DynamoDB user table
 */
async function checkPremiumStatus(userId) {
  // PLACEHOLDER: Replace with actual Premium check
  // Option 1: Query Cognito custom attributes
  // Option 2: Query DynamoDB user subscription table
  // For now, return true to allow testing
  
  console.warn('checkPremiumStatus not fully implemented, returning true');
  return true;
}

/**
 * Get user's current points balance
 * TODO: Implement based on your DynamoDB user points table
 */
async function getUserPoints(userId) {
  // PLACEHOLDER: Replace with actual points lookup
  // Query DynamoDB table with user's points
  
  console.warn('getUserPoints not fully implemented, returning high value for testing');
  return 999999; // High value for testing
}

/**
 * Deduct points from user's balance
 * TODO: Implement based on your DynamoDB user points table
 */
async function deductPoints(userId, points) {
  // PLACEHOLDER: Replace with actual points deduction
  // Update DynamoDB to subtract points
  
  console.warn('deductPoints not fully implemented');
  return true;
}

/**
 * Helper: Success response
 */
function successResponse(data) {
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*' // Update with your actual domain
    },
    body: JSON.stringify(data)
  };
}

/**
 * Helper: Error response
 */
function errorResponse(statusCode, message) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*' // Update with your actual domain
    },
    body: JSON.stringify({ 
      error: message,
      timestamp: new Date().toISOString()
    })
  };
}
