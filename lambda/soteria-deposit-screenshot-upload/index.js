/**
 * Lambda function to upload deposit screenshot to S3
 * 
 * Endpoint: POST /soteria/deposit-screenshot/upload
 * 
 * Query parameters:
 * - user_id: Cognito user ID
 * - deposit_id: Deposit UUID
 * 
 * Request body (JSON):
 * {
 *   "image_data": "base64_encoded_image_data",
 *   "deposit_id": "deposit_uuid"
 * }
 * 
 * Response:
 * {
 *   "s3_url": "https://s3.amazonaws.com/bucket/deposit-screenshots/user_id/deposit_id.jpg"
 * }
 */

const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const crypto = require('crypto');
const { validateUserAccess, getCorsHeaders } = require('./auth-utils');

const BUCKET_NAME = process.env.DEPOSIT_SCREENSHOT_BUCKET_NAME || 'soteria-avatars-516141816050'; // Reuse avatar bucket
const REGION = process.env.AWS_REGION || 'us-east-1';

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Deposit screenshot upload request received');
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
        // Parse query parameters
        const requestedUserId = event.queryStringParameters?.user_id;
        const depositId = event.queryStringParameters?.deposit_id;
        
        if (!requestedUserId || !depositId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Missing user_id or deposit_id parameter'
                })
            };
        }
        
        // SECURITY: Validate that authenticated user matches requested user_id
        const authenticatedUserId = await validateUserAccess(event, requestedUserId);
        // Use authenticated user ID instead of request parameter
        const validatedUserId = authenticatedUserId;
        
        // Parse request body
        let body;
        try {
            body = JSON.parse(event.body);
        } catch (e) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Invalid JSON in request body'
                })
            };
        }
        
        const imageData = body.image_data;
        const contentType = 'image/jpeg'; // Screenshots are always JPEG
        
        if (!imageData) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Missing image_data in request body'
                })
            };
        }
        
        // Decode base64 image data
        let imageBuffer;
        try {
            imageBuffer = Buffer.from(imageData, 'base64');
        } catch (e) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Invalid base64 image data'
                })
            };
        }
        
        // Validate image size (max 5MB)
        const maxSize = 5 * 1024 * 1024; // 5MB
        if (imageBuffer.length > maxSize) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Screenshot is too large (max 5MB)'
                })
            };
        }
        
        // Generate S3 key (path) for deposit screenshot
        const s3Key = `deposit-screenshots/${validatedUserId}/${depositId}.jpg`;
        
        // Upload to S3
        const uploadParams = {
            Bucket: BUCKET_NAME,
            Key: s3Key,
            Body: imageBuffer,
            ContentType: contentType,
            CacheControl: 'public, max-age=3600', // Cache for 1 hour
            Metadata: {
                'user_id': validatedUserId,
                'deposit_id': depositId,
                'uploaded_at': new Date().toISOString()
            }
        };
        
        console.log(`📤 [Lambda] Uploading deposit screenshot to S3: s3://${BUCKET_NAME}/${s3Key}`);
        const uploadResult = await s3.putObject(uploadParams).promise();
        
        console.log('✅ [Lambda] Deposit screenshot uploaded successfully:', uploadResult.ETag);
        
        // Generate public URL (or presigned URL for private access)
        const s3Url = `https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com/${s3Key}`;
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                s3_url: s3Url,
                etag: uploadResult.ETag
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error uploading deposit screenshot:', error);
        
        // Return appropriate status code based on error type
        let statusCode = 500;
        let errorMessage = 'An error occurred while uploading the deposit screenshot';
        
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

