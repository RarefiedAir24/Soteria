/**
 * Create Link Token Route
 * 
 * Mimics: lambda/soteria-plaid-create-link-token/index.js
 * Endpoint: POST /soteria/plaid/create-link-token
 */

const express = require('express');
const router = express.Router();
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

router.post('/create-link-token', async (req, res, next) => {
  try {
    console.log('🔗 [Local Dev] Creating Plaid link token...');
    console.log('Request body:', JSON.stringify(req.body, null, 2));
    
    // Parse request body
    // Note: 'balance' is NOT a valid product - use 'transactions' instead
    // Balance data is accessed via /accounts/get endpoint after linking
    const { user_id, client_name = 'Soteria', products = ['auth', 'transactions'], country_codes = ['US'], language = 'en' } = req.body;
    
    if (!user_id) {
      return res.status(400).json({ error: 'user_id is required' });
    }
    
    // Validate Plaid credentials
    if (!process.env.PLAID_CLIENT_ID || !process.env.PLAID_SECRET) {
      console.error('❌ [Local Dev] Missing Plaid credentials in .env file');
      return res.status(500).json({ 
        error: 'Plaid credentials not configured',
        details: 'Please set PLAID_CLIENT_ID and PLAID_SECRET in .env file'
      });
    }
    
    // Create link token request - Plaid SDK v21 format
    // Note: For iOS apps, we don't include redirect_uri or webhook in the request
    // The bundle ID is handled by LinkKit on the client side
    // ios_bundle_id is NOT a valid parameter for /link/token/create
    const linkTokenRequest = {
      user: {
        client_user_id: user_id,
      },
      client_name: client_name,
      products: products,
      country_codes: country_codes,
      language: language,
      // Don't include redirect_uri or webhook for mobile apps
      // These cause "INVALID_CONFIGURATION" errors
    };
    
    // Log the exact request being sent for debugging
    console.log('🔗 [Local Dev] Creating link token with request:', JSON.stringify(linkTokenRequest, null, 2));
    console.log('🔗 [Local Dev] Request structure validation:');
    console.log('   - client_name:', linkTokenRequest.client_name);
    console.log('   - language:', linkTokenRequest.language);
    console.log('   - country_codes:', JSON.stringify(linkTokenRequest.country_codes));
    console.log('   - user.client_user_id:', linkTokenRequest.user?.client_user_id);
    console.log('   - products:', JSON.stringify(linkTokenRequest.products));
    console.log('🔗 [Local Dev] Plaid environment:', process.env.PLAID_ENV || 'sandbox');
    
    const response = await client.linkTokenCreate(linkTokenRequest);
    
    console.log('✅ [Local Dev] Link token created successfully');
    
    res.json({
      link_token: response.data.link_token,
    });
  } catch (error) {
    console.error('❌ [Local Dev] Error creating link token:', error);
    
    // Extract Plaid error details if available
    let errorMessage = error.message || 'Failed to create link token';
    let errorDetails = 'Unknown error';
    
    if (error.response && error.response.data) {
      const plaidError = error.response.data;
      errorMessage = plaidError.error_message || errorMessage;
      errorDetails = plaidError.error_code || plaidError.error_type || errorDetails;
      console.error('   Plaid Error Code:', plaidError.error_code);
      console.error('   Plaid Error Type:', plaidError.error_type);
      console.error('   Plaid Error Message:', plaidError.error_message);
    }
    
    res.status(500).json({
      error: errorMessage,
      details: errorDetails,
      full_error: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

module.exports = router;

