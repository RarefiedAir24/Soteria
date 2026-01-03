# App Simplification Plan

## Current Problem
- 43-second delay between AuthView body evaluation and onAppear
- This is SwiftUI rendering overhead that we can't directly control
- DeviceActivity monitoring adds complexity and potential delays
- User wants to simplify: remove app monitoring, focus on savings reminders

## Proposed Simplification

### 1. Remove DeviceActivity Monitoring
- **Remove**: `DeviceActivityService` initialization and usage
- **Remove**: `QuietHoursService` app monitoring features
- **Remove**: App blocking functionality
- **Keep**: Basic savings tracking and goals

### 2. Focus on Savings Reminders
- **Keep**: Savings goals and tracking
- **Keep**: Notification system for savings reminders
- **Add**: Simple scheduled notifications to remind users to make deposits
- **Remove**: Complex app usage monitoring

### 3. Simplified Notification System
- **Use**: Simple `UNTimeIntervalNotificationTrigger` for scheduled reminders
- **Remove**: DeviceActivity-based notifications
- **Example**: "Time to make a savings deposit! Open Soteria to add to your savings goal."

### 4. Simplified App Structure
- **Remove**: App management views
- **Remove**: Quiet hours scheduling
- **Keep**: Home dashboard with savings goals
- **Keep**: Settings for basic preferences
- **Keep**: Authentication

## Implementation Steps

1. **Disable DeviceActivity Service**
   - Comment out or remove `DeviceActivityService.shared` access
   - Remove from environment objects
   - Remove from views that use it

2. **Simplify Notification System**
   - Create simple scheduled notifications for savings reminders
   - Remove DeviceActivity monitor extension
   - Use standard UserNotifications API

3. **Update Views**
   - Remove app management views
   - Remove quiet hours views
   - Simplify home view to focus on savings

4. **Test Performance**
   - Measure startup time
   - Should be < 10 seconds
   - Verify notifications work

## Expected Benefits
- **Faster startup**: No DeviceActivity initialization delays
- **Simpler codebase**: Less complexity, easier to maintain
- **Better UX**: Focus on core value proposition (savings)
- **More reliable**: Fewer moving parts = fewer bugs

## Next Steps
1. Create simplified notification service
2. Remove DeviceActivity dependencies
3. Update views to remove app monitoring features
4. Test and measure performance improvements

