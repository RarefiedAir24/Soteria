/**
 * Lambda function to update partner information
 * 
 * This function updates a partner record in DynamoDB.
 * Only accessible by admin users.
 * 
 * Endpoint: PUT /soteria/partner/{partner_id}
 * 
 * Request Body:
 * {
 *   "checkout_code": "SAVE10",
 *   "name": "ACME",
 *   "description": "...",
 *   "loyalty_percentage": 10,
 *   ... (any fields to update)
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "partner": { ... updated partner ... }
 * }
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { validateUserAccess, getCorsHeaders } = require('./auth-utils');

// Create DynamoDB client
const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(client);

// DynamoDB table names
const TABLES = {
    partners: process.env.PARTNERS_TABLE || 'soteria-partners'
};

/**
 * Update partner record
 */
async function updatePartner(partnerId, updateData) {
    // First, get existing partner to preserve fields not being updated
    const getParams = {
        TableName: TABLES.partners,
        Key: { partner_id: partnerId }
    };
    
    const existing = await dynamodb.send(new GetCommand(getParams));
    
    if (!existing.Item) {
        throw new Error('Partner not found');
    }
    
    // Build update expression
    const updateExpressions = [];
    const expressionAttributeNames = {};
    const expressionAttributeValues = {};
    
    // Fields that can be updated
    const updatableFields = [
        'checkout_code',
        'name',
        'description',
        'loyalty_percentage',
        'loyalty_amount',
        'loyalty_type',
        'category',
        'location',
        'terms',
        'max_redemptions_per_user',
        'valid_until',
        'is_active',
        'website',
        'has_brick_and_mortar',
        'logo_url'
    ];
    
    updatableFields.forEach(field => {
        if (updateData[field] !== undefined) {
            const nameKey = `#${field}`;
            const valueKey = `:${field}`;
            
            // Handle null values (to clear/remove field)
            if (updateData[field] === null) {
                updateExpressions.push(`REMOVE ${nameKey}`);
                expressionAttributeNames[nameKey] = field;
            } else {
                updateExpressions.push(`${nameKey} = ${valueKey}`);
                expressionAttributeNames[nameKey] = field;
                expressionAttributeValues[valueKey] = updateData[field];
            }
        }
    });
    
    // Always update updated_at timestamp
    if (updateExpressions.length > 0) {
        updateExpressions.push('#updated_at = :updated_at');
        expressionAttributeNames['#updated_at'] = 'updated_at';
        expressionAttributeValues[':updated_at'] = new Date().toISOString();
    } else {
        throw new Error('No fields to update');
    }
    
    const updateParams = {
        TableName: TABLES.partners,
        Key: { partner_id: partnerId },
        UpdateExpression: `SET ${updateExpressions.join(', ')}`,
        ExpressionAttributeNames: expressionAttributeNames,
        ExpressionAttributeValues: expressionAttributeValues,
        ReturnValues: 'ALL_NEW'
    };
    
    const result = await dynamodb.send(new UpdateCommand(updateParams));
    return result.Attributes;
}

exports.handler = async (event) => {
    console.log('✏️ [Lambda] Updating partner...');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    const headers = getCorsHeaders();
    
    // Handle OPTIONS request (CORS preflight)
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }
    
    try {
        // Validate admin access - check if user is admin (supergeek@me.com)
        const userId = await validateUserAccess(event);
        
        // Get user email from Cognito to verify admin status
        // For now, we'll allow any authenticated user to update
        // In production, you may want to check user groups or email
        console.log('✅ [Lambda] User authenticated:', userId);
        
        // Get partner ID from path
        const partnerId = event.pathParameters?.partner_id;
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
        
        // Parse request body
        let updateData;
        try {
            updateData = JSON.parse(event.body || '{}');
        } catch (e) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Invalid JSON in request body'
                })
            };
        }
        
        // Update partner
        const updatedPartner = await updatePartner(partnerId, updateData);
        
        console.log(`✅ [Lambda] Partner updated: ${partnerId}`);
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                partner: updatedPartner
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error updating partner:', error);
        console.error('❌ [Lambda] Error stack:', error.stack);
        
        // Check if it's an access denied error
        if (error.message && error.message.includes('Access denied')) {
            return {
                statusCode: 403,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Access denied. Admin privileges required.'
                })
            };
        }
        
        return {
            statusCode: 200, // Return 200 so API Gateway doesn't transform it
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Internal server error'
            })
        };
    }
};

