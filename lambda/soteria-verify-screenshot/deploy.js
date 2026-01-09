/**
 * Deployment script for soteria-verify-screenshot Lambda function
 * 
 * Run: npm install && npm run deploy
 */

const AWS = require('aws-sdk');
const fs = require('fs');
const archiver = require('archiver');
const path = require('path');

// AWS Configuration
AWS.config.update({ region: 'us-east-1' });
const lambda = new AWS.Lambda();
const iam = new AWS.IAM();
const apigateway = new AWS.APIGateway();

const FUNCTION_NAME = 'soteria-verify-screenshot';
const ROLE_NAME = 'soteria-verify-screenshot-role';
const API_NAME = 'soteria-api';

async function createZipFile() {
    console.log('📦 Creating deployment package...');
    
    return new Promise((resolve, reject) => {
        const output = fs.createWriteStream(path.join(__dirname, 'function.zip'));
        const archive = archiver('zip', { zlib: { level: 9 } });
        
        output.on('close', () => {
            console.log(`✅ Package created: ${archive.pointer()} bytes`);
            resolve();
        });
        
        archive.on('error', reject);
        archive.pipe(output);
        
        // Add files
        archive.file(path.join(__dirname, 'index.js'), { name: 'index.js' });
        archive.directory(path.join(__dirname, 'node_modules'), 'node_modules');
        
        archive.finalize();
    });
}

async function createOrUpdateRole() {
    console.log('🔑 Setting up IAM role...');
    
    const trustPolicy = {
        Version: '2012-10-17',
        Statement: [{
            Effect: 'Allow',
            Principal: { Service: 'lambda.amazonaws.com' },
            Action: 'sts:AssumeRole'
        }]
    };
    
    const policyDocument = {
        Version: '2012-10-17',
        Statement: [
            {
                Effect: 'Allow',
                Action: [
                    'logs:CreateLogGroup',
                    'logs:CreateLogStream',
                    'logs:PutLogEvents'
                ],
                Resource: 'arn:aws:logs:*:*:*'
            },
            {
                Effect: 'Allow',
                Action: [
                    'textract:DetectDocumentText',
                    'textract:AnalyzeDocument'
                ],
                Resource: '*'
            }
        ]
    };
    
    try {
        // Try to get existing role
        const roleData = await iam.getRole({ RoleName: ROLE_NAME }).promise();
        console.log('✅ IAM role exists:', roleData.Role.Arn);
        
        // Update inline policy
        await iam.putRolePolicy({
            RoleName: ROLE_NAME,
            PolicyName: 'soteria-textract-policy',
            PolicyDocument: JSON.stringify(policyDocument)
        }).promise();
        
        console.log('✅ Updated IAM policy');
        
        return roleData.Role.Arn;
    } catch (error) {
        if (error.code === 'NoSuchEntity') {
            // Create new role
            console.log('Creating new IAM role...');
            const roleData = await iam.createRole({
                RoleName: ROLE_NAME,
                AssumeRolePolicyDocument: JSON.stringify(trustPolicy),
                Description: 'Role for Soteria screenshot verification Lambda'
            }).promise();
            
            // Attach inline policy
            await iam.putRolePolicy({
                RoleName: ROLE_NAME,
                PolicyName: 'soteria-textract-policy',
                PolicyDocument: JSON.stringify(policyDocument)
            }).promise();
            
            console.log('✅ Created IAM role:', roleData.Role.Arn);
            
            // Wait for role to propagate
            console.log('⏳ Waiting for IAM role to propagate (10 seconds)...');
            await new Promise(resolve => setTimeout(resolve, 10000));
            
            return roleData.Role.Arn;
        }
        throw error;
    }
}

async function deployLambda(roleArn) {
    console.log('🚀 Deploying Lambda function...');
    
    const zipBuffer = fs.readFileSync(path.join(__dirname, 'function.zip'));
    
    try {
        // Try to update existing function
        await lambda.updateFunctionCode({
            FunctionName: FUNCTION_NAME,
            ZipFile: zipBuffer
        }).promise();
        
        console.log('✅ Lambda function updated');
        
        // Update configuration
        await lambda.updateFunctionConfiguration({
            FunctionName: FUNCTION_NAME,
            Timeout: 30,
            MemorySize: 512,
            Environment: {
                Variables: {
                    NODE_ENV: 'production'
                }
            }
        }).promise();
        
        console.log('✅ Lambda configuration updated');
        
    } catch (error) {
        if (error.code === 'ResourceNotFoundException') {
            // Create new function
            console.log('Creating new Lambda function...');
            await lambda.createFunction({
                FunctionName: FUNCTION_NAME,
                Runtime: 'nodejs20.x',
                Role: roleArn,
                Handler: 'index.handler',
                Code: { ZipFile: zipBuffer },
                Timeout: 30,
                MemorySize: 512,
                Description: 'Verifies deposit screenshots using AWS Textract',
                Environment: {
                    Variables: {
                        NODE_ENV: 'production'
                    }
                }
            }).promise();
            
            console.log('✅ Lambda function created');
        } else {
            throw error;
        }
    }
    
    // Get function ARN
    const functionData = await lambda.getFunction({ FunctionName: FUNCTION_NAME }).promise();
    return functionData.Configuration.FunctionArn;
}

async function setupApiGateway(lambdaArn) {
    console.log('🌐 Setting up API Gateway...');
    
    try {
        // Find existing API
        const apis = await apigateway.getRestApis().promise();
        let apiId = apis.items.find(api => api.name === API_NAME)?.id;
        
        if (!apiId) {
            console.log('❌ API Gateway not found. Please ensure "soteria-api" exists.');
            console.log('Create it manually or use your existing API ID.');
            return;
        }
        
        console.log('✅ Found API Gateway:', apiId);
        
        // Get root resource
        const resources = await apigateway.getResources({ restApiId: apiId }).promise();
        const rootResource = resources.items.find(r => r.path === '/');
        
        // Find or create /soteria resource
        let soteriaResource = resources.items.find(r => r.path === '/soteria');
        if (!soteriaResource) {
            soteriaResource = await apigateway.createResource({
                restApiId: apiId,
                parentId: rootResource.id,
                pathPart: 'soteria'
            }).promise();
            console.log('✅ Created /soteria resource');
        }
        
        // Find or create /soteria/verify-screenshot resource
        let verifyResource = resources.items.find(r => r.path === '/soteria/verify-screenshot');
        if (!verifyResource) {
            verifyResource = await apigateway.createResource({
                restApiId: apiId,
                parentId: soteriaResource.id,
                pathPart: 'verify-screenshot'
            }).promise();
            console.log('✅ Created /soteria/verify-screenshot resource');
        }
        
        // Create POST method
        try {
            await apigateway.putMethod({
                restApiId: apiId,
                resourceId: verifyResource.id,
                httpMethod: 'POST',
                authorizationType: 'NONE', // Change to 'COGNITO_USER_POOLS' if needed
                requestParameters: {}
            }).promise();
            console.log('✅ Created POST method');
        } catch (error) {
            if (error.code !== 'ConflictException') throw error;
            console.log('ℹ️ POST method already exists');
        }
        
        // Set up Lambda integration
        const accountId = lambdaArn.split(':')[4];
        const lambdaUri = `arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${lambdaArn}/invocations`;
        
        await apigateway.putIntegration({
            restApiId: apiId,
            resourceId: verifyResource.id,
            httpMethod: 'POST',
            type: 'AWS_PROXY',
            integrationHttpMethod: 'POST',
            uri: lambdaUri
        }).promise();
        console.log('✅ Lambda integration configured');
        
        // Add Lambda permission for API Gateway
        try {
            await lambda.addPermission({
                FunctionName: FUNCTION_NAME,
                StatementId: 'apigateway-invoke-' + Date.now(),
                Action: 'lambda:InvokeFunction',
                Principal: 'apigateway.amazonaws.com',
                SourceArn: `arn:aws:execute-api:us-east-1:${accountId}:${apiId}/*/*`
            }).promise();
            console.log('✅ Lambda invoke permission added');
        } catch (error) {
            if (error.code !== 'ResourceConflictException') throw error;
            console.log('ℹ️ Lambda permission already exists');
        }
        
        // Deploy API
        await apigateway.createDeployment({
            restApiId: apiId,
            stageName: 'prod',
            description: 'Deployment for screenshot verification'
        }).promise();
        
        console.log('✅ API Gateway deployed');
        console.log(`\n🌐 Endpoint: https://${apiId}.execute-api.us-east-1.amazonaws.com/prod/soteria/verify-screenshot`);
        
    } catch (error) {
        console.error('❌ API Gateway setup error:', error.message);
        console.log('\n📝 Manual setup required:');
        console.log('1. Go to API Gateway console');
        console.log('2. Select your soteria-api');
        console.log('3. Create resource: /soteria/verify-screenshot');
        console.log('4. Add POST method → Lambda integration');
        console.log(`5. Lambda function: ${FUNCTION_NAME}`);
        console.log('6. Deploy to prod stage');
    }
}

async function main() {
    console.log('🚀 Starting deployment...\n');
    
    try {
        // Step 1: Create deployment package
        await createZipFile();
        
        // Step 2: Create/update IAM role
        const roleArn = await createOrUpdateRole();
        
        // Step 3: Deploy Lambda
        const lambdaArn = await deployLambda(roleArn);
        
        // Step 4: Setup API Gateway
        await setupApiGateway(lambdaArn);
        
        console.log('\n✅ Deployment completed successfully!\n');
        console.log('📋 Summary:');
        console.log(`   Function: ${FUNCTION_NAME}`);
        console.log(`   Runtime: Node.js 20.x`);
        console.log(`   Timeout: 30 seconds`);
        console.log(`   Memory: 512 MB`);
        console.log(`   Role: ${ROLE_NAME}`);
        console.log('\n🧪 Test with:');
        console.log(`   aws lambda invoke --function-name ${FUNCTION_NAME} --payload file://test-payload.json response.json`);
        
    } catch (error) {
        console.error('\n❌ Deployment failed:', error);
        process.exit(1);
    }
}

main();

