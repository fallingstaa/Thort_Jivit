import 'package:flutter/material.dart';
import '../calender/calendar.dart';
import '../profile/profile.dart';
import '../camera/record_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thort_jivit/services/firestore_service.dart';

import '../videos/videos_screen.dart';

class HomePage extends StatefulWidget {
  final bool showBottomNav;

  const HomePage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Get current user from Firebase
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService = FirestoreService();

  int _currentStreak = 0;
  List<Map<String, dynamic>> _weekDays = [];
  bool _canRecordToday = true;
  bool _isCheckingRecord = true;
  AnimationController? _helpButtonAnimation;

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _loadWeekData();
    _checkCanRecord();

    // Setup blinking animation for help button
    _helpButtonAnimation = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _helpButtonAnimation?.dispose();
    super.dispose();
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
    final canRecord = await _firestoreService.canRecordToday();
    setState(() {
      _canRecordToday = canRecord;
      _isCheckingRecord = false;
    });
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF008060),
                          const Color(0xFF00A978),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.white,
                          size: 28,
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
                  _buildGuidelineSection(
                    '📹',
                    '1. Record Videos',
                    'You can only record your video for TODAY.\nYou cannot record for yesterday or tomorrow.\nOnly 1 video per day is allowed.\n\nExample: If today is December 11, you can record only for December 11.\n\nSuggestion: Short clips (10–15s) tend to be more memorable and eye‑catching. Longer videos still work — keep it concise for the best recap.',
                  ),
                  _buildGuidelineSection(
                    '⬆️',
                    '2. Upload Videos (Optional)',
                    'You can upload videos for any missed day within the current week—even if that day has already passed.\nYou can also upload up to 2 days in advance.\n\nExample: If you missed recording on the 9th or 10th, you can still upload for those days as long as it\'s within the same week. If today is Thursday, you can also upload for Friday and Saturday.',
                  ),
                  _buildGuidelineSection(
                    '🎬',
                    '3. Create Your First Recap',
                    'You need at least 3 videos to create a recap.\nThese can be recorded today or uploaded in advance — both are okay.\nOnce you create your recap for the week, it is final and cannot be edited or deleted.\n\nExample: Record 1 video today + upload 2 videos for the next days = 3 videos → recap is unlocked.',
                  ),
                  _buildGuidelineSection(
                    '⏱️',
                    '4. When You Can Create a Recap',
                    'You can create a recap as soon as you have 3 or more videos in a week.\n\nNo waiting needed—the moment you reach 3 videos, your recap is ready to create.\n\nEach week is separate: once you create a recap for one week, the next week starts fresh.',
                  ),
                  _buildGuidelineSection(
                    '🔒',
                    '5. What Happens After',
                    'Once you create a recap for a week, that week becomes locked.\nYou cannot add more videos, change anything, or delete the recap.\n\nA new week will automatically start, and you can begin recording or uploading new videos again.',
                  ),
                  const SizedBox(height: 20),
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00A978).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF00A978),
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You can access this guide anytime by tapping the Guide button',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8),
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
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF008060),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build falling snow animation with white dots
  Widget _buildSnowAnimation() {
    return Stack(
      children: List.generate(200, (index) {
        // Use DateTime to create truly random values for each snowflake
        final timeOffset = DateTime.now().millisecondsSinceEpoch;
        final randomLeft =
            ((index * 9973 + timeOffset * 7) % 10000) /
            10000.0 *
            MediaQuery.of(context).size.width;
        final randomDelay =
            ((index * 7919 + timeOffset * 13) % 8000).toDouble();
        final randomDuration =
            (10 + ((index * 3571 + timeOffset * 11) % 12)).toInt();
        return _SnowdotWidget(
          left: randomLeft,
          delay: Duration(milliseconds: randomDelay.toInt()),
          animationDuration: Duration(seconds: randomDuration),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isChristmasSeason = DateTime.now().month == 12;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  // margin: const EdgeInsets.all(16),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008060),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child:
                                  currentUser?.photoURL != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        child: Image.network(
                                          currentUser!.photoURL!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return _buildUserInitials();
                                          },
                                        ),
                                      )
                                      : _buildUserInitials(),
                            ),
                            Positioned(
                              top: -6,
                              right: -4,
                              child: Container(
                                width: 22,
                                height: 14,
                                decoration: BoxDecoration(
                                  color:
                                      isChristmasSeason
                                          ? const Color(0xFFC62828)
                                          : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(10),
                                    bottomLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  boxShadow:
                                      isChristmasSeason
                                          ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFC62828,
                                              ).withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                          : null,
                                ),
                                child:
                                    isChristmasSeason
                                        ? Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            height: 4,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $userName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getCurrentDate(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (isChristmasSeason) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Text(
                                    '❄',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Holiday spark is on',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Color(0xFFFF8C42),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_currentStreak-day streak',
                              style: const TextStyle(
                                color: Color(0xFFFF8C42),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (isChristmasSeason) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 18,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00A981),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(3),
                                    topRight: Radius.circular(8),
                                    bottomLeft: Radius.circular(3),
                                    bottomRight: Radius.circular(3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00A981,
                                      ).withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 3,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Weekly Progress Card
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.trending_up,
                                size: 20,
                                color: Colors.black87,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Weekly Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_weekDays.where((d) => d['hasVideo'] == true).length}/${_weekDays.length} days',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 20),
                      if (isChristmasSeason)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF008060),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Keep the merry streak rolling — log a memory today!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Text(
                                '❄',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Record Button
                Center(
                  child:
                      _isCheckingRecord
                          ? const CircularProgressIndicator(
                            color: Color(0xFF008060),
                          )
                          : InkWell(
                            onTap:
                                _canRecordToday
                                    ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RecordScreen(),
                                        ),
                                      ).then((_) {
                                        // Refresh when coming back
                                        _checkCanRecord();
                                        _loadWeekData();
                                      });
                                    }
                                    : () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'You have already recorded today! Come back tomorrow.',
                                          ),
                                          backgroundColor: Colors.orange,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          _canRecordToday
                                              ? const Color(0xFF008060)
                                              : Colors.grey,
                                      width: 8,
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          _canRecordToday
                                              ? const Color(0xFF008060)
                                              : Colors.grey,
                                    ),
                                    child:
                                        _canRecordToday
                                            ? null
                                            : const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 36,
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _canRecordToday
                                      ? 'Record Now'
                                      : 'Already Recorded',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        _canRecordToday
                                            ? const Color(0xFF008060)
                                            : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),

                const SizedBox(height: 40),

                // Today's Prompt Card - Matching exact design
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 12.0,
                  ),
                  child: TodaysPromptCard(),
                ),

                // Bottom spacing to account for bottom navigation bar
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
          // Snow animation (December only)
          if (DateTime.now().month == 12)
            Positioned.fill(child: IgnorePointer(child: _buildSnowAnimation())),
          // Floating Help Button with pulsing animation
          Positioned(
            bottom: 100,
            right: 20,
            child:
                _helpButtonAnimation != null
                    ? ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.85,
                        end: 1.15,
                      ).animate(_helpButtonAnimation!),
                      child: GestureDetector(
                        onTap: _showGuidelineModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF008060),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF008060).withOpacity(0.8),
                                blurRadius: 16,
                                spreadRadius: 3,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.help_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Guide',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : const SizedBox(),
          ),
        ],
      ),
      bottomNavigationBar:
          widget.showBottomNav
              ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                selectedItemColor: const Color(0xFF5D9F6A),
                unselectedItemColor: Colors.black45,
                currentIndex: 0,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      // Already on Home, do nothing
                      break;
                    case 1:
                      // Navigate to Calendar
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalendarScreen(),
                        ),
                      );
                      break;
                    case 2:
                      // Navigate to Videos
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VideosScreen(),
                        ),
                      );
                      break;
                    case 3:
                      // Navigate to Profile
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                      break;
                  }
                },
                selectedFontSize: 12,
                unselectedFontSize: 12,
                items: [
                  BottomNavigationBarItem(
                    icon: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (isChristmasSeason) ...[
                          const Text('🏠', style: TextStyle(fontSize: 20)),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00A981,
                                    ).withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else
                          const Icon(Icons.home),
                      ],
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (isChristmasSeason) ...[
                          const Text('📅', style: TextStyle(fontSize: 20)),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00A981,
                                    ).withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else
                          const Icon(Icons.calendar_today),
                      ],
                    ),
                    label: 'Calendar',
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (isChristmasSeason) ...[
                          const Text('🎬', style: TextStyle(fontSize: 20)),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00A981,
                                    ).withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else
                          const Icon(Icons.video_library),
                      ],
                    ),
                    label: 'Videos',
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (isChristmasSeason) ...[
                          const Text('👤', style: TextStyle(fontSize: 20)),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00A981,
                                    ).withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else
                          const Icon(Icons.person_outline),
                      ],
                    ),
                    label: 'Profile',
                  ),
                ],
              )
              : null,
    );
  }
}

class DayCheckmark extends StatelessWidget {
  final String day;
  final DateTime date;
  final bool isCompleted;

  const DayCheckmark({
    Key? key,
    required this.day,
    required this.date,
    required this.isCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? const Color(0xFF008060) : Colors.grey.shade200,
          ),
          child:
              isCompleted
                  ? const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  )
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: isCompleted ? const Color(0xFF004B36) : Colors.black45,
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          '${date.month}/${date.day}',
          style: TextStyle(
            fontSize: 10,
            color: isCompleted ? const Color(0xFF2F6B55) : Colors.black38,
          ),
        ),
      ],
    );
  }
}

class TodaysPromptCard extends StatefulWidget {
  const TodaysPromptCard({Key? key}) : super(key: key);

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Green left border
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF5D9F6A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DAILY INSPIRATION",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9E9E96),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _todayPrompt.isNotEmpty
                          ? _todayPrompt
                          : 'Every moment is a fresh beginning.',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3E2F),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Capture your moments and build your life story, one memory at a time.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B6B65),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Snowflake dot widget that falls down with blinking animation
class _SnowdotWidget extends StatefulWidget {
  final double left;
  final Duration delay;
  final Duration animationDuration;

  const _SnowdotWidget({
    required this.left,
    required this.delay,
    required this.animationDuration,
  });

  @override
  State<_SnowdotWidget> createState() => _SnowdotWidgetState();
}

class _SnowdotWidgetState extends State<_SnowdotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _position;
  late Animation<double> _opacity;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller = AnimationController(
          duration: widget.animationDuration,
          vsync: this,
        )..repeat();

        // Fall from top to bottom
        _position = Tween<double>(
          begin: -50,
          end: MediaQuery.of(context).size.height + 50,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

        // Gentle blink effect
        _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );

        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const SizedBox();

    final randomSize = 4.0 + ((widget.left.toInt() % 5)).toDouble();

    return AnimatedBuilder(
      animation: Listenable.merge([_position, _opacity]),
      builder: (context, child) {
        return Positioned(
          left: widget.left,
          top: _position.value,
          child: Opacity(opacity: _opacity.value, child: child),
        );
      },
      child: Container(
        width: randomSize,
        height: randomSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.6),
              blurRadius: randomSize * 1.5,
              spreadRadius: randomSize * 0.5,
            ),
          ],
        ),
      ),
    );
  }
}
