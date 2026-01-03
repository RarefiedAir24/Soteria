/**
 * Lambda function to download user avatar from S3
 * 
 * Endpoint: GET /soteria/avatar/download?user_id=xxx
 * 
 * Response:
 * {
 *   "success": true,
 *   "avatar_data": "base64_encoded_image_data",
 *   "content_type": "image/jpeg"
 * }
 * 
 * Or if avatar doesn't exist:
 * {
 *   "success": false,
 *   "error": "Avatar not found"
 * }
 */

const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const { validateUserAccess, getCorsHeaders } = require('../auth-utils');

const BUCKET_NAME = process.env.AVATAR_BUCKET_NAME || 'soteria-avatars-516141816050';
const REGION = process.env.AWS_REGION || 'us-east-1'; // AWS_REGION is automatically set by Lambda

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Avatar download request received');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    // CORS headers with restricted origin
    const headers = getCorsHeaders(event);
    
    // Handle OPTIONS request (CORS preflight)
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }
    
    try {
        // Get user_id from query parameters
        const requestedUserId = event.queryStringParameters?.user_id;
        
        if (!requestedUserId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'user_id query parameter is required'
                })
            };
        }
        
        // SECURITY: Validate that authenticated user matches requested user_id
        const authenticatedUserId = await validateUserAccess(event, requestedUserId);
        // Use authenticated user ID instead of request parameter
        const validatedUserId = authenticatedUserId;
        
        // Generate S3 key (path) for avatar
        const s3Key = `avatars/${validatedUserId}.jpg`;
        
        console.log(`📥 [Lambda] Downloading avatar from S3: s3://${BUCKET_NAME}/${s3Key}`);
        
        try {
            // Get object from S3
            const s3Object = await s3.getObject({
                Bucket: BUCKET_NAME,
                Key: s3Key
            }).promise();
            
            // Convert to base64
            const avatarData = s3Object.Body.toString('base64');
            const contentType = s3Object.ContentType || 'image/jpeg';
            
            console.log('✅ [Lambda] Avatar downloaded successfully');
            
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    success: true,
                    avatar_data: avatarData,
                    content_type: contentType,
                    size: s3Object.ContentLength
                })
            };
            
        } catch (s3Error) {
            if (s3Error.code === 'NoSuchKey' || s3Error.code === 'NotFound') {
                // Avatar doesn't exist - this is OK
                console.log('ℹ️ [Lambda] Avatar not found in S3 (this is OK)');
                return {
                    statusCode: 404,
                    headers,
                    body: JSON.stringify({
                        success: false,
                        error: 'Avatar not found'
                    })
                };
            } else {
                throw s3Error;
            }
        }
        
    } catch (error) {
        console.error('❌ [Lambda] Error downloading avatar:', error);
        
        // Return appropriate status code based on error type
        let statusCode = 500;
        let errorMessage = 'An error occurred while downloading the avatar';
        
        if (error.message === 'Missing Authorization header' || 
            error.message.includes('Invalid Authorization') ||
            error.message.includes('Empty token')) {
            statusCode = 401;
            errorMessage = 'Unauthorized';
        } else if (error.message.includes('Forbidden') || 
                   error.message.includes('Cannot access')) {
            statusCode = 403;
            errorMessage = 'Forbidden';
        }
        
        return {
            statusCode: statusCode,
            headers: getCorsHeaders(event),
            body: JSON.stringify({
                success: false,
                error: errorMessage
            })
        };
    }
};

