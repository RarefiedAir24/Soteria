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
        // Get user_id from request body
        let userId;
        if (event.body) {
            const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
            userId = body.user_id;
        }
        
        if (!userId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'user_id is required'
                })
            };
        }
        
        console.log(`🗑️ [Lambda] Deleting all data for user: ${userId}`);
        
        // Delete from all DynamoDB tables
        const deletePromises = TABLES.map(tableName => deleteUserDataFromTable(tableName, userId));
        await Promise.all(deletePromises);
        
        console.log(`✅ [Lambda] Deleted data from all DynamoDB tables for user: ${userId}`);
        
        // Delete Cognito user account
        try {
            await cognito.adminDeleteUser({
                UserPoolId: USER_POOL_ID,
                Username: userId
            }).promise();
            console.log(`✅ [Lambda] Deleted Cognito user account: ${userId}`);
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
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Failed to delete user data'
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

