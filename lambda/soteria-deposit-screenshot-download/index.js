/**
 * Lambda function to download deposit screenshot from S3
 * 
 * Endpoint: GET /soteria/deposit-screenshot/download
 * 
 * Query parameters:
 * - user_id: Cognito user ID
 * - deposit_id: Deposit UUID
 * 
 * Response:
 * - 200: Image binary data (Content-Type: image/jpeg)
 * - 404: Screenshot not found
 */

const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const { validateUserAccess, getCorsHeaders } = require('./auth-utils');

const BUCKET_NAME = process.env.DEPOSIT_SCREENSHOT_BUCKET_NAME || 'soteria-avatars-516141816050'; // Reuse avatar bucket

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Deposit screenshot download request received');
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
        
        // Generate S3 key (path) for deposit screenshot
        const s3Key = `deposit-screenshots/${validatedUserId}/${depositId}.jpg`;
        
        console.log(`📥 [Lambda] Downloading deposit screenshot from S3: s3://${BUCKET_NAME}/${s3Key}`);
        
        // Download from S3
        const downloadParams = {
            Bucket: BUCKET_NAME,
            Key: s3Key
        };
        
        try {
            const s3Object = await s3.getObject(downloadParams).promise();
            
            console.log('✅ [Lambda] Deposit screenshot downloaded successfully');
            
            // Return image with proper content type
            return {
                statusCode: 200,
                headers: {
                    ...headers,
                    'Content-Type': 'image/jpeg',
                    'Cache-Control': 'public, max-age=3600'
                },
                body: s3Object.Body.toString('base64'),
                isBase64Encoded: true
            };
            
        } catch (s3Error) {
            if (s3Error.code === 'NoSuchKey' || s3Error.code === 'NotFound') {
                console.log('⚠️ [Lambda] Screenshot not found:', s3Key);
                return {
                    statusCode: 404,
                    headers,
                    body: JSON.stringify({
                        success: false,
                        error: 'Screenshot not found'
                    })
                };
            }
            throw s3Error;
        }
        
    } catch (error) {
        console.error('❌ [Lambda] Error downloading deposit screenshot:', error);
        
        // Return appropriate status code based on error type
        let statusCode = 500;
        let errorMessage = 'An error occurred while downloading the deposit screenshot';
        
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

