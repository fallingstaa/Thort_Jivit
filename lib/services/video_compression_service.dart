import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'local_video_storage_service.dart';

/// Service for compressing old videos to save storage space
class VideoCompressionService {
  final LocalVideoStorageService _localStorage = LocalVideoStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Initialize the compression service
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  /// Compress videos older than specified weeks (default: 4 weeks)
  Future<Map<String, dynamic>> compressOldVideos({int weeksOld = 4}) async {
    try {
      print('[COMPRESSION] Starting compression of videos older than $weeksOld weeks...');
      
      final oldVideos = await _localStorage.getOldVideos(weeksOld);
      
      if (oldVideos.isEmpty) {
        print('[COMPRESSION] No old videos to compress');
        return {
          'success': true,
          'message': 'No videos to compress',
          'compressed': 0,
          'savedBytes': 0,
        };
      }

      // Filter out already compressed videos
      final toCompress = oldVideos.where((v) => !v['isCompressed']).toList();
      
      if (toCompress.isEmpty) {
        print('[COMPRESSION] All old videos already compressed');
        return {
          'success': true,
          'message': 'All videos already compressed',
          'compressed': 0,
          'savedBytes': 0,
        };
      }

      print('[COMPRESSION] Found ${toCompress.length} videos to compress');

      int compressed = 0;
      int failed = 0;
      int totalSavedBytes = 0;

      for (var video in toCompress) {
        try {
          final inputPath = video['path'] as String;
          
          final result = await compressVideo(inputPath, inputPath);
          
          if (result['success']) {
            compressed++;
            final savedBytes = result['savedBytes'] as int;
            totalSavedBytes += savedBytes;
            
            print('[COMPRESSION] Compressed: ${inputPath.split('/').last} - Saved: ${(savedBytes / 1024 / 1024).toStringAsFixed(2)} MB');
          } else {
            failed++;
            print('[COMPRESSION] Failed to compress: ${inputPath.split('/').last}');
          }
        } catch (e) {
          failed++;
          print('[COMPRESSION] Error compressing video: $e');
        }
      }

      print('[COMPRESSION] Compression completed - Compressed: $compressed, Failed: $failed');
      print('[COMPRESSION] Total saved: ${(totalSavedBytes / 1024 / 1024).toStringAsFixed(2)} MB');

      // Show notification
      if (compressed > 0) {
        await _showNotification(
          'Compression Complete',
          'Compressed $compressed video${compressed > 1 ? 's' : ''}, saved ${(totalSavedBytes / 1024 / 1024).toStringAsFixed(1)} MB',
        );
      }

      return {
        'success': true,
        'message': 'Compression completed',
        'compressed': compressed,
        'failed': failed,
        'savedBytes': totalSavedBytes,
        'savedMB': totalSavedBytes / 1024 / 1024,
      };
    } catch (e) {
      print('[COMPRESSION] Error in compressOldVideos: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'compressed': 0,
        'savedBytes': 0,
      };
    }
  }

  /// Compress a single video file
  /// Returns the compressed file path and space saved
  Future<Map<String, dynamic>> compressVideo(
    String inputPath,
    String outputPath,
  ) async {
    try {
      // Get original file size
      final inputFile = File(inputPath);
      final originalSize = await inputFile.length();
      
      // Create temporary output path
      final tempOutputPath = '${outputPath}_compressed_temp.mp4';
      
      // FFmpeg command for H.265 compression with good quality
      // CRF 28 provides good balance between quality and file size
      // preset medium balances encoding speed and compression
      final command = '-i "$inputPath" '
          '-c:v libx264 ' // Using H.264 as it's more compatible (H.265 might not be available on all devices)
          '-crf 28 ' // Constant Rate Factor (lower = better quality, 28 is good for archival)
          '-preset medium ' // Encoding preset
          '-c:a aac ' // Audio codec
          '-b:a 128k ' // Audio bitrate
          '-movflags +faststart ' // Optimize for streaming
          '-y ' // Overwrite output file
          '"$tempOutputPath"';

      print('[COMPRESSION] Compressing: ${inputPath.split('/').last}');
      print('[COMPRESSION] Command: ffmpeg $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Check compressed file size
        final compressedFile = File(tempOutputPath);
        final compressedSize = await compressedFile.length();
        
        final savedBytes = originalSize - compressedSize;
        final compressionRatio = (savedBytes / originalSize * 100);

        print('[COMPRESSION] Original: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('[COMPRESSION] Compressed: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('[COMPRESSION] Saved: ${compressionRatio.toStringAsFixed(1)}%');

        // Only replace if we actually saved space (at least 10%)
        if (compressionRatio > 10) {
          // Delete original and rename compressed file
          await inputFile.delete();
          await compressedFile.rename(outputPath);
          
          // Update metadata in Firestore
          await _updateCompressionMetadata(
            outputPath,
            originalSize,
            compressedSize,
          );

          return {
            'success': true,
            'outputPath': outputPath,
            'originalSize': originalSize,
            'compressedSize': compressedSize,
            'savedBytes': savedBytes,
            'compressionRatio': compressionRatio,
          };
        } else {
          // Compression didn't save enough space, keep original
          print('[COMPRESSION] Compression ratio too low, keeping original');
          await compressedFile.delete();
          
          return {
            'success': false,
            'message': 'Compression ratio too low',
            'savedBytes': 0,
          };
        }
      } else {
        print('[COMPRESSION] FFmpeg failed with return code: $returnCode');
        final output = await session.getOutput();
        print('[COMPRESSION] FFmpeg output: $output');
        
        // Clean up temp file if it exists
        final tempFile = File(tempOutputPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        
        return {
          'success': false,
          'message': 'FFmpeg compression failed',
          'savedBytes': 0,
        };
      }
    } catch (e) {
      print('[COMPRESSION] Error compressing video: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'savedBytes': 0,
      };
    }
  }

  /// Update compression metadata in Firestore
  Future<void> _updateCompressionMetadata(
    String localPath,
    int originalSize,
    int compressedSize,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Find the video document by localPath
      final weeksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeks')
          .get();

      for (var weekDoc in weeksSnapshot.docs) {
        final videosSnapshot = await weekDoc.reference
            .collection('videos')
            .where('localPath', isEqualTo: localPath)
            .get();
        
        for (var videoDoc in videosSnapshot.docs) {
          await videoDoc.reference.update({
            'isCompressed': true,
            'compressedAt': FieldValue.serverTimestamp(),
            'originalSize': originalSize,
            'compressedSize': compressedSize,
            'compressionRatio': ((originalSize - compressedSize) / originalSize * 100),
          });
          
          print('[COMPRESSION] Updated metadata for ${videoDoc.id}');
        }
      }
    } catch (e) {
      print('[COMPRESSION] Error updating metadata: $e');
    }
  }

  /// Calculate potential compression savings without actually compressing
  Future<Map<String, dynamic>> calculateCompressionSavings({int weeksOld = 4}) async {
    try {
      final oldVideos = await _localStorage.getOldVideos(weeksOld);
      
      // Filter uncompressed videos
      final uncompressed = oldVideos.where((v) => !v['isCompressed']).toList();
      
      if (uncompressed.isEmpty) {
        return {
          'videoCount': 0,
          'totalBytes': 0,
          'estimatedSavingsBytes': 0,
          'estimatedSavingsMB': 0.0,
        };
      }

      int totalBytes = 0;
      for (var video in uncompressed) {
        totalBytes += video['size'] as int;
      }

      // Estimate 60% compression ratio (conservative estimate)
      final estimatedSavingsBytes = (totalBytes * 0.6).round();
      
      return {
        'videoCount': uncompressed.length,
        'totalBytes': totalBytes,
        'totalMB': totalBytes / 1024 / 1024,
        'estimatedSavingsBytes': estimatedSavingsBytes,
        'estimatedSavingsMB': estimatedSavingsBytes / 1024 / 1024,
      };
    } catch (e) {
      print('[COMPRESSION] Error calculating savings: $e');
      return {
        'videoCount': 0,
        'totalBytes': 0,
        'estimatedSavingsBytes': 0,
        'estimatedSavingsMB': 0.0,
      };
    }
  }

  /// Get compression statistics
  Future<Map<String, dynamic>> getCompressionStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final weeksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeks')
          .get();

      int totalVideos = 0;
      int compressedVideos = 0;
      int totalOriginalSize = 0;
      int totalCompressedSize = 0;

      for (var weekDoc in weeksSnapshot.docs) {
        final videosSnapshot = await weekDoc.reference
            .collection('videos')
            .get();
        
        for (var video in videosSnapshot.docs) {
          final data = video.data();
          totalVideos++;
          
          if (data['isCompressed'] == true) {
            compressedVideos++;
            totalOriginalSize += (data['originalSize'] as int?) ?? 0;
            totalCompressedSize += (data['compressedSize'] as int?) ?? 0;
          }
        }
      }

      final savedBytes = totalOriginalSize - totalCompressedSize;

      return {
        'totalVideos': totalVideos,
        'compressedVideos': compressedVideos,
        'uncompressedVideos': totalVideos - compressedVideos,
        'totalOriginalSize': totalOriginalSize,
        'totalCompressedSize': totalCompressedSize,
        'savedBytes': savedBytes,
        'savedMB': savedBytes / 1024 / 1024,
        'compressionRatio': totalOriginalSize > 0 
            ? (savedBytes / totalOriginalSize * 100) 
            : 0.0,
      };
    } catch (e) {
      print('[COMPRESSION] Error getting stats: $e');
      return {};
    }
  }

  /// Show notification
  Future<void> _showNotification(String title, String body) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'compression_channel',
        'Video Compression',
        channelDescription: 'Notifications for video compression status',
        importance: Importance.low,
        priority: Priority.low,
      );
      
      const notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        1,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      print('[COMPRESSION] Notification error: $e');
    }
  }

  /// Manually trigger compression for a specific video
  Future<Map<String, dynamic>> compressSpecificVideo(String localPath) async {
    try {
      final exists = await _localStorage.videoExists(localPath);
      if (!exists) {
        return {
          'success': false,
          'message': 'Video file not found',
        };
      }

      final result = await compressVideo(localPath, localPath);
      return result;
    } catch (e) {
      print('[COMPRESSION] Error compressing specific video: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}

