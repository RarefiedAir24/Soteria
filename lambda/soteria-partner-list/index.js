/**
 * Lambda function to list available partners
 * 
 * This function returns a list of all active partner businesses
 * offering loyalty benefits to Soteria premium members.
 * 
 * Endpoint: GET /soteria/partner/list
 * 
 * Query Parameters:
 *   - user_id (optional): Filter partners by user's redemption history
 *   - category (optional): Filter by partner category
 *   - location (optional): Filter by location/region
 * 
 * Response:
 * {
 *   "success": true,
 *   "partners": [
 *     {
 *       "partner_id": "partner-123",
 *       "name": "Coffee Shop",
 *       "description": "Premium coffee and pastries",
 *       "discount_percentage": 10,
 *       "discount_amount": null,
 *       "discount_type": "percentage",
 *       "logo_url": "https://...",
 *       "category": "Food & Beverage",
 *       "location": "New York, NY",
 *       "terms": "Valid on all items. Cannot be combined with other offers.",
 *       "max_redemptions_per_user": 5,
 *       "valid_until": "2024-12-31T23:59:59Z"
 *     }
 *   ]
 * }
 */

// Use AWS SDK v3 for Node.js 18+ runtime
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');

// Create DynamoDB client
const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(client);

// DynamoDB table names
const TABLES = {
    partners: process.env.PARTNERS_TABLE || 'soteria-partners',
    redemptions: process.env.REDEMPTIONS_TABLE || 'soteria-partner-redemptions'
};

/**
 * Get user's redemption count for a partner
 */
async function getUserRedemptionCount(userId, partnerId) {
    try {
        const params = {
            TableName: TABLES.redemptions,
            KeyConditionExpression: 'user_id = :userId',
            FilterExpression: 'partner_id = :partnerId',
            ExpressionAttributeValues: {
                ':userId': userId,
                ':partnerId': partnerId
            }
        };
        
        const result = await dynamodb.send(new QueryCommand(params));
        return result.Items ? result.Items.length : 0;
    } catch (error) {
        console.error('❌ [Lambda] Error getting redemption count:', error);
        return 0;
    }
}

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Listing partners...');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
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
        // Log headers for debugging
        console.log('📋 [Lambda] Headers:', JSON.stringify(event.headers || {}, null, 2));
        
        const queryParams = event.queryStringParameters || {};
        const userId = queryParams.user_id;
        const category = queryParams.category;
        const location = queryParams.location;
        
        // Scan partners table
        const params = {
            TableName: TABLES.partners
        };
        
        // Add filter for active partners only
        params.FilterExpression = 'is_active = :active';
        params.ExpressionAttributeValues = {
            ':active': true
        };
        
        // Add category filter if provided
        if (category) {
            params.FilterExpression += ' AND #category = :category';
            params.ExpressionAttributeNames = {
                '#category': 'category'
            };
            params.ExpressionAttributeValues[':category'] = category;
        }
        
        // Add location filter if provided
        if (location) {
            params.FilterExpression += ' AND contains(#location, :location)';
            if (!params.ExpressionAttributeNames) {
                params.ExpressionAttributeNames = {};
            }
            params.ExpressionAttributeNames['#location'] = 'location';
            params.ExpressionAttributeValues[':location'] = location;
        }
        
        console.log('📊 [Lambda] Scanning DynamoDB with params:', JSON.stringify(params, null, 2));
        const result = await dynamodb.send(new ScanCommand(params));
        console.log('📊 [Lambda] Scan result count:', result.Items?.length || 0);
        
        let partners = result.Items || [];
        
        // Enrich with user-specific data if userId provided
        if (userId) {
            const enrichedPartners = await Promise.all(
                partners.map(async (partner) => {
                    const redemptionCount = await getUserRedemptionCount(userId, partner.partner_id);
                    const maxRedemptions = partner.max_redemptions_per_user;
                    const canRedeem = !maxRedemptions || redemptionCount < maxRedemptions;
                    
                    return {
                        partner_id: partner.partner_id,
                        name: partner.name,
                        description: partner.description,
                        loyalty_percentage: partner.loyalty_percentage || partner.discount_percentage || 0,
                        loyalty_amount: partner.loyalty_amount || partner.discount_amount || null,
                        loyalty_type: partner.loyalty_type || partner.discount_type || 'percentage',
                        logo_url: partner.logo_url || null,
                        category: partner.category || 'Other',
                        location: partner.location || null,
                        terms: partner.terms || null,
                        max_redemptions_per_user: maxRedemptions,
                        valid_until: partner.valid_until || null,
                        is_active: partner.is_active !== false,
                        website: partner.website || null,
                        has_brick_and_mortar: partner.has_brick_and_mortar || null,
                        checkout_code: partner.checkout_code || null,
                        user_redemption_count: redemptionCount,
                        can_redeem: canRedeem
                    };
                })
            );
            
            partners = enrichedPartners;
        } else {
            // Format partners without user-specific data
            partners = partners.map(partner => ({
                partner_id: partner.partner_id,
                name: partner.name,
                description: partner.description,
                loyalty_percentage: partner.loyalty_percentage || partner.discount_percentage || 0,
                loyalty_amount: partner.loyalty_amount || partner.discount_amount || null,
                loyalty_type: partner.loyalty_type || partner.discount_type || 'percentage',
                logo_url: partner.logo_url || null,
                category: partner.category || 'Other',
                location: partner.location || null,
                terms: partner.terms || null,
                max_redemptions_per_user: partner.max_redemptions_per_user || null,
                valid_until: partner.valid_until || null,
                is_active: partner.is_active !== false,
                website: partner.website || null,
                has_brick_and_mortar: partner.has_brick_and_mortar || null,
                checkout_code: partner.checkout_code || null
            }));
        }
        
        // Sort by name
        partners.sort((a, b) => a.name.localeCompare(b.name));
        
        console.log(`✅ [Lambda] Found ${partners.length} active partners`);
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                partners: partners
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error listing partners:', error);
        console.error('❌ [Lambda] Error stack:', error.stack);
        console.error('❌ [Lambda] Error name:', error.name);
        console.error('❌ [Lambda] Error code:', error.code);
        
        // Return error in format that matches success response
        return {
            statusCode: 200, // Return 200 so API Gateway doesn't transform it
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Internal server error',
                partners: [] // Empty array on error
            })
        };
    }
};

