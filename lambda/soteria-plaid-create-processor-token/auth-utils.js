/**
 * Authentication utility functions for Lambda
 * Validates Cognito JWT tokens and extracts user ID
 * 
 * Copy from: lambda/soteria-sync-user-data/auth-utils.js
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
            audience: clientId,
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

async function validateUserAccess(event) {
    try {
        const authHeader = event.headers?.Authorization || 
                          event.headers?.authorization ||
                          event.headers?.AuthorizationToken;
        
        if (!authHeader) {
            return { valid: false, error: 'Missing Authorization header' };
        }
        
        if (!authHeader.startsWith('Bearer ')) {
            return { valid: false, error: 'Invalid Authorization header format' };
        }
        
        const token = authHeader.substring(7).trim();
        
        if (!token) {
            return { valid: false, error: 'Empty token in Authorization header' };
        }
        
        const decoded = await verifyToken(token);
        const userId = decoded.sub;
        
        if (!userId) {
            return { valid: false, error: 'Token does not contain user ID' };
        }
        
        return { valid: true, userId: userId };
    } catch (error) {
        console.error('Token validation error:', error);
        return { valid: false, error: error.message };
    }
}

module.exports = {
    validateUserAccess,
    verifyToken,
};
