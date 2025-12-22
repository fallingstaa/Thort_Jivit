import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:thort_jivit/services/firestore_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  int? _selectedDay;
  bool _isSubmitting = false;
  DateTime _displayed = DateTime.now();
  Map<int, String> _recordedDays = {};
  bool _isSelectedAllowed = false;
  int _currentStreak = 0;

  @override
  bool get wantKeepAlive => true; // Keep state alive in IndexedStack

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecordedDays();
    _loadStreak();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload data when app resumes
    if (state == AppLifecycleState.resumed) {
      _loadRecordedDays();
      _loadStreak();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when widget becomes visible
    // This helps when user records video and comes back to calendar
    _loadRecordedDays();
    _loadStreak();
  }

  Future<void> _loadRecordedDays() async {
    // Fetch recorded days across all weeks for the displayed month.
    final data = await _firestoreService.getRecordedDaysForMonth(
      year: _displayed.year,
      month: _displayed.month,
    );
    setState(() {
      _recordedDays = data;
    });
  }

  Future<void> _loadStreak() async {
    // Recalculate the streak to ensure it's accurate
    await _firestoreService.updateUserStreak();
    final streak = await _firestoreService.getUserStreak();
    setState(() {
      _currentStreak = streak;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 12.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Calendar',
          style: TextStyle(
            color: const Color(0xFF009688),
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isTablet ? 16.0 : 8.0,
          ),
          child: Column(
            children: [
              _buildMonthSelector(isTablet, isDark),
              SizedBox(height: isTablet ? 16 : 10),
              _buildCalendarGrid(isTablet, isDark),
              SizedBox(height: isTablet ? 20 : 14),
              _buildStreakCard(isTablet, isDark),
              SizedBox(height: isTablet ? 16 : 12),
              _buildAddRecordingButton(isTablet),
              SizedBox(height: isTablet ? 80 : 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(bool isTablet, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 12,
        vertical: isTablet ? 12 : 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF009688),
            const Color(0xFF00A978),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009688).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: Colors.white,
            ),
            iconSize: isTablet ? 28 : 22,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _displayed = DateTime(_displayed.year, _displayed.month - 1);
                _selectedDay = null;
              });
              _loadRecordedDays();
            },
          ),
          Flexible(
            child: Text(
              '${_monthName(_displayed.month)} ${_displayed.year}',
              style: TextStyle(
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              color: Colors.white,
            ),
            iconSize: isTablet ? 28 : 22,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _displayed = DateTime(_displayed.year, _displayed.month + 1);
                _selectedDay = null;
              });
              _loadRecordedDays();
            },
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const names = [
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
    return names[m - 1];
  }

  Widget _buildCalendarGrid(bool isTablet, bool isDark) {
    final List<String> weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final firstOfMonth = DateTime(_displayed.year, _displayed.month, 1);
    final int firstDayOffset = firstOfMonth.weekday % 7;
    final int daysInMonth = DateTime(_displayed.year, _displayed.month + 1, 0).day;

    return Container(
      padding: EdgeInsets.all(isTablet ? 24.0 : 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Weekday headers
          Padding(
            padding: EdgeInsets.only(
              top: isTablet ? 8 : 4,
              bottom: isTablet ? 16 : 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isDark 
                            ? const Color(0xFF009688).withOpacity(0.9)
                            : const Color(0xFF009688),
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet ? 14 : 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Calendar grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: isTablet ? 12 : 4,
              crossAxisSpacing: isTablet ? 12 : 4,
            ),
            itemCount: daysInMonth + firstDayOffset,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink();
              }
              final int day = index - firstDayOffset + 1;
              return _buildCalendarDay(
                day: day,
                emoji: _recordedDays[day],
                isTablet: isTablet,
                isDark: isDark,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay({
    required int day,
    String? emoji,
    bool isTablet = false,
    bool isDark = false,
  }) {
    final bool isRecorded = emoji != null && emoji.isNotEmpty;
    final bool isSelected = _selectedDay == day;
    final now = DateTime.now();
    final bool isToday = now.year == _displayed.year &&
        now.month == _displayed.month &&
        now.day == day;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
          _isSelectedAllowed = false;
        });

        final selectedDate = DateTime(_displayed.year, _displayed.month, day);
        _firestoreService.canUploadForDate(selectedDate).then((allowed) {
          if (mounted) setState(() => _isSelectedAllowed = allowed);
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isRecorded
                ? const Color(0xFF009688)
                : (isSelected
                    ? const Color(0xFF009688).withOpacity(0.12)
                    : (isToday
                        ? isDark 
                            ? const Color(0xFF009688).withOpacity(0.15)
                            : const Color(0xFF009688).withOpacity(0.08)
                        : Colors.transparent)),
            borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF009688)
                  : (isToday
                      ? const Color(0xFF009688).withOpacity(0.4)
                      : Colors.transparent),
              width: isSelected ? (isTablet ? 2.5 : 2) : (isToday ? (isTablet ? 2 : 1.5) : 0),
            ),
            boxShadow: isRecorded
                ? [
                    BoxShadow(
                      color: const Color(0xFF009688).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 4.0 : 2.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Emoji as background (behind the date)
                if (isRecorded && emoji.isNotEmpty)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Opacity(
                        opacity: 0.6,
                        child: Text(
                          emoji,
                          style: TextStyle(
                            fontSize: isTablet ? 32 : 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Date number on top
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isRecorded
                          ? Colors.white
                          : (isSelected || isToday
                              ? const Color(0xFF009688)
                              : (isDark
                                  ? const Color(0xFFE0E0E0)
                                  : const Color(0xFF424242))),
                      fontWeight: isRecorded
                          ? FontWeight.w700
                          : (isToday || isSelected
                              ? FontWeight.w700
                              : FontWeight.w500),
                      fontSize: isTablet ? 15 : 12,
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

  Widget _buildStreakCard(bool isTablet, bool isDark) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35),
            const Color(0xFFFF8C42),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C42).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: isTablet ? 32 : 28,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Streak',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$_currentStreak day${_currentStreak == 1 ? "" : "s"}',
                        style: TextStyle(
                          fontSize: isTablet ? 32 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 12 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '🔥',
              style: TextStyle(
                fontSize: isTablet ? 32 : 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRecordingButton(bool isTablet) {
    final bool hasSelection = _selectedDay != null;
    final bool selectedIsRecorded =
        hasSelection && _recordedDays.containsKey(_selectedDay);
    final bool enabled =
        hasSelection &&
        !selectedIsRecorded &&
        !_isSubmitting &&
        _isSelectedAllowed;

    String buttonText;
    IconData buttonIcon;
    
    if (selectedIsRecorded) {
      buttonText = 'Already Recorded';
      buttonIcon = Icons.check_circle;
    } else if (_isSelectedAllowed) {
      buttonText = 'Add Missed Recording';
      buttonIcon = Icons.add_circle_outline;
    } else {
      buttonText = hasSelection ? 'Date Not Allowed' : 'Select a Date';
      buttonIcon = Icons.block;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF009688).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? _onAddMissingRecordingPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled 
                ? const Color(0xFF009688) 
                : Colors.grey.shade400,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(buttonIcon, size: isTablet ? 24 : 22),
              const SizedBox(width: 12),
              Text(
                buttonText,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAddMissingRecordingPressed() async {
    if (_selectedDay == null) return;

    // Show a bottom sheet to pick file, emoji and note
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String selectedEmoji = '';
        String textNote = '';
        PlatformFile? pickedFile;
        bool isUploading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF008060).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.upload_file,
                            color: Color(0xFF008060),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add Missing Recording',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Video file picker
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: pickedFile != null 
                              ? const Color(0xFF008060) 
                              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isUploading
                              ? null
                              : () async {
                                  final result = await FilePicker.platform
                                      .pickFiles(
                                        type: FileType.video,
                                        withData: true,
                                      );
                                  if (result != null && result.files.isNotEmpty) {
                                    setState(() {
                                      pickedFile = result.files.first;
                                    });
                                  }
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  pickedFile != null 
                                      ? Icons.video_file 
                                      : Icons.video_library_outlined,
                                  color: pickedFile != null 
                                      ? const Color(0xFF008060) 
                                      : Colors.grey,
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pickedFile != null 
                                            ? 'Video Selected' 
                                            : 'Select Video File',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark 
                                              ? const Color(0xFFE0E0E0) 
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pickedFile != null 
                                            ? pickedFile!.name 
                                            : 'Tap to choose a video',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark 
                                              ? const Color(0xFFB0B0B0) 
                                              : Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Optional text note
                    TextField(
                      enabled: !isUploading,
                      decoration: InputDecoration(
                        labelText: 'Add a note (optional)',
                        hintText: 'What happened today?',
                        prefixIcon: const Icon(Icons.edit_note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF008060),
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 2,
                      onChanged: (v) => textNote = v,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Optional mood emoji - collapsed by default
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Icon(
                              selectedEmoji.isEmpty 
                                  ? Icons.emoji_emotions_outlined 
                                  : Icons.emoji_emotions,
                              color: const Color(0xFF008060),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedEmoji.isEmpty 
                                  ? 'Add mood (optional)' 
                                  : 'Mood: $selectedEmoji',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: ['😊', '😢', '😡', '😰', '😌', '🤩', '😴', '🥳'].map((e) {
                                final isSel = selectedEmoji == e;
                                return InkWell(
                                  onTap: isUploading
                                      ? null
                                      : () => setState(() {
                                            selectedEmoji = isSel ? '' : e;
                                          }),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? const Color(0xFF008060).withOpacity(0.15)
                                          : (isDark 
                                              ? const Color(0xFF2A2A2A) 
                                              : Colors.grey.shade100),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSel
                                            ? const Color(0xFF008060)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      e,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Upload button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (pickedFile == null || isUploading)
                                ? null
                                : () async {
                                  // Skip duration validation for now to allow uploads on web even when
                                  // the browser cannot read metadata (e.g. DEMUXER_ERROR/unsupported codec).
                                  // Keep the code structure so we can re-enable later if needed.
                                  /*
                                  Duration? dur;
                                  if (pickedFile!.bytes != null) {
                                    final bytes = pickedFile!.bytes!.toList();
                                    dur = await video_duration.getVideoDuration(
                                      bytes: bytes,
                                      filename: pickedFile!.name,
                                    );
                                  } else if (pickedFile!.path != null) {
                                    // pass filename when available to help MIME detection
                                    final name = pickedFile!.name;
                                    dur = await video_duration.getVideoDuration(
                                      filePath: pickedFile!.path,
                                      filename: name,
                                    );
                                  }

                                  if (dur == null) {
                                    // Helpful debug info for web: log file info and reason hints
                                    if (pickedFile!.bytes == null) {
                                      debugPrint(
                                        'Picked file has no bytes: ${pickedFile!.name}',
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not read file bytes from picker. Try again or use a smaller file.',
                                          ),
                                        ),
                                      );
                                    } else {
                                      debugPrint(
                                        'Could not load metadata for file: ${pickedFile!.name} (size=${pickedFile!.size})',
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not determine video duration. Browser may not support the file codec/container.',
                                          ),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  final secs = dur.inSeconds;
                                  if (secs < 10 || secs > 30) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Video length must be between 10 and 30 seconds. Selected: ${secs}s',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  */

                                  // Start uploading while keeping the sheet open
                                  setState(() {
                                    isUploading = true;
                                  });

                                  try {
                                    await _submitMissingRecord(
                                      pickedFile!,
                                      selectedEmoji,
                                      textNote,
                                    );

                                    // show success
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ Upload successful'),
                                        backgroundColor: Color(0xFF008060),
                                      ),
                                    );

                                    // close sheet after success
                                    Navigator.of(context).pop();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Upload failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    // ensure we reset uploading flag if sheet still open
                                    try {
                                      setState(() {
                                        isUploading = false;
                                      });
                                    } catch (_) {}
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008060),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Upload Recording',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
          },
        );
      },
    );
  }

  Future<void> _submitMissingRecord(
    PlatformFile pickedFile,
    String emoji,
    String textNote,
  ) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare parameters for the platform-aware uploader.
      // CRITICAL: On web, accessing pickedFile.path throws an error!
      // Only access .path on non-web platforms.
      final String? filePath = kIsWeb ? null : pickedFile.path;
      final filename = pickedFile.name;
      final fileBytes = pickedFile.bytes; // Uint8List? on web

      print('=== UPLOAD START ===');
      print('Platform: ${kIsWeb ? "WEB" : "NATIVE"}');
      print('Filename: $filename');
      print('Bytes length: ${fileBytes?.length ?? 0}');
      print('FilePath: ${kIsWeb ? "N/A (web)" : (filePath ?? "null")}');

      // On web, bytes are required since path doesn't exist
      if (kIsWeb && fileBytes == null) {
        print('ERROR: Web platform but bytes are null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'File bytes missing. Please pick the file again with a smaller file size.',
            ),
          ),
        );
        return;
      }

      if (!kIsWeb && filePath == null) {
        print('ERROR: Native platform but path is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File path missing. Please pick the file again.'),
          ),
        );
        return;
      }

      // For the initial test, hardcode dayIndex as 1, and use a default weekId like 'week_1'.
      final DateTime selectedDate = DateTime(
        _displayed.year,
        _displayed.month,
        _selectedDay ?? 1,
      );

      // Ensure a week exists for this date (create if starting today)
      final weekInfo = await _firestoreService.getOrCreateWeekForDate(
        selectedDate,
      );
      if (weekInfo == null) {
        throw Exception(
          'No active week for selected date and cannot create one.',
        );
      }
      final String weekId = weekInfo['weekId'] as String;
      final DateTime weekStart = weekInfo['startDate'] as DateTime;
      final int dayIndex = selectedDate.difference(weekStart).inDays + 1;

      print('Week ID: $weekId, Day Index: $dayIndex');
      print('Starting upload to Firestore/Storage...');

      final downloadUrl = await _firestoreService.uploadVideoAndMetadata(
        filePath: filePath,
        bytes: fileBytes,
        filename: filename,
        dayIndex: dayIndex,
        emoji: emoji,
        textNote: textNote,
        weekId: weekId,
        timestamp: selectedDate,
      );

      print(
        'Upload completed. Download URL: ${downloadUrl.isNotEmpty ? "SUCCESS" : "FAILED"}',
      );

      // On success, reflect the emoji on the calendar by updating local state
      setState(() {
        _recordedDays[selectedDate.day] = emoji;
      });

      // Refresh recorded days so the calendar shows the new emoji immediately
      await _loadRecordedDays();

      if (downloadUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Metadata saved but file upload failed. Please retry upload.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Record uploaded')));
      }
    } catch (e, stackTrace) {
      print('=== UPLOAD ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      print('=== UPLOAD END ===');
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

