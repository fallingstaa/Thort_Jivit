import 'package:flutter/material.dart';
import 'package:thort_jivit/services/video_thumbnail_service.dart';
import 'package:thort_jivit/services/thumbnail_cache_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import 'dart:io';

/// A widget that displays a video thumbnail, generating it from the video URL or local path if needed
class VideoThumbnailWidget extends StatefulWidget {
  final String? thumbnailUrl;
  final String videoUrl;
  final String? localPath; // NEW: Support local file paths
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const VideoThumbnailWidget({
    super.key,
    this.thumbnailUrl,
    required this.videoUrl,
    this.localPath, // NEW
    required this.width,
    required this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  Uint8List? _generatedThumbnail;
  String? _cachedThumbnailPath;
  bool _isGenerating = false;
  bool _generationFailed = false;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  /// Check if thumbnail is already cached
  Future<void> _checkCache() async {
    // If thumbnail URL is provided, cached_network_image handles caching automatically
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      return;
    }

    // Check cache for generated thumbnails
    String? cacheKey;
    if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      cacheKey = widget.localPath!;
    } else if (widget.videoUrl.isNotEmpty) {
      cacheKey = widget.videoUrl;
    }

    if (cacheKey != null) {
      final cachedPath = await ThumbnailCacheService.getCachedThumbnailPath(cacheKey);
      if (cachedPath != null && mounted) {
        setState(() {
          _cachedThumbnailPath = cachedPath;
        });
        return;
      }
    }

    // No cache found, generate thumbnail
    if ((widget.thumbnailUrl == null || widget.thumbnailUrl!.isEmpty)) {
      if (widget.localPath != null && widget.localPath!.isNotEmpty) {
        _generateThumbnailFromLocal();
      } else if (widget.videoUrl.isNotEmpty) {
        _generateThumbnail();
      }
    }
  }

  Future<void> _generateThumbnailFromLocal() async {
    if (_isGenerating || _generationFailed) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Check if local file exists
      final file = File(widget.localPath!);
      if (!await file.exists()) {
        throw Exception('Local video file not found');
      }

      final thumbnail = await VideoThumbnailService.generateThumbnail(
        videoPath: widget.localPath!,
        maxHeight: 300,
        quality: 75,
      );

      if (thumbnail != null) {
        // Cache the generated thumbnail
        final cachedPath = await ThumbnailCacheService.cacheThumbnailBytes(
          widget.localPath!,
          thumbnail,
        );

        if (mounted) {
          setState(() {
            _generatedThumbnail = thumbnail;
            _cachedThumbnailPath = cachedPath;
            _isGenerating = false;
            _generationFailed = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _generationFailed = true;
          });
        }
      }
    } catch (e) {
      print('[THUMBNAIL_WIDGET] Error generating thumbnail from local: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generationFailed = true;
        });
      }
    }
  }

  Future<void> _generateThumbnail() async {
    if (_isGenerating || _generationFailed) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final thumbnail = await VideoThumbnailService.generateThumbnailFromUrl(
        videoUrl: widget.videoUrl,
        maxHeight: 300,
        quality: 75,
      );

      if (thumbnail != null) {
        // Cache the generated thumbnail
        final cachedPath = await ThumbnailCacheService.cacheThumbnailBytes(
          widget.videoUrl,
          thumbnail,
        );

        if (mounted) {
          setState(() {
            _generatedThumbnail = thumbnail;
            _cachedThumbnailPath = cachedPath;
            _isGenerating = false;
            _generationFailed = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _generationFailed = true;
          });
        }
      }
    } catch (e) {
      print('[THUMBNAIL_WIDGET] Error generating thumbnail: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generationFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUrl = widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty;

    Widget content;

    if (hasUrl) {
      // Use CachedNetworkImage for network thumbnails (automatically caches)
      content = CachedNetworkImage(
        imageUrl: widget.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFFFD700),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return widget.errorWidget ?? _buildPlaceholder(isDark);
        },
      );
    } else if (_cachedThumbnailPath != null) {
      // Use cached thumbnail file (fastest, no regeneration needed)
      content = Image.file(
        File(_cachedThumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? _buildPlaceholder(isDark);
        },
      );
    } else if (_generatedThumbnail != null) {
      // Use generated thumbnail from memory
      content = Image.memory(
        _generatedThumbnail!,
        fit: BoxFit.cover,
      );
    } else if (_isGenerating) {
      // Show loading indicator
      content = Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation<Color>(
            Color(0xFFFFD700),
          ),
        ),
      );
    } else {
      // Show placeholder or error widget
      content = widget.placeholder ?? _buildPlaceholder(isDark);
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
            isDark ? const Color(0xFF1A1A1A) : const Color(0xFFD0D0D0),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        child: content,
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      child: Center(
        child: Icon(
          Icons.videocam_rounded,
          size: widget.width * 0.35,
          color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF757575),
        ),
      ),
    );
  }
}

