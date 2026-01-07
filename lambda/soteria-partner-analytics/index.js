/**
 * Lambda function to get partner analytics
 * 
 * Returns redemption statistics and analytics for a partner.
 * 
 * Endpoint: GET /soteria/partner/analytics
 * 
 * Query Parameters:
 *   - partner_id (required)
 *   - start_date (optional) - ISO 8601 date
 *   - end_date (optional) - ISO 8601 date
 * 
 * Response:
 * {
 *   "success": true,
 *   "analytics": {
 *     "total_redemptions": 150,
 *     "total_discount_amount": 750.00,
 *     "unique_members": 45,
 *     "redemptions_by_day": [...],
 *     "top_members": [...]
 *   }
 * }
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

// DynamoDB table names
const TABLES = {
    partners: process.env.PARTNERS_TABLE || 'soteria-partners',
    redemptions: process.env.REDEMPTIONS_TABLE || 'soteria-partner-redemptions'
};

/**
 * Get partner analytics
 */
async function getPartnerAnalytics(partnerId, startDate, endDate) {
    // Query redemptions for this partner
    const params = {
        TableName: TABLES.redemptions,
        IndexName: 'partner_id-redeemed_at-index', // GSI
        KeyConditionExpression: 'partner_id = :partnerId',
        ExpressionAttributeValues: {
            ':partnerId': partnerId
        }
    };
    
    // Add date filter if provided
    if (startDate || endDate) {
        params.FilterExpression = '';
        if (startDate) {
            params.FilterExpression += 'redeemed_at >= :startDate';
            params.ExpressionAttributeValues[':startDate'] = startDate;
        }
        if (endDate) {
            if (params.FilterExpression) params.FilterExpression += ' AND ';
            params.FilterExpression += 'redeemed_at <= :endDate';
            params.ExpressionAttributeValues[':endDate'] = endDate;
        }
    }
    
    const result = await dynamodb.query(params).promise();
    const redemptions = result.Items || [];
    
    // Calculate statistics
    const totalRedemptions = redemptions.length;
    const totalDiscountAmount = redemptions.reduce((sum, r) => sum + (r.loyalty_amount || 0), 0);
    const uniqueMembers = new Set(redemptions.map(r => r.user_id)).size;
    
    // Group by day
    const redemptionsByDay = {};
    redemptions.forEach(r => {
        const date = r.redeemed_at.split('T')[0]; // Get date part
        redemptionsByDay[date] = (redemptionsByDay[date] || 0) + 1;
    });
    
    // Top members by redemption count
    const memberCounts = {};
    redemptions.forEach(r => {
        memberCounts[r.user_id] = (memberCounts[r.user_id] || 0) + 1;
    });
    const topMembers = Object.entries(memberCounts)
        .map(([userId, count]) => ({ user_id: userId, redemption_count: count }))
        .sort((a, b) => b.redemption_count - a.redemption_count)
        .slice(0, 10);
    
    return {
        total_redemptions: totalRedemptions,
        total_discount_amount: totalDiscountAmount,
        unique_members: uniqueMembers,
        average_discount_per_redemption: totalRedemptions > 0 ? totalDiscountAmount / totalRedemptions : 0,
        redemptions_by_day: Object.entries(redemptionsByDay)
            .map(([date, count]) => ({ date, count }))
            .sort((a, b) => a.date.localeCompare(b.date)),
        top_members: topMembers
    };
}

exports.handler = async (event) => {
    console.log('📊 [Lambda] Getting partner analytics...');
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Content-Type': 'application/json'
    };
    
    // Handle OPTIONS request
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }
    
    try {
        const queryParams = event.queryStringParameters || {};
        const partnerId = queryParams.partner_id;
        
        if (!partnerId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'partner_id is required'
                })
            };
        }
        
        const startDate = queryParams.start_date;
        const endDate = queryParams.end_date;
        
        const analytics = await getPartnerAnalytics(partnerId, startDate, endDate);
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                analytics
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error getting analytics:', error);
        
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

