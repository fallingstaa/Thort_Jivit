import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing local video storage
class LocalVideoStorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save a video to local storage
  /// Returns the local file path
  Future<String> saveVideoLocally({
    required File videoFile,
    required String weekId,
    required int dayIndex,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not signed in');

      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      
      // Create organized folder structure: videos/weekId/
      final weekDir = Directory('${directory.path}/videos/$weekId');
      if (!await weekDir.exists()) {
        await weekDir.create(recursive: true);
      }

      // Create filename with dayIndex
      final filename = 'day${dayIndex}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final localPath = '${weekDir.path}/$filename';

      // Copy video to local storage
      final localFile = await videoFile.copy(localPath);
      
      // Get file size
      final fileSize = await localFile.length();

      print('[LOCAL_STORAGE] Video saved locally: $localPath');
      print('[LOCAL_STORAGE] File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      return localPath;
    } catch (e) {
      print('[LOCAL_STORAGE] Error saving video locally: $e');
      rethrow;
    }
  }

  /// Get local video path for a specific week/day
  Future<String?> getVideoPath(String weekId, int dayIndex) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final weekDir = Directory('${directory.path}/videos/$weekId');
      
      if (!await weekDir.exists()) {
        return null;
      }

      // Find file matching dayIndex pattern
      final files = await weekDir.list().toList();
      for (var file in files) {
        if (file is File && file.path.contains('day$dayIndex')) {
          return file.path;
        }
      }
      
      return null;
    } catch (e) {
      print('[LOCAL_STORAGE] Error getting video path: $e');
      return null;
    }
  }

  /// Get all video paths for a specific week
  Future<List<String>> getVideosForWeek(String weekId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final weekDir = Directory('${directory.path}/videos/$weekId');
      
      if (!await weekDir.exists()) {
        return [];
      }

      final files = await weekDir.list().toList();
      return files
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4'))
          .map((f) => f.path)
          .toList();
    } catch (e) {
      print('[LOCAL_STORAGE] Error getting week videos: $e');
      return [];
    }
  }

  /// Calculate total storage usage
  Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${directory.path}/videos');
      
      if (!await videosDir.exists()) {
        return {
          'totalBytes': 0,
          'totalMB': 0.0,
          'videoCount': 0,
          'compressedCount': 0,
        };
      }

      int totalBytes = 0;
      int videoCount = 0;
      int compressedCount = 0;

      await for (var entity in videosDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          final size = await entity.length();
          totalBytes += size;
          videoCount++;
          
          // Check if compressed (from metadata)
          if (entity.path.contains('_compressed')) {
            compressedCount++;
          }
        }
      }

      final totalMB = totalBytes / 1024 / 1024;

      print('[LOCAL_STORAGE] Total storage: ${totalMB.toStringAsFixed(2)} MB');
      print('[LOCAL_STORAGE] Video count: $videoCount');
      print('[LOCAL_STORAGE] Compressed count: $compressedCount');

      return {
        'totalBytes': totalBytes,
        'totalMB': totalMB,
        'videoCount': videoCount,
        'compressedCount': compressedCount,
      };
    } catch (e) {
      print('[LOCAL_STORAGE] Error calculating storage usage: $e');
      return {
        'totalBytes': 0,
        'totalMB': 0.0,
        'videoCount': 0,
        'compressedCount': 0,
      };
    }
  }

  /// Delete a specific video from local storage
  Future<bool> deleteVideo(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        print('[LOCAL_STORAGE] Deleted video: $localPath');
        return true;
      }
      return false;
    } catch (e) {
      print('[LOCAL_STORAGE] Error deleting video: $e');
      return false;
    }
  }

  /// Delete all videos for a specific week
  Future<bool> deleteWeekVideos(String weekId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final weekDir = Directory('${directory.path}/videos/$weekId');
      
      if (await weekDir.exists()) {
        await weekDir.delete(recursive: true);
        print('[LOCAL_STORAGE] Deleted week folder: $weekId');
        return true;
      }
      return false;
    } catch (e) {
      print('[LOCAL_STORAGE] Error deleting week videos: $e');
      return false;
    }
  }

  /// Get videos older than specified weeks
  Future<List<Map<String, dynamic>>> getOldVideos(int weeksOld) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${directory.path}/videos');
      
      if (!await videosDir.exists()) {
        return [];
      }

      final cutoffDate = DateTime.now().subtract(Duration(days: weeksOld * 7));
      final oldVideos = <Map<String, dynamic>>[];

      await for (var entity in videosDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            final size = await entity.length();
            oldVideos.add({
              'path': entity.path,
              'modified': stat.modified,
              'size': size,
              'isCompressed': entity.path.contains('_compressed'),
            });
          }
        }
      }

      print('[LOCAL_STORAGE] Found ${oldVideos.length} videos older than $weeksOld weeks');
      return oldVideos;
    } catch (e) {
      print('[LOCAL_STORAGE] Error finding old videos: $e');
      return [];
    }
  }

  /// Check if local video exists
  Future<bool> videoExists(String localPath) async {
    try {
      final file = File(localPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get video file size
  Future<int> getVideoSize(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('[LOCAL_STORAGE] Error getting video size: $e');
      return 0;
    }
  }

  /// Save weekly recap video locally
  Future<String> saveRecapLocally({
    required File recapFile,
    required String weekId,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      // Create recaps folder
      final recapsDir = Directory('${directory.path}/recaps');
      if (!await recapsDir.exists()) {
        await recapsDir.create(recursive: true);
      }

      // Create filename for recap
      final filename = 'recap_${weekId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final localPath = '${recapsDir.path}/$filename';

      // Copy recap to local storage
      await recapFile.copy(localPath);
      
      print('[LOCAL_STORAGE] Recap saved locally: $localPath');
      return localPath;
    } catch (e) {
      print('[LOCAL_STORAGE] Error saving recap locally: $e');
      rethrow;
    }
  }

  /// Get all recap videos
  Future<List<String>> getAllRecaps() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recapsDir = Directory('${directory.path}/recaps');
      
      if (!await recapsDir.exists()) {
        return [];
      }

      final files = await recapsDir.list().toList();
      return files
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4'))
          .map((f) => f.path)
          .toList();
    } catch (e) {
      print('[LOCAL_STORAGE] Error getting recaps: $e');
      return [];
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = await tempDir.list().toList();
      
      for (var file in files) {
        if (file is File && file.path.endsWith('.mp4')) {
          try {
            await file.delete();
          } catch (e) {
            // Ignore errors for individual file deletion
          }
        }
      }
      
      print('[LOCAL_STORAGE] Cleaned up temporary files');
    } catch (e) {
      print('[LOCAL_STORAGE] Error cleaning temp files: $e');
    }
  }
}

