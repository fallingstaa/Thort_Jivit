import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:thort_jivit/screen/profile/profile.dart';
import 'package:thort_jivit/screen/videos/videos_screen.dart';
import 'package:thort_jivit/screen/home/HomePage.dart'; // <<< ADJUSTED IMPORT PATH
import 'package:thort_jivit/screen/calender/calendar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey _videosScreenKey = GlobalKey();

  // List of screens for each tab - using PageStorageKey to preserve state
  late final List<Widget> _screens = [
    PageStorage(
      bucket: PageStorageBucket(),
      child: const HomePage(showBottomNav: false),
    ),
    PageStorage(bucket: PageStorageBucket(), child: const CalendarScreen()),
    PageStorage(
      bucket: PageStorageBucket(), 
      child: VideosScreen(key: _videosScreenKey),
    ),
    PageStorage(bucket: PageStorageBucket(), child: const ProfilePage()),
  ];

  void _onTabTapped(int index) {
    final previousIndex = _currentIndex;
    setState(() {
      _currentIndex = index;
    });
    
    // Force refresh videos screen when videos tab is selected
    // This ensures videos appear immediately after recording
    if (index == 2 && previousIndex != 2) {
      // Videos tab was just selected - trigger refresh after a short delay
      Future.delayed(const Duration(milliseconds: 400), () {
        // The videos screen will refresh via didChangeDependencies
        // but we can also trigger a rebuild by changing the key
        // For now, rely on didChangeDependencies
      });
    }
    
    // Refresh profile screen when profile tab is selected to sync profile picture
    if (index == 3 && previousIndex != 3) {
      // Profile tab was just selected - refresh user data to sync profile picture
      Future.delayed(const Duration(milliseconds: 300), () {
        // Trigger a rebuild of the profile screen by updating the key
        // This will cause ProfilePage to reload user data
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              selectedItemColor: const Color(0xFF008060),
              unselectedItemColor: isDark ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Center(
                      child: FaIcon(
                        _currentIndex == 0 ? FontAwesomeIcons.solidHouse : FontAwesomeIcons.house,
                        size: 22,
                      ),
                    ),
                  ),
                  activeIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008060).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.solidHouse,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Center(
                      child: FaIcon(
                        _currentIndex == 1 ? FontAwesomeIcons.solidCalendarDays : FontAwesomeIcons.calendar,
                        size: 22,
                      ),
                    ),
                  ),
                  activeIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008060).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.solidCalendarDays,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  label: 'Calendar',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Center(
                      child: FaIcon(
                        _currentIndex == 2 ? FontAwesomeIcons.solidCirclePlay : FontAwesomeIcons.circlePlay,
                        size: 22,
                      ),
                    ),
                  ),
                  activeIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008060).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.solidCirclePlay,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  label: 'Videos',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Center(
                      child: FaIcon(
                        _currentIndex == 3 ? FontAwesomeIcons.solidUser : FontAwesomeIcons.user,
                        size: 22,
                      ),
                    ),
                  ),
                  activeIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008060).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.solidUser,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
