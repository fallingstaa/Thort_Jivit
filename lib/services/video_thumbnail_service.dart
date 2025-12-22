import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailService {
  /// Generate a thumbnail from a video file path
  /// Returns the thumbnail as Uint8List
  static Future<Uint8List?> generateThumbnail({
    required String videoPath,
    int maxHeight = 300,
    int quality = 75,
  }) async {
    if (kIsWeb) {
      // Web doesn't support video_thumbnail generation yet
      return null;
    }

    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.PNG,
        maxHeight: maxHeight,
        quality: quality,
      );

      return uint8list;
    } catch (e) {
      print('[THUMBNAIL] Error generating thumbnail: $e');
      return null;
    }
  }

  /// Generate a thumbnail and save it to a file
  /// Returns the file path of the saved thumbnail
  static Future<String?> generateThumbnailFile({
    required String videoPath,
    int maxHeight = 300,
    int quality = 75,
  }) async {
    if (kIsWeb) {
      // Web doesn't support video_thumbnail generation yet
      return null;
    }

    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: ImageFormat.PNG,
        maxHeight: maxHeight,
        quality: quality,
      );

      return thumbnailPath;
    } catch (e) {
      print('[THUMBNAIL] Error generating thumbnail file: $e');
      return null;
    }
  }

  /// Generate thumbnail from video URL (downloads video temporarily if needed)
  static Future<Uint8List?> generateThumbnailFromUrl({
    required String videoUrl,
    int maxHeight = 300,
    int quality = 75,
  }) async {
    if (kIsWeb) {
      return null;
    }

    try {
      // For network URLs, video_thumbnail package can handle it directly
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.PNG,
        maxHeight: maxHeight,
        quality: quality,
      );

      return uint8list;
    } catch (e) {
      print('[THUMBNAIL] Error generating thumbnail from URL: $e');
      return null;
    }
  }
}

