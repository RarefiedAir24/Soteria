const { Client } = require('plaid');
const AWS = require('aws-sdk');
const { validateUserAccess } = require('../auth-utils');

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
  console.log('📋 [Lambda] Getting connected accounts...');
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
    // Validate user authentication
    const authResult = await validateUserAccess(event);
    if (!authResult.valid) {
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({ error: 'Unauthorized', details: authResult.error }),
      };
    }
    
    const userId = authResult.userId;
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    
    // Query DynamoDB for all accounts for this user
    const queryParams = {
      TableName: TABLE_NAME,
      KeyConditionExpression: 'user_id = :userId',
      ExpressionAttributeValues: {
        ':userId': userId,
      },
    };
    
    const result = await dynamodb.query(queryParams).promise();
    
    if (!result.Items || result.Items.length === 0) {
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          accounts: [],
          message: 'No connected accounts found',
        }),
      };
    }
    
    // Group accounts by item_id (same bank connection)
    const accountsByItem = {};
    for (const item of result.Items) {
      const itemId = item.item_id;
      if (!accountsByItem[itemId]) {
        accountsByItem[itemId] = {
          item_id: itemId,
          institution_name: item.institution_name || 'Bank',
          access_token: item.access_token,
          accounts: [],
        };
      }
      
      accountsByItem[itemId].accounts.push({
        account_id: item.account_id,
        name: item.account_name,
        mask: item.mask,
        type: item.account_type,
        subtype: item.account_subtype,
      });
    }
    
    // Flatten all accounts from all items
    const allAccounts = [];
    for (const itemData of Object.values(accountsByItem)) {
      allAccounts.push(...itemData.accounts);
    }
    
    console.log(`✅ [Lambda] Retrieved ${allAccounts.length} accounts for user ${userId}`);
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        accounts: allAccounts,
        items: Object.values(accountsByItem).map(item => ({
          item_id: item.item_id,
          institution_name: item.institution_name,
          account_count: item.accounts.length,
        })),
      }),
    };
  } catch (error) {
    console.error('❌ [Lambda] Error getting accounts:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: error.message || 'Failed to get accounts',
        details: error.error_code || error.error_type || 'Unknown error',
      }),
    };
  }
};

