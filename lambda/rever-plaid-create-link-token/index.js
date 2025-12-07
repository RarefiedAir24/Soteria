const { Client } = require('plaid');

// Initialize Plaid client
const client = new Client({
  clientID: process.env.PLAID_CLIENT_ID,
  secret: process.env.PLAID_SECRET,
  env: process.env.PLAID_ENV === 'production' 
    ? require('plaid').environments.production
    : require('plaid').environments.sandbox,
});

exports.handler = async (event) => {
  console.log('🔗 [Lambda] Creating Plaid link token...');
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
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    const { user_id, client_name = 'Rever', products = ['auth', 'transactions'], country_codes = ['US'], language = 'en' } = body;
    
    if (!user_id) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'user_id is required' }),
      };
    }
    
    // Create link token
    const response = await client.createLinkToken({
      user: {
        client_user_id: user_id,
      },
      client_name: client_name,
      products: products,
      country_codes: country_codes,
      language: language,
    });
    
    console.log('✅ [Lambda] Link token created successfully');
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        link_token: response.link_token,
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

