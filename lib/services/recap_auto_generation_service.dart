// lib/services/recap_auto_generation_service.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/recap_template.dart';
import 'firestore_service.dart';
import 'local_video_storage_service.dart';
import 'video_analysis_service.dart';
import 'recap_template_service.dart';

/// Service for automatically generating weekly recaps
class RecapAutoGenerationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final LocalVideoStorageService _localStorage = LocalVideoStorageService();
  final VideoAnalysisService _analysisService = VideoAnalysisService();
  final RecapTemplateService _templateService = RecapTemplateService();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Auto-generate weekly recap for the current week
  Future<bool> autoGenerateWeeklyRecap() async {
    try {
      print('[AUTO_RECAP] Starting auto-generation...');

      final user = _auth.currentUser;
      if (user == null) {
        print('[AUTO_RECAP] No user logged in');
        return false;
      }

      // Load user preferences
      final prefs = await loadRecapPreferences();
      
      // Check if auto-generation is enabled
      if (!prefs.autoGenerate) {
        print('[AUTO_RECAP] Auto-generation is disabled');
        return false;
      }

      // Get active week
      final activeWeek = await _firestoreService.getActiveWeekNow();
      if (activeWeek == null) {
        print('[AUTO_RECAP] No active week found');
        return false;
      }

      final weekId = activeWeek['weekId'] as String;
      print('[AUTO_RECAP] Processing week: $weekId');

      // Get all uploaded videos for the week
      final allVideos = await _firestoreService.getAllUploadedVideos();
      final weekVideos = allVideos
          .where((v) => v['weekId'] == weekId && v['uploadStatus'] == 'uploaded')
          .toList();

      if (weekVideos.length < 3) {
        print('[AUTO_RECAP] Not enough videos (${weekVideos.length}/3)');
        return false;
      }

      print('[AUTO_RECAP] Found ${weekVideos.length} videos for recap');

      // Check if recap already exists
      final existingRecaps = await _firestoreService.getWeeklyRecaps(isAdmin: false);
      final hasRecap = existingRecaps.any((r) => r['weekId'] == weekId);
      
      if (hasRecap) {
        print('[AUTO_RECAP] Recap already exists for week $weekId');
        return false;
      }

      // Analyze videos and create segments
      final segments = await _analyzeAndCreateSegments(
        weekVideos: weekVideos,
        targetDuration: prefs.targetDuration,
        style: prefs.defaultTemplate,
      );

      if (segments.isEmpty) {
        print('[AUTO_RECAP] Failed to create segments');
        return false;
      }

      // Call enhanced Cloud Function
      final result = await _callEnhancedRecapFunction(
        segments: segments,
        templateStyle: prefs.defaultTemplate,
        effects: prefs.effects,
        musicBPM: prefs.musicBPM,
        weekId: weekId,
        uid: user.uid,
      );

      if (result['success'] == true) {
        // Save recap to Firestore
        await _firestoreService.saveWeeklyRecap(
          weekId: weekId,
          recapUrl: result['recapUrl'],
          clipsCount: segments.length,
          duration: result['duration'] ?? '',
          isAdmin: false,
        );

        // Show notification
        await _showSuccessNotification(weekId);

        print('[AUTO_RECAP] Recap generated successfully');
        return true;
      } else {
        print('[AUTO_RECAP] Cloud function failed: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('[AUTO_RECAP] Error: $e');
      return false;
    }
  }

  /// Analyze videos and create smart segments
  Future<List<VideoSegment>> _analyzeAndCreateSegments({
    required List<Map<String, dynamic>> weekVideos,
    required double targetDuration,
    required RecapTemplateStyle style,
  }) async {
    try {
      // Sort videos by day index
      weekVideos.sort((a, b) {
        final aDay = a['dayIndex'] ?? 0;
        final bDay = b['dayIndex'] ?? 0;
        return aDay.compareTo(bDay);
      });

      // Calculate target duration per video
      final durationPerVideo = _templateService.calculateTargetDurationPerVideo(
        style: style,
        videoCount: weekVideos.length,
        totalTargetDuration: targetDuration,
      );

      print('[AUTO_RECAP] Target duration per video: ${durationPerVideo}s');

      final allSegments = <VideoSegment>[];

      for (final video in weekVideos) {
        // Get local path
        final localPath = await _localStorage.getVideoPath(
          video['weekId'],
          video['dayIndex'],
        );

        if (localPath == null || localPath.isEmpty) {
          print('[AUTO_RECAP] No local path for video ${video['dayId']}');
          continue;
        }

        // Find best moments in this video
        final segments = await _analysisService.findBestMoments(
          videoPath: localPath,
          videoUrl: video['storageDownloadUrl'] ?? '',
          targetDuration: durationPerVideo,
          dayId: video['dayId'] ?? 'Unknown',
          emoji: video['emoji'] ?? '📹',
          description: video['description'] ?? '',
          dayIndex: video['dayIndex'] ?? 0,
        );

        allSegments.addAll(segments);
      }

      // Adjust durations to fit target
      final adjustedSegments = _templateService.adjustSegmentDurations(
        segments: allSegments,
        targetDuration: targetDuration,
        style: style,
      );

      print('[AUTO_RECAP] Created ${adjustedSegments.length} segments');
      return adjustedSegments;
    } catch (e) {
      print('[AUTO_RECAP] Error creating segments: $e');
      return [];
    }
  }

  /// Call the enhanced recap Cloud Function
  Future<Map<String, dynamic>> _callEnhancedRecapFunction({
    required List<VideoSegment> segments,
    required RecapTemplateStyle templateStyle,
    required RecapEffectsConfig effects,
    required int musicBPM,
    required String weekId,
    required String uid,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not signed in');

      final idToken = await user.getIdToken();

      const functionUrl =
          'https://us-central1-thort-jivit.cloudfunctions.net/createEnhancedRecap';

      print('[AUTO_RECAP] Calling enhanced recap function');

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'videoSegments': segments.map((s) => s.toJson()).toList(),
          'templateStyle': templateStyle.identifier,
          'effects': effects.toJson(),
          'musicBPM': musicBPM,
          'weekId': weekId,
          'uid': uid,
        }),
      );

      print('[AUTO_RECAP] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Unknown error');
      }
    } catch (e) {
      print('[AUTO_RECAP] Cloud function error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Load user's recap preferences
  Future<RecapPreferences> loadRecapPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('recap_preferences');
      
      if (json != null) {
        final data = jsonDecode(json);
        return RecapPreferences.fromJson(data);
      }
      
      // Return default preferences
      return RecapPreferences();
    } catch (e) {
      print('[AUTO_RECAP] Error loading preferences: $e');
      return RecapPreferences();
    }
  }

  /// Save user's recap preferences
  Future<void> saveRecapPreferences(RecapPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recap_preferences', jsonEncode(preferences.toJson()));
      print('[AUTO_RECAP] Preferences saved');
    } catch (e) {
      print('[AUTO_RECAP] Error saving preferences: $e');
    }
  }

  /// Show success notification
  Future<void> _showSuccessNotification(String weekId) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'recap_channel',
        'Weekly Recap',
        channelDescription: 'Notifications for weekly recap generation',
        importance: Importance.high,
        priority: Priority.high,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        1,
        '🎬 Your week is ready!',
        'Your weekly recap for $weekId has been created. Tap to view!',
        notificationDetails,
      );
    } catch (e) {
      print('[AUTO_RECAP] Notification error: $e');
    }
  }

  /// Initialize notifications
  Future<void> initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }
}

