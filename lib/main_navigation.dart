import 'package:flutter/material.dart';
import 'package:thort_jivit/screen/profile/profile.dart';
import 'package:thort_jivit/screen/videos/videos_screen.dart';
import 'package:thort_jivit/screen/home/HomePage.dart'; // <<< ADJUSTED IMPORT PATH
import 'package:thort_jivit/screen/calender/calendar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // List of screens for each tab - using PageStorageKey to preserve state
  late final List<Widget> _screens = [
    PageStorage(
      bucket: PageStorageBucket(),
      child: const HomePage(showBottomNav: false),
    ),
    PageStorage(bucket: PageStorageBucket(), child: const CalendarScreen()),
    PageStorage(bucket: PageStorageBucket(), child: const VideosScreen()),
    PageStorage(bucket: PageStorageBucket(), child: const ProfilePage()),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5D9F6A),
        unselectedItemColor: Colors.black45,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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
      ),
    );
  }
}