// lib/services/thumbnail_cache_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for caching video thumbnails locally
class ThumbnailCacheService {
  static const String _cacheDirName = 'video_thumbnails';
  static const int _maxCacheAgeDays = 30; // Cache expires after 30 days

  /// Get the cache directory for thumbnails
  static Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheDirName');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Generate a cache key from URL or path
  static String _generateCacheKey(String urlOrPath) {
    final bytes = utf8.encode(urlOrPath);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get cached thumbnail file path
  static Future<String?> getCachedThumbnailPath(String urlOrPath) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final cacheKey = _generateCacheKey(urlOrPath);
      final cachedFile = File('${cacheDir.path}/$cacheKey.png');

      if (await cachedFile.exists()) {
        // Check if cache is still valid (not expired)
        final stat = await cachedFile.stat();
        final age = DateTime.now().difference(stat.modified);
        if (age.inDays < _maxCacheAgeDays) {
          print('[THUMBNAIL_CACHE] ✅ Found cached thumbnail: $cacheKey');
          return cachedFile.path;
        } else {
          // Cache expired, delete it
          print('[THUMBNAIL_CACHE] ⏰ Cache expired, deleting: $cacheKey');
          await cachedFile.delete();
        }
      }
      return null;
    } catch (e) {
      print('[THUMBNAIL_CACHE] Error getting cached thumbnail: $e');
      return null;
    }
  }

  /// Cache a thumbnail from bytes
  static Future<String?> cacheThumbnailBytes(
    String urlOrPath,
    Uint8List thumbnailBytes,
  ) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final cacheKey = _generateCacheKey(urlOrPath);
      final cachedFile = File('${cacheDir.path}/$cacheKey.png');

      await cachedFile.writeAsBytes(thumbnailBytes);
      print('[THUMBNAIL_CACHE] 💾 Cached thumbnail: $cacheKey');
      return cachedFile.path;
    } catch (e) {
      print('[THUMBNAIL_CACHE] Error caching thumbnail: $e');
      return null;
    }
  }

  /// Cache a thumbnail from file path
  static Future<String?> cacheThumbnailFile(
    String urlOrPath,
    String sourceFilePath,
  ) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      final thumbnailBytes = await sourceFile.readAsBytes();
      return await cacheThumbnailBytes(urlOrPath, thumbnailBytes);
    } catch (e) {
      print('[THUMBNAIL_CACHE] Error caching thumbnail from file: $e');
      return null;
    }
  }

  /// Clear all cached thumbnails
  static Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        print('[THUMBNAIL_CACHE] 🗑️ Cleared all cached thumbnails');
      }
    } catch (e) {
      print('[THUMBNAIL_CACHE] Error clearing cache: $e');
    }
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('[THUMBNAIL_CACHE] Error getting cache size: $e');
      return 0;
    }
  }

  /// Clean up expired cache files
  static Future<void> cleanupExpiredCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) {
        return;
      }

      int deletedCount = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = DateTime.now().difference(stat.modified);
          if (age.inDays >= _maxCacheAgeDays) {
            await entity.delete();
            deletedCount++;
          }
        }
      }
      if (deletedCount > 0) {
        print('[THUMBNAIL_CACHE] 🧹 Cleaned up $deletedCount expired thumbnails');
      }
    } catch (e) {
      print('[THUMBNAIL_CACHE] Error cleaning up cache: $e');
    }
  }
}

