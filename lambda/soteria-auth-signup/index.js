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
const crypto = require('crypto');
const cognito = new AWS.CognitoIdentityServiceProvider();
const dynamodb = new AWS.DynamoDB.DocumentClient();

// These will be set via environment variables
const USER_POOL_ID = process.env.USER_POOL_ID;
const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;

// Helper function to compute SECRET_HASH for Cognito
function computeSecretHash(username) {
    if (!CLIENT_SECRET) {
        throw new Error('CLIENT_SECRET is required but not set');
    }
    const message = username + CLIENT_ID;
    return crypto.createHmac('sha256', CLIENT_SECRET).update(message).digest('base64');
}

exports.handler = async (event) => {
    console.log('📥 [Lambda] Sign up request received');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
        'Content-Type': 'application/json'
    };
    
    // Handle preflight
    if (event.httpMethod === 'OPTIONS' || (event.requestContext && event.requestContext.http && event.requestContext.http.method === 'OPTIONS')) {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }
    
    try {
        // Parse request body - handle both API Gateway v1 and v2 formats
        let body;
        if (event.body) {
            body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
        } else {
            body = event;
        }
        
        console.log('📥 [Lambda] Parsed body:', JSON.stringify(body, null, 2));
        const { email, password, isTestFlight } = body; // Check if signup is from TestFlight
        
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
        const username = email.toLowerCase().trim();
        const signUpParams = {
            ClientId: CLIENT_ID,
            Username: username,
            Password: password,
            UserAttributes: [
                {
                    Name: 'email',
                    Value: username
                }
            ]
        };
        
        // Add SECRET_HASH if client secret is configured
        if (CLIENT_SECRET && CLIENT_SECRET !== '') {
            try {
                signUpParams.SecretHash = computeSecretHash(username);
                console.log('✅ [Lambda] SECRET_HASH computed');
            } catch (error) {
                console.error('❌ [Lambda] Failed to compute SECRET_HASH:', error);
                throw error;
            }
        } else {
            console.log('⚠️ [Lambda] No CLIENT_SECRET configured, skipping SECRET_HASH');
        }
        
        const signUpResult = await cognito.signUp(signUpParams).promise();
        
        // Track TestFlight signups and check if user is in first 100
        let isFirst100TestFlightUser = false;
        if (isTestFlight === true) {
            try {
                const counterKey = 'testflight_signup_counter';
                const counterTable = process.env.COUNTER_TABLE || 'soteria-counters';
                
                // Atomically increment counter and get new value
                const updateParams = {
                    TableName: counterTable,
                    Key: { counter_key: counterKey },
                    UpdateExpression: 'ADD #count :inc SET #updated = :now',
                    ExpressionAttributeNames: {
                        '#count': 'count',
                        '#updated': 'updated_at'
                    },
                    ExpressionAttributeValues: {
                        ':inc': 1,
                        ':now': new Date().toISOString()
                    },
                    ReturnValues: 'UPDATED_NEW'
                };
                
                // Try to update counter (create if doesn't exist)
                try {
                    const result = await dynamodb.update(updateParams).promise();
                    const newCount = result.Attributes.count;
                    console.log(`📊 [Lambda] TestFlight signup count: ${newCount}`);
                    
                    if (newCount <= 100) {
                        isFirst100TestFlightUser = true;
                        console.log(`✅ [Lambda] User is in first 100 TestFlight signups (${newCount}/100)`);
                    } else {
                        console.log(`⚠️ [Lambda] User is NOT in first 100 TestFlight signups (${newCount}/100)`);
                    }
                } catch (updateError) {
                    // If table doesn't exist or item doesn't exist, create it
                    if (updateError.code === 'ResourceNotFoundException' || updateError.code === 'ValidationException') {
                        console.log('⚠️ [Lambda] Counter table/item not found, creating...');
                        await dynamodb.put({
                            TableName: counterTable,
                            Item: {
                                counter_key: counterKey,
                                count: 1,
                                updated_at: new Date().toISOString()
                            }
                        }).promise();
                        isFirst100TestFlightUser = true; // First user gets it
                        console.log('✅ [Lambda] Created counter, user is first TestFlight signup');
                    } else {
                        console.error('❌ [Lambda] Error updating counter:', updateError);
                        // Continue without counter - don't fail signup
                    }
                }
            } catch (counterError) {
                console.error('❌ [Lambda] Error tracking TestFlight signup:', counterError);
                // Don't fail signup if counter fails
            }
        }
        
        // If user needs to confirm email, return confirmation required
        if (signUpResult.UserConfirmed === false) {
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    success: true,
                    requiresConfirmation: true,
                    message: 'User created. Please check your email for confirmation code.',
                    isFirst100TestFlightUser: isFirst100TestFlightUser
                })
            };
        }
        
        // If user is auto-confirmed, sign them in
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
                },
                isFirst100TestFlightUser: isFirst100TestFlightUser
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

