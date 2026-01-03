# Savings-Focused App Pivot

## New App Focus
**Core Value Proposition**: Soteria is a savings assistant that reminds users to save before spending.

## Core Features (Free/Base App)
1. **Savings Goals**: Set daily or weekly savings targets
2. **Savings Reminders**: Notifications to remind users to save before spending
3. **Savings Tracking**: Track progress toward goals
4. **Simple Dashboard**: View savings progress

## Premium Features (Subscription Add-On)
1. **Quiet Hours**: App monitoring and blocking during specific hours
2. **Advanced Analytics**: Detailed spending and savings insights
3. **Multiple Goals**: Track multiple savings goals simultaneously

## Notification System

### Savings Reminder Notifications
- **Frequency**: Daily or weekly (user choice)
- **Message**: "Before you spend money, remember to save your desired daily savings"
- **Timing**: 
  - Daily: User-specified time (e.g., 9 AM)
  - Weekly: User-specified day and time (e.g., Monday 9 AM)
- **Action**: Tapping notification opens app to savings screen

### Implementation
- Use `UNTimeIntervalNotificationTrigger` for daily reminders
- Use `UNCalendarNotificationTrigger` for weekly reminders
- Simple, reliable, no DeviceActivity complexity

## Benefits
1. **Faster Startup**: No DeviceActivity initialization delays
2. **Simpler Codebase**: Less complexity, easier to maintain
3. **Clear Value Prop**: Focus on core savings functionality
4. **Better UX**: Users understand the app's purpose immediately
5. **Monetization**: Premium features as add-on subscription

## Migration Plan
1. Create `SavingsReminderService` for notification scheduling
2. Move QuietHours to premium subscription feature
3. Update UI to emphasize savings over app monitoring
4. Test and measure performance improvements

