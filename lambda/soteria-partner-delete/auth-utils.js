// Copy from lambda/auth-utils.js
const jwt = require('jsonwebtoken');
const jwkToPem = require('jwk-to-pem');
const https = require('https');

// Cognito User Pool details
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID || 'us-east-1_YourPoolId';
const REGION = process.env.AWS_REGION || 'us-east-1';
const JWKS_URL = `https://cognito-idp.${REGION}.amazonaws.com/${USER_POOL_ID}/.well-known/jwks.json`;

let jwksCache = null;
let jwksCacheTime = 0;
const JWKS_CACHE_TTL = 3600000; // 1 hour

/**
 * Fetch JWKS from Cognito
 */
async function fetchJWKS() {
    const now = Date.now();
    if (jwksCache && (now - jwksCacheTime) < JWKS_CACHE_TTL) {
        return jwksCache;
    }
    
    return new Promise((resolve, reject) => {
        https.get(JWKS_URL, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                try {
                    jwksCache = JSON.parse(data);
                    jwksCacheTime = now;
                    resolve(jwksCache);
                } catch (error) {
                    reject(error);
                }
            });
        }).on('error', reject);
    });
}

/**
 * Verify JWT token
 */
async function verifyToken(token) {
    try {
        const jwks = await fetchJWKS();
        const decoded = jwt.decode(token, { complete: true });
        
        if (!decoded || !decoded.header || !decoded.header.kid) {
            throw new Error('Invalid token format');
        }
        
        const key = jwks.keys.find(k => k.kid === decoded.header.kid);
        if (!key) {
            throw new Error('Key not found in JWKS');
        }
        
        const pem = jwkToPem(key);
        const verified = jwt.verify(token, pem, { algorithms: ['RS256'] });
        return verified;
    } catch (error) {
        console.error('❌ [auth-utils] Token verification failed:', error.message);
        throw error;
    }
}

/**
 * Get user ID from event (from Authorization header)
 */
async function getUserIdFromEvent(event) {
    const authHeader = event.headers?.Authorization || event.headers?.authorization;
    
    if (!authHeader) {
        throw new Error('Missing Authorization header');
    }
    
    const token = authHeader.replace('Bearer ', '').trim();
    
    if (!token) {
        throw new Error('Empty token');
    }
    
    try {
        const decoded = await verifyToken(token);
        return decoded.sub || decoded['cognito:username'];
    } catch (error) {
        throw new Error(`Invalid Authorization token: ${error.message}`);
    }
}

/**
 * Validate that the requested user_id matches the authenticated user
 */
async function validateUserAccess(event, requestedUserId) {
    const userId = await getUserIdFromEvent(event);
    
    // For admin operations, we might want to allow access
    // For now, we'll just verify the token is valid
    // In the future, we can add admin role checking here
    
    return userId;
}

/**
 * Get CORS headers
 */
function getCorsHeaders(event) {
    const origin = event.headers?.Origin || event.headers?.origin || '*';
    
    return {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Content-Type': 'application/json'
    };
}

module.exports = {
    getUserIdFromEvent,
    validateUserAccess,
    getCorsHeaders,
    verifyToken
};

