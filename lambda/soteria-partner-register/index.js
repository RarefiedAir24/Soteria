/**
 * Lambda function to register new partners
 * 
 * This function creates a new partner record in DynamoDB and generates
 * an API key for the partner.
 * 
 * Endpoint: POST /soteria/partner/register
 * 
 * Request Body:
 * {
 *   "name": "ACME Coffee",
 *   "description": "Premium coffee and pastries",
 *   "discount_percentage": 10,
 *   "discount_type": "percentage",  // or "fixed"
 *   "category": "Food & Beverage",
 *   "location": "New York, NY",
 *   "logo_url": "https://...",
 *   "terms": "Valid on all items. Cannot be combined with other offers.",
 *   "max_redemptions_per_user": 5,
 *   "valid_until": "2026-12-31T23:59:59Z",
 *   "contact_email": "partner@acme.com",
 *   "contact_phone": "+1-555-0123"
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "partner": {
 *     "partner_id": "partner-acme-coffee",
 *     "api_key": "sk_live_abc123...",
 *     "name": "ACME Coffee",
 *     ...
 *   }
 * }
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const crypto = require('crypto');

// DynamoDB table names
const TABLES = {
    partners: process.env.PARTNERS_TABLE || 'soteria-partners',
    apiKeys: process.env.API_KEYS_TABLE || 'soteria-partner-api-keys'
};

/**
 * Generate a unique partner ID from name
 */
function generatePartnerId(name) {
    // Convert to lowercase, replace spaces with hyphens, remove special chars
    const base = name
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-')
        .substring(0, 50);
    
    // Add random suffix to ensure uniqueness
    const suffix = crypto.randomBytes(4).toString('hex');
    return `partner-${base}-${suffix}`;
}

/**
 * Generate API key
 */
function generateApiKey() {
    // Generate a secure random API key
    const prefix = 'sk_live_';
    const randomBytes = crypto.randomBytes(32).toString('base64')
        .replace(/[^a-zA-Z0-9]/g, '')
        .substring(0, 40);
    return prefix + randomBytes;
}

/**
 * Create partner record
 */
async function createPartner(partnerData) {
    const partnerId = generatePartnerId(partnerData.name);
    const apiKey = generateApiKey();
    const now = new Date().toISOString();
    
    const partner = {
        partner_id: partnerId,
        name: partnerData.name,
        description: partnerData.description || '',
        discount_percentage: partnerData.discount_percentage || 0,
        discount_amount: partnerData.discount_amount || null,
        discount_type: partnerData.discount_type || 'percentage',
        category: partnerData.category || 'Other',
        location: partnerData.location || '',
        logo_url: partnerData.logo_url || null,
        terms: partnerData.terms || '',
        max_redemptions_per_user: partnerData.max_redemptions_per_user || null,
        valid_until: partnerData.valid_until || null,
        is_active: true,
        contact_email: partnerData.contact_email || null,
        contact_phone: partnerData.contact_phone || null,
        created_at: now,
        updated_at: now
    };
    
    // Save partner to DynamoDB
    await dynamodb.put({
        TableName: TABLES.partners,
        Item: partner
    }).promise();
    
    // Save API key (hashed)
    const hashedKey = crypto.createHash('sha256').update(apiKey).digest('hex');
    await dynamodb.put({
        TableName: TABLES.apiKeys,
        Item: {
            partner_id: partnerId,
            api_key_hash: hashedKey,
            created_at: now,
            last_used: null
        }
    }).promise();
    
    return {
        partner,
        apiKey // Return plain API key only once
    };
}

exports.handler = async (event) => {
    console.log('📝 [Lambda] Registering new partner...');
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
        let body;
        try {
            body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
        } catch (error) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Invalid JSON in request body'
                })
            };
        }
        
        // Validate required fields
        if (!body.name) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'name is required'
                })
            };
        }
        
        // Create partner
        const { partner, apiKey } = await createPartner(body);
        
        console.log(`✅ [Lambda] Partner registered: ${partner.partner_id}`);
        
        // Return partner with API key (only time it's returned in plain text)
        return {
            statusCode: 201,
            headers,
            body: JSON.stringify({
                success: true,
                partner: {
                    ...partner,
                    api_key: apiKey // Include API key in response
                },
                message: 'Partner registered successfully. Save your API key - it will not be shown again.'
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error registering partner:', error);
        
        // Check for duplicate partner name
        if (error.code === 'ConditionalCheckFailedException') {
            return {
                statusCode: 409,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Partner with this name already exists'
                })
            };
        }
        
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

