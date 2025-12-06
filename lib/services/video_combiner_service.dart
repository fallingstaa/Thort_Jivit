import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class VideoCombinerService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Combine multiple video URLs into one video using FFmpeg
  /// For web: uses Cloud Function with FFmpeg backend
  /// For mobile/desktop: uses local FFmpeg
  /// Returns success status and a message
  Future<Map<String, dynamic>> combineVideos({
    required List<String> videoUrls,
    required List<String> videoPaths,
  }) async {
    try {
      print('[VIDEO_COMBINER] Starting to combine ${videoUrls.length} videos');

      if (videoUrls.isEmpty || videoUrls.length < 3) {
        return {
          'success': false,
          'message': 'Need at least 3 videos to create a recap',
        };
      }

      if (kIsWeb) {
        // Web: Call Cloud Function to merge videos with FFmpeg
        return await _mergeVideosViaCloudFunction(videoUrls);
      } else {
        // Mobile/Desktop: Use local FFmpeg to merge videos
        return await _mergeVideosLocally(videoPaths);
      }
    } catch (e) {
      print('[VIDEO_COMBINER] Error combining videos: $e');
      return {'success': false, 'message': 'Error creating recap: $e'};
    }
  }

  /// Merge videos via Cloud Function (web)
  Future<Map<String, dynamic>> _mergeVideosViaCloudFunction(
    List<String> videoUrls,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not signed in');
      }

      // Get the Firebase project ID from the current config
      // The function will be at: https://region-projectId.cloudfunctions.net/mergeVideos
      final functionUrl =
          'https://us-central1-thort-jivit.cloudfunctions.net/mergeVideos?uid=${user.uid}';

      print('[VIDEO_COMBINER] Calling Cloud Function: $functionUrl');

      final response = await http
          .post(
            Uri.parse(functionUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'videoUrls': videoUrls}),
          )
          .timeout(
            const Duration(seconds: 120), // 2 minute timeout for merging
            onTimeout: () {
              throw Exception(
                'Cloud Function timeout - video merge taking too long',
              );
            },
          );

      print('[VIDEO_COMBINER] Cloud Function response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print(
            '[VIDEO_COMBINER] Successfully merged ${videoUrls.length} videos',
          );
          return {
            'success': true,
            'message': data['message'] ?? 'Weekly recap created successfully!',
            'recapUrl': data['recapUrl'] ?? '',
            'clipsCount': data['clipsCount'] ?? videoUrls.length,
            'duration': data['duration'] ?? '',
          };
        } else {
          throw Exception(data['error'] ?? 'Unknown error from Cloud Function');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'Cloud Function error: ${errorData['error'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('[VIDEO_COMBINER] Cloud Function error: $e');
      return {'success': false, 'message': 'Error merging videos: $e'};
    }
  }

  /// Merge videos locally using FFmpeg (mobile/desktop)
  Future<Map<String, dynamic>> _mergeVideosLocally(
    List<String> videoPaths,
  ) async {
    try {
      if (videoPaths.isEmpty || videoPaths.length < 3) {
        return {
          'success': false,
          'message': 'Need at least 3 local video files to create a recap',
        };
      }

      // Create a file list for FFmpeg
      final tempDir = Directory.systemTemp;
      final fileListPath =
          '${tempDir.path}/filelist_${DateTime.now().millisecondsSinceEpoch}.txt';
      final fileListContent = videoPaths.map((p) => "file '$p'").join('\n');
      final fileListFile = File(fileListPath);
      await fileListFile.writeAsString(fileListContent);

      final outputPath =
          '${tempDir.path}/recap_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ffmpegCmd =
          "-f concat -safe 0 -i '$fileListPath' -c copy '$outputPath'";

      print('[VIDEO_COMBINER] Running FFmpeg: $ffmpegCmd');
      final session = await FFmpegKit.execute(ffmpegCmd);
      final returnCode = await session.getReturnCode();

      if (returnCode != null && returnCode.isValueSuccess()) {
        print('[VIDEO_COMBINER] FFmpeg merge successful: $outputPath');
        return {
          'success': true,
          'message': 'Weekly recap created successfully!',
          'recapUrl': outputPath,
          'duration': '',
          'clipsCount': videoPaths.length,
        };
      } else {
        final logs = await session.getLogsAsString();
        print('[VIDEO_COMBINER] FFmpeg failed. Logs: $logs');
        return {'success': false, 'message': 'FFmpeg failed to merge videos'};
      }
    } catch (e) {
      print('[VIDEO_COMBINER] Mobile/Desktop merge error: $e');
      return {'success': false, 'message': 'Error creating recap: $e'};
    }
  }

  /// Check if enough videos exist for recap
  bool canCreateRecap(int videoCount) {
    return videoCount >= 3;
  }
}
