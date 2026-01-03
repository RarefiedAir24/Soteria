/**
 * Lambda function to get user data from DynamoDB
 * 
 * Endpoint: GET /soteria/data
 * 
 * Query parameters:
 * - user_id: Firebase user ID (required)
 * - data_type: Type of data to retrieve (required)
 * - item_id: Specific item ID (optional, for single item retrieval)
 * 
 * Response:
 * {
 *   "success": true,
 *   "data": [ ... ] or { ... } // Array of items or single item
 * }
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const { validateUserAccess, getCorsHeaders } = require('../auth-utils');

// Table name based on data type
const TABLE_MAPPING = {
    'app_names': 'soteria-user-data',
    'purchase_intents': 'soteria-purchase-intents',
    'goals': 'soteria-goals',
    'regrets': 'soteria-regrets',
    'moods': 'soteria-moods',
    'quiet_hours': 'soteria-quiet-hours',
    'app_usage': 'soteria-app-usage',
    'unblock_events': 'soteria-unblock-events'
};

// Sort key mapping
const SORT_KEY_MAPPING = {
    'app_names': 'data_type',
    'purchase_intents': 'intent_id',
    'goals': 'goal_id',
    'regrets': 'regret_id',
    'moods': 'entry_id',
    'quiet_hours': 'schedule_id',
    'app_usage': 'session_id',
    'unblock_events': 'timestamp'
};

exports.handler = async (event) => {
    console.log('📥 [Lambda] Get request received:', JSON.stringify(event));
    
    // CORS headers with restricted origin
    const headers = getCorsHeaders(event);
    
    // Handle OPTIONS request for CORS
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ message: 'CORS preflight' })
        };
    }
    
    try {
        // Get query parameters
        const queryParams = event.queryStringParameters || {};
        const { user_id, data_type, item_id } = queryParams;
        
        // Validate input
        if (!user_id || !data_type) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Missing required parameters: user_id and data_type are required'
                })
            };
        }
        
        // SECURITY: Validate that authenticated user matches requested user_id
        const authenticatedUserId = await validateUserAccess(event, user_id);
        // Use authenticated user ID instead of request parameter
        const validatedUserId = authenticatedUserId;
        
        // Get table name
        const tableName = TABLE_MAPPING[data_type];
        if (!tableName) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: `Invalid data_type: ${data_type}. Valid types: ${Object.keys(TABLE_MAPPING).join(', ')}`
                })
            };
        }
        
        // Get sort key name
        const sortKeyName = SORT_KEY_MAPPING[data_type];
        
        let result;
        
        if (item_id) {
            // Get specific item
            const params = {
                TableName: tableName,
                Key: {
                    user_id: validatedUserId,
                    [sortKeyName]: item_id
                }
            };
            
            const response = await dynamodb.get(params).promise();
            result = response.Item ? [response.Item] : [];
            
        } else {
            // Get all items for this user and data type
            const params = {
                TableName: tableName,
                KeyConditionExpression: 'user_id = :user_id',
                ExpressionAttributeValues: {
                    ':user_id': validatedUserId
                }
            };
            
            // For app_names, filter by data_type
            if (data_type === 'app_names') {
                params.KeyConditionExpression = 'user_id = :user_id AND data_type = :data_type';
                params.ExpressionAttributeValues[':data_type'] = 'app_names';
            }
            
            const response = await dynamodb.query(params).promise();
            result = response.Items || [];
        }
        
        // Extract data field from items
        const data = result.map(item => item.data || item);
        
        console.log(`✅ [Lambda] Retrieved ${data.length} item(s) for user ${validatedUserId}, type ${data_type}`);
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                data: data_type === 'app_names' && data.length === 1 ? data[0] : data,
                count: data.length
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error getting data:', error);
        
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

