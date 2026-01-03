/**
 * Lambda function to generate and retrieve member numbers
 * 
 * This function generates unique member numbers for premium users
 * Format: SOT-XXXXXX (6-digit number)
 * 
 * Endpoint: GET /soteria/member-number?user_id={userId}
 * 
 * Response:
 * {
 *   "success": true,
 *   "member_number": "SOT-123456"
 * }
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const cognito = new AWS.CognitoIdentityServiceProvider();
const { validateUserAccess, getCorsHeaders } = require('../auth-utils');

// DynamoDB table names
const TABLES = {
    userData: process.env.USER_DATA_TABLE || 'soteria-user-data',
    memberNumbers: process.env.MEMBER_NUMBERS_TABLE || 'soteria-member-numbers'
};

/**
 * Generate a unique 6-digit member number
 */
async function generateMemberNumber() {
    let attempts = 0;
    const maxAttempts = 10;
    
    while (attempts < maxAttempts) {
        // Generate random 6-digit number (000001 to 999999)
        const number = Math.floor(Math.random() * 999999) + 1;
        const memberNumber = `SOT-${String(number).padStart(6, '0')}`;
        
        // Check if number already exists
        const exists = await checkMemberNumberExists(memberNumber);
        
        if (!exists) {
            return memberNumber;
        }
        
        attempts++;
    }
    
    // Fallback: Use timestamp-based number if all random attempts fail
    const timestamp = Date.now() % 1000000;
    return `SOT-${String(timestamp).padStart(6, '0')}`;
}

/**
 * Check if member number already exists
 */
async function checkMemberNumberExists(memberNumber) {
    try {
        const params = {
            TableName: TABLES.memberNumbers,
            Key: {
                member_number: memberNumber
            }
        };
        
        const result = await dynamodb.get(params).promise();
        return !!result.Item;
    } catch (error) {
        console.error('❌ [Lambda] Error checking member number:', error);
        return false;
    }
}

/**
 * Store member number mapping
 */
async function storeMemberNumber(userId, memberNumber) {
    try {
        // Store in member numbers table
        const params1 = {
            TableName: TABLES.memberNumbers,
            Item: {
                member_number: memberNumber,
                user_id: userId,
                created_at: new Date().toISOString()
            }
        };
        
        await dynamodb.put(params1).promise();
        
        // Also store in user data table for quick lookup
        const params2 = {
            TableName: TABLES.userData,
            Key: {
                user_id: userId,
                data_type: 'member_number'
            },
            UpdateExpression: 'SET #data = :data, updated_at = :updated_at',
            ExpressionAttributeNames: {
                '#data': 'data'
            },
            ExpressionAttributeValues: {
                ':data': {
                    member_number: memberNumber,
                    created_at: new Date().toISOString()
                },
                ':updated_at': new Date().toISOString()
            }
        };
        
        await dynamodb.update(params2).promise();
        
        console.log(`✅ [Lambda] Stored member number ${memberNumber} for user ${userId}`);
    } catch (error) {
        console.error('❌ [Lambda] Error storing member number:', error);
        throw error;
    }
}

/**
 * Get existing member number for user
 */
async function getMemberNumber(userId) {
    try {
        const params = {
            TableName: TABLES.userData,
            Key: {
                user_id: userId,
                data_type: 'member_number'
            }
        };
        
        const result = await dynamodb.get(params).promise();
        
        if (result.Item && result.Item.data && result.Item.data.member_number) {
            return result.Item.data.member_number;
        }
        
        return null;
    } catch (error) {
        console.error('❌ [Lambda] Error getting member number:', error);
        return null;
    }
}

/**
 * Check if user has premium subscription
 */
async function checkPremiumStatus(userId) {
    try {
        const params = {
            TableName: TABLES.userData,
            Key: {
                user_id: userId,
                data_type: 'subscription'
            }
        };
        
        const result = await dynamodb.get(params).promise();
        
        if (!result.Item) {
            return false;
        }
        
        const subscription = result.Item.data || {};
        const expiresAt = subscription.expires_at || subscription.expiresAt;
        const isExpired = expiresAt ? new Date(expiresAt) < new Date() : false;
        
        return subscription.is_premium === true && !isExpired;
    } catch (error) {
        console.error('❌ [Lambda] Error checking premium status:', error);
        return false;
    }
}

exports.handler = async (event) => {
    console.log('🔢 [Lambda] Getting/generating member number...');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    // CORS headers with restricted origin
    const headers = getCorsHeaders(event);
    
    // Handle OPTIONS request (CORS preflight)
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }
    
    try {
        // Get user_id from query parameters
        const requestedUserId = event.queryStringParameters?.user_id;
        
        if (!requestedUserId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'user_id is required'
                })
            };
        }
        
        // SECURITY: Validate that authenticated user matches requested user_id
        const authenticatedUserId = await validateUserAccess(event, requestedUserId);
        // Use authenticated user ID instead of request parameter
        const validatedUserId = authenticatedUserId;
        
        // Check if user is premium
        const isPremium = await checkPremiumStatus(validatedUserId);
        if (!isPremium) {
            return {
                statusCode: 403,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'User must have an active premium subscription to get a member number'
                })
            };
        }
        
        // Check if member number already exists
        let memberNumber = await getMemberNumber(validatedUserId);
        
        if (!memberNumber) {
            // Generate new member number
            memberNumber = await generateMemberNumber();
            
            // Store it
            await storeMemberNumber(validatedUserId, memberNumber);
            
            console.log(`✅ [Lambda] Generated new member number ${memberNumber} for user ${validatedUserId}`);
        } else {
            console.log(`✅ [Lambda] Retrieved existing member number ${memberNumber} for user ${validatedUserId}`);
        }
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                member_number: memberNumber
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error getting/generating member number:', error);
        
        // Return appropriate status code based on error type
        let statusCode = 500;
        let errorMessage = 'Internal server error';
        
        if (error.message === 'Missing Authorization header' || 
            error.message.includes('Invalid Authorization') ||
            error.message.includes('Empty token')) {
            statusCode = 401;
            errorMessage = 'Unauthorized';
        } else if (error.message.includes('Forbidden') || 
                   error.message.includes('Cannot access')) {
            statusCode = 403;
            errorMessage = 'Forbidden';
        } else {
            errorMessage = error.message || 'Internal server error';
        }
        
        return {
            statusCode: statusCode,
            headers: getCorsHeaders(event),
            body: JSON.stringify({
                success: false,
                error: errorMessage
            })
        };
    }
};

