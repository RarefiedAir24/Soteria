/**
 * Lambda function to delete goal photo from S3
 * 
 * Endpoint: DELETE /soteria/goal-photo/delete
 * 
 * Query parameters:
 * - user_id: Cognito user ID
 * - goal_id: Goal UUID
 * 
 * Response:
 * {
 *   "success": true
 * }
 */

const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const { validateUserAccess, getCorsHeaders } = require('../auth-utils');

const BUCKET_NAME = process.env.GOAL_PHOTO_BUCKET_NAME || 'soteria-avatars-516141816050'; // Reuse avatar bucket

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Goal photo delete request received');
    
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
        
        console.log(`🗑️ [Lambda] Deleting goal photo from S3: s3://${BUCKET_NAME}/${s3Key}`);
        
        // Delete from S3
        const deleteParams = {
            Bucket: BUCKET_NAME,
            Key: s3Key
        };
        
        try {
            await s3.deleteObject(deleteParams).promise();
            console.log('✅ [Lambda] Goal photo deleted successfully');
            
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    success: true
                })
            };
        } catch (s3Error) {
            if (s3Error.code === 'NoSuchKey') {
                console.log('ℹ️ [Lambda] Goal photo not found in S3 (already deleted)');
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
        console.error('❌ [Lambda] Error deleting goal photo:', error);
        
        // Return appropriate status code based on error type
        let statusCode = 500;
        let errorMessage = 'An error occurred while deleting the goal photo';
        
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

