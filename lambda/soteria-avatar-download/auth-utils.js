/**
 * Authentication utility functions for Lambda
 * Validates Cognito JWT tokens and extracts user ID
 */

const AWS = require('aws-sdk');
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

// Initialize Cognito client
const cognito = new AWS.CognitoIdentityServiceProvider();

// JWKS client for token verification
let jwksClientInstance = null;

function getJwksClient() {
    if (!jwksClientInstance) {
        const userPoolId = process.env.COGNITO_USER_POOL_ID;
        // AWS_REGION is automatically set by Lambda runtime
        const region = process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION || 'us-east-1';
        
        if (!userPoolId) {
            throw new Error('COGNITO_USER_POOL_ID environment variable not set');
        }
        
        const jwksUri = `https://cognito-idp.${region}.amazonaws.com/${userPoolId}/.well-known/jwks.json`;
        
        jwksClientInstance = jwksClient({
            jwksUri: jwksUri,
            cache: true,
            cacheMaxAge: 86400000, // 24 hours
            rateLimit: true,
            jwksRequestsPerMinute: 10
        });
    }
    
    return jwksClientInstance;
}

function getKey(header, callback) {
    const client = getJwksClient();
    client.getSigningKey(header.kid, (err, key) => {
        if (err) {
            callback(err);
            return;
        }
        const signingKey = key.publicKey || key.rsaPublicKey;
        callback(null, signingKey);
    });
}

/**
 * Verify and decode Cognito JWT token
 * @param {string} token - JWT token from Authorization header
 * @returns {Promise<Object>} Decoded token payload
 */
async function verifyToken(token) {
    return new Promise((resolve, reject) => {
        const userPoolId = process.env.COGNITO_USER_POOL_ID;
        const region = process.env.AWS_REGION || 'us-east-1';
        const clientId = process.env.COGNITO_CLIENT_ID;
        
        if (!userPoolId) {
            reject(new Error('COGNITO_USER_POOL_ID not configured'));
            return;
        }
        
        const issuer = `https://cognito-idp.${region}.amazonaws.com/${userPoolId}`;
        
        jwt.verify(token, getKey, {
            audience: clientId, // Optional: verify client ID
            issuer: issuer,
            algorithms: ['RS256']
        }, (err, decoded) => {
            if (err) {
                reject(err);
            } else {
                resolve(decoded);
            }
        });
    });
}

/**
 * Extract user ID from Authorization header
 * @param {Object} event - Lambda event object
 * @returns {Promise<string>} User ID (sub claim from JWT)
 */
async function getUserIdFromEvent(event) {
    // Get Authorization header
    const authHeader = event.headers?.Authorization || 
                      event.headers?.authorization ||
                      event.headers?.AuthorizationToken;
    
    if (!authHeader) {
        throw new Error('Missing Authorization header');
    }
    
    // Extract token (Bearer <token>)
    if (!authHeader.startsWith('Bearer ')) {
        throw new Error('Invalid Authorization header format. Expected: Bearer <token>');
    }
    
    const token = authHeader.substring(7).trim();
    
    if (!token) {
        throw new Error('Empty token in Authorization header');
    }
    
    // Verify and decode token
    const decoded = await verifyToken(token);
    
    // Extract user ID from token (sub claim is the Cognito user ID)
    const userId = decoded.sub;
    
    if (!userId) {
        throw new Error('Token does not contain user ID (sub claim)');
    }
    
    return userId;
}

/**
 * Validate that requested user_id matches authenticated user
 * @param {Object} event - Lambda event object
 * @param {string} requestedUserId - User ID from request (query params or body)
 * @returns {Promise<string>} Authenticated user ID
 * @throws {Error} If user IDs don't match
 */
async function validateUserAccess(event, requestedUserId) {
    const authenticatedUserId = await getUserIdFromEvent(event);
    
    if (requestedUserId && authenticatedUserId !== requestedUserId) {
        throw new Error('Forbidden: Cannot access other user\'s data');
    }
    
    return authenticatedUserId;
}

/**
 * Get CORS headers with restricted origin
 * @param {Object} event - Lambda event object
 * @returns {Object} CORS headers
 */
function getCorsHeaders(event) {
    // Allowed origins - update these for production
    const allowedOrigins = [
        'https://soteria.montebay.io', // Production web app
        'http://localhost:3000',      // Local development
        'capacitor://localhost',      // Capacitor iOS/Android
        'ionic://localhost'           // Ionic iOS/Android
    ];
    
    const origin = event.headers?.origin || event.headers?.Origin || '';
    
    // For development, allow localhost (dynamic ports)
    if (origin && (origin.includes('localhost') || origin.includes('127.0.0.1'))) {
        // Allow any localhost port for development
        if (!allowedOrigins.includes(origin)) {
            allowedOrigins.push(origin);
        }
    }
    
    // Determine CORS origin
    // iOS apps don't send Origin headers, so default to first allowed origin
    // This is safe because CORS only applies to browsers, not native apps
    let corsOrigin = '*'; // Default to * for native apps (iOS/Android)
    
    if (origin) {
        // If origin is provided (web browser), validate it
        if (allowedOrigins.includes(origin)) {
            corsOrigin = origin;
        } else if (origin.startsWith('http://localhost:') || origin.startsWith('https://localhost:')) {
            // Allow dynamic localhost ports for development
            corsOrigin = origin;
        } else {
            // Unknown origin - default to first allowed (more secure than *)
            corsOrigin = allowedOrigins[0] || '*';
        }
    }
    
    return {
        'Access-Control-Allow-Origin': corsOrigin,
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Content-Type': 'application/json'
    };
}

module.exports = {
    getUserIdFromEvent,
    validateUserAccess,
    verifyToken,
    getCorsHeaders
};

