/**
 * Lambda function to delete a partner
 * 
 * This function deletes a partner from the DynamoDB table.
 * Only accessible by admin users.
 * 
 * Endpoint: DELETE /soteria/partner/{partner_id}
 * 
 * Response:
 * {
 *   "success": true,
 *   "message": "Partner deleted successfully"
 * }
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, DeleteCommand } = require('@aws-sdk/lib-dynamodb');
const { validateUserAccess, getCorsHeaders } = require('./auth-utils');

// Create DynamoDB client
const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(client);

// DynamoDB table names
const TABLES = {
    partners: process.env.PARTNERS_TABLE || 'soteria-partners'
};

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Deleting partner...');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    // CORS headers
    const headers = getCorsHeaders(event);
    
    // Handle OPTIONS request (CORS preflight)
    if (event.httpMethod === 'OPTIONS' || event.requestContext?.http?.method === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }
    
    try {
        // Get user ID from token
        const userId = await validateUserAccess(event, null); // No specific user_id needed for admin
        
        // Extract partner_id from path parameters
        const partnerId = event.pathParameters?.partner_id || event.pathParameters?.partnerId;
        
        if (!partnerId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Partner ID is required'
                })
            };
        }
        
        // Delete partner from DynamoDB
        const params = {
            TableName: TABLES.partners,
            Key: {
                partner_id: partnerId
            }
        };
        
        console.log('🗑️ [Lambda] Deleting partner with params:', JSON.stringify(params, null, 2));
        await dynamodb.send(new DeleteCommand(params));
        
        console.log('✅ [Lambda] Partner deleted successfully');
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                message: 'Partner deleted successfully'
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error deleting partner:', error);
        console.error('❌ [Lambda] Error stack:', error.stack);
        
        // Return error in format that matches success response
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Internal server error'
            })
        };
    }
};

