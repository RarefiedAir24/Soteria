const { Client } = require('plaid');
const AWS = require('aws-sdk');

const client = new Client({
  clientID: process.env.PLAID_CLIENT_ID,
  secret: process.env.PLAID_SECRET,
  env: process.env.PLAID_ENV === 'production'
    ? require('plaid').environments.production
    : require('plaid').environments.sandbox,
});

const dynamodb = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.DYNAMODB_TABLE || 'rever-plaid-access-tokens';

exports.handler = async (event) => {
  console.log('💰 [Lambda] Processing transfer...');
  console.log('Event:', JSON.stringify(event, null, 2));
  
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'POST,OPTIONS',
    'Content-Type': 'application/json',
  };
  
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: '',
    };
  }
  
  try {
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    const { account_id, amount, user_id } = body;
    
    if (!account_id || !amount || !user_id) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'account_id, amount, and user_id are required' }),
      };
    }
    
    if (amount <= 0) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'amount must be greater than 0' }),
      };
    }
    
    // Retrieve access token from DynamoDB
    const result = await dynamodb.query({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'user_id = :uid AND account_id = :aid',
      ExpressionAttributeValues: {
        ':uid': user_id,
        ':aid': account_id,
      },
    }).promise();
    
    if (!result.Items || result.Items.length === 0) {
      return {
        statusCode: 404,
        headers,
        body: JSON.stringify({ error: 'Account not found for user' }),
      };
    }
    
    const accountData = result.Items[0];
    const accessToken = accountData.access_token; // TODO: Decrypt if encrypted
    
    // Create transfer authorization
    const authResponse = await client.transferAuthorizationCreate({
      access_token: accessToken,
      account_id: account_id,
      type: 'credit',
      network: 'ach',
      amount: amount.toFixed(2),
      ach_class: 'ppd',
      user: {
        legal_name: 'Rever User', // TODO: Get from user profile
      },
    });
    
    if (!authResponse.authorization.approved) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: 'Transfer not authorized',
          reason: authResponse.authorization.authorization_decision_rationale?.code,
        }),
      };
    }
    
    // Create the transfer
    const transferResponse = await client.transferCreate({
      idempotency_key: `rever-${user_id}-${account_id}-${Date.now()}`,
      access_token: accessToken,
      account_id: account_id,
      authorization_id: authResponse.authorization.id,
      type: 'credit',
      network: 'ach',
      amount: amount.toFixed(2),
      ach_class: 'ppd',
      user: {
        legal_name: 'Rever User', // TODO: Get from user profile
      },
      description: 'Rever savings transfer',
    });
    
    console.log('✅ [Lambda] Transfer created. Transfer ID:', transferResponse.transfer.id);
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        transfer_id: transferResponse.transfer.id,
        status: transferResponse.transfer.status,
        amount: amount,
        account_id: account_id,
      }),
    };
  } catch (error) {
    console.error('❌ [Lambda] Error processing transfer:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: error.message || 'Failed to process transfer',
        details: error.error_code || error.error_type || 'Unknown error',
      }),
    };
  }
};

