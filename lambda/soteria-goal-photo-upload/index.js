/**
 * Lambda function to upload goal photo to S3
 * 
 * Endpoint: POST /soteria/goal-photo/upload
 * 
 * Request body (JSON):
 * {
 *   "user_id": "cognito_user_id",
 *   "goal_id": "goal_uuid",
 *   "photo_data": "base64_encoded_image_data",
 *   "content_type": "image/jpeg"
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "photo_url": "https://s3.amazonaws.com/bucket/goal-photos/user_id/goal_id.jpg"
 * }
 */

const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const crypto = require('crypto');
const { validateUserAccess, getCorsHeaders } = require('../auth-utils');

const BUCKET_NAME = process.env.GOAL_PHOTO_BUCKET_NAME || 'soteria-avatars-516141816050'; // Reuse avatar bucket
const REGION = process.env.AWS_REGION || 'us-east-1';

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Goal photo upload request received');
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
        const goalId = event.queryStringParameters?.goal_id;
        
        if (!requestedUserId || !goalId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Missing user_id or goal_id parameter'
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
        
        const photoData = body.photo_data;
        const contentType = body.content_type || 'image/jpeg';
        
        if (!photoData) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Missing photo_data in request body'
                })
            };
        }
        
        // Decode base64 image data
        let imageBuffer;
        try {
            imageBuffer = Buffer.from(photoData, 'base64');
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
                    error: 'Goal photo is too large (max 5MB)'
                })
            };
        }
        
        // Generate S3 key (path) for goal photo
        const s3Key = `goal-photos/${validatedUserId}/${goalId}.jpg`;
        
        // Upload to S3
        const uploadParams = {
            Bucket: BUCKET_NAME,
            Key: s3Key,
            Body: imageBuffer,
            ContentType: contentType,
            CacheControl: 'public, max-age=3600', // Cache for 1 hour
            Metadata: {
                'user_id': validatedUserId,
                'goal_id': goalId,
                'uploaded_at': new Date().toISOString()
            }
        };
        
        console.log(`📤 [Lambda] Uploading goal photo to S3: s3://${BUCKET_NAME}/${s3Key}`);
        const uploadResult = await s3.putObject(uploadParams).promise();
        
        console.log('✅ [Lambda] Goal photo uploaded successfully:', uploadResult.ETag);
        
        // Generate public URL (or presigned URL for private access)
        const photoUrl = `https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com/${s3Key}`;
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                photo_url: photoUrl,
                etag: uploadResult.ETag
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error uploading goal photo:', error);
        
        // Return appropriate status code based on error type
        let statusCode = 500;
        let errorMessage = 'An error occurred while uploading the goal photo';
        
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

