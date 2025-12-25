/**
 * Lambda function to upload user avatar to S3
 * 
 * Endpoint: POST /soteria/avatar/upload
 * 
 * Request body (multipart/form-data or base64):
 * {
 *   "user_id": "cognito_user_id",
 *   "avatar_data": "base64_encoded_image_data" // Optional if using multipart
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "avatar_url": "https://s3.amazonaws.com/bucket/avatars/user_id.jpg"
 * }
 */

const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const crypto = require('crypto');

const BUCKET_NAME = process.env.AVATAR_BUCKET_NAME || 'soteria-avatars-516141816050';
const REGION = process.env.AWS_REGION || 'us-east-1'; // AWS_REGION is automatically set by Lambda

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Avatar upload request received');
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
        // Get user_id from query parameters or body
        const userId = event.queryStringParameters?.user_id || 
                      (event.body ? JSON.parse(event.body).user_id : null);
        
        if (!userId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'user_id is required'
                })
            };
        }
        
        // Get avatar data from body
        let avatarData;
        let contentType = 'image/jpeg';
        
        if (event.isBase64Encoded) {
            // Base64 encoded data
            const body = JSON.parse(event.body);
            avatarData = Buffer.from(body.avatar_data, 'base64');
            contentType = body.content_type || 'image/jpeg';
        } else {
            // Raw binary data (multipart/form-data)
            // For now, we'll expect base64 in JSON body
            const body = JSON.parse(event.body);
            if (body.avatar_data) {
                avatarData = Buffer.from(body.avatar_data, 'base64');
                contentType = body.content_type || 'image/jpeg';
            } else {
                return {
                    statusCode: 400,
                    headers,
                    body: JSON.stringify({
                        success: false,
                        error: 'avatar_data is required (base64 encoded)'
                    })
                };
            }
        }
        
        if (!avatarData || avatarData.length === 0) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'avatar_data is empty or invalid'
                })
            };
        }
        
        // Validate image size (max 5MB)
        const maxSize = 5 * 1024 * 1024; // 5MB
        if (avatarData.length > maxSize) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Avatar image is too large (max 5MB)'
                })
            };
        }
        
        // Generate S3 key (path) for avatar
        const s3Key = `avatars/${userId}.jpg`;
        
        // Upload to S3
        const uploadParams = {
            Bucket: BUCKET_NAME,
            Key: s3Key,
            Body: avatarData,
            ContentType: contentType,
            CacheControl: 'public, max-age=3600', // Cache for 1 hour
            Metadata: {
                'user_id': userId,
                'uploaded_at': new Date().toISOString()
            }
        };
        
        console.log(`📤 [Lambda] Uploading avatar to S3: s3://${BUCKET_NAME}/${s3Key}`);
        const uploadResult = await s3.putObject(uploadParams).promise();
        
        console.log('✅ [Lambda] Avatar uploaded successfully:', uploadResult.ETag);
        
        // Generate public URL (or presigned URL for private access)
        const avatarUrl = `https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com/${s3Key}`;
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                avatar_url: avatarUrl,
                etag: uploadResult.ETag
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Avatar upload error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Failed to upload avatar'
            })
        };
    }
};

