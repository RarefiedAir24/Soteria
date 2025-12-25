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

const BUCKET_NAME = process.env.GOAL_PHOTO_BUCKET_NAME || 'soteria-avatars-516141816050'; // Reuse avatar bucket

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Goal photo delete request received');
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'DELETE, OPTIONS',
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
        console.error('❌ [Lambda] Goal photo delete error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Failed to delete goal photo'
            })
        };
    }
};

