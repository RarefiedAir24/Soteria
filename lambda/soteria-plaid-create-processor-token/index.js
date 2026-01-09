/**
 * Lambda function to create a Plaid processor token for Unit
 * 
 * Endpoint: POST /soteria/plaid/create-processor-token
 * 
 * Request body:
 * {
 *   "access_token": "access-sandbox-...",
 *   "account_id": "BxBXxLj1m4HMXBm9WZZmCWVbPjX16EHwv99vp",
 *   "user_id": "cognito-user-id"
 * }
 * 
 * Response:
 * {
 *   "processor_token": "processor-sandbox-0asd1-a92nc",
 *   "account_id": "BxBXxLj1m4HMXBm9WZZmCWVbPjX16EHwv99vp"
 * }
 * 
 * Reference: https://plaid.com/docs/auth/partnerships/unit/
 */

const { Configuration, PlaidApi, PlaidEnvironments } = require('plaid');
const { validateUserAccess } = require('./auth-utils');
const AWS = require('aws-sdk');

const dynamodb = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.PLAID_ACCOUNTS_TABLE || 'soteria-plaid-accounts';

// Initialize Plaid client
const configuration = new Configuration({
  basePath: process.env.PLAID_ENV === 'production' 
    ? PlaidEnvironments.production
    : PlaidEnvironments.sandbox,
  baseOptions: {
    headers: {
      'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
      'PLAID-SECRET': process.env.PLAID_SECRET,
    },
  },
});

const client = new PlaidApi(configuration);

exports.handler = async (event) => {
  console.log('🔄 [Lambda] Creating Plaid processor token for Unit...');
  console.log('Event:', JSON.stringify(event, null, 2));
  
  // CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'POST,OPTIONS',
    'Content-Type': 'application/json',
  };
  
  // Handle OPTIONS request for CORS
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: '',
    };
  }
  
  try {
    // Validate authentication
    const authResult = await validateUserAccess(event);
    if (!authResult.valid) {
      console.error('❌ [Lambda] Authentication failed:', authResult.error);
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({ 
          error: 'Unauthorized',
          message: authResult.error 
        }),
      };
    }
    
    const userId = authResult.userId;
    console.log('✅ [Lambda] Authenticated user:', userId);
    
    // Parse request body
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    let { access_token, account_id, user_id = userId } = body;
    
    if (!account_id) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ 
          error: 'account_id is required' 
        }),
      };
    }
    
    // If access_token not provided, fetch from DynamoDB
    if (!access_token) {
      console.log('🔍 [Lambda] Fetching access_token from DynamoDB...');
      try {
        const result = await dynamodb.get({
          TableName: TABLE_NAME,
          Key: {
            user_id: user_id,
            account_id: account_id,
          },
        }).promise();
        
        if (!result.Item || !result.Item.access_token) {
          return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ 
              error: 'Access token not found. Please connect your bank account first.' 
            }),
          };
        }
        
        access_token = result.Item.access_token;
        console.log('✅ [Lambda] Access token retrieved from DynamoDB');
      } catch (error) {
        console.error('❌ [Lambda] Error fetching access token:', error);
        return {
          statusCode: 500,
          headers,
          body: JSON.stringify({ 
            error: 'Failed to retrieve access token' 
          }),
        };
      }
    }
    
    console.log('🔑 [Lambda] Creating processor token for account:', account_id);
    
    // Create processor token for Unit
    // Reference: https://plaid.com/docs/api/processors/#processortokencreate
    const request = {
      access_token: access_token,
      account_id: account_id,
      processor: 'unit', // Specify Unit as the processor
    };
    
    const response = await client.processorTokenCreate(request);
    const processorToken = response.data.processor_token;
    
    console.log('✅ [Lambda] Processor token created successfully');
    
    // Store processor token in DynamoDB for future reference
    await dynamodb.update({
      TableName: TABLE_NAME,
      Key: {
        user_id: user_id,
        account_id: account_id,
      },
      UpdateExpression: 'SET processor_token = :token, updated_at = :timestamp',
      ExpressionAttributeValues: {
        ':token': processorToken,
        ':timestamp': new Date().toISOString(),
      },
    }).promise();
    
    console.log('✅ [Lambda] Processor token stored in DynamoDB');
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        processor_token: processorToken,
        account_id: account_id,
        message: 'Processor token created successfully',
      }),
    };
  } catch (error) {
    console.error('❌ [Lambda] Error creating processor token:', error);
    
    // Handle Plaid API errors
    if (error.response) {
      const plaidError = error.response.data;
      console.error('Plaid API Error:', JSON.stringify(plaidError, null, 2));
      
      return {
        statusCode: error.response.status || 500,
        headers,
        body: JSON.stringify({
          error: plaidError.error_message || 'Failed to create processor token',
          error_code: plaidError.error_code,
          error_type: plaidError.error_type,
        }),
      };
    }
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: error.message || 'Failed to create processor token',
        details: error.error_code || error.error_type || 'Unknown error',
      }),
    };
  }
};
