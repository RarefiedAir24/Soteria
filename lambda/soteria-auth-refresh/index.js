/**
 * Lambda function for refreshing Cognito tokens
 * 
 * Endpoint: POST /soteria/auth/refresh
 * 
 * Request body:
 * {
 *   "refreshToken": "..."
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "tokens": {
 *     "accessToken": "...",
 *     "idToken": "..."
 *   }
 * }
 */

const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

// These will be set via environment variables
const CLIENT_ID = process.env.CLIENT_ID;

exports.handler = async (event) => {
    console.log('📥 [Lambda] Token refresh request received');
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
        'Content-Type': 'application/json'
    };
    
    // Handle preflight
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
        const { refreshToken } = body;
        
        if (!refreshToken) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Refresh token is required'
                })
            };
        }
        
        // Refresh tokens with Cognito
        const refreshParams = {
            AuthFlow: 'REFRESH_TOKEN_AUTH',
            ClientId: CLIENT_ID,
            AuthParameters: {
                REFRESH_TOKEN: refreshToken
            }
        };
        
        const refreshResult = await cognito.initiateAuth(refreshParams).promise();
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                tokens: {
                    accessToken: refreshResult.AuthenticationResult.AccessToken,
                    idToken: refreshResult.AuthenticationResult.IdToken
                }
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Token refresh error:', error);
        
        let errorMessage = 'Token refresh failed';
        let statusCode = 401;
        
        if (error.code === 'NotAuthorizedException') {
            errorMessage = 'Invalid or expired refresh token';
        }
        
        return {
            statusCode,
            headers,
            body: JSON.stringify({
                success: false,
                error: errorMessage
            })
        };
    }
};

