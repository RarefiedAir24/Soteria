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
const ACCESS_TOKEN_TABLE = process.env.DYNAMODB_TABLE || 'soteria-plaid-access-tokens';
const TRANSFER_TABLE = process.env.TRANSFER_TABLE || 'soteria-plaid-transfers';

exports.handler = async (event) => {
  console.log('💸 [Lambda] Initiating transfer for Soteria...');
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
    const { user_id, from_account_id, to_account_id, amount } = body;
    
    if (!user_id || !from_account_id || !to_account_id || !amount) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'user_id, from_account_id, to_account_id, and amount are required' }),
      };
    }
    
    if (amount <= 0) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Amount must be greater than 0' }),
      };
    }
    
    // Get access token from DynamoDB (use from_account_id to get the token)
    const result = await dynamodb.get({
      TableName: ACCESS_TOKEN_TABLE,
      Key: {
        user_id: user_id,
        account_id: from_account_id,
      },
    }).promise();
    
    if (!result.Item || !result.Item.access_token) {
      return {
        statusCode: 404,
        headers,
        body: JSON.stringify({ error: 'Source account not found' }),
      };
    }
    
    const accessToken = result.Item.access_token;
    
    // Check balance before transfer
    const accountsResponse = await client.getAccounts(accessToken);
    const fromAccount = accountsResponse.accounts.find(acc => acc.account_id === from_account_id);
    
    if (!fromAccount) {
      return {
        statusCode: 404,
        headers,
        body: JSON.stringify({ error: 'Source account not found in Plaid' }),
      };
    }
    
    const availableBalance = fromAccount.balances.available ?? fromAccount.balances.current ?? 0;
    
    if (availableBalance < amount) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Insufficient funds' }),
      };
    }
    
    // Create transfer authorization (required before initiating transfer)
    // Note: This is a simplified version - production should handle transfer authorization flow
    const transferAuthorization = await client.transferAuthorizationCreate({
      access_token: accessToken,
      account_id: from_account_id,
      type: 'debit', // Money leaving the account
      network: 'ach',
      amount: amount.toString(),
      ach_class: 'ppd', // Prearranged Payment and Deposit
      user: {
        legal_name: 'User', // TODO: Get from user profile
        email_address: 'user@example.com', // TODO: Get from user profile
      },
      description: 'Soteria Protection Savings',
    });
    
    if (!transferAuthorization.authorization_id) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({ error: 'Failed to create transfer authorization' }),
      };
    }
    
    // Create the transfer
    const transfer = await client.transferCreate({
      idempotency_key: `soteria-${user_id}-${Date.now()}`,
      access_token: accessToken,
      account_id: from_account_id,
      authorization_id: transferAuthorization.authorization_id,
      type: 'debit',
      network: 'ach',
      amount: amount.toString(),
      ach_class: 'ppd',
      description: 'Soteria Protection Savings',
    });
    
    console.log('✅ [Lambda] Transfer created:', transfer.transfer.id);
    
    // Store transfer record in DynamoDB
    await dynamodb.put({
      TableName: TRANSFER_TABLE,
      Item: {
        user_id: user_id,
        transfer_id: transfer.transfer.id,
        timestamp: new Date().toISOString(),
        from_account_id: from_account_id,
        to_account_id: to_account_id,
        amount: amount,
        status: transfer.transfer.status,
        created_at: new Date().toISOString(),
      },
    }).promise();
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        transfer_id: transfer.transfer.id,
        status: transfer.transfer.status,
        amount: amount,
      }),
    };
  } catch (error) {
    console.error('❌ [Lambda] Error initiating transfer:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: error.message || 'Failed to initiate transfer',
        details: error.error_code || error.error_type || 'Unknown error',
      }),
    };
  }
};

