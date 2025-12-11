const { Configuration, PlaidApi, PlaidEnvironments } = require('plaid');

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
  console.log('🔗 [Lambda] Creating Plaid link token for Soteria...');
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
    // Parse request body
    // Note: 'balance' is NOT a valid product - use 'transactions' instead
    // Balance data is accessed via /accounts/get endpoint after linking
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    const { user_id, client_name = 'Soteria', products = ['auth', 'transactions'], country_codes = ['US'], language = 'en' } = body;
    
    if (!user_id) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'user_id is required' }),
      };
    }
    
    // Create link token request - Plaid SDK v21 format
    // According to Plaid Auth docs: https://plaid.com/docs/auth/
    // For mobile apps, the bundle ID is handled by LinkKit on the client side
    // ios_bundle_id is NOT a valid parameter for /link/token/create
    const linkTokenRequest = {
      user: {
        client_user_id: user_id,
      },
      client_name: client_name,
      products: products,
      country_codes: country_codes,
      language: language,
    };
    
    console.log('🔗 [Lambda] Creating link token with request:', JSON.stringify(linkTokenRequest, null, 2));
    console.log('🔗 [Lambda] Plaid environment:', process.env.PLAID_ENV || 'sandbox');
    console.log('🔗 [Lambda] Client ID:', process.env.PLAID_CLIENT_ID ? 'Set' : 'Missing');
    console.log('🔗 [Lambda] Secret:', process.env.PLAID_SECRET ? 'Set' : 'Missing');
    
    const response = await client.linkTokenCreate(linkTokenRequest);
    
    console.log('✅ [Lambda] Link token created successfully');
    console.log('🔗 [Lambda] Response:', JSON.stringify(response.data, null, 2));
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        link_token: response.data.link_token,
      }),
    };
  } catch (error) {
    console.error('❌ [Lambda] Error creating link token:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: error.message || 'Failed to create link token',
        details: error.error_code || error.error_type || 'Unknown error',
      }),
    };
  }
};

