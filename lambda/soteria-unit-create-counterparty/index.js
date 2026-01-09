/**
 * Lambda function to create a Unit counterparty using Plaid processor token
 * 
 * Endpoint: POST /soteria/unit/create-counterparty
 * 
 * Request body:
 * {
 *   "processor_token": "processor-sandbox-0asd1-a92nc",
 *   "account_id": "unit-account-id",
 *   "customer_id": "unit-customer-id",
 *   "counterparty_name": "Chase Checking",
 *   "user_id": "cognito-user-id"
 * }
 * 
 * Response:
 * {
 *   "counterparty_id": "123456",
 *   "name": "Chase Checking",
 *   "routing_number": "021000021",
 *   "account_number": "****6789",
 *   "type": "Checking"
 * }
 * 
 * Reference: https://docs.unit.co/counterparties#create-counterparty-with-plaid-processor-token
 */

const AWS = require('aws-sdk');
const { validateUserAccess } = require('./auth-utils');
const https = require('https');

const dynamodb = new AWS.DynamoDB.DocumentClient();
const COUNTERPARTIES_TABLE = process.env.COUNTERPARTIES_TABLE || 'soteria-unit-counterparties';

// Unit API configuration
const UNIT_API_URL = process.env.UNIT_ENV === 'production'
  ? 'https://api.s.unit.sh'
  : 'https://api.s.unit.sh'; // Unit uses same URL for sandbox/production
const UNIT_API_TOKEN = process.env.UNIT_API_TOKEN;

/**
 * Make HTTP request to Unit API
 */
function makeUnitRequest(endpoint, method, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(endpoint, UNIT_API_URL);
    
    const options = {
      hostname: url.hostname,
      port: 443,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/vnd.api+json',
        'Authorization': `Bearer ${UNIT_API_TOKEN}`,
      },
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: data,
        });
      });
    });
    
    req.on('error', (error) => {
      reject(error);
    });
    
    if (body) {
      req.write(JSON.stringify(body));
    }
    
    req.end();
  });
}

exports.handler = async (event) => {
  console.log('🏦 [Lambda] Creating Unit counterparty with Plaid processor token...');
  
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
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    const { 
      processor_token, 
      account_id, 
      customer_id,
      counterparty_name = 'External Bank Account',
      user_id = userId 
    } = body;
    
    if (!processor_token || !account_id || !customer_id) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ 
          error: 'processor_token, account_id, and customer_id are required' 
        }),
      };
    }
    
    console.log('🔑 [Lambda] Creating counterparty for Unit account:', account_id);
    
    // Create counterparty with Plaid processor token
    // Reference: https://docs.unit.co/counterparties#create-counterparty-with-plaid-processor-token
    const unitRequest = {
      data: {
        type: 'achCounterparty',
        attributes: {
          name: counterparty_name,
          plaidProcessorToken: processor_token,
          verifyName: false, // Set to true in production
          permissions: 'DebitOnly', // Only allow pulling funds (not pushing)
        },
        relationships: {
          account: {
            data: {
              type: 'depositAccount',
              id: account_id,
            },
          },
          customer: {
            data: {
              type: 'customer',
              id: customer_id,
            },
          },
        },
      },
    };
    
    const response = await makeUnitRequest('/counterparties', 'POST', unitRequest);
    
    console.log('Unit API Response:', response.statusCode);
    
    if (response.statusCode !== 201) {
      const errorBody = JSON.parse(response.body);
      console.error('❌ [Lambda] Unit API error:', JSON.stringify(errorBody, null, 2));
      
      return {
        statusCode: response.statusCode,
        headers,
        body: JSON.stringify({
          error: 'Failed to create counterparty',
          details: errorBody,
        }),
      };
    }
    
    const responseData = JSON.parse(response.body);
    const counterpartyData = responseData.data;
    const counterpartyId = counterpartyData.id;
    const attributes = counterpartyData.attributes || {};
    
    console.log('✅ [Lambda] Counterparty created:', counterpartyId);
    
    // Store counterparty info in DynamoDB
    await dynamodb.put({
      TableName: COUNTERPARTIES_TABLE,
      Item: {
        user_id: user_id,
        counterparty_id: counterpartyId,
        unit_account_id: account_id,
        unit_customer_id: customer_id,
        name: attributes.name || counterparty_name,
        routing_number: attributes.routingNumber || '',
        account_number_last4: attributes.accountNumberLast4 || '',
        type: attributes.type || 'Checking',
        permissions: attributes.permissions || 'DebitOnly',
        created_at: new Date().toISOString(),
      },
    }).promise();
    
    console.log('✅ [Lambda] Counterparty stored in DynamoDB');
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        counterparty_id: counterpartyId,
        name: attributes.name || counterparty_name,
        routing_number: attributes.routingNumber || '',
        account_number_last4: attributes.accountNumberLast4 || '',
        type: attributes.type || 'Checking',
        message: 'Counterparty created successfully',
      }),
    };
  } catch (error) {
    console.error('❌ [Lambda] Error creating counterparty:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: error.message || 'Failed to create counterparty',
      }),
    };
  }
};
