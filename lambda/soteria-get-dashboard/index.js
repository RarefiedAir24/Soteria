/**
 * Lambda function to get pre-computed dashboard data
 * 
 * This function aggregates data from multiple DynamoDB tables to provide
 * a single, fast response with all dashboard metrics pre-computed.
 * 
 * Endpoint: GET /soteria/dashboard?user_id={userId}
 * 
 * Response:
 * {
 *   "success": true,
 *   "data": {
 *     "totalSaved": 150.00,
 *     "currentStreak": 5,
 *     "longestStreak": 10,
 *     "activeGoal": {
 *       "id": "goal-123",
 *       "name": "Vacation",
 *       "currentAmount": 500.00,
 *       "targetAmount": 2000.00,
 *       "progress": 0.25
 *     },
 *     "recentRegretCount": 2,
 *     "currentRisk": "medium",
 *     "isQuietModeActive": false,
 *     "soteriaMomentsCount": 15,
 *     "lastUpdated": 1703123456789
 *   }
 * }
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

// DynamoDB table names
const TABLES = {
    goals: process.env.GOALS_TABLE || 'soteria-goals',
    regrets: process.env.REGRETS_TABLE || 'soteria-regrets',
    transfers: process.env.TRANSFERS_TABLE || 'soteria-plaid-transfers',
    unblockEvents: process.env.UNBLOCK_EVENTS_TABLE || 'soteria-unblock-events',
    quietHours: process.env.QUIET_HOURS_TABLE || 'soteria-quiet-hours',
    appUsage: process.env.APP_USAGE_TABLE || 'soteria-app-usage',
    moods: process.env.MOODS_TABLE || 'soteria-moods',
    purchaseIntents: process.env.PURCHASE_INTENTS_TABLE || 'soteria-purchase-intents'
};

/**
 * Calculate current streak (days without unblocking)
 */
async function calculateStreak(userId) {
    try {
        // Get all unblock events for this user, sorted by date (newest first)
        const params = {
            TableName: TABLES.unblockEvents,
            IndexName: 'user_id-timestamp-index', // GSI if exists, otherwise scan
            KeyConditionExpression: 'user_id = :userId',
            ExpressionAttributeValues: {
                ':userId': userId
            },
            ScanIndexForward: false, // Newest first
            Limit: 1
        };
        
        let result;
        try {
            result = await dynamodb.query(params).promise();
        } catch (error) {
            // If index doesn't exist, scan the table (less efficient but works)
            console.log('⚠️ [Lambda] Index not found, scanning table...');
            const scanParams = {
                TableName: TABLES.unblockEvents,
                FilterExpression: 'user_id = :userId',
                ExpressionAttributeValues: {
                    ':userId': userId
                }
            };
            result = await dynamodb.scan(scanParams).promise();
            // Sort by timestamp descending
            if (result.Items) {
                result.Items.sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0));
            }
        }
        
        if (!result.Items || result.Items.length === 0) {
            // No unblock events = infinite streak (or calculate from app usage)
            return { current: 0, longest: 0 };
        }
        
        const lastUnblock = result.Items[0];
        const lastUnblockDate = new Date(lastUnblock.timestamp || lastUnblock.created_at || 0);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        lastUnblockDate.setHours(0, 0, 0, 0);
        
        const daysSince = Math.floor((today - lastUnblockDate) / (1000 * 60 * 60 * 24));
        const currentStreak = Math.max(0, daysSince);
        
        // For longest streak, we'd need to analyze all events (simplified for now)
        // In production, you might want to calculate this separately and cache it
        const longestStreak = currentStreak; // Simplified - calculate properly in production
        
        return { current: currentStreak, longest: longestStreak };
    } catch (error) {
        console.error('❌ [Lambda] Error calculating streak:', error);
        return { current: 0, longest: 0 };
    }
}

/**
 * Get total saved (sum of all transfers)
 */
async function getTotalSaved(userId) {
    try {
        const params = {
            TableName: TABLES.transfers,
            FilterExpression: 'user_id = :userId',
            ExpressionAttributeValues: {
                ':userId': userId
            }
        };
        
        const result = await dynamodb.scan(params).promise();
        
        if (!result.Items || result.Items.length === 0) {
            return 0.0;
        }
        
        // Sum all transfer amounts
        const total = result.Items.reduce((sum, transfer) => {
            return sum + (parseFloat(transfer.amount) || 0);
        }, 0);
        
        return total;
    } catch (error) {
        console.error('❌ [Lambda] Error getting total saved:', error);
        // If transfers table doesn't exist, return 0
        return 0.0;
    }
}

/**
 * Get active goal (first active goal)
 */
async function getActiveGoal(userId) {
    try {
        const params = {
            TableName: TABLES.goals,
            FilterExpression: 'user_id = :userId AND #status = :active',
            ExpressionAttributeNames: {
                '#status': 'status'
            },
            ExpressionAttributeValues: {
                ':userId': userId,
                ':active': 'active'
            }
        };
        
        const result = await dynamodb.scan(params).promise();
        
        if (!result.Items || result.Items.length === 0) {
            return null;
        }
        
        // Get first active goal
        const goal = result.Items[0];
        
        // Calculate progress
        const currentAmount = parseFloat(goal.currentAmount) || 0;
        const targetAmount = parseFloat(goal.targetAmount) || 1;
        const progress = Math.min(currentAmount / targetAmount, 1.0);
        
        // Return full goal data (not just simplified)
        return {
            id: goal.id || goal.goal_id,
            name: goal.name || 'Untitled Goal',
            currentAmount: currentAmount,
            targetAmount: targetAmount,
            progress: progress,
            startDate: goal.startDate || goal.createdDate || null,
            targetDate: goal.targetDate || goal.deadline || null,
            category: goal.category || 'Other',
            protectionAmount: parseFloat(goal.protectionAmount) || 10.0,
            photoPath: goal.photoPath || null,
            description: goal.description || null,
            status: goal.status || 'active',
            createdDate: goal.createdDate || goal.created_at || Date.now(),
            completedDate: goal.completedDate || null,
            completedAmount: goal.completedAmount ? parseFloat(goal.completedAmount) : null
        };
    } catch (error) {
        console.error('❌ [Lambda] Error getting active goal:', error);
        return null;
    }
}

/**
 * Get recent regret count (last 30 days)
 */
async function getRecentRegretCount(userId) {
    try {
        const thirtyDaysAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);
        
        const params = {
            TableName: TABLES.regrets,
            FilterExpression: 'user_id = :userId AND (timestamp > :thirtyDaysAgo OR created_at > :thirtyDaysAgo)',
            ExpressionAttributeValues: {
                ':userId': userId,
                ':thirtyDaysAgo': thirtyDaysAgo
            }
        };
        
        const result = await dynamodb.scan(params).promise();
        
        return result.Items ? result.Items.length : 0;
    } catch (error) {
        console.error('❌ [Lambda] Error getting recent regret count:', error);
        return 0;
    }
}

/**
 * Check if Quiet Hours is currently active
 */
async function isQuietModeActive(userId) {
    try {
        const now = new Date();
        const currentHour = now.getHours();
        const currentMinute = now.getMinutes();
        const currentDay = now.getDay(); // 0 = Sunday, 6 = Saturday
        
        const params = {
            TableName: TABLES.quietHours,
            FilterExpression: 'user_id = :userId AND enabled = :enabled',
            ExpressionAttributeValues: {
                ':userId': userId,
                ':enabled': true
            }
        };
        
        const result = await dynamodb.scan(params).promise();
        
        if (!result.Items || result.Items.length === 0) {
            return false;
        }
        
        // Check if any schedule is currently active
        for (const schedule of result.Items) {
            const startTime = schedule.startTime || '00:00';
            const endTime = schedule.endTime || '23:59';
            const days = schedule.days || [];
            
            // Parse time (format: "HH:MM")
            const [startHour, startMinute] = startTime.split(':').map(Number);
            const [endHour, endMinute] = endTime.split(':').map(Number);
            
            // Check if current day is in schedule
            if (days.includes(currentDay)) {
                // Check if current time is within schedule
                const currentTimeMinutes = currentHour * 60 + currentMinute;
                const startTimeMinutes = startHour * 60 + startMinute;
                const endTimeMinutes = endHour * 60 + endMinute;
                
                if (startTimeMinutes <= endTimeMinutes) {
                    // Normal case: start < end (e.g., 9:00 - 17:00)
                    if (currentTimeMinutes >= startTimeMinutes && currentTimeMinutes <= endTimeMinutes) {
                        return true;
                    }
                } else {
                    // Overnight case: start > end (e.g., 22:00 - 6:00)
                    if (currentTimeMinutes >= startTimeMinutes || currentTimeMinutes <= endTimeMinutes) {
                        return true;
                    }
                }
            }
        }
        
        return false;
    } catch (error) {
        console.error('❌ [Lambda] Error checking quiet mode:', error);
        return false;
    }
}

/**
 * Get Soteria moments count (protection moments)
 * This could be from app usage or a separate table
 */
async function getSoteriaMomentsCount(userId) {
    try {
        // Count app usage sessions where user chose protection
        // This is a simplified version - adjust based on your data structure
        const params = {
            TableName: TABLES.appUsage,
            FilterExpression: 'user_id = :userId AND protection_chosen = :true',
            ExpressionAttributeValues: {
                ':userId': userId,
                ':true': true
            }
        };
        
        const result = await dynamodb.scan(params).promise();
        
        return result.Items ? result.Items.length : 0;
    } catch (error) {
        console.error('❌ [Lambda] Error getting Soteria moments count:', error);
        return 0;
    }
}

/**
 * Get current mood (most recent mood entry)
 */
async function getCurrentMood(userId) {
    try {
        const params = {
            TableName: TABLES.moods,
            FilterExpression: 'user_id = :userId',
            ExpressionAttributeValues: {
                ':userId': userId
            }
        };
        
        const result = await dynamodb.scan(params).promise();
        
        if (!result.Items || result.Items.length === 0) {
            return null;
        }
        
        // Get most recent mood entry
        const sorted = result.Items.sort((a, b) => {
            const dateA = a.date || a.timestamp || a.created_at || 0;
            const dateB = b.date || b.timestamp || b.created_at || 0;
            return dateB - dateA;
        });
        
        return sorted[0].mood || null;
    } catch (error) {
        console.error('❌ [Lambda] Error getting current mood:', error);
        return null;
    }
}

/**
 * Get recent mood count (last 7 days)
 */
async function getRecentMoodCount(userId) {
    try {
        const sevenDaysAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
        
        const params = {
            TableName: TABLES.moods,
            FilterExpression: 'user_id = :userId AND (date > :sevenDaysAgo OR timestamp > :sevenDaysAgo OR created_at > :sevenDaysAgo)',
            ExpressionAttributeValues: {
                ':userId': userId,
                ':sevenDaysAgo': sevenDaysAgo
            }
        };
        
        const result = await dynamodb.scan(params).promise();
        
        return result.Items ? result.Items.length : 0;
    } catch (error) {
        console.error('❌ [Lambda] Error getting recent mood count:', error);
        return 0;
    }
}

/**
 * Get recent purchase intents count (last 7 days)
 */
async function getRecentPurchaseIntentsCount(userId) {
    try {
        const sevenDaysAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
        
        const params = {
            TableName: TABLES.purchaseIntents,
            FilterExpression: 'user_id = :userId AND (date > :sevenDaysAgo OR timestamp > :sevenDaysAgo OR created_at > :sevenDaysAgo)',
            ExpressionAttributeValues: {
                ':userId': userId,
                ':sevenDaysAgo': sevenDaysAgo
            }
        };
        
        const result = await dynamodb.scan(params).promise();
        
        return result.Items ? result.Items.length : 0;
    } catch (error) {
        console.error('❌ [Lambda] Error getting recent purchase intents count:', error);
        return 0;
    }
}

/**
 * Calculate risk level (simplified - you can enhance this)
 */
function calculateRiskLevel(recentRegretCount, currentStreak) {
    // Simple risk calculation
    if (recentRegretCount >= 3) {
        return 'high';
    } else if (recentRegretCount >= 1 || currentStreak < 3) {
        return 'medium';
    } else {
        return 'low';
    }
}

exports.handler = async (event) => {
    console.log('🔍 [Lambda] Getting dashboard data...');
    console.log('📥 [Lambda] Event:', JSON.stringify(event, null, 2));
    
    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
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
        // Get user_id from query parameters
        const userId = event.queryStringParameters?.user_id;
        
        if (!userId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'user_id query parameter is required'
                })
            };
        }
        
        console.log(`🔍 [Lambda] Getting dashboard data for user: ${userId}`);
        
        // Fetch all data in parallel for speed
        const [
            totalSaved,
            streakData,
            activeGoal,
            recentRegretCount,
            quietModeActive,
            soteriaMomentsCount,
            currentMood,
            recentMoodCount,
            recentPurchaseIntentsCount
        ] = await Promise.all([
            getTotalSaved(userId),
            calculateStreak(userId),
            getActiveGoal(userId),
            getRecentRegretCount(userId),
            isQuietModeActive(userId),
            getSoteriaMomentsCount(userId),
            getCurrentMood(userId),
            getRecentMoodCount(userId),
            getRecentPurchaseIntentsCount(userId)
        ]);
        
        // Calculate risk level
        const currentRisk = calculateRiskLevel(recentRegretCount, streakData.current);
        
        // Build dashboard data
        const dashboardData = {
            totalSaved: totalSaved,
            currentStreak: streakData.current,
            longestStreak: streakData.longest,
            activeGoal: activeGoal,
            recentRegretCount: recentRegretCount,
            currentRisk: currentRisk,
            isQuietModeActive: quietModeActive,
            soteriaMomentsCount: soteriaMomentsCount,
            currentMood: currentMood,
            recentMoodCount: recentMoodCount,
            recentPurchaseIntentsCount: recentPurchaseIntentsCount,
            lastUpdated: Date.now()
        };
        
        console.log(`✅ [Lambda] Dashboard data computed:`, JSON.stringify(dashboardData, null, 2));
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                data: dashboardData
            })
        };
        
    } catch (error) {
        console.error('❌ [Lambda] Error getting dashboard data:', error);
        
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message || 'Internal server error'
            })
        };
    }
};

