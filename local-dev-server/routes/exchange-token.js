/**
 * Exchange Public Token Route
 * 
 * Mimics: lambda/soteria-plaid-exchange-token/index.js
 * Endpoint: POST /soteria/plaid/exchange-public-token
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

// In-memory storage for access tokens (for local dev only!)
// In production, these would be stored in DynamoDB
const accessTokens = new Map();

router.post('/exchange-public-token', async (req, res, next) => {
  try {
    console.log('🔄 [Local Dev] Exchanging public token...');
    
    const { public_token, user_id } = req.body;
    
    if (!public_token) {
      return res.status(400).json({ error: 'public_token is required' });
    }
    
    if (!user_id) {
      return res.status(400).json({ error: 'user_id is required' });
    }
    
    // Exchange public token for access token
    const exchangeRequest = {
      public_token: public_token,
    };
    
    const response = await client.itemPublicTokenExchange(exchangeRequest);
    
    const accessToken = response.data.access_token;
    const itemId = response.data.item_id;
    
    // Store access token (in production, this goes to DynamoDB)
    accessTokens.set(user_id, {
      access_token: accessToken,
      item_id: itemId,
      user_id: user_id,
      created_at: new Date().toISOString(),
    });
    
    console.log('✅ [Local Dev] Token exchanged successfully');
    console.log(`   Item ID: ${itemId}`);
    console.log(`   Access token stored for user: ${user_id}`);
    
    // Get account information
    const accountsResponse = await client.accountsGet({
      access_token: accessToken,
    });
    
    const accounts = accountsResponse.data.accounts.map(account => ({
      id: account.account_id,
      name: account.name,
      mask: account.mask,
      type: account.type,
      subtype: account.subtype,
      balance: account.balances.current || 0,
    }));
    
    res.json({
      access_token: accessToken,
      item_id: itemId,
      accounts: accounts,
    });
  } catch (error) {
    console.error('❌ [Local Dev] Error exchanging token:', error);
    next(error);
  }
});

// Helper function to get access token (used by other routes)
function getAccessToken(userId) {
  const stored = accessTokens.get(userId);
  return stored ? stored.access_token : null;
}

module.exports = router;
module.exports.getAccessToken = getAccessToken;

