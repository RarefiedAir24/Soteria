const { Configuration, PlaidApi, PlaidEnvironments } = require('plaid');
const { validateUserAccess } = require('./auth-utils');

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
    // Note: 'balance' is NOT a valid product - use 'transactions' instead
    // Balance data is accessed via /accounts/get endpoint after linking
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    const { user_id = userId, client_name = 'Soteria', products = ['auth', 'transactions'], country_codes = ['US'], language = 'en' } = body;
    
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
    console.log('🔗 [Lambda] Client ID:', process.env.PLAID_CLIENT_ID ? `${process.env.PLAID_CLIENT_ID.substring(0, 8)}...` : 'Missing');
    console.log('🔗 [Lambda] Secret:', process.env.PLAID_SECRET ? `Set (${process.env.PLAID_SECRET.length} chars)` : 'Missing');
    
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
    console.error('❌ [Lambda] Error stack:', error.stack);
    console.error('❌ [Lambda] Error response:', error.response?.data || 'No response data');
    
    // Extract Plaid-specific error details
    const plaidError = error.response?.data || {};
    const errorCode = plaidError.error_code || error.error_code || 'UNKNOWN_ERROR';
    const errorType = plaidError.error_type || error.error_type || 'API_ERROR';
    const errorMessage = plaidError.error_message || error.message || 'Failed to create link token';
    
    // Check for invalid credentials
    if (errorCode === 'INVALID_CLIENT_ID' || errorCode === 'INVALID_SECRET' || 
        errorMessage.toLowerCase().includes('invalid client') || 
        errorMessage.toLowerCase().includes('invalid secret')) {
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({
          error: 'Invalid Plaid credentials',
          error_code: errorCode,
          error_type: errorType,
          message: 'The Plaid Client ID or Secret is invalid. Please verify your credentials in the Plaid Dashboard.',
          details: {
            client_id_set: !!process.env.PLAID_CLIENT_ID,
            secret_set: !!process.env.PLAID_SECRET,
            secret_length: process.env.PLAID_SECRET?.length || 0,
            environment: process.env.PLAID_ENV || 'sandbox'
          }
        }),
      };
    }
    
    return {
      statusCode: error.response?.status || 500,
      headers,
      body: JSON.stringify({
        error: errorMessage,
        error_code: errorCode,
        error_type: errorType,
        details: plaidError,
      }),
    };
  }
};

