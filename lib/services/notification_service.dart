import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thort_jivit/services/firestore_service.dart';
import 'package:workmanager/workmanager.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirestoreService _firestoreService = FirestoreService();

  static const String _notificationEnabledKey = 'notification_enabled';
  static const int _dailyNotificationId = 0;
  static const String dailyNotificationTaskName = 'dailyNotificationCheck';

  /// Initialize the notification service
  Future<void> initialize() async {
    print('[NOTIFICATION] Initializing notification service...');

    // Initialize timezone data
    tz_data.initializeTimeZones();
    // Set local timezone (important for scheduling)
    // If you want to use a specific timezone, you can set it like:
    // tz.setLocalLocation(tz.getLocation('America/New_York'));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with settings
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+ and iOS
    await _requestPermissions();

    print('[NOTIFICATION] Notification service initialized');

    // Schedule notifications if enabled
    final isEnabled = await getNotificationEnabled();
    if (isEnabled) {
      await scheduleDailyNotification();
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Android 13+ permission request
    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // iOS permission request
    final iosPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('[NOTIFICATION] Notification tapped: ${response.payload}');
    // You can add navigation logic here if needed
    // For example, navigate to the recording screen
  }

  /// Schedule daily notification at 12 PM using background task
  /// This will check if user has recorded before sending notification
  Future<void> scheduleDailyNotification() async {
    print('[NOTIFICATION] Scheduling daily notification check at 12 PM...');

    try {
      // Cancel any existing scheduled notifications
      await _notifications.cancel(_dailyNotificationId);
      
      // Cancel any existing background task
      await Workmanager().cancelByUniqueName(dailyNotificationTaskName);

      // Calculate delay until next 12 PM
      final now = DateTime.now();
      var next12PM = DateTime(now.year, now.month, now.day, 12, 0); // 12 PM today

      // If 12 PM has already passed today, schedule for tomorrow
      if (next12PM.isBefore(now)) {
        next12PM = next12PM.add(const Duration(days: 1));
      }

      final delay = next12PM.difference(now);

      print(
        '[NOTIFICATION] Scheduling notification check for: ${next12PM.toString()} (in ${delay.inHours}h ${delay.inMinutes % 60}m)',
      );

      // Schedule a one-time task that will check and show notification
      // After it runs, it will reschedule itself for the next day
      await Workmanager().registerOneOffTask(
        dailyNotificationTaskName,
        dailyNotificationTaskName,
        initialDelay: delay,
        constraints: Constraints(),
      );

      print('[NOTIFICATION] Daily notification check scheduled successfully');
    } catch (e) {
      print('[NOTIFICATION] Error scheduling notification: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    print('[NOTIFICATION] Canceling all notifications...');
    await _notifications.cancelAll();
    await Workmanager().cancelByUniqueName(dailyNotificationTaskName);
    print('[NOTIFICATION] All notifications canceled');
  }
  
  /// Reschedule the daily notification check for the next day at 12 PM
  /// This is called after the background task runs
  Future<void> rescheduleDailyNotification() async {
    print('[NOTIFICATION] Rescheduling daily notification check...');
    await scheduleDailyNotification();
  }

  /// Initialize notification plugin for use in isolate (background task)
  /// This ensures the plugin is ready when called from Workmanager
  Future<void> _ensureNotificationPluginInitialized() async {
    try {
      // Check if already initialized by trying to get pending notifications
      // If it throws, we need to initialize
      await _notifications.pendingNotificationRequests();
    } catch (e) {
      // Plugin not initialized, initialize it
      print('[NOTIFICATION] Initializing notification plugin in isolate...');
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // Already requested in main app
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _notifications.initialize(initSettings);
      print('[NOTIFICATION] Notification plugin initialized in isolate');
    }
  }

  /// Check if user has recorded today and show notification if not
  /// This method can be called by a background task or at app launch
  Future<void> checkAndShowNotification() async {
    print('[NOTIFICATION] Checking if user has recorded today...');

    // Ensure notification plugin is initialized (important for isolate context)
    await _ensureNotificationPluginInitialized();

    // Check if notifications are enabled
    final isEnabled = await getNotificationEnabled();
    if (!isEnabled) {
      print('[NOTIFICATION] Notifications are disabled');
      return;
    }

    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[NOTIFICATION] User not logged in, skipping notification');
      return;
    }

    // Check if user has recorded today
    final canRecord = await _firestoreService.canRecordToday();

    print('[NOTIFICATION] Can record today: $canRecord');

    // If canRecord is true, it means user hasn't recorded yet
    // Show notification to remind them
    if (canRecord) {
      await _showImmediateNotification();
    } else {
      print('[NOTIFICATION] User has already recorded today, no notification');
    }
  }

  /// Show an immediate notification (for testing or manual trigger)
  Future<void> _showImmediateNotification() async {
    print('[NOTIFICATION] Showing immediate notification...');

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Recording Reminder',
      channelDescription: 'Reminds you to record your daily video',
      importance: Importance.high,
      priority: Priority.high,
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Capture your daily moment and keep your streak going! 📹',
      ),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _dailyNotificationId,
      'Time to Record! 🎥',
      'Capture your daily moment and keep your streak going! 📹',
      notificationDetails,
      payload: 'daily_reminder',
    );

    print('[NOTIFICATION] Immediate notification shown');
  }

  /// Get notification enabled status from preferences
  Future<bool> getNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true (enabled)
    return prefs.getBool(_notificationEnabledKey) ?? true;
  }

  /// Set notification enabled status
  Future<void> setNotificationEnabled(bool enabled) async {
    print('[NOTIFICATION] Setting notification enabled: $enabled');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);

    if (enabled) {
      // Schedule notifications
      await scheduleDailyNotification();
    } else {
      // Cancel all notifications
      await cancelAllNotifications();
    }

    print('[NOTIFICATION] Notification enabled status saved: $enabled');
  }

  /// Show a test notification (for debugging)
  Future<void> showTestNotification() async {
    print('[NOTIFICATION] Showing test notification...');
    await _showImmediateNotification();
  }
}
