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
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,OPTIONS',
        'Content-Type': 'application/json'
    };
    
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
                    user_id: user_id,
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
                    ':user_id': user_id
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
        
        console.log(`✅ [Lambda] Retrieved ${data.length} item(s) for user ${user_id}, type ${data_type}`);
        
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

