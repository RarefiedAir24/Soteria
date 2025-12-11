#!/usr/bin/env node

/**
 * Local Development Server for Soteria Plaid Integration
 * 
 * This server mimics the AWS Lambda functions for local development.
 * It uses the same Plaid SDK and logic as the Lambda functions.
 * 
 * Usage:
 *   npm start          - Start server
 *   npm run dev        - Start with auto-reload (nodemon)
 * 
 * Server runs on: http://localhost:8000
 */

const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables from .env file
dotenv.config();

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(cors()); // Enable CORS for iOS app
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Soteria local dev server is running' });
});

// Import route handlers
const linkTokenRoutes = require('./routes/link-token');
const exchangeTokenRoutes = require('./routes/exchange-token');
const accountsRoutes = require('./routes/accounts');
const balanceRoutes = require('./routes/balance');
const transferRoutes = require('./routes/transfer');

// Mount routes
app.use('/soteria/plaid', linkTokenRoutes);
app.use('/soteria/plaid', exchangeTokenRoutes);
app.use('/soteria/plaid', accountsRoutes);
app.use('/soteria/plaid', balanceRoutes);
app.use('/soteria/plaid', transferRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ [Server] Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
    details: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found', path: req.path });
});

// Start server
app.listen(PORT, () => {
  console.log('');
  console.log('════════════════════════════════════════');
  console.log('🚀 Soteria Local Dev Server');
  console.log('════════════════════════════════════════');
  console.log(`📍 Server running on: http://localhost:${PORT}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log('');
  console.log('📡 Available endpoints:');
  console.log(`   POST /soteria/plaid/create-link-token`);
  console.log(`   POST /soteria/plaid/exchange-public-token`);
  console.log(`   POST /soteria/plaid/get-accounts`);
  console.log(`   POST /soteria/plaid/get-balance`);
  console.log(`   POST /soteria/plaid/transfer`);
  console.log('');
  console.log('💡 Tip: Update PlaidService.swift to use:');
  console.log(`   http://localhost:${PORT}`);
  console.log('════════════════════════════════════════');
  console.log('');
});

