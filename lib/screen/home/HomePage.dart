import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../camera/record_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thort_jivit/services/firestore_service.dart';

class HomePage extends StatefulWidget {
  final bool showBottomNav;

  const HomePage({super.key, this.showBottomNav = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Get current user from Firebase
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService = FirestoreService();

  int _currentStreak = 0;
  List<Map<String, dynamic>> _weekDays = [];
  bool _canRecordToday = true;
  bool _isCheckingRecord = true;
  
  // Animation for guide button
  late AnimationController _guideButtonController;
  late Animation<double> _guideButtonAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStreak();
    _loadWeekData();
    _checkCanRecord();
    
    // SECURITY FIX: Validate and cleanup invalid recorded videos on startup
    // This removes videos that were recorded before the correct date
    _validateAndCleanupVideos();
    
    // Setup guide button pulsing animation
    _guideButtonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _guideButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _guideButtonController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _guideButtonController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh streak when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshStreak();
    }
  }
  
  /// Refresh streak by recalculating and reloading
  Future<void> _refreshStreak() async {
    try {
      // Recalculate streak to ensure it's accurate
      await _firestoreService.updateUserStreak();
      // Reload from user document
      await _loadStreak();
    } catch (e) {
      print('[HOMEPAGE] Error refreshing streak: $e');
    }
  }
  
  /// Validate and cleanup invalid recorded videos (recorded before correct date)
  Future<void> _validateAndCleanupVideos() async {
    try {
      await _firestoreService.validateAndCleanupRecordedVideos();
    } catch (e) {
      print('[HOMEPAGE] Error during video validation: $e');
      // Don't block the UI if cleanup fails
    }
  }

  Future<void> _loadStreak() async {
    final streak = await _firestoreService.getUserStreak();
    setState(() {
      _currentStreak = streak;
    });
  }

  Future<void> _loadWeekData() async {
    final weekData = await _firestoreService.getCurrentWeekData();
    if (weekData != null) {
      setState(() {
        _weekDays = List<Map<String, dynamic>>.from(weekData['days'] ?? []);
      });
    }
  }

  Future<void> _checkCanRecord() async {
    setState(() {
      _isCheckingRecord = true;
    });
    
    // Check with retry for Firestore eventual consistency
    bool canRecord = await _firestoreService.canRecordToday();
    
    // If still true, double-check after a delay
    if (canRecord) {
      await Future.delayed(const Duration(milliseconds: 500));
      canRecord = await _firestoreService.canRecordToday(retryCount: 1);
    }
    
    if (mounted) {
      setState(() {
        _canRecordToday = canRecord;
        _isCheckingRecord = false;
      });
      print('[HOMEPAGE] Record button state: canRecord=$canRecord');
    }
  }

  // Get username - with fallback options
  String get userName {
    if (currentUser?.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      return currentUser!.displayName!;
    } else if (currentUser?.email != null) {
      // If no display name, use the part before @ in email
      return currentUser!.email!.split('@')[0];
    }
    return 'User'; // Fallback if nothing is available
  }

  // Get current date formatted nicely
  String _getCurrentDate() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  // Build user initials widget
  Widget _buildUserInitials() {
    String initials = '';
    if (userName.isNotEmpty) {
      final nameParts = userName.split(' ');
      if (nameParts.length >= 2) {
        // First and last name initials
        initials =
            nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
      } else {
        // Just first initial
        initials = userName[0].toUpperCase();
      }
    } else {
      initials = 'U';
    }

    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF008060),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Show guidelines modal about merging rules
  void _showGuidelineModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with gradient background
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF008060), Color(0xFF00A978)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.lightbulb,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How It Works',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Simple steps to create your recap',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Quick Features Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00A978).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.star,
                              color: const Color(0xFF008060),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Quick Features',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildQuickFeature(
                          '🔔',
                          'Smart Daily Reminders',
                          'Get a friendly reminder at 12 PM only if you haven\'t recorded yet. No spam!',
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildQuickFeature(
                          '📊',
                          'Weekly Progress Tracker',
                          'See all 7 days of your week with dates. Track your recording progress visually.',
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildGuidelineSection(
                    '📹',
                    '1. Record Videos',
                    'You can only record your video for TODAY.\nYou cannot record for yesterday or tomorrow.\nOnly 1 video per day is allowed.\n\nExample: If today is December 11, you can record only for December 11.\n\n💡 Tip: Short clips (10–15s) tend to be more memorable and eye‑catching. Longer videos still work — keep it concise for the best recap.',
                  ),
                  _buildGuidelineSection(
                    '⬆️',
                    '2. Upload Videos (Optional)',
                    'You can upload videos for any missed day within the current week—even if that day has already passed.\nYou can also upload up to 2 days in advance.\n\nExample: If you missed recording on the 9th or 10th, you can still upload for those days as long as it\'s within the same week. If today is Thursday, you can also upload for Friday and Saturday.',
                  ),
                  _buildGuidelineSection(
                    '📊',
                    '3. Track Your Weekly Progress',
                    'The Weekly Progress card shows all 7 days of your current week (Monday–Sunday).\n\n• See actual calendar dates for each day\n• Checkmarks (✓) show days you\'ve recorded\n• Progress counter shows "X/7" (e.g., "3/7")\n• Progress bar visualizes your completion\n\nEven if you\'re new and haven\'t recorded anything, you\'ll see all 7 days displayed immediately. As you record videos, checkmarks will appear automatically.',
                  ),
                  _buildGuidelineSection(
                    '🔔',
                    '4. Smart Daily Reminders',
                    'Never miss a recording with our smart notification system!\n\n• Daily reminder at 12:00 PM (your local time)\n• Only sends if you haven\'t recorded yet\n• No notifications if you already recorded (no spam!)\n• Works even when the app is closed\n\nTo manage: Go to Profile → Privacy & Security → Notifications\n\nExample: Record at 11 AM → No notification at 12 PM. Forget to record → Get a friendly reminder!',
                  ),
                  _buildGuidelineSection(
                    '🎬',
                    '5. Create Your First Recap',
                    'You need at least 3 videos to create a recap.\nThese can be recorded today or uploaded in advance — both are okay.\nOnce you create your recap for the week, it is final and cannot be edited or deleted.\n\nExample: Record 1 video today + upload 2 videos for the next days = 3 videos → recap is unlocked.',
                  ),
                  _buildGuidelineSection(
                    '⏱️',
                    '6. When You Can Create a Recap',
                    'You can create a recap as soon as you have 3 or more videos in a week.\n\nNo waiting needed—the moment you reach 3 videos, your recap is ready to create.\n\nEach week is separate: once you create a recap for one week, the next week starts fresh.',
                  ),
                  _buildGuidelineSection(
                    '🔒',
                    '7. What Happens After',
                    'Once you create a recap for a week, that week becomes locked.\nYou cannot add more videos, change anything, or delete the recap.\n\nA new week will automatically start, and you can begin recording or uploading new videos again.',
                  ),
                  const SizedBox(height: 20),
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF008060).withOpacity(0.1),
                          const Color(0xFF00A978).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00A978).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A978).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.circleInfo,
                            color: Color(0xFF00A978),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need Help?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap the Guide button (?) anytime to see this help',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008060),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Got it!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// Build a guideline section item with icon
  Widget _buildGuidelineSection(
    String emoji,
    String title,
    String description,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00A978).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008060).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 0),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a quick feature item for the features section
  Widget _buildQuickFeature(
    String emoji,
    String title,
    String description,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 16.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Set status bar to light icons for the green header
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1A1A1A), const Color(0xFF121212)]
                    : [const Color(0xFFF7F9FB), const Color(0xFFFFFFFF)],
              ),
            ),
          ),
          Column(
            children: [
              // Green gradient extending to top of screen (including status bar)
              Container(
                height: MediaQuery.of(context).padding.top,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF008060), Color(0xFF00A978)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    // Enhanced Header Section with gradient
                    Container(
                      padding: EdgeInsets.only(
                        top: isTablet ? 20 : 16,
                        left: horizontalPadding,
                        right: horizontalPadding,
                        bottom: isTablet ? 20 : 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF008060), Color(0xFF00A978)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF008060).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Enhanced avatar with shadow and ring
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Container(
                              width: isTablet ? 56 : 48,
                              height: isTablet ? 56 : 48,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child:
                                    currentUser?.photoURL != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(100),
                                          child: Image.network(
                                            currentUser!.photoURL!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return _buildUserInitials();
                                            },
                                          ),
                                        )
                                        : _buildUserInitials(),
                              ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 14 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $userName 👋',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isTablet ? 20 : 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getCurrentDate(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: isTablet ? 13 : 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                  // Enhanced streak badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 10,
                      vertical: isTablet ? 8 : 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: const Color(0xFFFF8C42),
                          size: isTablet ? 18 : 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_currentStreak ${_currentStreak == 1 ? 'day' : 'days'}',
                          style: TextStyle(
                            color: const Color(0xFFFF8C42),
                            fontWeight: FontWeight.w700,
                            fontSize: isTablet ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Guide button in header with pulsing animation
                  GestureDetector(
                    onTap: _showGuidelineModal,
                    child: AnimatedBuilder(
                      animation: _guideButtonAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _guideButtonAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.circleQuestion,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Enhanced Weekly Progress Card
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF008060).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const FaIcon(
                                        FontAwesomeIcons.chartLine,
                                        size: 16,
                                        color: Color(0xFF008060),
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 10 : 8),
                                    Text(
                                      'Weekly Progress',
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF008060).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_weekDays.where((d) => d['hasVideo'] == true).length}/${_weekDays.length}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 13 : 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF008060),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isTablet ? 18 : 14),
                            // Progress percentage bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _weekDays.isEmpty
                                    ? 0
                                    : _weekDays.where((d) => d['hasVideo'] == true).length / _weekDays.length,
                                backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F8),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF008060)),
                                minHeight: 5,
                              ),
                            ),
                            SizedBox(height: isTablet ? 18 : 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children:
                                  _weekDays.map((dayData) {
                                    final DateTime date = dayData['date'] as DateTime;
                                    final String dayLetter =
                                        dayData['dayLetter'] as String;
                                    final bool hasVideo = dayData['hasVideo'] as bool;
                                    return DayCheckmark(
                                      day: dayLetter,
                                      date: date,
                                      isCompleted: hasVideo,
                                      isTablet: isTablet,
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Spacer to center the record button
                    const Spacer(),

                    // Enhanced Record Button with animation - Centered
                    Center(
                      child: _isCheckingRecord
                          ? const CircularProgressIndicator(
                            color: Color(0xFF008060),
                            strokeWidth: 3,
                          )
                          : AbsorbPointer(
                            // Block all interactions when button is disabled
                            absorbing: !_canRecordToday,
                            child: GestureDetector(
                              onTap: () {
                                if (!_canRecordToday) return; // Extra safety check
                                
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RecordScreen(),
                                  ),
                                ).then((_) async {
                                  // Immediately disable button while checking
                                  if (mounted) {
                                    setState(() {
                                      _canRecordToday = false;
                                      _isCheckingRecord = true;
                                    });
                                  }
                                  
                                  // Wait for Firestore to be ready (eventual consistency)
                                  await Future.delayed(const Duration(milliseconds: 1500));
                                  
                                  // Refresh when coming back
                                  if (mounted) {
                                    _checkCanRecord();
                                    _loadWeekData();
                                    // Recalculate streak to ensure it's up to date
                                    await _firestoreService.updateUserStreak();
                                    _loadStreak();
                                  }
                                });
                              },
                              child: Opacity(
                                // Visual feedback for disabled state
                                opacity: _canRecordToday ? 1.0 : 0.6,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: isTablet ? 110 : 95,
                                      height: isTablet ? 110 : 95,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_canRecordToday
                                                    ? const Color(0xFF008060)
                                                    : Colors.grey)
                                                .withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                _canRecordToday
                                                    ? const Color(0xFF008060)
                                                    : Colors.grey.shade400,
                                            width: isTablet ? 5 : 4,
                                          ),
                                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                        ),
                                        child: Container(
                                          margin: EdgeInsets.all(isTablet ? 10 : 9),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient:
                                                _canRecordToday
                                                    ? const LinearGradient(
                                                      colors: [Color(0xFF008060), Color(0xFF00A978)],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    )
                                                    : null,
                                            color: _canRecordToday ? null : Colors.grey.shade400,
                                          ),
                                          child: Center(
                                            child:
                                              _canRecordToday
                                                  ? FaIcon(
                                                    FontAwesomeIcons.video,
                                                    color: Colors.white,
                                                    size: isTablet ? 32 : 26,
                                                  )
                                                  : FaIcon(
                                                    FontAwesomeIcons.solidCircleCheck,
                                                    color: Colors.white,
                                                    size: isTablet ? 32 : 26,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 14 : 12),
                                    Text(
                                      _canRecordToday
                                          ? 'Tap to Record'
                                          : 'Completed Today',
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 15,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            _canRecordToday
                                                ? const Color(0xFF008060)
                                                : Colors.grey.shade600,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _canRecordToday
                                          ? 'Capture your moment'
                                          : 'See you tomorrow!',
                                      style: TextStyle(
                                        fontSize: isTablet ? 13 : 11.5,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            _canRecordToday
                                                ? (isDark ? const Color(0xFFB0B0B0) : Colors.grey.shade600)
                                                : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ),

                    // Spacer to push daily inspiration to bottom
                    const Spacer(),

                    // Enhanced Today's Prompt Card - At Bottom
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: TodaysPromptCard(isTablet: isTablet),
                    ),

                    // Bottom spacing to account for bottom navigation bar
                    SizedBox(height: screenHeight > 700 ? 30 : 70),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class DayCheckmark extends StatelessWidget {
  final String day;
  final DateTime date;
  final bool isCompleted;
  final bool isTablet;

  const DayCheckmark({
    super.key,
    required this.day,
    required this.date,
    required this.isCompleted,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Column(
      children: [
        Container(
          width: isTablet ? 46 : 38,
          height: isTablet ? 46 : 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isCompleted
                ? const LinearGradient(
                    colors: [Color(0xFF008060), Color(0xFF00A978)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isCompleted
                ? null
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F8)),
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: const Color(0xFF008060).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
            border: isToday && !isCompleted
                ? Border.all(
                    color: const Color(0xFF008060).withOpacity(0.5),
                    width: 2,
                  )
                : null,
          ),
          child:
              isCompleted
                  ? const Center(
                      child: FaIcon(
                        FontAwesomeIcons.solidCircleCheck,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  : isToday
                      ? Center(
                          child: Container(
                            width: isTablet ? 9 : 7,
                            height: isTablet ? 9 : 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF008060),
                            ),
                          ),
                        )
                      : null,
        ),
        const SizedBox(height: 5),
        Text(
          day,
          style: TextStyle(
            fontSize: isTablet ? 12 : 10.5,
            color: isCompleted 
                ? const Color(0xFF008060)
                : isToday
                    ? const Color(0xFF008060)
                    : (isDark ? const Color(0xFFB0B0B0) : Colors.black54),
            fontWeight: isCompleted || isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          '${date.month}/${date.day}',
          style: TextStyle(
            fontSize: isTablet ? 10 : 8.5,
            color: isCompleted 
                ? const Color(0xFF008060).withOpacity(0.7)
                : (isDark ? const Color(0xFF757575) : Colors.black38),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class TodaysPromptCard extends StatefulWidget {
  final bool isTablet;

  const TodaysPromptCard({super.key, this.isTablet = false});

  @override
  State<TodaysPromptCard> createState() => _TodaysPromptCardState();
}

class _TodaysPromptCardState extends State<TodaysPromptCard> {
  String _todayPrompt = '';

  // List of motivational quotes
  final List<String> _prompts = [
    'Every moment is a fresh beginning.',
    'Your story matters. Keep recording it.',
    'Life is a collection of moments. Make them count.',
    'Small steps forward are still progress.',
    'Your journey is uniquely yours. Embrace it.',
    'Today is a new page in your story.',
    'Memories are the treasures that time cannot steal.',
    'Be the author of your own beautiful story.',
    'Every day is a chance to create something memorable.',
    'Your life is your message to the world.',
    'The best time to start is now.',
    'Celebrate the small wins—they add up to big victories.',
    'You are stronger than you think.',
    'Your past shaped you, but your future is unwritten.',
    'Keep going. Your story is far from over.',
    'Life is happening now. Capture it.',
    'Difficult roads often lead to beautiful destinations.',
    'Progress, not perfection.',
    'You are writing your legacy, one day at a time.',
    'The present moment is all we truly have.',
    'Your experiences make you who you are.',
    'Every ending is a new beginning.',
    'Courage is taking one more step forward.',
    'Your story inspires others more than you know.',
    'The best stories have ups and downs.',
    'Tomorrow is a blank canvas. Paint it well.',
    'Reflection is the first step to growth.',
    'Keep showing up for yourself.',
    'Life is a journey, not a destination.',
    'Your resilience is your superpower.',
    'The little moments create the big picture.',
    'Today struggles are tomorrow strengths.',
    'You have overcome 100% of your bad days so far.',
    'Gratitude turns what we have into enough.',
    'Your story is still being written.',
    'Embrace the journey, trust the process.',
    'Growth happens outside your comfort zone.',
    'You are capable of amazing things.',
    'Every day is a gift worth celebrating.',
    'Your voice matters. Your story matters.',
    'Be proud of how far you have come.',
    'Life beauty is in its imperfections.',
    'Keep moving forward, one step at a time.',
    'Your future self will thank you.',
    'Believe in the magic of new beginnings.',
    'You are the hero of your own story.',
    'The comeback is always stronger than the setback.',
    'Your potential is limitless.',
    'Today is another chance to grow.',
    'You are exactly where you need to be.',
  ];

  @override
  void initState() {
    super.initState();
    _selectRandomPrompt();
  }

  void _selectRandomPrompt() {
    final random = DateTime.now().millisecondsSinceEpoch % _prompts.length;
    setState(() {
      _todayPrompt = _prompts[random];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF8FAF9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle elements
          // Positioned(
          //   top: -20,
          //   right: -20,
          //   child: Container(
          //     width: 80,
          //     height: 80,
          //     decoration: BoxDecoration(
          //       shape: BoxShape.circle,
          //       color: const Color(0xFF008060).withOpacity(0.05),
          //     ),
          //   ),
          // ),
          // Positioned(
          //   bottom: -25,
          //   left: -25,
          //   child: Container(
          //     width: 100,
          //     height: 100,
          //     decoration: BoxDecoration(
          //       shape: BoxShape.circle,
          //       color: const Color(0xFF00A978).withOpacity(0.03),
          //     ),
          //   ),
          // ),
          // Content
          Padding(
            padding: EdgeInsets.all(widget.isTablet ? 24 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF008060), Color(0xFF00A978)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF008060).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.wandMagicSparkles,
                          color: Colors.white,
                          size: widget.isTablet ? 16 : 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "DAILY INSPIRATION",
                      style: TextStyle(
                        fontSize: widget.isTablet ? 11 : 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF008060),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: widget.isTablet ? 14 : 12),
                Text(
                  _todayPrompt.isNotEmpty
                      ? '"$_todayPrompt"'
                      : '"Every moment is a fresh beginning."',
                  style: TextStyle(
                    fontSize: widget.isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                    height: 1.4,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: widget.isTablet ? 14 : 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008060).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color(0xFF008060).withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.lightbulb,
                        color: Color(0xFF008060),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Capture your moments and build your life story, one memory at a time.',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 13 : 11.5,
                            color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

