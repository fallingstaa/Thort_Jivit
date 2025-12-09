import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:thort_jivit/services/firestore_service.dart';
import 'package:thort_jivit/services/video_combiner_service.dart';
import 'package:thort_jivit/services/music_service.dart';
import 'package:thort_jivit/screen/videos/video_player_screen.dart';
import 'package:thort_jivit/services/admin_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({Key? key}) : super(key: key);

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final VideoCombinerService _videoCombiner = VideoCombinerService();
  String selectedTab = 'Daily';
  final List<String> tabs = ['Daily', 'Weekly'];
  List<Map<String, dynamic>> dailyVideos = [];
  List<Map<String, dynamic>> weeklyVideos = [];
  bool _isLoading = true;
  bool _isCreatingRecap = false;
  bool _canCreateRecap = false;
  bool _isAdmin = false;
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadVideos();

    // Setup blinking animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final videos = await _firestoreService.getAllUploadedVideos();
      bool isAdmin = await isWebAdmin();
      final recaps = await _firestoreService.getWeeklyRecaps(isAdmin: isAdmin);

      // Check if current week can create recap
      final activeWeek = await _firestoreService.getActiveWeekNow();
      bool canCreate = false;
      if (activeWeek != null) {
        final weekId = activeWeek['weekId'] as String;
        final weekVideos = videos.where((v) => v['weekId'] == weekId).toList();
        final videoCount = weekVideos.length;
        final hasEnoughVideos = _videoCombiner.canCreateRecap(videoCount);

        print('[VIDEOS] Active week: $weekId');
        print('[VIDEOS] Total videos loaded: ${videos.length}');
        print('[VIDEOS] Videos for current week: $videoCount');
        print(
          '[VIDEOS] Week videos IDs: ${weekVideos.map((v) => v['dayId']).toList()}',
        );
        print(
          '[VIDEOS] Week videos emojis: ${weekVideos.map((v) => v['emoji']).toList()}',
        );
        print(
          '[VIDEOS] Week videos status: ${weekVideos.map((v) => '${v['dayId']}-uploaded').toList()}',
        );
        print('[VIDEOS] Has enough for recap (need 3): $hasEnoughVideos');

        // For admin, always allow creating recap
        if (isAdmin) {
          canCreate = hasEnoughVideos;
        } else {
          // For normal users: check if week already has a recap
          final alreadyHasRecap = await _firestoreService.weekHasRecap(weekId);
          canCreate = hasEnoughVideos && !alreadyHasRecap;
        }
      }

      setState(() {
        dailyVideos = videos;
        weeklyVideos = recaps;
        _canCreateRecap = canCreate;
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      print('[VIDEOS] Error loading videos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  // Get current video list based on selected tab
  List<Map<String, dynamic>> get currentVideos {
    switch (selectedTab) {
      case 'Weekly':
        return weeklyVideos;
      default:
        return dailyVideos;
    }
  }

  void _toggleFavorite(String videoId) {
    setState(() {
      final video = dailyVideos.firstWhere((v) => v['id'] == videoId);
      video['isFavorite'] = !video['isFavorite'];
    });
  }

  Future<void> _createWeeklyRecap() async {
    if (_isCreatingRecap) return;

    setState(() {
      _isCreatingRecap = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF009688)),
                      SizedBox(height: 16),
                      Text(
                        'Creating your weekly recap...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );

      // Get active week
      final activeWeek = await _firestoreService.getActiveWeekNow();
      if (activeWeek == null) {
        throw Exception('No active week found');
      }

      final weekId = activeWeek['weekId'] as String;

      // Get all daily videos for this week
      final weekVideos =
          dailyVideos.where((v) => v['weekId'] == weekId).toList();

      print('[VIDEOS] DEBUG: Total dailyVideos: ${dailyVideos.length}');
      print('[VIDEOS] DEBUG: ActiveWeekId: $weekId');
      print('[VIDEOS] DEBUG: WeekVideos filtered: ${weekVideos.length}');
      print(
        '[VIDEOS] DEBUG: WeekVideos IDs: ${weekVideos.map((v) => v['id']).toList()}',
      );
      print(
        '[VIDEOS] DEBUG: WeekVideos dayIndexes: ${weekVideos.map((v) => v['dayIndex']).toList()}',
      );
      print(
        '[VIDEOS] DEBUG: WeekVideos types: ${weekVideos.map((v) => v['videoType']).toList()}',
      );
      print(
        '[VIDEOS] DEBUG: WeekVideos URLs: ${weekVideos.map((v) => v['storageDownloadUrl']).toList()}',
      );

      final videoUrls =
          weekVideos.map((v) => v['storageDownloadUrl'] as String).toList();
      final videoPaths =
          weekVideos
              .map((v) => v['filePath'] as String? ?? '')
              .where((p) => p.isNotEmpty)
              .toList();

      print('[VIDEOS] DEBUG: Final videoUrls count: ${videoUrls.length}');
      print('[VIDEOS] DEBUG: Final videoPaths count: ${videoPaths.length}');
      print('[VIDEOS] DEBUG: Final videoUrls: $videoUrls');

      // Combine all videos for the week
      final result = await _videoCombiner.combineVideos(
        videoUrls: videoUrls,
        videoPaths: videoPaths,
      );

      if (result['success'] == true) {
        // Get first and last video dates for display
        String firstVideoDate = '';
        String lastVideoDate = '';
        List<Map<String, dynamic>> mergeOrder = [];
        if (weekVideos.isNotEmpty) {
          final sortedVideos = List.from(weekVideos);
          sortedVideos.sort(
            (a, b) => (a['uploadedDate'] as DateTime).compareTo(
              b['uploadedDate'] as DateTime,
            ),
          );
          firstVideoDate = sortedVideos.first['uploadedDate'].toString();
          lastVideoDate = sortedVideos.last['uploadedDate'].toString();

          // Create merge order with position
          for (int i = 0; i < sortedVideos.length; i++) {
            mergeOrder.add({
              'position': i + 1,
              'day': sortedVideos[i]['dayIndex'] ?? 0,
              'uploadedDate': sortedVideos[i]['uploadedDate'].toString(),
              'duration': sortedVideos[i]['videoDuration'] ?? 'unknown',
              'fileName': sortedVideos[i]['fileName'] ?? 'Video ${i + 1}',
            });
          }
        }

        // Save weekly recap
        await _firestoreService.saveWeeklyRecap(
          weekId: weekId,
          recapUrl: result['recapUrl'],
          clipsCount: result['clipsCount'],
          duration: result['duration'],
          isAdmin: _isAdmin,
          firstVideoDate: firstVideoDate,
          lastVideoDate: lastVideoDate,
          mergeOrder: mergeOrder,
        );

        // Reload videos
        await _loadVideos();

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Weekly recap created successfully!'),
              backgroundColor: Color(0xFF009688),
              duration: Duration(seconds: 3),
            ),
          );

          // Switch to Weekly tab
          setState(() {
            selectedTab = 'Weekly';
          });
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to create recap');
      }
    } catch (e) {
      print('[VIDEOS] Error creating recap: $e');

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingRecap = false;
        });
      }
    }
  }

  void _showVideoOptions(String videoId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionItem(Icons.share_outlined, 'Share', () {}),
              _buildOptionItem(Icons.edit_outlined, 'Edit', () {}),
              _buildOptionItem(
                Icons.delete_outline,
                'Delete',
                () {},
                isDestructive: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            isDestructive ? const Color(0xFFE53935) : const Color(0xFF009688),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color:
              isDestructive ? const Color(0xFFE53935) : const Color(0xFF1A1A1A),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Videos',
          style: TextStyle(
            color: Color(0xFF009688),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Custom Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children:
                    tabs.map((tab) {
                      final isSelected = tab == selectedTab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTab = tab;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFF009688)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                tab,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : const Color(0xFF757575),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Videos List
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF009688),
                      ),
                    )
                    : currentVideos.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selectedTab == 'Weekly'
                                ? Icons.movie_creation_outlined
                                : Icons.videocam_off_outlined,
                            size: 64,
                            color: const Color(0xFFBDBDBD),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedTab == 'Weekly'
                                ? 'No weekly recap yet'
                                : 'No videos yet',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedTab == 'Weekly'
                                ? 'Weekly recap videos coming soon!'
                                : 'Start recording your memories',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 100,
                      ),
                      itemCount: currentVideos.length,
                      itemBuilder: (context, index) {
                        final video = currentVideos[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child:
                              selectedTab == 'Daily'
                                  ? _buildDailyVideoCard(video)
                                  : _buildCompilationCard(video),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton:
          selectedTab == 'Daily' && _canCreateRecap && _scaleAnimation != null
              ? ScaleTransition(
                scale: _scaleAnimation!,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFD700), // Gold
                        Color(0xFFFFA500), // Orange-gold
                        Color(0xFFFFD700), // Gold
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      onTap: _canCreateRecap ? _createWeeklyRecap : null,
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.auto_awesome,
                              size: 24,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Roll into the Memories Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Daily video card (small card with favorite and more options)
  Widget _buildDailyVideoCard(Map<String, dynamic> video) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to video player screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => VideoPlayerScreen(
                      videoUrl: video['storageDownloadUrl'] ?? '',
                      emoji: video['emoji']?.toString() ?? '',
                      description:
                          video['textNote']?.toString() ?? 'No description',
                      date: video['date']?.toString() ?? '',
                    ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFE0E0E0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: const Color(0xFFE0E0E0),
                      child: const Icon(
                        Icons.play_circle_outline,
                        size: 32,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Emoji, Description and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          if (video['emoji'] != null &&
                              video['emoji'].toString().isNotEmpty) ...[
                            Text(
                              video['emoji'].toString(),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              (video['textNote'] ?? 'No description')
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (video['date'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Favorite Icon
                GestureDetector(
                  onTap: () => _toggleFavorite(video['id']),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      video['isFavorite']
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 22,
                      color:
                          video['isFavorite']
                              ? const Color(0xFFE53935)
                              : const Color(0xFFBDBDBD),
                    ),
                  ),
                ),

                // More Options Icon
                GestureDetector(
                  onTap: () => _showVideoOptions(video['id']),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.more_vert,
                      size: 22,
                      color: Color(0xFFBDBDBD),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Weekly/Monthly compilation card (large card with share, save, and music buttons)
  Widget _buildCompilationCard(Map<String, dynamic> compilation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to compilation video player
            if (compilation['recapUrl'] != null &&
                compilation['recapUrl'].toString().isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => VideoPlayerScreen(
                        videoUrl: compilation['recapUrl'],
                        emoji: '🎬',
                        description: compilation['title'] ?? 'Weekly Recap',
                        date: compilation['timestamp'] ?? '',
                      ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0D0D0D), // Pure black
                          Color(0xFF1C1C1C), // Slightly lighter black
                          Color(0xFF0D0D0D), // Pure black
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Film grain texture overlay
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.08,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  radius: 1.0,
                                  colors: [
                                    Colors.white.withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Vignette effect
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.7,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Center content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1.5,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.movie_filter_outlined,
                                  size: 52,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'WEEKLY RECAP',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.75),
                                  letterSpacing: 3.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 60,
                                height: 1,
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      compilation['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Stats Row (clips count and duration)
                    Row(
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 16,
                          color: Color(0xFF757575),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${compilation['clipsCount']} clips',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time_outlined,
                          size: 16,
                          color: Color(0xFF757575),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          compilation['duration'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Merge date and time
                    if (compilation['createdAt'] != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Merged ${_formatMergeDateTime(compilation['createdAt'])}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9E9E9E),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // Selected music track (if any)
                    if ((compilation['selectedMusicTrack'] ?? '')
                        .toString()
                        .isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.music_note,
                            size: 16,
                            color: Color(0xFF757575),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              compilation['selectedMusicTrack'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    // Action Buttons Row
                    Row(
                      children: [
                        // Share Button
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          color: const Color(0xFF009688),
                          onTap: () => _shareRecap(compilation),
                        ),

                        const SizedBox(width: 12),

                        // Save Button
                        _buildActionButton(
                          icon: Icons.file_download_outlined,
                          label: 'Save',
                          color: const Color(0xFF009688),
                          onTap: () => _saveRecap(compilation),
                        ),

                        const SizedBox(width: 12),

                        // Music Button
                        _buildActionButton(
                          icon: Icons.music_note_outlined,
                          label: '',
                          color: const Color(0xFF009688),
                          onTap: () => _openMusicPicker(compilation),
                          iconOnly: true,
                        ),

                        const SizedBox(width: 12),

                        // Delete Button
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: '',
                          color: const Color(0xFFE53935),
                          onTap: () => _deleteRecap(compilation),
                          iconOnly: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Delete a weekly recap
  Future<void> _deleteRecap(Map<String, dynamic> compilation) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Recap?'),
            content: const Text(
              'Are you sure you want to delete this weekly recap? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF009688)),
                      SizedBox(height: 16),
                      Text('Deleting recap...'),
                    ],
                  ),
                ),
              ),
            ),
      );

      // Delete the recap
      await _firestoreService.deleteWeeklyRecap(
        weekId: compilation['weekId'],
        recapId: compilation['id'],
        isAdmin: _isAdmin,
      );

      // Reload videos
      await _loadVideos();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recap deleted successfully'),
            backgroundColor: Color(0xFF009688),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[VIDEOS] Error deleting recap: $e');

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting recap: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openMusicPicker(Map<String, dynamic> compilation) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FutureBuilder<List<String>>(
          future: MusicService().getMusicLibrary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF009688)),
                ),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Error loading music: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final tracks = snapshot.data ?? [];
            if (tracks.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('No music found in music_library')),
              );
            }

            return SizedBox(
              height: 320,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Choose background music',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final isSelected =
                            (compilation['selectedMusicTrack'] ?? '') == track;
                        return ListTile(
                          leading: const Icon(
                            Icons.music_note,
                            color: Color(0xFF009688),
                          ),
                          title: Text(track),
                          trailing:
                              isSelected
                                  ? const Icon(
                                    Icons.check,
                                    color: Color(0xFF009688),
                                  )
                                  : null,
                          onTap: () {
                            Navigator.pop(context);
                            _confirmChangeMusic(compilation, track);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmChangeMusic(
    Map<String, dynamic> compilation,
    String track,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change music?'),
            content: Text('Replace the recap background music with "$track"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _applyMusicSelection(compilation, track);
    }
  }

  Future<void> _applyMusicSelection(
    Map<String, dynamic> compilation,
    String track,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF009688)),
                    SizedBox(height: 16),
                    Text('Updating music...'),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final result = await _videoCombiner.changeRecapMusic(
        recapUrl: compilation['recapUrl'],
        weekId: compilation['weekId'],
        musicFileName: track,
      );

      if (result['success'] == true) {
        final newUrl = result['recapUrl'] as String? ?? '';
        await _firestoreService.updateRecapMusicTrack(
          weekId: compilation['weekId'],
          recapId: compilation['id'],
          musicFileName: track,
          recapUrl: newUrl,
        );

        // Update local data immediately so Save uses fresh audio version
        compilation['recapUrl'] = newUrl;
        compilation['selectedMusicTrack'] = track;

        await _loadVideos();

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Music updated to "$track"'),
              backgroundColor: const Color(0xFF009688),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to change music');
      }
    } catch (e) {
      print('[VIDEOS] Error changing music: $e');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating music: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveRecap(Map<String, dynamic> compilation) async {
    final recapUrl = (compilation['recapUrl'] as String?) ?? '';

    if (recapUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recap URL available to download.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(recapUrl);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid recap URL.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final mode =
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
      final launched = await launchUrl(uri, mode: mode);

      if (!launched) throw Exception('Could not open recap link');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening recap download...'),
          backgroundColor: Color(0xFF009688),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to open recap. If this is your first run after adding url_launcher, fully restart the app. Error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareRecap(Map<String, dynamic> compilation) async {
    final recapUrl = (compilation['recapUrl'] as String?) ?? '';

    if (recapUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recap URL available to share.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (kIsWeb) {
        // On web: show dialog with share options
        if (!mounted) return;
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Share Recap'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Instagram direct sharing is not available on web. You can:',
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.link, color: Color(0xFF009688)),
                      title: const Text('Copy Link'),
                      onTap: () {
                        Navigator.pop(context);
                        _copyRecapLink(recapUrl);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.download,
                        color: Color(0xFF009688),
                      ),
                      title: const Text('Download & Share Manually'),
                      onTap: () {
                        Navigator.pop(context);
                        _saveRecap(compilation);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      } else {
        // On mobile: use share sheet (will show Instagram if installed)
        final result = await Share.shareUri(
          Uri.parse(recapUrl),
          sharePositionOrigin: Rect.fromLTWH(0, 0, 10, 10),
        );

        if (!mounted) return;
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shared successfully!'),
              backgroundColor: Color(0xFF009688),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyRecapLink(String url) {
    // For web, we can use Share.share with text
    Share.share('Check out my weekly recap: $url', subject: 'Weekly Recap');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share dialog opened!'),
          backgroundColor: Color(0xFF009688),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Format merge date and time for display
  String _formatMergeDateTime(dynamic timestamp) {
    if (timestamp == null) return 'unknown';

    try {
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp.toString().contains('Timestamp')) {
        // Firestore Timestamp object
        dateTime = (timestamp as dynamic).toDate();
      } else {
        return 'unknown';
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

      // Format time
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute';

      if (dateOnly == today) {
        return 'today at $timeStr';
      } else if (dateOnly == yesterday) {
        return 'yesterday at $timeStr';
      } else {
        // Format as "Jan 15 at 14:30"
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[dateTime.month - 1]} ${dateTime.day} at $timeStr';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  // Action button widget for compilation cards
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool iconOnly = false,
  }) {
    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                if (!iconOnly) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
