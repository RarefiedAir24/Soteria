/**
 * Lambda function to delete all user data from DynamoDB and Cognito
 * 
 * Endpoint: POST /soteria/user/delete
 * 
 * Request body:
 * {
 *   "user_id": "cognito_user_id"
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "message": "User data deleted successfully"
 * }
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const cognito = new AWS.CognitoIdentityServiceProvider();
const { validateUserAccess, getCorsHeaders } = require('../auth-utils');

// All DynamoDB tables that store user data
const TABLES = [
    'soteria-user-data',
    'soteria-purchase-intents',
    'soteria-goals',
    'soteria-regrets',
    'soteria-moods',
    'soteria-quiet-hours',
    'soteria-app-usage',
    'soteria-unblock-events'
];

// Cognito User Pool ID (set as environment variable)
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID || 'us-east-1_XXXXXXXXX';

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Delete user data request received');
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
        // Get user_id from request body
        let requestedUserId;
        if (event.body) {
            const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
            requestedUserId = body.user_id;
        }
        
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
        
        console.log(`🗑️ [Lambda] Deleting all data for user: ${validatedUserId}`);
        
        // Delete from all DynamoDB tables
        const deletePromises = TABLES.map(tableName => deleteUserDataFromTable(tableName, validatedUserId));
        await Promise.all(deletePromises);
        
        console.log(`✅ [Lambda] Deleted data from all DynamoDB tables for user: ${validatedUserId}`);
        
        // Delete Cognito user account
        try {
            await cognito.adminDeleteUser({
                UserPoolId: USER_POOL_ID,
                Username: validatedUserId
            }).promise();
            console.log(`✅ [Lambda] Deleted Cognito user account: ${validatedUserId}`);
        } catch (cognitoError) {
            // Log error but don't fail - DynamoDB deletion is more important
            console.error(`⚠️ [Lambda] Failed to delete Cognito user: ${cognitoError.message}`);
            // Continue - DynamoDB data is deleted, which is the main goal
        }
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                message: 'User data deleted successfully'
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Delete user data error:', error);
        
        // Return appropriate status code based on error type
        let statusCode = 500;
        let errorMessage = 'Failed to delete user data';
        
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
            errorMessage = error.message || 'Failed to delete user data';
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

/**
 * Delete all items for a user from a DynamoDB table
 */
async function deleteUserDataFromTable(tableName, userId) {
    try {
        // First, query all items for this user
        const queryParams = {
            TableName: tableName,
            KeyConditionExpression: 'user_id = :userId',
            ExpressionAttributeValues: {
                ':userId': userId
            }
        };
        
        const items = [];
        let lastEvaluatedKey = null;
        
        // Paginate through all items
        do {
            if (lastEvaluatedKey) {
                queryParams.ExclusiveStartKey = lastEvaluatedKey;
            }
            
            const result = await dynamodb.query(queryParams).promise();
            items.push(...result.Items);
            lastEvaluatedKey = result.LastEvaluatedKey;
        } while (lastEvaluatedKey);
        
        console.log(`📊 [Lambda] Found ${items.length} items in ${tableName} for user ${userId}`);
        
        // Delete all items in batches (DynamoDB batch write limit is 25)
        const batchSize = 25;
        for (let i = 0; i < items.length; i += batchSize) {
            const batch = items.slice(i, i + batchSize);
            const deleteRequests = batch.map(item => {
                // Build delete request based on table structure
                const key = {
                    user_id: item.user_id
                };
                
                // Add sort key if it exists
                if (item.data_type) {
                    key.data_type = item.data_type;
                } else if (item.session_id) {
                    key.session_id = item.session_id;
                } else if (item.timestamp) {
                    key.timestamp = item.timestamp;
                } else if (item.goal_id) {
                    key.goal_id = item.goal_id;
                } else if (item.regret_id) {
                    key.regret_id = item.regret_id;
                } else if (item.entry_id) {
                    key.entry_id = item.entry_id;
                } else if (item.schedule_id) {
                    key.schedule_id = item.schedule_id;
                } else if (item.intent_id) {
                    key.intent_id = item.intent_id;
                }
                
                return {
                    DeleteRequest: {
                        Key: key
                    }
                };
            });
            
            await dynamodb.batchWrite({
                RequestItems: {
                    [tableName]: deleteRequests
                }
            }).promise();
        }
        
        console.log(`✅ [Lambda] Deleted ${items.length} items from ${tableName}`);
        
    } catch (error) {
        console.error(`❌ [Lambda] Error deleting from ${tableName}:`, error);
        throw error;
    }
}

