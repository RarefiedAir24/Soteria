/**
 * Lambda function to generate Apple Wallet pass (.pkpass file)
 * 
 * This function generates a signed .pkpass file for the premium member card
 * that can be added to Apple Wallet.
 * 
 * Endpoint: GET /soteria/apple-wallet/pass?user_id={userId}&card_type={cardType}
 * 
 * Response:
 * - Binary .pkpass file (application/vnd.apple.pkpass)
 * 
 * Note: This requires:
 * - Pass Type ID registered with Apple
 * - Pass signing certificate (.p12 file)
 * - WWDR certificate
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const s3 = new AWS.S3();
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const archiver = require('archiver');
const { validateUserAccess, getCorsHeaders } = require('./auth-utils');

// DynamoDB table names
const TABLES = {
    userData: process.env.USER_DATA_TABLE || 'soteria-user-data'
};

// S3 bucket for pass assets
const PASS_BUCKET = process.env.PASS_BUCKET || 'soteria-wallet-passes';

// Pass Type ID (from Apple Developer account)
const PASS_TYPE_ID = process.env.PASS_TYPE_ID || 'pass.com.soteria.member';

// Certificate paths (stored in S3 or Lambda layer)
const CERT_PATH = process.env.CERT_PATH || '/tmp/cert.p12';
const CERT_PASSWORD_SECRET_NAME = process.env.CERT_PASSWORD_SECRET_NAME || 'soteria/apple-wallet/cert-password';
const CERT_PASSWORD_ENV = process.env.CERT_PASSWORD || '';
const WWDR_CERT_PATH = process.env.WWDR_CERT_PATH || '/tmp/wwdr.pem';

// Get certificate password from Secrets Manager or environment variable
let CERT_PASSWORD = '';
async function getCertPassword() {
    if (CERT_PASSWORD_ENV) {
        return CERT_PASSWORD_ENV;
    }
    
    try {
        const secretsManager = new AWS.SecretsManager();
        const secret = await secretsManager.getSecretValue({ SecretId: CERT_PASSWORD_SECRET_NAME }).promise();
        return secret.SecretString;
    } catch (error) {
        console.warn('⚠️ [Lambda] Could not retrieve password from Secrets Manager, using empty password:', error.message);
        return '';
    }
}

/**
 * Get user data
 */
async function getUserData(userId) {
    try {
        const params = {
            TableName: TABLES.userData,
            Key: {
                user_id: userId,
                data_type: 'profile'
            }
        };
        
        const result = await dynamodb.get(params).promise();
        return result.Item ? result.Item.data : null;
    } catch (error) {
        console.error('❌ [Lambda] Error getting user data:', error);
        return null;
    }
}

/**
 * Download certificates from S3
 */
async function downloadCertificates() {
    try {
        // Download signing certificate
        const certData = await s3.getObject({
            Bucket: PASS_BUCKET,
            Key: 'certificates/cert.p12'
        }).promise();
        
        fs.writeFileSync(CERT_PATH, certData.Body);
        
        // Download WWDR certificate
        const wwdrData = await s3.getObject({
            Bucket: PASS_BUCKET,
            Key: 'certificates/wwdr.pem'
        }).promise();
        
        fs.writeFileSync(WWDR_CERT_PATH, wwdrData.Body);
        
        console.log('✅ [Lambda] Certificates downloaded');
    } catch (error) {
        console.error('❌ [Lambda] Error downloading certificates:', error);
        throw error;
    }
}

/**
 * Generate pass.json
 */
function generatePassJSON(userId, userData, cardType, memberSince) {
    const userName = userData?.username || userData?.name || 'Member';
    const cardColor = cardType === 'black' ? '#000000' : (cardType === 'platinum' ? '#2C3E50' : '#FFD700');
    const cardLabel = cardType === 'black' ? 'BLACK' : (cardType === 'platinum' ? 'PLATINUM' : 'GOLD');
    
    return {
        formatVersion: 1,
        passTypeIdentifier: PASS_TYPE_ID,
        serialNumber: `soteria-${userId}`,
        teamIdentifier: process.env.TEAM_IDENTIFIER || 'XXXXXXXXXX',
        organizationName: 'Soteria',
        description: 'Soteria Premium Member Card',
        logoText: 'SOTERIA',
        foregroundColor: cardType === 'black' ? 'rgb(255, 255, 255)' : 'rgb(0, 0, 0)',
        backgroundColor: cardColor,
        labelColor: cardType === 'black' ? 'rgb(255, 255, 255)' : 'rgb(0, 0, 0)',
        webServiceURL: `${process.env.API_BASE_URL || 'https://api.soteria.app'}/wallet`,
        authenticationToken: generateAuthToken(userId),
        barcodes: [
            {
                message: JSON.stringify({
                    user_id: userId,
                    card_type: cardType,
                    member_since: memberSince.toISOString()
                }),
                format: 'PKBarcodeFormatQR',
                messageEncoding: 'iso-8859-1'
            }
        ],
        genericPass: {
            primaryFields: [
                {
                    key: 'memberName',
                    label: 'MEMBER',
                    value: userName.toUpperCase()
                }
            ],
            secondaryFields: [
                {
                    key: 'cardType',
                    label: 'CARD TYPE',
                    value: cardLabel
                },
                {
                    key: 'memberSince',
                    label: 'MEMBER SINCE',
                    value: memberSince.getFullYear().toString()
                }
            ],
            auxiliaryFields: [
                {
                    key: 'memberId',
                    label: 'MEMBER ID',
                    value: userId.substring(0, 8).toUpperCase()
                }
            ]
        }
    };
}

/**
 * Generate authentication token
 */
function generateAuthToken(userId) {
    // In production, use a proper JWT or signed token
    const crypto = require('crypto');
    return crypto.createHash('sha256')
        .update(userId + Date.now() + process.env.SECRET_KEY || 'default-secret')
        .digest('hex');
}

/**
 * Sign and create .pkpass file
 */
async function createPassFile(passJSON, assets) {
    const tempDir = '/tmp/pass_' + Date.now();
    fs.mkdirSync(tempDir, { recursive: true });
    
    try {
        // Write pass.json
        fs.writeFileSync(path.join(tempDir, 'pass.json'), JSON.stringify(passJSON));
        
        // Copy assets (logo, icon, etc.)
        if (assets) {
            for (const [filename, data] of Object.entries(assets)) {
                fs.writeFileSync(path.join(tempDir, filename), data);
            }
        }
        
        // Create manifest.json
        const manifest = {};
        const files = fs.readdirSync(tempDir);
        for (const file of files) {
            const filePath = path.join(tempDir, file);
            const fileData = fs.readFileSync(filePath);
            const hash = require('crypto').createHash('sha1').update(fileData).digest('hex');
            manifest[file] = hash;
        }
        
        fs.writeFileSync(path.join(tempDir, 'manifest.json'), JSON.stringify(manifest));
        
        // Sign manifest
        const signaturePath = path.join(tempDir, 'signature');
        const certPassword = await getCertPassword();
        execSync(`openssl smime -binary -sign -certfile ${WWDR_CERT_PATH} -signer ${CERT_PATH} -inkey ${CERT_PATH} -in ${path.join(tempDir, 'manifest.json')} -out ${signaturePath} -outform DER -passin pass:${certPassword}`, {
            stdio: 'inherit'
        });
        
        // Create .pkpass zip file
        const passFilePath = '/tmp/pass_' + Date.now() + '.pkpass';
        const output = fs.createWriteStream(passFilePath);
        const archive = archiver('zip', { zlib: { level: 9 } });
        
        archive.pipe(output);
        archive.directory(tempDir, false);
        await archive.finalize();
        
        // Read pass file
        const passData = fs.readFileSync(passFilePath);
        
        // Cleanup
        fs.rmSync(tempDir, { recursive: true, force: true });
        fs.unlinkSync(passFilePath);
        
        return passData;
    } catch (error) {
        // Cleanup on error
        if (fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true });
        }
        throw error;
    }
}

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Generating Apple Wallet pass...');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    // CORS headers
    const headers = getCorsHeaders(event);
    headers['Content-Type'] = 'application/vnd.apple.pkpass';
    
    // Handle OPTIONS request (CORS preflight)
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }
    
    try {
        // Validate authentication
        const authResult = await validateUserAccess(event);
        if (!authResult.valid) {
            return {
                statusCode: 401,
                headers: { ...headers, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    success: false,
                    error: authResult.error || 'Unauthorized'
                })
            };
        }
        
        const authenticatedUserId = authResult.userId;
        
        const queryParams = event.queryStringParameters || {};
        const requestedUserId = queryParams.user_id;
        const cardType = queryParams.card_type || 'gold';
        
        if (!requestedUserId) {
            return {
                statusCode: 400,
                headers: { ...headers, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    success: false,
                    error: 'user_id query parameter is required'
                })
            };
        }
        
        // Verify user can only request their own pass
        if (requestedUserId !== authenticatedUserId) {
            return {
                statusCode: 403,
                headers: { ...headers, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    success: false,
                    error: 'Forbidden: You can only request your own pass'
                })
            };
        }
        
        // Get user data
        const userData = await getUserData(authenticatedUserId);
        const memberSince = userData?.signup_date ? new Date(userData.signup_date) : new Date();
        
        // Download certificates
        await downloadCertificates();
        
        // Generate pass.json
        const passJSON = generatePassJSON(authenticatedUserId, userData, cardType, memberSince);
        
        // Download pass assets from S3
        let assets = {};
        try {
            const logoData = await s3.getObject({
                Bucket: PASS_BUCKET,
                Key: 'assets/logo.png'
            }).promise();
            assets['logo.png'] = logoData.Body;
            
            const iconData = await s3.getObject({
                Bucket: PASS_BUCKET,
                Key: 'assets/icon.png'
            }).promise();
            assets['icon.png'] = iconData.Body;
        } catch (error) {
            console.warn('⚠️ [Lambda] Could not load pass assets, using defaults');
        }
        
        // Create .pkpass file
        const passData = await createPassFile(passJSON, assets);
        
        console.log(`✅ [Lambda] Pass generated for user: ${authenticatedUserId}`);
        
        return {
            statusCode: 200,
            headers: {
                ...headers,
                'Content-Disposition': `attachment; filename="soteria-${cardType}-pass.pkpass"`
            },
            body: passData.toString('base64'),
            isBase64Encoded: true
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error generating pass:', error);
        
        return {
            statusCode: 500,
            headers: { ...headers, 'Content-Type': 'application/json' },
            body: JSON.stringify({
                success: false,
                error: error.message || 'Internal server error'
            })
        };
    }
};

