import 'package:flutter/material.dart';
import '../calender/calendar.dart';
import '../profile/profile.dart';
import '../camera/record_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../videos/videos_screen.dart';

class HomePage extends StatefulWidget {
  final bool showBottomNav;

  const HomePage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Get current user from Firebase
  final User? currentUser = FirebaseAuth.instance.currentUser;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
                color: Color(0xFF008060),
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
                      children: const [
                        Icon(
                          Icons.local_fire_department,
                          color: Color(0xFFFF8C42),
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '5-day streak',
                          style: TextStyle(
                            color: Color(0xFFFF8C42),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Weekly Progress Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      const Text(
                        '6/7 days',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      DayCheckmark(day: 'M', isCompleted: true),
                      DayCheckmark(day: 'T', isCompleted: true),
                      DayCheckmark(day: 'W', isCompleted: true),
                      DayCheckmark(day: 'T', isCompleted: true),
                      DayCheckmark(day: 'F', isCompleted: true),
                      DayCheckmark(day: 'S', isCompleted: true),
                      DayCheckmark(day: 'S', isCompleted: false),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                          children: [
                            TextSpan(text: 'Your best streak:  '),
                            TextSpan(
                              text: '14 days',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: const [
                          Text(
                            'View calendar',
                            style: TextStyle(
                              color: Color(0xFF5D9F6A),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Color(0xFF5D9F6A),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Record Button
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RecordScreen()),
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
                          color: const Color(0xFF008060),
                          width: 8,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF008060),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Record Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF008060),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalendarScreen(),
                        ),
                      );
                      break;
                    case 2:
                      // Navigate to Videos
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VideosScreen(),
                        ),
                      );
                      break;
                    case 3:
                      // Navigate to Profile
                      Navigator.push(
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
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today),
                    label: 'Calendar',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.video_library),
                    label: 'Videos',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
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
  final bool isCompleted;

  const DayCheckmark({Key? key, required this.day, required this.isCompleted})
    : super(key: key);

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
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: isCompleted ? Colors.black87 : Colors.black45,
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class TodaysPromptCard extends StatelessWidget {
  const TodaysPromptCard({Key? key}) : super(key: key);

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
                  children: const [
                    Text(
                      "TODAY'S PROMPT",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9E9E96),
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'What made you smile today?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3E2F),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Record a short clip answering this question to continue your life story.',
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
