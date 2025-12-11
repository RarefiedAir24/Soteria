/**
 * Transfer Route
 * 
 * Endpoint: POST /soteria/plaid/transfer
 * 
 * Note: Transfer API requires special access from Plaid.
 * This route may not work in sandbox without proper setup.
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

router.post('/transfer', async (req, res, next) => {
  try {
    console.log('💸 [Local Dev] Initiating transfer...');
    
    const { user_id, amount, from_account_id, to_account_id, description } = req.body;
    
    if (!user_id || !amount || !from_account_id || !to_account_id) {
      return res.status(400).json({ 
        error: 'Missing required fields',
        required: ['user_id', 'amount', 'from_account_id', 'to_account_id']
      });
    }
    
    const accessToken = getAccessToken(user_id);
    
    if (!accessToken) {
      return res.status(404).json({ 
        error: 'No access token found',
        details: 'Please connect your account first'
      });
    }
    
    // Note: Transfer API implementation depends on Plaid Transfer product setup
    // This is a placeholder - actual implementation requires:
    // 1. Transfer product enabled in Plaid dashboard
    // 2. Transfer ID creation
    // 3. Transfer authorization
    // 4. Transfer submission
    
    console.log('⚠️ [Local Dev] Transfer API requires additional setup');
    console.log('   This endpoint is a placeholder');
    
    // For now, return a mock response
    res.json({
      transfer_id: `transfer-${Date.now()}`,
      status: 'pending',
      amount: amount,
      from_account_id: from_account_id,
      to_account_id: to_account_id,
      message: 'Transfer API requires Plaid Transfer product setup',
    });
  } catch (error) {
    console.error('❌ [Local Dev] Error initiating transfer:', error);
    next(error);
  }
});

module.exports = router;

