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

const BUCKET_NAME = process.env.AVATAR_BUCKET_NAME || 'soteria-avatars-516141816050';
const REGION = process.env.AWS_REGION || 'us-east-1'; // AWS_REGION is automatically set by Lambda

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Avatar download request received');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Content-Type': 'application/json'
    };
    
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
        const userId = event.queryStringParameters?.user_id;
        
        if (!userId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'user_id query parameter is required'
                })
            };
        }
        
        // Generate S3 key (path) for avatar
        const s3Key = `avatars/${userId}.jpg`;
        
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
        console.error('❌ [Lambda] Avatar download error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Failed to download avatar'
            })
        };
    }
};

