// lib/screen/profile/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thort_jivit/services/firestore_service.dart';
import 'package:thort_jivit/controllers/favorites_controller.dart';
import 'package:thort_jivit/screen/videos/video_player_screen.dart';
import 'package:thort_jivit/widgets/video_thumbnail_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FavoritesController _favoritesController = Get.find<FavoritesController>();
  List<Map<String, dynamic>> _favoriteVideos = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteVideos();
  }

  Future<void> _loadFavoriteVideos() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Reload favorites from GetX controller
      await _favoritesController.loadFavorites();
      
      // Get all videos from Firestore
      final allVideos = await _firestoreService.getAllUploadedVideos();
      
      // Filter to only favorite videos using GetX controller
      final favoriteVideos = allVideos.where((video) {
        final videoId = video['id'] as String?;
        return videoId != null && _favoritesController.isFavorite(videoId);
      }).toList();
      
      // Mark all as favorites
      for (final video in favoriteVideos) {
        video['isFavorite'] = true;
      }
      
      if (mounted) {
        setState(() {
          _favoriteVideos = favoriteVideos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[FAVORITES] Error loading favorite videos: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(String videoId, String weekId, String dayId) async {
    try {
      // Use GetX controller to toggle favorite
      // GetX will automatically update all reactive widgets
      await _favoritesController.toggleFavorite(videoId);
      
      // Remove from list immediately if unfavorited
      if (!_favoritesController.isFavorite(videoId)) {
        setState(() {
          _favoriteVideos.removeWhere((v) => v['id'] == videoId);
        });
      }
    } catch (e) {
      print('[FAVORITES] ❌ Error toggling favorite: $e');
      // Reload on error
      _loadFavoriteVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Favorite Videos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF009688),
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load favorites',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadFavoriteVideos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _favoriteVideos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 80,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No favorite videos yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the heart icon on any video\nto add it to favorites',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavoriteVideos,
                      color: const Color(0xFF009688),
                      child: ListView.builder(
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        itemCount: _favoriteVideos.length,
                        itemBuilder: (context, index) {
                          final video = _favoriteVideos[index];
                          return _buildVideoCard(video, isDark, isTablet);
                        },
                      ),
                    ),
    );
  }

  Widget _buildVideoCard(
    Map<String, dynamic> video,
    bool isDark,
    bool isTablet,
  ) {
    final thumbnailUrl = video['thumbnailUrl']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final videoPath = (video['localPath']?.toString() ?? '').isNotEmpty
                ? video['localPath'].toString()
                : video['storageDownloadUrl'] ?? '';

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  videoUrl: videoPath,
                  emoji: video['emoji']?.toString() ?? '',
                  description: video['textNote']?.toString() ?? 'No description',
                  date: video['date']?.toString() ?? '',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Row(
              children: [
                // Enhanced Thumbnail with gradient overlay and play button
                Stack(
                  children: [
                    VideoThumbnailWidget(
                      thumbnailUrl: thumbnailUrl,
                      videoUrl: video['storageDownloadUrl']?.toString() ?? '',
                      localPath: video['localPath']?.toString(),
                      width: isTablet ? 110 : 96,
                      height: isTablet ? 110 : 96,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // Shadow for depth
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Play button overlay
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 12 : 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: isTablet ? 32 : 28,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: isTablet ? 16 : 12),
                // Emoji, Description and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji and Title Row
                      Row(
                        children: [
                          if (video['emoji'] != null &&
                              video['emoji'].toString().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                video['emoji'].toString(),
                                style: TextStyle(fontSize: isTablet ? 22 : 20),
                              ),
                            ),
                            SizedBox(width: isTablet ? 10 : 8),
                          ],
                          Expanded(
                            child: Text(
                              (video['textNote'] ?? 'No description').toString(),
                              style: TextStyle(
                                fontSize: isTablet ? 17 : 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1A1A1A),
                                height: 1.3,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 8 : 6),
                      // Date with icon
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: isTablet ? 14 : 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (video['date'] ?? '').toString(),
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 12,
                              color: const Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Favorite Icon - Improved Design
                Obx(() {
                  final videoId = video['id'] as String? ?? '';
                  final isFavorite = _favoritesController.isFavorite(videoId);
                  
                  return GestureDetector(
                    onTap: () => _toggleFavorite(
                      videoId,
                      video['weekId'],
                      video['dayId'],
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.all(isTablet ? 12 : 10),
                      decoration: BoxDecoration(
                        color: isFavorite
                            ? const Color(0xFFE53935).withOpacity(0.15)
                            : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5)),
                        shape: BoxShape.circle,
                        boxShadow: isFavorite
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFE53935).withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: isTablet ? 26 : 24,
                        color: isFavorite
                            ? const Color(0xFFE53935)
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

