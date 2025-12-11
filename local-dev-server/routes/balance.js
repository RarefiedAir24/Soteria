/**
 * Get Balance Route
 * 
 * Endpoint: POST /soteria/plaid/get-balance
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

router.post('/get-balance', async (req, res, next) => {
  try {
    console.log('💰 [Local Dev] Getting balance...');
    
    const { user_id, account_id } = req.body;
    
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
    
    let account = null;
    
    if (account_id) {
      // Get specific account
      account = response.data.accounts.find(acc => acc.account_id === account_id);
      if (!account) {
        return res.status(404).json({ error: 'Account not found' });
      }
    } else {
      // Get first account (or savings account if available)
      account = response.data.accounts.find(acc => acc.subtype === 'savings') 
             || response.data.accounts[0];
    }
    
    if (!account) {
      return res.status(404).json({ error: 'No accounts found' });
    }
    
    const balance = {
      account_id: account.account_id,
      name: account.name,
      mask: account.mask,
      type: account.type,
      subtype: account.subtype,
      current: account.balances.current || 0,
      available: account.balances.available || 0,
      currency: account.balances.iso_currency_code || 'USD',
    };
    
    console.log(`✅ [Local Dev] Balance retrieved: $${balance.current}`);
    
    res.json({ balance });
  } catch (error) {
    console.error('❌ [Local Dev] Error getting balance:', error);
    next(error);
  }
});

module.exports = router;

