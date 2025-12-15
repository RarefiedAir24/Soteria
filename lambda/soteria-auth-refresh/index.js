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
const crypto = require('crypto');
const cognito = new AWS.CognitoIdentityServiceProvider();

// These will be set via environment variables
const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;

// Helper function to compute SECRET_HASH for Cognito
// For refresh token, we need the username from the token
function computeSecretHash(username) {
    if (!CLIENT_SECRET) return undefined;
    const message = username + CLIENT_ID;
    return crypto.createHmac('sha256', CLIENT_SECRET).update(message).digest('base64');
}

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
        // Note: For refresh token auth, we need to decode the token to get username for SECRET_HASH
        // However, if client secret is not required, we can skip SECRET_HASH
        const refreshParams = {
            AuthFlow: 'REFRESH_TOKEN_AUTH',
            ClientId: CLIENT_ID,
            AuthParameters: {
                REFRESH_TOKEN: refreshToken
            }
        };
        
        // For refresh token, SECRET_HASH requires username, but we don't have it
        // If client has secret, we'll need to extract username from refresh token
        // For now, try without SECRET_HASH (some Cognito configs allow this)
        // If it fails, we'll need to decode the JWT token to get username
        
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

