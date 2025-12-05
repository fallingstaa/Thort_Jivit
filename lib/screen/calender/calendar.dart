import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thort_jivit/services/firestore_service.dart';
import 'package:thort_jivit/services/video_duration.dart' as video_duration;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int? _selectedDay;
  bool _isSubmitting = false;
  DateTime _displayed = DateTime.now();
  Map<int, String> _recordedDays = {};
  bool _isSelectedAllowed = false;
  @override
  void initState() {
    super.initState();
    _loadRecordedDays();
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

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              _buildMonthSelector(),
              const SizedBox(height: 12),
              _buildCalendarGrid(),
              const SizedBox(height: 24),
              _buildAddRecordingButton(),
              const SizedBox(height: 12),
              _buildActionButtons(),
              const SizedBox(height: 12),
              _buildMonthlySummaryCard(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text(
        'Calendar',
        style: TextStyle(color: Color(0xFF00A981), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black54),
            onPressed: () {
              setState(() {
                _displayed = DateTime(_displayed.year, _displayed.month - 1);
                _selectedDay = null;
              });
              _loadRecordedDays();
            },
          ),
          Text(
            '${_monthName(_displayed.month)} ${_displayed.year}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.black54),
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

  Widget _buildCalendarGrid() {
    final List<String> weekDays = [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ];
    final firstOfMonth = DateTime(_displayed.year, _displayed.month, 1);
    final int firstDayOffset = firstOfMonth.weekday % 7; // Sunday=0
    final int daysInMonth =
        DateTime(_displayed.year, _displayed.month + 1, 0).day;

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
            children:
                weekDays
                    .map(
                      (day) => Text(
                        day,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: daysInMonth + firstDayOffset,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink();
              }
              final int day = index - firstDayOffset + 1;
              return _buildCalendarDay(day: day, emoji: _recordedDays[day]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay({required int day, String? emoji}) {
    final bool isRecorded = emoji != null && emoji.isNotEmpty;
    final bool isSelected = _selectedDay == day;
    final now = DateTime.now();
    final bool isToday =
        now.year == _displayed.year &&
        now.month == _displayed.month &&
        now.day == day;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
          _isSelectedAllowed = false;
        });

        // Check whether this date is allowed for upload
        final selectedDate = DateTime(_displayed.year, _displayed.month, day);
        _firestoreService.canUploadForDate(selectedDate).then((allowed) {
          if (mounted) setState(() => _isSelectedAllowed = allowed);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isRecorded ? const Color(0xFF00A981) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected && !isRecorded
                  ? Border.all(color: const Color(0xFF00A981), width: 2)
                  : (isToday
                      ? Border.all(
                        color: Colors.blueAccent.withOpacity(0.6),
                        width: 2,
                      )
                      : null),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isRecorded ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRecorded)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRecordingButton() {
    // Determine if the button should be enabled
    final bool hasSelection = _selectedDay != null;
    // Use fetched recorded days for the displayed month
    final bool selectedIsRecorded =
        hasSelection && _recordedDays.containsKey(_selectedDay);
    final bool enabled =
        hasSelection &&
        !selectedIsRecorded &&
        !_isSubmitting &&
        _isSelectedAllowed;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? _onAddMissingRecordingPressed : null,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          selectedIsRecorded
              ? 'Already Recorded'
              : (_isSelectedAllowed
                  ? 'Add Missed Recording'
                  : 'Date Not Allowed'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? const Color(0xFF00A981) : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add Missing Record',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.video,
                          withData: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          setState(() {
                            pickedFile = result.files.first;
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Pick Video File'),
                    ),
                    if (pickedFile != null) ...[
                      const SizedBox(height: 8),
                      Text('Selected: ${pickedFile!.name}'),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !isUploading,
                      decoration: const InputDecoration(
                        labelText: 'Text note (optional)',
                      ),
                      onChanged: (v) => textNote = v,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children:
                          ['😊', '😢', '😡', '😰', '😌'].map((e) {
                            final isSel = selectedEmoji == e;
                            return ChoiceChip(
                              label: Text(
                                e,
                                style: const TextStyle(fontSize: 18),
                              ),
                              selected: isSel,
                              onSelected: isUploading ? null : (_) => setState(() => selectedEmoji = e),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (pickedFile == null || isUploading)
                            ? null
                            : () async {
                                // Validate video duration between 10-30 seconds
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
                                    debugPrint('Picked file has no bytes: ${pickedFile!.name}');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not read file bytes from picker. Try again or use a smaller file.',
                                        ),
                                      ),
                                    );
                                  } else {
                                    debugPrint('Could not load metadata for file: ${pickedFile!.name} (size=${pickedFile!.size})');
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                    const SnackBar(content: Text('Upload successful')),
                                  );

                                  // close sheet after success
                                  Navigator.of(context).pop();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Upload failed: $e')));
                                } finally {
                                  // ensure we reset uploading flag if sheet still open
                                  try {
                                    setState(() {
                                      isUploading = false;
                                    });
                                  } catch (_) {}
                                }
                              },
                        child: isUploading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit Record'),
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
      final String? filePath = pickedFile.path;
      final bytes = pickedFile.bytes;
      final filename = pickedFile.name;

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

      final downloadUrl = await _firestoreService.uploadVideoAndMetadata(
        filePath: filePath,
        bytes: bytes,
        filename: filename,
        dayIndex: dayIndex,
        emoji: emoji,
        textNote: textNote,
        weekId: weekId,
        timestamp: selectedDate,
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
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: const Color(0xFF00A981),
              side: BorderSide(color: const Color(0xFF00A981)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: const Color(0xFF00A981),
              side: BorderSide(color: const Color(0xFF00A981)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Month',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
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
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00A981),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}
