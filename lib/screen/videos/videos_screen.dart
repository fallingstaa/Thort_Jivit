import 'package:flutter/material.dart';
import 'package:thort_jivit/services/firestore_service.dart';
import 'package:thort_jivit/screen/videos/video_player_screen.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({Key? key}) : super(key: key);

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  String selectedTab = 'Daily';
  final List<String> tabs = ['Daily', 'Weekly'];
  List<Map<String, dynamic>> dailyVideos = [];
  bool _isLoading = true;
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadDailyVideos();

    // Setup blinking animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadDailyVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final videos = await _firestoreService.getAllUploadedVideos();
      setState(() {
        dailyVideos = videos;
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
        return []; // Weekly recap not implemented yet
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          selectedTab == 'Daily' &&
                  dailyVideos.isNotEmpty &&
                  _scaleAnimation != null
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
                      onTap: () {
                        // TODO: Add roll into memories action
                      },
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
                  child: Image.asset(
                    compilation['thumbnail'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFE0E0E0),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 64,
                            color: Color(0xFF757575),
                          ),
                        ),
                      );
                    },
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
                        Text(
                          '${compilation['clipsCount']} clips',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF757575),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
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

                    const SizedBox(height: 4),

                    // Timestamp
                    Text(
                      compilation['timestamp'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons Row
                    Row(
                      children: [
                        // Share Button
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          color: const Color(0xFF009688),
                          onTap: () {
                            // Handle share
                          },
                        ),

                        const SizedBox(width: 12),

                        // Save Button
                        _buildActionButton(
                          icon: Icons.file_download_outlined,
                          label: 'Save',
                          color: const Color(0xFF009688),
                          onTap: () {
                            // Handle save
                          },
                        ),

                        const SizedBox(width: 12),

                        // Music Button
                        _buildActionButton(
                          icon: Icons.music_note_outlined,
                          label: '',
                          color: const Color(0xFF009688),
                          onTap: () {
                            // Handle music
                          },
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
