/**
 * Lambda function to sync user data to DynamoDB
 * 
 * Endpoint: POST /soteria/sync
 * 
 * Request body:
 * {
 *   "user_id": "firebase_user_id",
 *   "data_type": "app_names|purchase_intents|goals|regrets|moods|quiet_hours|app_usage|unblock_events",
 *   "data": { ... } // The actual data to store
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "message": "Data synced successfully"
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
    console.log('📥 [Lambda] Sync request received:', JSON.stringify(event));
    
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
        // Parse request body
        const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
        const { user_id, data_type, data } = body;
        
        // Validate input
        if (!user_id || !data_type || !data) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Missing required fields: user_id, data_type, and data are required'
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
        
        // Prepare DynamoDB item
        const timestamp = Date.now();
        const item = {
            user_id: validatedUserId,
            [sortKeyName]: data_type === 'app_names' ? 'app_names' : (data.id || data.timestamp || timestamp.toString()),
            data: data,
            updated_at: timestamp,
            created_at: data.created_at || timestamp
        };
        
        // Save to DynamoDB
        await dynamodb.put({
            TableName: tableName,
            Item: item
        }).promise();
        
        console.log(`✅ [Lambda] Data synced successfully for user ${validatedUserId}, type ${data_type}`);
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                message: 'Data synced successfully',
                timestamp: timestamp
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error syncing data:', error);
        
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

