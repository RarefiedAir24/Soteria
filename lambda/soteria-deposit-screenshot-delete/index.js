/**
 * Lambda function to delete deposit screenshot from S3
 * 
 * Endpoint: DELETE /soteria/deposit-screenshot/delete
 * 
 * Query parameters:
 * - user_id: Cognito user ID
 * - deposit_id: Deposit UUID
 * 
 * Response:
 * {
 *   "success": true
 * }
 */

const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const { validateUserAccess, getCorsHeaders } = require('./auth-utils');

const BUCKET_NAME = process.env.DEPOSIT_SCREENSHOT_BUCKET_NAME || 'soteria-avatars-516141816050'; // Reuse avatar bucket

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Deposit screenshot delete request received');
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
        
        console.log(`🗑️ [Lambda] Deleting deposit screenshot from S3: s3://${BUCKET_NAME}/${s3Key}`);
        
        // Delete from S3
        const deleteParams = {
            Bucket: BUCKET_NAME,
            Key: s3Key
        };
        
        try {
            await s3.deleteObject(deleteParams).promise();
            
            console.log('✅ [Lambda] Deposit screenshot deleted successfully');
            
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    success: true
                })
            };
            
        } catch (s3Error) {
            if (s3Error.code === 'NoSuchKey' || s3Error.code === 'NotFound') {
                // Screenshot doesn't exist - treat as success (idempotent)
                console.log('⚠️ [Lambda] Screenshot not found (already deleted):', s3Key);
                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({
                        success: true,
                        message: 'Screenshot not found (already deleted)'
                    })
                };
            }
            throw s3Error;
        }
        
    } catch (error) {
        console.error('❌ [Lambda] Error deleting deposit screenshot:', error);
        
        // Return appropriate status code based on error type
        let statusCode = 500;
        let errorMessage = 'An error occurred while deleting the deposit screenshot';
        
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

