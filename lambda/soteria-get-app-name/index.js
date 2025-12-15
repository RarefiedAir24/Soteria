/**
 * Lambda function to get app name from ApplicationToken hash
 * 
 * This function maps ApplicationToken hashes to app names.
 * The hash is generated from the ApplicationToken on the client side.
 * 
 * Endpoint: POST /soteria/app-name
 * 
 * Request:
 * {
 *   "token_hashes": ["hash1", "hash2", ...]  // Array of token hashes
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "app_names": {
 *     "hash1": "Amazon",
 *     "hash2": "Uber Eats",
 *     ...
 *   }
 * }
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

// DynamoDB table name for app token mappings
const TABLE_NAME = process.env.APP_TOKEN_MAPPINGS_TABLE || 'soteria-app-token-mappings';

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Getting app names for token hashes...');
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
        // Parse request body
        const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
        const { token_hashes } = body;
        
        if (!token_hashes || !Array.isArray(token_hashes) || token_hashes.length === 0) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'token_hashes array is required'
                })
            };
        }
        
        console.log(`🔍 [Lambda] Looking up ${token_hashes.length} token hash(es)...`);
        
        // Batch get items from DynamoDB
        // DynamoDB BatchGetItem can handle up to 100 items
        const batchSize = 100;
        const appNames = {};
        
        for (let i = 0; i < token_hashes.length; i += batchSize) {
            const batch = token_hashes.slice(i, i + batchSize);
            
            // Prepare keys for batch get
            const keys = batch.map(hash => ({
                token_hash: hash
            }));
            
            const params = {
                RequestItems: {
                    [TABLE_NAME]: {
                        Keys: keys
                    }
                }
            };
            
            console.log(`🔍 [Lambda] Batch ${Math.floor(i / batchSize) + 1}: Looking up ${batch.length} hashes...`);
            
            const result = await dynamodb.batchGet(params).promise();
            
            // Process results
            if (result.Responses && result.Responses[TABLE_NAME]) {
                for (const item of result.Responses[TABLE_NAME]) {
                    appNames[item.token_hash] = item.app_name;
                    console.log(`✅ [Lambda] Found: ${item.token_hash} → ${item.app_name}`);
                }
            }
            
            // Handle unprocessed keys (retry if needed)
            if (result.UnprocessedKeys && result.UnprocessedKeys[TABLE_NAME]) {
                console.warn('⚠️ [Lambda] Some keys were unprocessed, retrying...');
                // In production, you might want to retry unprocessed keys
            }
        }
        
        // Log which hashes were not found
        const foundHashes = Object.keys(appNames);
        const notFoundHashes = token_hashes.filter(hash => !foundHashes.includes(hash));
        if (notFoundHashes.length > 0) {
            console.log(`⚠️ [Lambda] ${notFoundHashes.length} hash(es) not found in database:`, notFoundHashes);
        }
        
        console.log(`✅ [Lambda] Found ${foundHashes.length} out of ${token_hashes.length} app name(s)`);
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                app_names: appNames,
                found_count: foundHashes.length,
                total_requested: token_hashes.length
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error getting app names:', error);
        
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

