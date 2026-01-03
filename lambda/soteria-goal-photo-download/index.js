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
const { validateUserAccess, getCorsHeaders } = require('../auth-utils');

const BUCKET_NAME = process.env.GOAL_PHOTO_BUCKET_NAME || 'soteria-avatars-516141816050'; // Reuse avatar bucket
const REGION = process.env.AWS_REGION || 'us-east-1';

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Goal photo download request received');
    
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
        
        // Generate S3 key (path) for goal photo
        const s3Key = `goal-photos/${validatedUserId}/${goalId}.jpg`;
        
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
        console.error('❌ [Lambda] Error downloading goal photo:', error);
        
        // Return appropriate status code based on error type
        let statusCode = 500;
        let errorMessage = 'An error occurred while downloading the goal photo';
        
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

