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
const TABLE_NAME = process.env.DYNAMODB_TABLE || 'soteria-plaid-access-tokens';

exports.handler = async (event) => {
  console.log('💰 [Lambda] Getting account balance for Soteria...');
  console.log('Event:', JSON.stringify(event, null, 2));
  
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,OPTIONS',
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
    // Parse query parameters
    const userId = event.queryStringParameters?.user_id;
    const accountId = event.queryStringParameters?.account_id;
    
    if (!userId || !accountId) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'user_id and account_id are required' }),
      };
    }
    
    // Get access token from DynamoDB
    const result = await dynamodb.get({
      TableName: TABLE_NAME,
      Key: {
        user_id: userId,
        account_id: accountId,
      },
    }).promise();
    
    if (!result.Item || !result.Item.access_token) {
      return {
        statusCode: 404,
        headers,
        body: JSON.stringify({ error: 'Account not found' }),
      };
    }
    
    const accessToken = result.Item.access_token;
    
    // Get account balance from Plaid
    const accountsResponse = await client.getAccounts(accessToken);
    const account = accountsResponse.accounts.find(acc => acc.account_id === accountId);
    
    if (!account) {
      return {
        statusCode: 404,
        headers,
        body: JSON.stringify({ error: 'Account not found in Plaid' }),
      };
    }
    
    // Get balance (available balance, not current balance)
    const balance = account.balances.available ?? account.balances.current ?? 0;
    
    console.log('✅ [Lambda] Balance retrieved:', balance);
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        balance: balance,
        account_id: accountId,
      }),
    };
  } catch (error) {
    console.error('❌ [Lambda] Error getting balance:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: error.message || 'Failed to get balance',
        details: error.error_code || error.error_type || 'Unknown error',
      }),
    };
  }
};

