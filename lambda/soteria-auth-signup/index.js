/**
 * Lambda function for user sign up with AWS Cognito
 * 
 * Endpoint: POST /soteria/auth/signup
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
const cognito = new AWS.CognitoIdentityServiceProvider();

// These will be set via environment variables
const USER_POOL_ID = process.env.USER_POOL_ID;
const CLIENT_ID = process.env.CLIENT_ID;

exports.handler = async (event) => {
    console.log('📥 [Lambda] Sign up request received');
    
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
        
        // Validate password (Cognito will also validate, but we can add custom checks)
        if (password.length < 8) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Password must be at least 8 characters'
                })
            };
        }
        
        // Sign up user with Cognito
        const signUpParams = {
            ClientId: CLIENT_ID,
            Username: email.toLowerCase().trim(),
            Password: password,
            UserAttributes: [
                {
                    Name: 'email',
                    Value: email.toLowerCase().trim()
                }
            ]
        };
        
        const signUpResult = await cognito.signUp(signUpParams).promise();
        
        // If user needs to confirm email, return confirmation required
        if (signUpResult.UserConfirmed === false) {
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    success: true,
                    requiresConfirmation: true,
                    message: 'User created. Please check your email for confirmation code.'
                })
            };
        }
        
        // If user is auto-confirmed, sign them in
        const authParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: CLIENT_ID,
            AuthParameters: {
                USERNAME: email.toLowerCase().trim(),
                PASSWORD: password
            }
        };
        
        const authResult = await cognito.initiateAuth(authParams).promise();
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                tokens: {
                    accessToken: authResult.AuthenticationResult.AccessToken,
                    idToken: authResult.AuthenticationResult.IdToken,
                    refreshToken: authResult.AuthenticationResult.RefreshToken,
                    userId: signUpResult.UserSub,
                    email: email.toLowerCase().trim()
                }
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Sign up error:', error);
        
        let errorMessage = 'Sign up failed';
        let statusCode = 500;
        
        if (error.code === 'UsernameExistsException') {
            errorMessage = 'An account with this email already exists';
            statusCode = 409;
        } else if (error.code === 'InvalidPasswordException') {
            errorMessage = 'Password does not meet requirements';
            statusCode = 400;
        } else if (error.code === 'InvalidParameterException') {
            errorMessage = error.message || 'Invalid parameters';
            statusCode = 400;
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

