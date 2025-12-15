/**
 * Lambda function for password reset with AWS Cognito
 * 
 * Endpoint: POST /soteria/auth/reset-password
 * 
 * Request body:
 * {
 *   "email": "user@example.com"
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "message": "Password reset email sent"
 * }
 */

const AWS = require('aws-sdk');
const crypto = require('crypto');
const cognito = new AWS.CognitoIdentityServiceProvider();

// These will be set via environment variables
const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;

// Helper function to compute SECRET_HASH for Cognito
function computeSecretHash(username) {
    if (!CLIENT_SECRET) return undefined;
    const message = username + CLIENT_ID;
    return crypto.createHmac('sha256', CLIENT_SECRET).update(message).digest('base64');
}

exports.handler = async (event) => {
    console.log('📥 [Lambda] Password reset request received');
    
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
        const { email } = body;
        
        if (!email) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Email is required'
                })
            };
        }
        
        // Initiate forgot password flow
        const username = email.toLowerCase().trim();
        const forgotPasswordParams = {
            ClientId: CLIENT_ID,
            Username: username
        };
        
        // Add SECRET_HASH if client secret is configured
        if (CLIENT_SECRET) {
            forgotPasswordParams.SecretHash = computeSecretHash(username);
        }
        
        await cognito.forgotPassword(forgotPasswordParams).promise();
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                message: 'Password reset email sent. Please check your inbox.'
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Password reset error:', error);
        
        let errorMessage = 'Password reset failed';
        let statusCode = 500;
        
        if (error.code === 'UserNotFoundException') {
            // Don't reveal if user exists - security best practice
            errorMessage = 'If an account exists with this email, a password reset link has been sent';
            statusCode = 200; // Return success even if user doesn't exist
        } else if (error.code === 'LimitExceededException') {
            errorMessage = 'Too many password reset attempts. Please try again later';
            statusCode = 429;
        } else if (error.code === 'InvalidParameterException') {
            errorMessage = 'Invalid email address';
            statusCode = 400;
        }
        
        return {
            statusCode,
            headers,
            body: JSON.stringify({
                success: statusCode === 200,
                message: errorMessage
            })
        };
    }
};

