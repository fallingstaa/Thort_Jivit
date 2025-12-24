import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:thort_jivit/firebase_options.dart';
import 'local_video_storage_service.dart';
import 'notification_service.dart';
import 'firestore_service.dart';

/// Background service for syncing local videos to Firebase
class BackgroundSyncService {
  static const String syncTaskName = 'videoSyncTask';
  static const String compressionTaskName = 'videoCompressionTask';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final LocalVideoStorageService _localStorage = LocalVideoStorageService();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirestoreService _firestoreService = FirestoreService();

  /// Initialize background sync service
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    await _initializeNotifications();
    
    print('[BACKGROUND_SYNC] Service initialized');
  }

  /// Initialize notifications
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(initSettings);
  }

  /// Schedule nightly sync (11 PM - 5 AM window)
  Future<void> scheduleNightlySync() async {
    // Schedule daily sync at 11 PM
    await Workmanager().registerPeriodicTask(
      'nightlySync',
      syncTaskName,
      frequency: const Duration(hours: 24),
      initialDelay: _calculateInitialDelay(),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    print('[BACKGROUND_SYNC] Nightly sync scheduled');
  }

  /// Calculate delay until next 11 PM
  Duration _calculateInitialDelay() {
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, 23, 0); // 11 PM
    
    if (now.isAfter(nextRun)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }
    
    return nextRun.difference(now);
  }

  /// Schedule weekly compression task (Saturday night)
  Future<void> scheduleWeeklyCompression() async {
    await Workmanager().registerPeriodicTask(
      'weeklyCompression',
      compressionTaskName,
      frequency: const Duration(days: 7),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    print('[BACKGROUND_SYNC] Weekly compression scheduled');
  }

  /// Check if sync conditions are met (WiFi + Charging)
  Future<bool> checkSyncConditions() async {
    try {
      // Check WiFi connection
      final connectivity = await Connectivity().checkConnectivity();
      final isWiFi = connectivity.contains(ConnectivityResult.wifi);
      
      // Check if device is charging
      final battery = Battery();
      final isCharging = await battery.batteryState == BatteryState.charging ||
                        await battery.batteryState == BatteryState.full;
      
      final canSync = isWiFi && isCharging;
      
      print('[BACKGROUND_SYNC] Sync conditions - WiFi: $isWiFi, Charging: $isCharging');
      
      return canSync;
    } catch (e) {
      print('[BACKGROUND_SYNC] Error checking sync conditions: $e');
      return false;
    }
  }

  /// Perform sync - upload pending videos
  Future<Map<String, dynamic>> performSync({bool forceSync = false}) async {
    try {
      print('[BACKGROUND_SYNC] Starting sync...');
      
      // Check conditions unless forced
      if (!forceSync) {
        final canSync = await checkSyncConditions();
        if (!canSync) {
          print('[BACKGROUND_SYNC] Sync conditions not met, skipping');
          return {
            'success': false,
            'message': 'Sync conditions not met (need WiFi + charging)',
            'uploaded': 0,
            'failed': 0,
          };
        }
      }

      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not signed in',
          'uploaded': 0,
          'failed': 0,
        };
      }

      // SECURITY: Cleanup invalid recorded videos before sync
      try {
        print('[BACKGROUND_SYNC] Cleaning up invalid recorded videos...');
        final cleanupResult = await _firestoreService.deleteInvalidRecordedVideos();
        if (cleanupResult['deletedCount'] > 0) {
          print('[BACKGROUND_SYNC] Cleaned up ${cleanupResult['deletedCount']} invalid videos');
        }
      } catch (e) {
        print('[BACKGROUND_SYNC] Error during video cleanup: $e');
        // Continue with sync even if cleanup fails
      }

      // Only premium users are allowed to sync videos to Firebase in background.
      final isPremium = await _firestoreService.isUserPremium();
      if (!isPremium) {
        print(
          '[BACKGROUND_SYNC] User is not premium. Skipping cloud sync for free user.',
        );
        return {
          'success': false,
          'message':
              'Cloud sync is available for premium users only. Your videos are stored safely on this device.',
          'uploaded': 0,
          'failed': 0,
        };
      }

      // Get all pending videos from Firestore
      final pendingVideos = await _getPendingVideos(user.uid);
      
      if (pendingVideos.isEmpty) {
        print('[BACKGROUND_SYNC] No pending videos to sync');
        return {
          'success': true,
          'message': 'No videos to sync',
          'uploaded': 0,
          'failed': 0,
        };
      }

      print('[BACKGROUND_SYNC] Found ${pendingVideos.length} pending videos');

      int uploaded = 0;
      int failed = 0;

      for (var videoDoc in pendingVideos) {
        try {
          final data = videoDoc.data() as Map<String, dynamic>;
          final localPath = data['localPath'] as String?;
          
          if (localPath == null || localPath.isEmpty) {
            print('[BACKGROUND_SYNC] No local path for video ${videoDoc.id}');
            continue;
          }

          // Check if file exists
          final exists = await _localStorage.videoExists(localPath);
          if (!exists) {
            print('[BACKGROUND_SYNC] Local file not found: $localPath');
            await _updateVideoStatus(user.uid, videoDoc, 'failed', 'Local file not found');
            failed++;
            continue;
          }

          // Upload to Firebase Storage
          final storagePath = data['storagePath'] as String;
          final downloadUrl = await _uploadToStorage(localPath, storagePath);

          if (downloadUrl != null) {
            // Update Firestore with download URL
            await _updateVideoStatus(
              user.uid,
              videoDoc,
              'uploaded',
              null,
              downloadUrl: downloadUrl,
            );
            uploaded++;
            print('[BACKGROUND_SYNC] Uploaded: ${videoDoc.id}');
          } else {
            await _updateVideoStatus(user.uid, videoDoc, 'failed', 'Upload failed');
            failed++;
          }
        } catch (e) {
          print('[BACKGROUND_SYNC] Error uploading video ${videoDoc.id}: $e');
          failed++;
        }
      }

      print('[BACKGROUND_SYNC] Sync completed - Uploaded: $uploaded, Failed: $failed');

      // Show notification
      if (uploaded > 0) {
        await _showNotification(
          'Sync Complete',
          'Successfully synced $uploaded video${uploaded > 1 ? 's' : ''}',
        );
      }

      return {
        'success': true,
        'message': 'Sync completed',
        'uploaded': uploaded,
        'failed': failed,
      };
    } catch (e) {
      print('[BACKGROUND_SYNC] Sync error: $e');
      return {
        'success': false,
        'message': 'Sync error: $e',
        'uploaded': 0,
        'failed': 0,
      };
    }
  }

  /// Get pending videos that need to be uploaded
  Future<List<QueryDocumentSnapshot>> _getPendingVideos(String uid) async {
    try {
      final weeksSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('weeks')
          .get();

      final pendingVideos = <QueryDocumentSnapshot>[];

      for (var weekDoc in weeksSnapshot.docs) {
        final videosSnapshot = await weekDoc.reference
            .collection('videos')
            .where('uploadStatus', isEqualTo: 'pending')
            .get();
        
        pendingVideos.addAll(videosSnapshot.docs);
      }

      return pendingVideos;
    } catch (e) {
      print('[BACKGROUND_SYNC] Error getting pending videos: $e');
      return [];
    }
  }

  /// Upload file to Firebase Storage
  Future<String?> _uploadToStorage(String localPath, String storagePath) async {
    try {
      final file = File(localPath);
      final ref = _storage.ref().child(storagePath);
      
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('[BACKGROUND_SYNC] Upload error: $e');
      return null;
    }
  }

  /// Update video status in Firestore
  Future<void> _updateVideoStatus(
    String uid,
    QueryDocumentSnapshot videoDoc,
    String status,
    String? error, {
    String? downloadUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'uploadStatus': status,
        'lastSyncAttempt': FieldValue.serverTimestamp(),
      };

      if (downloadUrl != null) {
        updateData['storageDownloadUrl'] = downloadUrl;
        updateData['uploadedAt'] = FieldValue.serverTimestamp();
      }

      if (error != null) {
        updateData['uploadError'] = error;
      }

      await videoDoc.reference.update(updateData);
    } catch (e) {
      print('[BACKGROUND_SYNC] Error updating video status: $e');
    }
  }

  /// Retry failed uploads
  Future<Map<String, dynamic>> retryFailedUploads() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not signed in'};
      }

      // Get failed videos
      final weeksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeks')
          .get();

      final failedVideos = <QueryDocumentSnapshot>[];

      for (var weekDoc in weeksSnapshot.docs) {
        final videosSnapshot = await weekDoc.reference
            .collection('videos')
            .where('uploadStatus', isEqualTo: 'failed')
            .get();
        
        failedVideos.addAll(videosSnapshot.docs);
      }

      if (failedVideos.isEmpty) {
        return {
          'success': true,
          'message': 'No failed uploads to retry',
          'retried': 0,
        };
      }

      // Reset to pending so they'll be picked up in next sync
      for (var videoDoc in failedVideos) {
        await videoDoc.reference.update({'uploadStatus': 'pending'});
      }

      print('[BACKGROUND_SYNC] Reset ${failedVideos.length} failed videos to pending');

      return {
        'success': true,
        'message': 'Failed uploads queued for retry',
        'retried': failedVideos.length,
      };
    } catch (e) {
      print('[BACKGROUND_SYNC] Error retrying failed uploads: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Show notification
  Future<void> _showNotification(String title, String body) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'sync_channel',
        'Video Sync',
        channelDescription: 'Notifications for video sync status',
        importance: Importance.low,
        priority: Priority.low,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );
      
      const notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        0,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      print('[BACKGROUND_SYNC] Notification error: $e');
    }
  }

  /// Schedule weekly recap auto-generation (Sunday night at 11 PM)
  Future<void> scheduleWeeklyRecapGeneration() async {
    await Workmanager().registerPeriodicTask(
      'weeklyRecapAutoGen',
      'weeklyRecapTask',
      frequency: const Duration(days: 7),
      initialDelay: _calculateNextSunday11PM(),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    print('[BACKGROUND_SYNC] Weekly recap auto-generation scheduled');
  }

  /// Calculate delay until next Sunday at 11 PM
  Duration _calculateNextSunday11PM() {
    final now = DateTime.now();
    var nextSunday = DateTime(now.year, now.month, now.day, 23, 0); // 11 PM today
    
    // Find next Sunday
    while (nextSunday.weekday != DateTime.sunday || now.isAfter(nextSunday)) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }
    
    final delay = nextSunday.difference(now);
    print('[BACKGROUND_SYNC] Next Sunday recap generation: $nextSunday (in ${delay.inHours}h)');
    return delay;
  }

  /// Cancel all scheduled tasks
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    print('[BACKGROUND_SYNC] All tasks cancelled');
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final weeksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeks')
          .get();

      int pending = 0;
      int uploaded = 0;
      int failed = 0;

      for (var weekDoc in weeksSnapshot.docs) {
        final videosSnapshot = await weekDoc.reference
            .collection('videos')
            .get();
        
        for (var video in videosSnapshot.docs) {
          final status = video.data()['uploadStatus'] as String?;
          if (status == 'pending') pending++;
          else if (status == 'uploaded') uploaded++;
          else if (status == 'failed') failed++;
        }
      }

      return {
        'pending': pending,
        'uploaded': uploaded,
        'failed': failed,
        'total': pending + uploaded + failed,
      };
    } catch (e) {
      print('[BACKGROUND_SYNC] Error getting sync stats: $e');
      return {};
    }
  }
}

/// Callback dispatcher for background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('[BACKGROUND_SYNC] Background task started: $task');
      
      // Initialize Firebase in the isolate if not already initialized
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('[BACKGROUND_SYNC] Firebase initialized in isolate');
      } catch (e) {
        // Firebase might already be initialized, ignore error
        print('[BACKGROUND_SYNC] Firebase init check: $e');
      }
      
      if (task == BackgroundSyncService.syncTaskName) {
        // Perform video sync
        final syncService = BackgroundSyncService();
        await syncService.performSync();
      } else if (task == BackgroundSyncService.compressionTaskName) {
        // This will be handled by VideoCompressionService
        print('[BACKGROUND_SYNC] Compression task triggered');
      } else if (task == 'weeklyRecapTask') {
        // Auto-generate weekly recap
        print('[BACKGROUND_SYNC] Weekly recap auto-generation triggered');
        // This will be handled by the auto-generation service
        // We'll implement this in a separate service file
      } else if (task == NotificationService.dailyNotificationTaskName) {
        // Daily notification check - check if user has recorded and show notification if not
        print('[BACKGROUND_SYNC] Daily notification check task triggered');
        final notificationService = NotificationService();
        await notificationService.checkAndShowNotification();
        // Reschedule for the next day at 12 PM
        await notificationService.rescheduleDailyNotification();
      }
      
      return Future.value(true);
    } catch (e) {
      print('[BACKGROUND_SYNC] Background task error: $e');
      return Future.value(false);
    }
  });
}

