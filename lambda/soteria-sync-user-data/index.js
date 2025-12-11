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
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
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
            user_id: user_id,
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
        
        console.log(`✅ [Lambda] Data synced successfully for user ${user_id}, type ${data_type}`);
        
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

