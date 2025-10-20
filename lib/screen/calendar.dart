import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedIndex = 1; // Set to 1 for the Calendar tab

  // --- Navigation ---
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    // Use pushReplacementNamed to avoid building up a stack of pages
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        // Already on Calendar, do nothing
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
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildMonthSelector(),
              const SizedBox(height: 16),
              _buildCalendarGrid(),
              const SizedBox(height: 24),
              _buildAddRecordingButton(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 24),
              _buildMonthlySummaryCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- UI Widget Builders ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () {
            // Navigate back to the previous screen, likely HomePage
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Fallback if there's no screen to pop to
              Navigator.pushReplacementNamed(context, '/home');
            }
        },
      ),
      title: const Text(
        'Calendar',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black54),
            onPressed: () {},
          ),
          const Text(
            'October 2025',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // Weekday headers
    final List<String> weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    // Days in October 2025 start on a Wednesday (index 3)
    final int firstDayOffset = 3;
    final int daysInMonth = 31;
    // Mock data for recorded days, matching the image
    final Map<int, List<IconData>> recordedDays = {
      3: [Icons.videocam],
      5: [Icons.videocam],
      8: [Icons.videocam, Icons.notes],
      12: [Icons.videocam],
      15: [Icons.videocam, Icons.notes],
      18: [Icons.videocam, Icons.notes],
      22: [Icons.videocam],
      25: [Icons.videocam],
      27: [Icons.videocam, Icons.notes],
    };

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) => Text(day, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))).toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1, // Adjust aspect ratio for better spacing
            ),
            itemCount: daysInMonth + firstDayOffset,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink(); // Empty space before the 1st
              }
              final int day = index - firstDayOffset + 1;
              return _buildCalendarDay(
                day: day,
                isRecorded: recordedDays.containsKey(day),
                icons: recordedDays[day] ?? [],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay({required int day, bool isRecorded = false, List<IconData> icons = const []}) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isRecorded ? const Color(0xFF00A981) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              color: isRecorded ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (icons.isNotEmpty)
            Positioned(
              bottom: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: icons
                    .map((icon) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                          child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 8),
                        ))
                    .toList(),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildAddRecordingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Missed Recording',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A981),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.video_library_outlined),
            label: const Text('All Videos'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.dashboard_outlined),
            label: const Text('Dashboard'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Month',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('9', 'Clips'),
              _buildSummaryItem('8:32', 'Total Time'),
              _buildSummaryItem('29%', 'Coverage'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00A981)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        BottomNavigationBarItem(icon: Icon(Icons.videocam), label: 'Videos'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xFF00A981),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
    );
  }
}

