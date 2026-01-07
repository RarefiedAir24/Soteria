/**
 * Get Accounts Route
 * 
 * Endpoint: POST /soteria/plaid/get-accounts
 */

const express = require('express');
const router = express.Router();
const { Configuration, PlaidApi, PlaidEnvironments } = require('plaid');
const { getAccessToken } = require('./exchange-token');

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

router.post('/get-accounts', async (req, res, next) => {
  try {
    console.log('📋 [Local Dev] Getting accounts...');
    
    const { user_id } = req.body;
    
    if (!user_id) {
      return res.status(400).json({ error: 'user_id is required' });
    }
    
    const accessToken = getAccessToken(user_id);
    
    if (!accessToken) {
      return res.status(404).json({ 
        error: 'No access token found',
        details: 'Please connect your account first'
      });
    }
    
    const response = await client.accountsGet({
      access_token: accessToken,
    });
    
    const accounts = response.data.accounts.map(account => ({
      account_id: account.account_id, // Match Lambda format
      name: account.name,
      mask: account.mask,
      type: account.type,
      subtype: account.subtype,
      balance: account.balances.current || 0,
      available: account.balances.available || 0,
    }));
    
    console.log(`✅ [Local Dev] Retrieved ${accounts.length} accounts`);
    console.log(`📋 [Local Dev] Account format check - first account keys:`, Object.keys(accounts[0] || {}));
    console.log(`📋 [Local Dev] First account sample:`, accounts[0]);
    
    const responseData = {
      accounts: accounts,
      items: [{
        item_id: response.data.item.item_id,
        institution_id: response.data.item.institution_id,
        account_count: accounts.length,
      }],
    };
    
    console.log(`📤 [Local Dev] Sending response with ${accounts.length} accounts`);
    res.json(responseData);
  } catch (error) {
    console.error('❌ [Local Dev] Error getting accounts:', error);
    next(error);
  }
});

module.exports = router;

