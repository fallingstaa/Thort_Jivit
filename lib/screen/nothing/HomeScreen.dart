import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- Navigation ---
  // This function handles navigation when a bottom navigation bar item is tapped.
  // NOTE: You must have routes named '/calendar', '/videos', and '/profile'
  // set up in your main.dart file for this to work.
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Do nothing if already on the selected screen

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on Home, do nothing or refresh
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/calendar');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/videos');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // A light bluish-grey background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildWeeklyProgressCard(),
                const SizedBox(height: 40),
                _buildRecordNowButton(),
                const SizedBox(height: 40),
                _buildTodaysPromptCard(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- UI Widget Builders ---

  /// Builds the top header section with user info and streak.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF00A981), // Greenish color from the image
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            // You can replace this with a NetworkImage or an AssetImage
            // For example: backgroundImage: AssetImage('assets/images/your_profile_pic.png')
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 30, color: Color(0xFF00A981)),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Sinet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Monday, October 6',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Spacer(),
          Chip(
            backgroundColor: Colors.orange,
            avatar: Icon(Icons.whatshot, color: Colors.white, size: 20),
            label: Text(
              '5-day streak',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the weekly progress card.
  Widget _buildWeeklyProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '6/7 days',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayCircle('M', isCompleted: true),
              _buildDayCircle('T', isCompleted: true),
              _buildDayCircle('W', isCompleted: true),
              _buildDayCircle('T', isCompleted: true),
              _buildDayCircle('F', isCompleted: true),
              _buildDayCircle('S', isCompleted: false),
              _buildDayCircle('S', isCompleted: true),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your best streak: 14 days',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Navigate to calendar screen
                  Navigator.pushReplacementNamed(context, '/calendar');
                },
                icon: const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                label: const Text(
                  'View calendar',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper widget for the day circles in the progress card.
  Widget _buildDayCircle(String day, {required bool isCompleted}) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFF00A981) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  /// Builds the central "Record Now" button.
  Widget _buildRecordNowButton() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            // Handle record now tap
            print("Record Now tapped!");
          },
          borderRadius: BorderRadius.circular(60),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00A981),
                width: 6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Record Now',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Builds the "Today's Prompt" card at the bottom.
  Widget _buildTodaysPromptCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S PROMPT",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'What made you smile today?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Record a short clip answering this question to continue your life story.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5, // Line height
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.videocam),
          label: 'Videos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xFF00A981),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed, // To show all labels
    );
  }
}
