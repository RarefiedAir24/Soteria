/**
 * Lambda function to handle root path requests for api.soteria.zone
 * Returns a helpful JSON response with API information
 */

exports.handler = async (event) => {
    console.log('📋 [Lambda] Root path request');
    
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
    
    // Return API information
    const response = {
        message: 'Soteria API',
        version: '1.0',
        documentation: 'https://api.soteria.zone',
        endpoints: {
            'List Partners': 'GET /soteria/partner/list',
            'Validate Member': 'POST /soteria/partner/validate-member',
            'Record Redemption': 'POST /soteria/partner/redeem',
            'Get Analytics': 'GET /soteria/partner/analytics',
            'Register Partner': 'POST /soteria/partner/register'
        },
        baseUrl: 'https://api.soteria.zone',
        support: 'partners@soteria.app'
    };
    
    return {
        statusCode: 200,
        headers,
        body: JSON.stringify(response, null, 2)
    };
};

