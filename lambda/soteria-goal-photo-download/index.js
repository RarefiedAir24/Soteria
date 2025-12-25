/**
 * Lambda function to download goal photo from S3
 * 
 * Endpoint: GET /soteria/goal-photo/download
 * 
 * Query parameters:
 * - user_id: Cognito user ID
 * - goal_id: Goal UUID
 * 
 * Response:
 * {
 *   "success": true,
 *   "photo_data": "base64_encoded_image_data"
 * }
 */

const AWS = require('aws-sdk');
const s3 = new AWS.S3();

const BUCKET_NAME = process.env.GOAL_PHOTO_BUCKET_NAME || 'soteria-avatars-516141816050'; // Reuse avatar bucket
const REGION = process.env.AWS_REGION || 'us-east-1';

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Goal photo download request received');
    
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
        
        // Generate S3 key (path) for goal photo
        const s3Key = `goal-photos/${userId}/${goalId}.jpg`;
        
        console.log(`📥 [Lambda] Downloading goal photo from S3: s3://${BUCKET_NAME}/${s3Key}`);
        
        // Download from S3
        const getObjectParams = {
            Bucket: BUCKET_NAME,
            Key: s3Key
        };
        
        try {
            const s3Object = await s3.getObject(getObjectParams).promise();
            const imageBuffer = s3Object.Body;
            const base64Data = imageBuffer.toString('base64');
            
            console.log('✅ [Lambda] Goal photo downloaded successfully');
            
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    success: true,
                    photo_data: base64Data,
                    content_type: s3Object.ContentType || 'image/jpeg'
                })
            };
        } catch (s3Error) {
            if (s3Error.code === 'NoSuchKey') {
                console.log('ℹ️ [Lambda] Goal photo not found in S3');
                return {
                    statusCode: 404,
                    headers,
                    body: JSON.stringify({
                        success: false,
                        error: 'Goal photo not found'
                    })
                };
            }
            throw s3Error;
        }
        
    } catch (error) {
        console.error('❌ [Lambda] Goal photo download error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Failed to download goal photo'
            })
        };
    }
};

