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
  console.log('🔄 [Lambda] Exchanging public token for Soteria...');
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
    const { public_token, user_id } = body;
    
    if (!public_token || !user_id) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'public_token and user_id are required' }),
      };
    }
    
    // Exchange public token for access token
    const exchangeResponse = await client.exchangePublicToken(public_token);
    const { access_token, item_id } = exchangeResponse;
    
    console.log('✅ [Lambda] Token exchanged. Item ID:', item_id);
    
    // Get account information
    const accountsResponse = await client.getAccounts(access_token);
    const accounts = accountsResponse.accounts;
    
    // Get institution information
    let institutionName = 'Bank';
    try {
      const itemResponse = await client.getItem(access_token);
      if (itemResponse.item.institution_id) {
        const institutionResponse = await client.getInstitutionById(
          itemResponse.item.institution_id,
          ['US']
        );
        institutionName = institutionResponse.institution.name;
      }
    } catch (err) {
      console.warn('⚠️ [Lambda] Could not fetch institution name:', err.message);
    }
    
    // Store access token in DynamoDB (encrypted in production)
    // Table schema: user_id (HASH), account_id (RANGE)
    for (const account of accounts) {
      await dynamodb.put({
        TableName: TABLE_NAME,
        Item: {
          user_id: user_id,
          account_id: account.account_id, // Range key
          item_id: item_id,
          access_token: access_token, // TODO: Encrypt this in production
          institution_name: institutionName,
          account_name: account.name,
          account_type: account.type,
          account_subtype: account.subtype,
          mask: account.mask,
          created_at: new Date().toISOString(),
        },
      }).promise();
    }
    
    console.log('✅ [Lambda] Access token stored in DynamoDB');
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        access_token: access_token,
        item_id: item_id,
        accounts: accounts.map(acc => ({
          account_id: acc.account_id,
          name: acc.name,
          mask: acc.mask,
          type: acc.type,
          subtype: acc.subtype,
        })),
        institution_name: institutionName,
      }),
    };
  } catch (error) {
    console.error('❌ [Lambda] Error exchanging token:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: error.message || 'Failed to exchange token',
        details: error.error_code || error.error_type || 'Unknown error',
      }),
    };
  }
};

