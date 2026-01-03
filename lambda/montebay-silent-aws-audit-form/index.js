/**
 * Lambda function to handle Silent AWS Audit form submissions
 * 
 * Endpoint: POST /montebay/silent-aws-audit
 * 
 * Sends formatted email via AWS SES to contact@montebay.io
 */

const AWS = require('aws-sdk');
const ses = new AWS.SES({ region: process.env.AWS_REGION || 'us-east-1' });

// Email configuration
const TO_EMAIL = process.env.TO_EMAIL || 'contact@montebay.io';
const FROM_EMAIL = process.env.FROM_EMAIL || 'noreply@montebay.io';

exports.handler = async (event) => {
    console.log('📧 [Lambda] Silent AWS Audit form submission received');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Content-Type': 'application/json'
    };
    
    // Handle OPTIONS request (CORS preflight)
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }
    
    try {
        // Parse request body
        let formData;
        if (event.body) {
            formData = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
        } else {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Request body is required'
                })
            };
        }
        
        // Validate required fields
        const requiredFields = ['full-name', 'work-email', 'company-name', 'role-title', 
                                'aws-environment-type', 'monthly-aws-spend', 'audit-tier'];
        
        for (const field of requiredFields) {
            if (!formData[field]) {
                return {
                    statusCode: 400,
                    headers,
                    body: JSON.stringify({
                        success: false,
                        error: `Missing required field: ${field}`
                    })
                };
            }
        }
        
        // Validate checkbox groups
        if (!formData['audit-concerns'] || (Array.isArray(formData['audit-concerns']) && formData['audit-concerns'].length === 0)) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'At least one primary concern must be selected'
                })
            };
        }
        
        if (!formData['audit-confirmations'] || (Array.isArray(formData['audit-confirmations']) && formData['audit-confirmations'].length !== 3)) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'All boundary confirmations must be checked'
                })
            };
        }
        
        if (!formData['delivery-acknowledgment']) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Delivery acknowledgment is required'
                })
            };
        }
        
        // Format email content
        const emailSubject = 'Silent AWS Audit Request';
        const emailBody = formatEmailBody(formData);
        
        // Send email via SES
        const emailParams = {
            Source: FROM_EMAIL,
            Destination: {
                ToAddresses: [TO_EMAIL]
            },
            Message: {
                Subject: {
                    Data: emailSubject,
                    Charset: 'UTF-8'
                },
                Body: {
                    Text: {
                        Data: emailBody,
                        Charset: 'UTF-8'
                    },
                    Html: {
                        Data: formatEmailBodyHTML(formData),
                        Charset: 'UTF-8'
                    }
                }
            }
        };
        
        console.log('📤 [Lambda] Sending email via SES...');
        const result = await ses.sendEmail(emailParams).promise();
        console.log('✅ [Lambda] Email sent successfully:', result.MessageId);
        
        // Optional: Store submission in DynamoDB for tracking
        // (Uncomment if you want to track submissions)
        /*
        const dynamodb = new AWS.DynamoDB.DocumentClient();
        await dynamodb.put({
            TableName: 'montebay-audit-submissions',
            Item: {
                submission_id: result.MessageId,
                timestamp: new Date().toISOString(),
                email: formData['work-email'],
                company: formData['company-name'],
                tier: formData['audit-tier'],
                ...formData
            }
        }).promise();
        */
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                message: 'Request received. If this looks like a good fit, you\'ll receive next steps and read-only access instructions within 1–2 business days. No meetings are required unless you request one.'
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error processing form submission:', error);
        console.error('❌ [Lambda] Error stack:', error.stack);
        console.error('❌ [Lambda] Event received:', JSON.stringify(event, null, 2));
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Failed to process form submission',
                details: process.env.NODE_ENV === 'development' ? error.stack : undefined
            })
        };
    }
};

/**
 * Format email body as plain text
 */
function formatEmailBody(formData) {
    let body = 'SILENT AWS AUDIT REQUEST\n';
    body += '='.repeat(50) + '\n\n';
    
    body += '=== CONTACT INFORMATION ===\n';
    body += `Full Name: ${formData['full-name']}\n`;
    body += `Work Email: ${formData['work-email']}\n`;
    body += `Company: ${formData['company-name']}\n`;
    body += `Role/Title: ${formData['role-title']}\n\n`;
    
    body += '=== AWS ENVIRONMENT ===\n';
    body += `Environment Type: ${formData['aws-environment-type']}\n`;
    body += `Monthly AWS Spend: ${formData['monthly-aws-spend']}\n\n`;
    
    body += '=== AUDIT FOCUS ===\n';
    const concerns = Array.isArray(formData['audit-concerns']) 
        ? formData['audit-concerns'] 
        : [formData['audit-concerns']];
    body += `Primary Concerns: ${concerns.join(', ')}\n\n`;
    
    body += '=== AUDIT TIER ===\n';
    body += `Selected Tier: ${formData['audit-tier']}\n\n`;
    
    body += '=== BOUNDARY CONFIRMATIONS ===\n';
    const confirmations = Array.isArray(formData['audit-confirmations']) 
        ? formData['audit-confirmations'] 
        : [formData['audit-confirmations']];
    confirmations.forEach(conf => {
        body += `✓ ${conf}\n`;
    });
    body += '\n';
    
    if (formData['additional-context']) {
        body += '=== ADDITIONAL CONTEXT ===\n';
        body += `${formData['additional-context']}\n\n`;
    }
    
    body += '=== DELIVERY ACKNOWLEDGMENT ===\n';
    body += `✓ ${formData['delivery-acknowledgment']}\n\n`;
    
    body += '='.repeat(50) + '\n';
    body += `Submitted: ${new Date().toISOString()}\n`;
    
    return body;
}

/**
 * Format email body as HTML
 */
function formatEmailBodyHTML(formData) {
    let html = '<html><body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">';
    html += '<h2 style="color: #1a2a4a;">Silent AWS Audit Request</h2>';
    
    html += '<h3 style="color: #5a8ab0; border-bottom: 2px solid #5a8ab0; padding-bottom: 5px;">Contact Information</h3>';
    html += '<table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">';
    html += `<tr><td style="padding: 8px; font-weight: bold; width: 150px;">Full Name:</td><td style="padding: 8px;">${escapeHtml(formData['full-name'])}</td></tr>`;
    html += `<tr><td style="padding: 8px; font-weight: bold;">Work Email:</td><td style="padding: 8px;">${escapeHtml(formData['work-email'])}</td></tr>`;
    html += `<tr><td style="padding: 8px; font-weight: bold;">Company:</td><td style="padding: 8px;">${escapeHtml(formData['company-name'])}</td></tr>`;
    html += `<tr><td style="padding: 8px; font-weight: bold;">Role/Title:</td><td style="padding: 8px;">${escapeHtml(formData['role-title'])}</td></tr>`;
    html += '</table>';
    
    html += '<h3 style="color: #5a8ab0; border-bottom: 2px solid #5a8ab0; padding-bottom: 5px;">AWS Environment</h3>';
    html += '<table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">';
    html += `<tr><td style="padding: 8px; font-weight: bold; width: 200px;">Environment Type:</td><td style="padding: 8px;">${escapeHtml(formData['aws-environment-type'])}</td></tr>`;
    html += `<tr><td style="padding: 8px; font-weight: bold;">Monthly AWS Spend:</td><td style="padding: 8px;">${escapeHtml(formData['monthly-aws-spend'])}</td></tr>`;
    html += '</table>';
    
    html += '<h3 style="color: #5a8ab0; border-bottom: 2px solid #5a8ab0; padding-bottom: 5px;">Audit Focus</h3>';
    const concerns = Array.isArray(formData['audit-concerns']) 
        ? formData['audit-concerns'] 
        : [formData['audit-concerns']];
    html += '<ul style="margin-bottom: 20px;">';
    concerns.forEach(concern => {
        html += `<li style="margin: 5px 0;">${escapeHtml(concern)}</li>`;
    });
    html += '</ul>';
    
    html += '<h3 style="color: #5a8ab0; border-bottom: 2px solid #5a8ab0; padding-bottom: 5px;">Selected Audit Tier</h3>';
    html += `<p style="font-size: 16px; font-weight: bold; color: #1a2a4a; margin-bottom: 20px;">${escapeHtml(formData['audit-tier'])}</p>`;
    
    html += '<h3 style="color: #5a8ab0; border-bottom: 2px solid #5a8ab0; padding-bottom: 5px;">Boundary Confirmations</h3>';
    html += '<ul style="margin-bottom: 20px;">';
    const confirmations = Array.isArray(formData['audit-confirmations']) 
        ? formData['audit-confirmations'] 
        : [formData['audit-confirmations']];
    confirmations.forEach(conf => {
        html += `<li style="margin: 5px 0; color: #28a745;">✓ ${escapeHtml(conf)}</li>`;
    });
    html += '</ul>';
    
    if (formData['additional-context']) {
        html += '<h3 style="color: #5a8ab0; border-bottom: 2px solid #5a8ab0; padding-bottom: 5px;">Additional Context</h3>';
        html += `<p style="white-space: pre-wrap; background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px;">${escapeHtml(formData['additional-context'])}</p>`;
    }
    
    html += '<h3 style="color: #5a8ab0; border-bottom: 2px solid #5a8ab0; padding-bottom: 5px;">Delivery Acknowledgment</h3>';
    html += `<p style="color: #28a745;">✓ ${escapeHtml(formData['delivery-acknowledgment'])}</p>`;
    
    html += '<hr style="margin: 30px 0; border: none; border-top: 1px solid #ddd;">';
    html += `<p style="color: #666; font-size: 12px;">Submitted: ${new Date().toISOString()}</p>`;
    html += '</body></html>';
    
    return html;
}

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
    if (!text) return '';
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return String(text).replace(/[&<>"']/g, m => map[m]);
}

