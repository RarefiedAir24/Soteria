/**
 * Lambda function for user sign in with AWS Cognito
 * 
 * Endpoint: POST /soteria/auth/signin
 * 
 * Request body:
 * {
 *   "email": "user@example.com",
 *   "password": "SecurePassword123!"
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "tokens": {
 *     "accessToken": "...",
 *     "idToken": "...",
 *     "refreshToken": "...",
 *     "userId": "cognito_user_id",
 *     "email": "user@example.com"
 *   }
 * }
 */

const AWS = require('aws-sdk');
const crypto = require('crypto');
const cognito = new AWS.CognitoIdentityServiceProvider();

// These will be set via environment variables
const USER_POOL_ID = process.env.USER_POOL_ID;
const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;

// Helper function to compute SECRET_HASH for Cognito
function computeSecretHash(username) {
    const message = username + CLIENT_ID;
    return crypto.createHmac('sha256', CLIENT_SECRET).update(message).digest('base64');
}

exports.handler = async (event) => {
    console.log('📥 [Lambda] Sign in request received');
    
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
        const { email, password } = body;
        
        if (!email || !password) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Email and password are required'
                })
            };
        }
        
        // Authenticate user with Cognito
        const username = email.toLowerCase().trim();
        const authParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: CLIENT_ID,
            AuthParameters: {
                USERNAME: username,
                PASSWORD: password
            }
        };
        
        // Add SECRET_HASH if client secret is configured
        if (CLIENT_SECRET) {
            authParams.AuthParameters.SECRET_HASH = computeSecretHash(username);
        }
        
        const authResult = await cognito.initiateAuth(authParams).promise();
        
        // Get user attributes to retrieve email
        const getUserParams = {
            AccessToken: authResult.AuthenticationResult.AccessToken
        };
        
        const userInfo = await cognito.getUser(getUserParams).promise();
        const emailAttr = userInfo.UserAttributes.find(attr => attr.Name === 'email');
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                tokens: {
                    accessToken: authResult.AuthenticationResult.AccessToken,
                    idToken: authResult.AuthenticationResult.IdToken,
                    refreshToken: authResult.AuthenticationResult.RefreshToken,
                    userId: userInfo.Username,
                    email: emailAttr ? emailAttr.Value : email.toLowerCase().trim()
                }
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Sign in error:', error);
        
        let errorMessage = 'Sign in failed';
        let statusCode = 401;
        
        if (error.code === 'NotAuthorizedException') {
            errorMessage = 'Invalid email or password';
        } else if (error.code === 'UserNotConfirmedException') {
            errorMessage = 'Please confirm your email address before signing in';
            statusCode = 403;
        } else if (error.code === 'UserNotFoundException') {
            errorMessage = 'No account found with this email';
        } else if (error.code === 'TooManyFailedAttemptsException') {
            errorMessage = 'Too many failed login attempts. Please try again later';
            statusCode = 429;
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

