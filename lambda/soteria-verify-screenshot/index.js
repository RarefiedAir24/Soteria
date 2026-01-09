/**
 * Lambda Function: Screenshot Verification
 * 
 * Uses AWS Textract to analyze deposit screenshots and prevent fraud
 * 
 * Checks:
 * 1. Extract text from image using Textract
 * 2. Look for dollar amounts in extracted text
 * 3. Verify extracted amount matches claimed amount (±10% tolerance)
 * 4. Check for bank/financial keywords
 * 5. Flag suspicious patterns
 */

const AWS = require('aws-sdk');
const textract = new AWS.Textract({ region: 'us-east-1' });

// Bank/financial keywords that should appear in legitimate screenshots
const BANK_KEYWORDS = [
    'deposit', 'transfer', 'transaction', 'bank', 'checking', 'savings',
    'account', 'balance', 'payment', 'withdrawal', 'debit', 'credit',
    'venmo', 'zelle', 'paypal', 'cash app', 'chase', 'wells fargo',
    'bank of america', 'citibank', 'capital one', 'td bank', 'usaa'
];

exports.handler = async (event) => {
    console.log('Screenshot verification request received');
    
    try {
        const body = JSON.parse(event.body || '{}');
        const { image, claimed_amount } = body;
        
        if (!image || !claimed_amount) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    success: false,
                    error: 'Missing required parameters: image, claimed_amount'
                })
            };
        }
        
        // Decode base64 image
        const imageBuffer = Buffer.from(image, 'base64');
        
        console.log(`Analyzing screenshot for claimed amount: $${claimed_amount}`);
        
        // Call AWS Textract to extract text
        const textractParams = {
            Document: {
                Bytes: imageBuffer
            }
        };
        
        const textractResult = await textract.detectDocumentText(textractParams).promise();
        
        // Extract all text lines
        const textLines = textractResult.Blocks
            .filter(block => block.BlockType === 'LINE')
            .map(block => block.Text);
        
        const fullText = textLines.join(' ').toLowerCase();
        
        console.log('Extracted text:', fullText.substring(0, 200) + '...');
        
        // Analysis
        const verification = analyzeScreenshot(fullText, textLines, claimed_amount);
        
        console.log('Verification result:', JSON.stringify(verification));
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: true,
                ...verification
            })
        };
        
    } catch (error) {
        console.error('Error verifying screenshot:', error);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: false,
                error: error.message
            })
        };
    }
};

function analyzeScreenshot(fullText, textLines, claimedAmount) {
    const fraudIndicators = [];
    let confidence = 0.0;
    let extractedAmount = null;
    
    // Check 1: Look for bank/financial keywords
    const foundKeywords = BANK_KEYWORDS.filter(keyword => 
        fullText.includes(keyword.toLowerCase())
    );
    
    if (foundKeywords.length === 0) {
        fraudIndicators.push('No banking keywords found');
        confidence = 0.1;
    } else if (foundKeywords.length < 2) {
        fraudIndicators.push('Few banking keywords found');
        confidence = 0.3;
    } else {
        confidence = 0.6;
    }
    
    console.log(`Found ${foundKeywords.length} bank keywords:`, foundKeywords);
    
    // Check 2: Extract dollar amounts from text
    const amountPattern = /\$?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)/g;
    const amounts = [];
    
    for (const line of textLines) {
        const matches = line.matchAll(amountPattern);
        for (const match of matches) {
            const amountStr = match[1].replace(/,/g, '');
            const amount = parseFloat(amountStr);
            if (!isNaN(amount) && amount > 0) {
                amounts.push(amount);
            }
        }
    }
    
    console.log('Extracted amounts:', amounts);
    
    // Check 3: Verify claimed amount matches an extracted amount (±10% tolerance)
    const tolerance = claimedAmount * 0.10;
    const matchingAmount = amounts.find(amount => 
        Math.abs(amount - claimedAmount) <= tolerance
    );
    
    if (matchingAmount) {
        extractedAmount = matchingAmount;
        confidence += 0.3;
        console.log(`✅ Found matching amount: $${matchingAmount} (claimed: $${claimedAmount})`);
    } else {
        fraudIndicators.push('Claimed amount not found in screenshot');
        confidence -= 0.2;
        console.log(`❌ No matching amount found. Claimed: $${claimedAmount}, Extracted: [${amounts.join(', ')}]`);
    }
    
    // Check 4: Look for date patterns (legitimate transactions have dates)
    const datePattern = /\d{1,2}\/\d{1,2}\/\d{2,4}|\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}/i;
    if (datePattern.test(fullText)) {
        confidence += 0.1;
    } else {
        fraudIndicators.push('No date found');
    }
    
    // Check 5: Minimum text requirement
    if (fullText.length < 50) {
        fraudIndicators.push('Insufficient text in image');
        confidence = Math.min(confidence, 0.3);
    }
    
    // Check 6: Too many round numbers (suspicious)
    const roundNumbers = amounts.filter(amt => amt % 100 === 0);
    if (roundNumbers.length > 3 && amounts.length > 0) {
        fraudIndicators.push('Too many round numbers');
    }
    
    // Final confidence score
    confidence = Math.max(0, Math.min(1, confidence));
    
    // Determine validity
    const isValid = confidence >= 0.5 && fraudIndicators.length < 2;
    
    return {
        is_valid: isValid,
        confidence: parseFloat(confidence.toFixed(2)),
        extracted_amount: extractedAmount,
        extracted_text: fullText.substring(0, 500), // Limit for security
        fraud_indicators: fraudIndicators,
        reason: isValid 
            ? `Screenshot verified with ${(confidence * 100).toFixed(0)}% confidence`
            : `Verification failed: ${fraudIndicators.join(', ')}`,
        found_keywords: foundKeywords,
        extracted_amounts: amounts
    };
}

