import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:thort_jivit/services/firestore_service.dart';
import 'package:thort_jivit/services/video_combiner_service.dart';
import 'package:thort_jivit/services/music_service.dart';
import 'package:thort_jivit/services/background_sync_service.dart';
import 'package:thort_jivit/services/local_video_storage_service.dart';
import 'package:thort_jivit/services/manual_recap_service.dart';
import 'package:thort_jivit/services/smart_template_selector.dart';
import 'package:thort_jivit/controllers/favorites_controller.dart';
import 'package:get/get.dart';
import 'package:thort_jivit/screen/videos/video_player_screen.dart';
import 'package:thort_jivit/services/admin_utils.dart';
import 'package:thort_jivit/models/recap_template.dart';
import 'package:thort_jivit/models/video.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thort_jivit/widgets/video_thumbnail_widget.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
  
  // Static method to trigger refresh from anywhere
  static void triggerRefresh() {
    _refreshNotifier.value = DateTime.now();
    print('[VIDEOS] Refresh triggered via static method');
  }
  
  // ValueNotifier to trigger refresh (accessible from state)
  static final ValueNotifier<DateTime> _refreshNotifier = ValueNotifier<DateTime>(DateTime.now());
  
  // Getter to access notifier from state
  static ValueNotifier<DateTime> get refreshNotifier => _refreshNotifier;
}

class _VideosScreenState extends State<VideosScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();
  final VideoCombinerService _videoCombiner = VideoCombinerService();
  final BackgroundSyncService _syncService = BackgroundSyncService();
  final LocalVideoStorageService _localStorage = LocalVideoStorageService();
  final ManualRecapService _manualRecapService = ManualRecapService();
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
  Map<String, dynamic> _syncStats = {};
  Map<String, dynamic> _storageUsage = {};
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadVideos();
    _loadSyncStats();

    // Setup blinking animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    
    // Listen for refresh triggers
    VideosScreen.refreshNotifier.addListener(_onRefreshTriggered);
  }
  
  void _onRefreshTriggered() {
    print('[VIDEOS] 🔄 Refresh triggered by external event');
    // Wait a moment for Firestore to be ready, then refresh
    // Use multiple refresh attempts to handle eventual consistency
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        print('[VIDEOS] 🔄 First refresh attempt');
        refreshVideos();
      }
    });
    // Second refresh after longer delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        print('[VIDEOS] 🔄 Second refresh attempt (for eventual consistency)');
        refreshVideos();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController?.dispose();
    VideosScreen.refreshNotifier.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload videos and favorites when app resumes
    if (state == AppLifecycleState.resumed) {
      // Add delay to ensure Firestore is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          refreshVideos();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if it's been more than 1 second since last refresh
    // This prevents excessive refreshes while still keeping data fresh
    final now = DateTime.now();
    if (_lastRefreshTime == null || 
        now.difference(_lastRefreshTime!).inSeconds > 1) {
      _lastRefreshTime = now;
      // Add small delay to ensure Firestore is ready
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _refreshVideos();
        }
      });
    }
  }

  // Public method to refresh videos (can be called from outside)
  void refreshVideos() {
    _loadVideos();
    _loadSyncStats();
    final favoritesController = Get.find<FavoritesController>();
    favoritesController.loadFavorites();
  }

  void _refreshVideos() {
    refreshVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('[VIDEOS] 📹 Loading videos from Firestore...');
      final videos = await _firestoreService.getAllUploadedVideos();
      print('[VIDEOS] 📹 Loaded ${videos.length} videos from Firestore');
      
      // Log video details for debugging
      for (var video in videos) {
        final localPath = video['localPath'] as String?;
        print('[VIDEOS] 📹 Video: ${video['dayId']}, type=${video['videoType']}, status=${video['uploadStatus']}, hasLocalPath=${localPath != null && localPath.isNotEmpty}');
      }
      
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

      // Load favorites from GetX controller
      final favoritesController = Get.find<FavoritesController>();
      await favoritesController.loadFavorites();
      
      // Apply favorites to videos (for initial load)
      final videosWithFavorites = videos.map((video) {
        final videoId = video['id'] as String?;
        final isFavorite = videoId != null && favoritesController.isFavorite(videoId);
        return Map<String, dynamic>.from(video)..['isFavorite'] = isFavorite;
      }).toList();

      setState(() {
        dailyVideos = videosWithFavorites;
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

  Future<void> _loadSyncStats() async {
    try {
      final stats = await _syncService.getSyncStats();
      final usage = await _localStorage.getStorageUsage();
      
      if (mounted) {
        setState(() {
          _syncStats = stats;
          _storageUsage = usage;
        });
      }
    } catch (e) {
      print('[VIDEOS] Error loading sync stats: $e');
    }
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

  Future<void> _forceSyncNow() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF009688)),
                  SizedBox(height: 16),
                  Text(
                    'Syncing videos...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final result = await _syncService.performSync(forceSync: true);
      
      if (mounted) Navigator.of(context).pop();

      await _loadSyncStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['uploaded'] > 0
                  ? '✓ Synced ${result['uploaded']} video${result['uploaded'] > 1 ? 's' : ''}'
                  : 'All videos already synced',
            ),
            backgroundColor: const Color(0xFF009688),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _toggleFavorite(String videoId) async {
    final favoritesController = Get.find<FavoritesController>();
    await favoritesController.toggleFavorite(videoId);
    // GetX will automatically update the UI via Obx
  }

  Future<void> _createWeeklyRecap() async {
    if (_isCreatingRecap) return;

    setState(() {
      _isCreatingRecap = true;
    });

    try {
      // Get active week
      final activeWeek = await _firestoreService.getActiveWeekNow();
      if (activeWeek == null) {
        throw Exception('No active week found');
      }

      final weekId = activeWeek['weekId'] as String;

      // Upload any pending videos for this week first
      print('[VIDEOS] Checking for pending videos to upload...');
      final uploadResult = await _firestoreService.uploadPendingVideosForWeek(weekId);
      
      if (uploadResult['uploaded'] > 0) {
        print('[VIDEOS] Uploaded ${uploadResult['uploaded']} pending videos');
      }
      
      if (uploadResult['failed'] > 0) {
        print('[VIDEOS] Warning: ${uploadResult['failed']} videos failed to upload');
      }

      // Get all uploaded videos for this week
      final weekVideos = dailyVideos
          .where((v) => v['weekId'] == weekId && v['uploadStatus'] == 'uploaded')
          .toList();

      if (weekVideos.length < 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Need at least 3 videos (have ${weekVideos.length})'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Try enhanced system first, fall back to old system if it fails
      bool useEnhancedSystem = true;
      
      // SMART AUTO-SELECTION: Choose best template and duration based on video content
      final videoModels = weekVideos.map((v) => Video.fromMap(v)).toList();
      final smartPrefs = SmartTemplateSelector.createSmartPreferences(videoModels);
      
      print('[VIDEOS] 🤖 Smart selection: ${smartPrefs.defaultTemplate.name} (${smartPrefs.targetDuration.toInt()}s) for ${videoModels.length} videos');

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF009688)),
                    const SizedBox(height: 16),
                    const Text(
                      'Creating your weekly recap...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Style: ${smartPrefs.defaultTemplate.name}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF009688)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      Map<String, dynamic> result;
      
      try {
        // TRY ENHANCED SYSTEM FIRST
        print('[VIDEOS] Attempting enhanced recap generation with ${smartPrefs.defaultTemplate.name} template');
        
        result = await _manualRecapService.generateRecap(
          weekId: weekId,
          weekVideos: weekVideos,
          templateStyle: smartPrefs.defaultTemplate,
          effects: smartPrefs.effects,
          targetDuration: smartPrefs.targetDuration,
          musicBPM: smartPrefs.musicBPM,
        );

        if (result['success'] != true) {
          throw Exception('Enhanced system failed: ${result['message']}');
        }

        print('[VIDEOS] ✅ Enhanced recap generated successfully');
        
      } catch (enhancedError) {
        // FALLBACK TO OLD SYSTEM
        print('[VIDEOS] ⚠️ Enhanced system failed: $enhancedError');
        print('[VIDEOS] 🔄 Falling back to simple merge (backup system)...');
        
        useEnhancedSystem = false;

        // Extract video URLs and paths for old system
        final videoUrls = weekVideos.map((v) => v['storageDownloadUrl'] as String).toList();
        final videoPaths = weekVideos
            .map((v) => v['filePath'] as String? ?? '')
            .where((p) => p.isNotEmpty)
            .toList();

        // Use old combineVideos method as backup
        result = await _videoCombiner.combineVideos(
          videoUrls: videoUrls,
          videoPaths: videoPaths,
        );

        if (result['success'] != true) {
          throw Exception('Both systems failed. Old system error: ${result['message']}');
        }

        print('[VIDEOS] ✅ Backup system (simple merge) succeeded');
      }

      if (mounted) Navigator.of(context).pop(); // Close loading dialog

      if (result['success'] == true) {
        // Save recap metadata
        await _firestoreService.saveWeeklyRecap(
          weekId: weekId,
          recapUrl: result['recapUrl'],
          clipsCount: result['clipsCount'],
          duration: result['duration'] ?? '',
          isAdmin: _isAdmin,
        );

        // Reload videos
        await _loadVideos();

        if (mounted) {
          final systemUsed = useEnhancedSystem 
              ? '${smartPrefs.defaultTemplate.name} style' 
              : 'simple merge (backup)';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ Weekly recap created with $systemUsed!'),
              backgroundColor: const Color(0xFF009688),
              duration: const Duration(seconds: 3),
            ),
          );

          // Switch to Weekly tab
          setState(() {
            selectedTab = 'Weekly';
          });
        }
      } else {
        throw Exception('Failed to create recap');
      }
    } catch (e) {
      print('[VIDEOS] Error creating recap: $e');

      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 20.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Videos',
          style: TextStyle(
            color: const Color(0xFF009688),
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        actions: [
          // Sync status indicator
          if (_syncStats['pending'] != null && _syncStats['pending'] > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.cloudArrowUp, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${_syncStats['pending']}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Force sync button - Uploads pending videos to cloud
          Tooltip(
            message: 'Sync Now\nUpload pending videos to cloud storage',
            child: IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.arrowsRotate,
                size: 18,
                color: Color(0xFF009688),
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              onPressed: _forceSyncNow,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: isTablet ? 24 : 20),

          // Custom Tab Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Container(
              height: isTablet ? 52 : 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
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
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : (isDark ? const Color(0xFFB0B0B0) : const Color(0xFF757575)),
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

          SizedBox(height: isTablet ? 16 : 12),

          // Storage info banner
          if (_storageUsage['totalMB'] != null && _storageUsage['totalMB'] > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.database,
                      size: 20,
                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_storageUsage['videoCount']} videos • ${(_storageUsage['totalMB'] as double).toStringAsFixed(1)} MB used',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_syncStats['pending'] != null && _syncStats['pending'] > 0)
                      Text(
                        '${_syncStats['pending']} pending',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          SizedBox(height: isTablet ? 24 : 20),

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
                          FaIcon(
                            selectedTab == 'Weekly'
                                ? FontAwesomeIcons.film
                                : FontAwesomeIcons.video,
                            size: isTablet ? 80 : 64,
                            color: isDark ? const Color(0xFF757575) : const Color(0xFFBDBDBD),
                          ),
                          SizedBox(height: isTablet ? 20 : 16),
                          Text(
                            selectedTab == 'Weekly'
                                ? 'No weekly recap yet'
                                : 'No videos yet',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF757575),
                            ),
                          ),
                          SizedBox(height: isTablet ? 10 : 8),
                          Text(
                            selectedTab == 'Weekly'
                                ? 'Weekly recap videos coming soon!'
                                : 'Start recording your memories',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: isDark ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        bottom: 100,
                      ),
                      itemCount: currentVideos.length,
                      itemBuilder: (context, index) {
                        final video = currentVideos[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                          child:
                              selectedTab == 'Daily'
                                  ? _buildDailyVideoCard(video, isTablet)
                                  : _buildCompilationCard(video, isTablet),
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
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.wandMagicSparkles,
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
  Widget _buildDailyVideoCard(Map<String, dynamic> video, bool isTablet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thumbnailUrl = video['thumbnailUrl']?.toString() ?? '';

    return Container(
      height: isTablet ? 140 : 120,
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
            // Navigate to video player screen
            // Use local path if video hasn't been uploaded yet, otherwise use remote URL
            final videoPath = (video['localPath']?.toString() ?? '').isNotEmpty
                ? video['localPath'].toString()
                : video['storageDownloadUrl'] ?? '';
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => VideoPlayerScreen(
                      videoUrl: videoPath,
                      emoji: video['emoji']?.toString() ?? '',
                      description:
                          video['textNote']?.toString() ?? 'No description',
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
                      localPath: video['localPath']?.toString(), // NEW: Pass local path
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
                          child: FaIcon(
                            FontAwesomeIcons.play,
                            size: isTablet ? 32 : 28,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                    ),

                    // Video duration badge (bottom right)
                    if (video['durationText']?.toString().isNotEmpty ?? false)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            video['durationText'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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
                              (video['textNote'] ?? 'No description')
                                  .toString(),
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
                          FaIcon(
                            FontAwesomeIcons.calendar,
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

                // Favorite Icon - Improved Design (Reactive with GetX)
                Obx(() {
                  final favoritesController = Get.find<FavoritesController>();
                  final videoId = video['id'] as String? ?? '';
                  final isFavorite = favoritesController.isFavorite(videoId);
                  
                  return GestureDetector(
                    onTap: () => _toggleFavorite(videoId),
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
                      child: FaIcon(
                        isFavorite
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
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

  // Weekly/Monthly compilation card (large card with share, save, and music buttons)
  Widget _buildCompilationCard(
    Map<String, dynamic> compilation,
    bool isTablet,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
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
                      gradient: const LinearGradient(
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
                                child: FaIcon(
                                  FontAwesomeIcons.clapperboard,
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
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      compilation['title'],
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),

                    SizedBox(height: isTablet ? 10 : 8),

                    // Stats Row (clips count and duration)
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.video,
                          size: isTablet ? 18 : 16,
                          color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF757575),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${compilation['clipsCount']} clips',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF757575),
                            height: 1.3,
                          ),
                        ),
                        SizedBox(width: isTablet ? 14 : 12),
                        FaIcon(
                          FontAwesomeIcons.clock,
                          size: isTablet ? 18 : 16,
                          color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF757575),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          compilation['duration'],
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF757575),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isTablet ? 10 : 8),

                    // Merge date and time
                    if (compilation['createdAt'] != null)
                      Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.clock,
                            size: isTablet ? 16 : 14,
                            color: isDark ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Merged ${_formatMergeDateTime(compilation['createdAt'])}',
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 13,
                              color: isDark ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: isTablet ? 10 : 8),

                    // Selected music track (if any)
                    if ((compilation['selectedMusicTrack'] ?? '')
                        .toString()
                        .isNotEmpty)
                      Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.music,
                            size: isTablet ? 18 : 16,
                            color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF757575),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              compilation['selectedMusicTrack'],
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF757575),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: isTablet ? 16 : 12),

                    // Action Buttons Row
                    Row(
                      children: [
                        // Share Button
                        _buildActionButton(
                          icon: FontAwesomeIcons.share,
                          label: 'Share',
                          color: const Color(0xFF009688),
                          onTap: () => _shareRecap(compilation),
                          isTablet: isTablet,
                        ),

                        SizedBox(width: isTablet ? 14 : 12),

                        // Save Button
                        _buildActionButton(
                          icon: FontAwesomeIcons.download,
                          label: 'Save',
                          color: const Color(0xFF009688),
                          onTap: () => _saveRecap(compilation),
                          isTablet: isTablet,
                        ),

                        SizedBox(width: isTablet ? 14 : 12),

                        // Music Button
                        _buildActionButton(
                          icon: FontAwesomeIcons.music,
                          label: '',
                          color: const Color(0xFF009688),
                          onTap: () => _openMusicPicker(compilation),
                          iconOnly: true,
                          isTablet: isTablet,
                        ),

                        SizedBox(width: isTablet ? 14 : 12),

                        // Delete Button
                        _buildActionButton(
                          icon: FontAwesomeIcons.trash,
                          label: '',
                          color: const Color(0xFFE53935),
                          onTap: () => _deleteRecap(compilation),
                          iconOnly: true,
                          isTablet: isTablet,
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
                          leading: const FaIcon(
                            FontAwesomeIcons.music,
                            color: Color(0xFF009688),
                          ),
                          title: Text(track),
                          trailing:
                              isSelected
                                  ? const FaIcon(
                                    FontAwesomeIcons.check,
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
      const mode =
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
                      leading: const FaIcon(FontAwesomeIcons.link, color: Color(0xFF009688)),
                      title: const Text('Copy Link'),
                      onTap: () {
                        Navigator.pop(context);
                        _copyRecapLink(recapUrl);
                      },
                    ),
                    ListTile(
                      leading: const FaIcon(
                        FontAwesomeIcons.download,
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
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 10, 10),
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
    bool isTablet = false,
  }) {
    return Expanded(
      child: Container(
        height: isTablet ? 46 : 40,
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
                FaIcon(icon, size: isTablet ? 22 : 18, color: color),
                if (!iconOnly) ...[
                  SizedBox(width: isTablet ? 8 : 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
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
