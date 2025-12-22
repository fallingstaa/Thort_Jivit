# Daily Notification Reminder System

## Overview
The app includes a **smart daily notification reminder system** that encourages users to record their daily video at 12 PM every day. The system intelligently checks if the user has already recorded before sending a notification, preventing unnecessary interruptions.

## Features

### 1. Smart Daily Reminders at 12 PM
- Notifications are automatically scheduled for 12:00 PM local time every day
- **Smart Detection**: The system checks if the user has already recorded today
- **Conditional Sending**: Notifications are **only sent if the user hasn't recorded yet**
- Users receive a friendly reminder: "Time to Record! 🎥"
- Message: "Capture your daily moment and keep your streak going! 📹"
- **No Spam**: If you've already recorded, you won't receive the notification

### 2. Settings Integration
- Users can toggle notifications ON/OFF from the Profile screen
- Setting is saved using SharedPreferences and persists across app restarts
- Toggle location: Profile → Privacy & Security → Notifications
- **Test Notification Button** - Instantly test if notifications are working (only available when notifications are enabled)

### 3. Permission Handling
- Automatically requests notification permissions on Android 13+ and iOS
- Supports the following permissions:
  - POST_NOTIFICATIONS (Android 13+)
  - SCHEDULE_EXACT_ALARM (for precise 12 PM delivery)
  - VIBRATE (for notification alert)
  - RECEIVE_BOOT_COMPLETED (to reschedule after device restart)

### 4. Smart Scheduling & Background Processing
- Notifications are scheduled using **background tasks** (Workmanager) for reliable delivery
- The system uses timezone-aware scheduling based on your device's local time
- **Background Check**: At 12 PM, a background task runs that:
  1. Checks if notifications are enabled
  2. Verifies the user is logged in
  3. Checks if the user has already recorded today
  4. Only sends the notification if the user hasn't recorded yet
  5. Automatically reschedules for the next day at 12 PM
- If you turn on notifications after 12 PM, the first notification will be scheduled for the next day
- Notifications automatically reschedule daily at 12 PM

## Technical Implementation

### Files Modified/Created:
1. **`lib/services/notification_service.dart`** (NEW)
   - Main notification service handling all notification logic
   - Singleton pattern for global access
   - Methods:
     - `initialize()` - Sets up notification system
     - `scheduleDailyNotification()` - Schedules 12 PM daily reminder background task
     - `checkAndShowNotification()` - Checks if user recorded today and shows notification if not
     - `rescheduleDailyNotification()` - Reschedules the daily check for the next day
     - `setNotificationEnabled(bool)` - Toggle notifications on/off
     - `getNotificationEnabled()` - Get current notification status
     - `showTestNotification()` - Show a test notification for debugging

2. **`lib/main.dart`** (MODIFIED)
   - Added notification service initialization on app startup

3. **`lib/services/background_sync_service.dart`** (MODIFIED)
   - Updated `callbackDispatcher()` to handle daily notification check task
   - Initializes Firebase in isolate context for background tasks
   - Calls `checkAndShowNotification()` and reschedules for next day

4. **`lib/screen/profile/profile.dart`** (MODIFIED)
   - Added notification toggle connected to NotificationService
   - Loads notification status on screen init
   - Shows feedback when toggling notifications

5. **`pubspec.yaml`** (MODIFIED)
   - Added `flutter_local_notifications: ^18.0.1`
   - Added `workmanager: ^0.5.2` for background task scheduling
   - Added `timezone: ^0.9.4` for timezone-aware scheduling (now optional)

6. **`android/app/src/main/AndroidManifest.xml`** (MODIFIED)
   - Added notification permissions
   - Added notification receivers for scheduling and boot completion

## How to Use

### For Users:
1. Open the app and go to Profile tab
2. Scroll to "Privacy & Security" section
3. Toggle the "Notifications" switch
4. You'll receive daily reminders at 12 PM when enabled

### For Developers:
```dart
// Get notification service instance
final notificationService = NotificationService();

// Check if notifications are enabled
bool isEnabled = await notificationService.getNotificationEnabled();

// Enable/disable notifications
await notificationService.setNotificationEnabled(true);

// Show a test notification
await notificationService.showTestNotification();

// Check if user recorded today (returns true if not recorded yet)
await notificationService.checkAndShowNotification();
```

## How the Smart Notification Works

### Technical Flow

1. **Scheduling**: When notifications are enabled, a background task is scheduled for 12 PM
2. **Background Execution**: At 12 PM, Workmanager triggers the background task
3. **Check Process**:
   - Verifies notifications are enabled
   - Checks if user is logged in
   - Calls `FirestoreService.canRecordToday()` to check recording status
   - If `canRecordToday()` returns `true` (user hasn't recorded), shows notification
   - If `canRecordToday()` returns `false` (user already recorded), skips notification
4. **Rescheduling**: After execution, automatically reschedules for the next day at 12 PM

### Benefits

- ✅ **No Unnecessary Notifications**: Users who already recorded won't be bothered
- ✅ **Reliable Delivery**: Uses background tasks that work even when app is closed
- ✅ **Battery Efficient**: Only runs once per day at the scheduled time
- ✅ **User-Friendly**: Respects user's recording status automatically

## Future Enhancements

Potential improvements that could be added:
1. **Customizable notification time** - Allow users to set their preferred reminder time
2. **Notification analytics** - Track notification open rates and engagement
3. **Multiple reminders** - Optional second reminder in the evening if user hasn't recorded
4. **Streak reminders** - Special notifications for streak milestones
5. **Custom notification messages** - Allow users to personalize reminder messages

## Testing

To test the notification system:

1. **Enable notifications:**
   - Go to Profile → Toggle Notifications ON
   - Check that you see "🔔 Daily reminders enabled at 12 PM"

2. **Test notification using the Test Button (RECOMMENDED):**
   - Go to Profile → Privacy & Security
   - Make sure Notifications toggle is ON
   - Tap the "Test Notification" button
   - You should see: "📨 Sending test notification..."
   - Then: "✅ Test notification sent! Check your notification tray."
   - Check your device's notification tray for the test notification
   - **Note:** Button is disabled when notifications are OFF (appears gray)

3. **Test immediate notification (via code):**
   - Add this to your test code:
   ```dart
   await NotificationService().showTestNotification();
   ```

4. **Check scheduled notifications:**
   - The notification will automatically fire at 12 PM the next day
   - Or change system time to 11:59 AM and wait for 12:00 PM

5. **Test toggle:**
   - Toggle notifications OFF
   - Check that you see "🔕 Daily reminders disabled"
   - No notifications should be received
   - Test button becomes disabled (gray)

## Troubleshooting

### Notifications not appearing:
1. Check if notification permission is granted in device settings
2. Verify that "Do Not Disturb" mode is not enabled
3. Check if the app has been force-stopped (may prevent scheduled notifications)
4. Ensure battery optimization is not enabled for the app

### Notifications appearing at wrong time:
1. Verify device timezone is correct
2. Check that device has automatic date & time enabled
3. Restart the app to reinitialize notification scheduling

## Platform-Specific Notes

### Android:
- Requires Android 13 (API 33)+ for POST_NOTIFICATIONS permission
- Uses AndroidScheduleMode.exactAllowWhileIdle for reliable delivery
- Notifications persist after device restart (RECEIVE_BOOT_COMPLETED)

### iOS:
- Requires user permission for alerts, badge, and sound
- Notifications may be delayed if app is in low-power mode
- Banner style notification with default sound

## Dependencies

- `flutter_local_notifications: ^18.0.1` - Local notification delivery
- `workmanager: ^0.5.2` - Background task scheduling for smart notification checks
- `shared_preferences: ^2.0.15` - Storing notification preferences
- `timezone: ^0.9.4` - Timezone-aware scheduling (optional, for future enhancements)

## License
Part of the THOT JIVIT (Life Record) application.
