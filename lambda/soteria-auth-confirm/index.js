/**
 * Lambda function for confirming user signup with verification code
 * 
 * Endpoint: POST /soteria/auth/confirm
 * 
 * Request body:
 * {
 *   "email": "user@example.com",
 *   "confirmationCode": "123456"
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "message": "Email confirmed successfully"
 * }
 */

const AWS = require('aws-sdk');
const crypto = require('crypto');
const cognito = new AWS.CognitoIdentityServiceProvider();

const USER_POOL_ID = process.env.USER_POOL_ID;
const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;

function computeSecretHash(username) {
    if (!CLIENT_SECRET) {
        throw new Error('CLIENT_SECRET is required but not set');
    }
    const message = username + CLIENT_ID;
    return crypto.createHmac('sha256', CLIENT_SECRET).update(message).digest('base64');
}

exports.handler = async (event) => {
    console.log('📥 [Lambda] Confirm signup request received');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
        'Content-Type': 'application/json'
    };
    
    if (event.httpMethod === 'OPTIONS' || (event.requestContext && event.requestContext.http && event.requestContext.http.method === 'OPTIONS')) {
        return { statusCode: 200, headers, body: '' };
    }
    
    try {
        let body;
        if (event.body) {
            body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
        } else {
            body = event;
        }
        
        console.log('📥 [Lambda] Parsed body:', JSON.stringify(body, null, 2));
        const { email, confirmationCode } = body;
        
        if (!email || !confirmationCode) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Email and confirmation code are required'
                })
            };
        }
        
        const username = email.toLowerCase().trim();
        const confirmParams = {
            ClientId: CLIENT_ID,
            Username: username,
            ConfirmationCode: confirmationCode
        };
        
        if (CLIENT_SECRET && CLIENT_SECRET !== '') {
            try {
                confirmParams.SecretHash = computeSecretHash(username);
                console.log('✅ [Lambda] SECRET_HASH computed');
            } catch (error) {
                console.error('❌ [Lambda] Failed to compute SECRET_HASH:', error);
                throw error;
            }
        } else {
            console.log('⚠️ [Lambda] No CLIENT_SECRET configured, skipping SECRET_HASH');
        }
        
        await cognito.confirmSignUp(confirmParams).promise();
        
        console.log('✅ [Lambda] User confirmed successfully');
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                message: 'Email confirmed successfully. You can now sign in.'
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Confirm signup error:', error);
        let errorMessage = 'Confirmation failed';
        let statusCode = 400;
        
        if (error.code === 'CodeMismatchException') {
            errorMessage = 'Invalid confirmation code. Please check your email and try again.';
        } else if (error.code === 'ExpiredCodeException') {
            errorMessage = 'Confirmation code has expired. Please request a new code.';
        } else if (error.code === 'UserNotFoundException') {
            errorMessage = 'No account found with this email';
            statusCode = 404;
        } else if (error.code === 'NotAuthorizedException') {
            errorMessage = 'User is already confirmed';
            statusCode = 409;
        } else if (error.code === 'InvalidParameterException') {
            errorMessage = error.message || 'Invalid parameters';
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

