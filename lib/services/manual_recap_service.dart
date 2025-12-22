// lib/services/manual_recap_service.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/recap_template.dart';
import 'local_video_storage_service.dart';
import 'video_analysis_service.dart';
import 'recap_template_service.dart';

/// Service for manually generating recaps with custom templates
class ManualRecapService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalVideoStorageService _localStorage = LocalVideoStorageService();
  final VideoAnalysisService _analysisService = VideoAnalysisService();
  final RecapTemplateService _templateService = RecapTemplateService();

  /// Manually generate a recap with specified template and settings
  Future<Map<String, dynamic>> generateRecap({
    required String weekId,
    required List<Map<String, dynamic>> weekVideos,
    required RecapTemplateStyle templateStyle,
    required RecapEffectsConfig effects,
    required double targetDuration,
    int musicBPM = 120,
  }) async {
    try {
      print('[MANUAL_RECAP] Generating $templateStyle recap for week $weekId');

      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      if (weekVideos.length < 3) {
        return {
          'success': false,
          'message': 'Need at least 3 videos to create recap',
        };
      }

      // Analyze videos and create segments
      final segments = await _analyzeAndCreateSegments(
        weekVideos: weekVideos,
        targetDuration: targetDuration,
        style: templateStyle,
      );

      if (segments.isEmpty) {
        return {
          'success': false,
          'message': 'Failed to create segments',
        };
      }

      // Call enhanced Cloud Function
      final result = await _callEnhancedRecapFunction(
        segments: segments,
        templateStyle: templateStyle,
        effects: effects,
        musicBPM: musicBPM,
        weekId: weekId,
        uid: user.uid,
      );

      return result;
    } catch (e) {
      print('[MANUAL_RECAP] Error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
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

      print('[MANUAL_RECAP] Target duration per video: ${durationPerVideo}s');

      final allSegments = <VideoSegment>[];

      for (final video in weekVideos) {
        // Get local path
        final localPath = await _localStorage.getVideoPath(
          video['weekId'],
          video['dayIndex'],
        );

        if (localPath == null || localPath.isEmpty) {
          print('[MANUAL_RECAP] No local path for video ${video['dayId']}');
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

      print('[MANUAL_RECAP] Created ${adjustedSegments.length} segments');
      return adjustedSegments;
    } catch (e) {
      print('[MANUAL_RECAP] Error creating segments: $e');
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

      print('[MANUAL_RECAP] Calling enhanced recap function');

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

      print('[MANUAL_RECAP] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Unknown error');
      }
    } catch (e) {
      print('[MANUAL_RECAP] Cloud function error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}

