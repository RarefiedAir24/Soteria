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

const BUCKET_NAME = process.env.GOAL_PHOTO_BUCKET_NAME || 'soteria-avatars-516141816050'; // Reuse avatar bucket
const REGION = process.env.AWS_REGION || 'us-east-1';

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Goal photo upload request received');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
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
        // Parse query parameters
        const userId = event.queryStringParameters?.user_id;
        const goalId = event.queryStringParameters?.goal_id;
        
        if (!userId || !goalId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Missing user_id or goal_id parameter'
                })
            };
        }
        
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
        const s3Key = `goal-photos/${userId}/${goalId}.jpg`;
        
        // Upload to S3
        const uploadParams = {
            Bucket: BUCKET_NAME,
            Key: s3Key,
            Body: imageBuffer,
            ContentType: contentType,
            CacheControl: 'public, max-age=3600', // Cache for 1 hour
            Metadata: {
                'user_id': userId,
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
        console.error('❌ [Lambda] Goal photo upload error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Failed to upload goal photo'
            })
        };
    }
};

