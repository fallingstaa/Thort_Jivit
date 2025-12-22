# Weekly Progress UI Component

## Overview
The Weekly Progress card is a key feature on the Home screen that provides users with a visual representation of their recording activity for the current week. It displays all 7 days of the week with dates, day indicators, and progress tracking.

---

## UI Components

### 1. Weekly Progress Card

**Location:** Home Screen (main feed)

**Visual Structure:**
```
┌─────────────────────────────────────────┐
│  📊 Weekly Progress              3/7    │
│  ─────────────────────────────────────  │
│  [████████░░░░░░░░░░░░] 43%             │
│                                          │
│  M   T   W   T   F   S   S              │
│  9   10  11  12  13  14  15             │
│  ✓   ✓   ✓   ○   ○   ○   ○             │
└─────────────────────────────────────────┘
```

### 2. Component Elements

#### Header Section
- **Icon**: Chart line icon (📊) in a rounded container with brand green background
- **Title**: "Weekly Progress" text
- **Progress Counter**: Shows "X/7" format (e.g., "3/7" means 3 days recorded out of 7)
  - Styled with brand green color
  - Rounded background with light green tint

#### Progress Bar
- **Visual Indicator**: Linear progress bar showing completion percentage
- **Color**: Brand green (#008060) for filled portion
- **Background**: Light gray in light mode, dark gray in dark mode
- **Height**: 5px
- **Calculation**: `(days with videos / total days) * 100%`

#### Days Display
- **7 Day Indicators**: Shows Monday through Sunday
- **Day Letters**: S, M, T, W, T, F, S (abbreviated day names)
- **Dates**: Actual calendar dates displayed below day letters
- **Status Icons**:
  - ✓ (Checkmark) - Day has been recorded
  - ○ (Circle) - Day not yet recorded

---

## Visual Design

### Light Mode
- **Card Background**: White (#FFFFFF)
- **Text Color**: Dark gray (#1A1A1A)
- **Progress Bar Background**: Light gray (#F0F4F8)
- **Progress Bar Fill**: Brand green (#008060)
- **Shadow**: Subtle black shadow with 6% opacity

### Dark Mode
- **Card Background**: Dark gray (#1E1E1E)
- **Text Color**: Light gray (#E0E0E0)
- **Progress Bar Background**: Dark gray (#2A2A2A)
- **Progress Bar Fill**: Brand green (#008060)
- **Shadow**: Enhanced black shadow with 30% opacity

### Responsive Design
- **Tablet**: Larger padding (20px), larger font sizes (16px title, 13px counter)
- **Mobile**: Standard padding (16px), standard font sizes (15px title, 11.5px counter)

---

## Data Flow

### Initialization
1. On Home screen load, `_loadWeekData()` is called
2. `FirestoreService.getCurrentWeekData()` is invoked
3. For new users, a week is automatically created if it doesn't exist
4. Week data is fetched with all 7 days populated

### Data Structure
```dart
{
  'weekStart': DateTime,  // Monday of current week
  'days': [
    {
      'date': DateTime,        // Actual calendar date
      'dayLetter': String,      // 'S', 'M', 'T', 'W', 'T', 'F', 'S'
      'hasVideo': bool          // true if video recorded for this day
    },
    // ... 7 days total
  ]
}
```

### Updates
- **On Recording**: When user records a video, `_loadWeekData()` is called again
- **On App Resume**: Week data refreshes when returning to home screen
- **Automatic**: Week automatically updates when crossing into a new week

---

## User Experience

### For New Users
- **Immediate Display**: All 7 days are shown immediately, even without any recordings
- **Clear Dates**: Actual calendar dates are visible (e.g., "9", "10", "11")
- **Empty State**: All days show ○ (circle) indicating no videos yet
- **Progress**: Shows "0/7" with empty progress bar

### For Active Users
- **Visual Feedback**: Checkmarks appear on days with videos
- **Progress Tracking**: Counter and bar update in real-time
- **Motivation**: Visual progress encourages daily recording

### Edge Cases Handled
- **New User**: Week is automatically created, all days displayed
- **Week Transition**: Automatically shows new week when Monday arrives
- **No Videos**: Still displays all 7 days with empty state
- **Partial Week**: Shows current week even if it's mid-week

---

## Technical Implementation

### Key Files
- **`lib/screen/home/HomePage.dart`**: Main UI component
- **`lib/services/firestore_service.dart`**: Data fetching logic
- **`lib/widgets/day_checkmark.dart`**: Individual day indicator widget (if exists)

### Key Methods
```dart
// Load week data
Future<void> _loadWeekData() async {
  final weekData = await _firestoreService.getCurrentWeekData();
  if (weekData != null) {
    setState(() {
      _weekDays = List<Map<String, dynamic>>.from(weekData['days'] ?? []);
    });
  }
}

// Calculate progress
final progress = _weekDays.isEmpty
    ? 0
    : _weekDays.where((d) => d['hasVideo'] == true).length / _weekDays.length;

// Count recorded days
final recordedCount = _weekDays.where((d) => d['hasVideo'] == true).length;
```

---

## Accessibility

### Features
- **High Contrast**: Text and backgrounds meet WCAG AA standards
- **Clear Labels**: "Weekly Progress" title clearly identifies the component
- **Visual Indicators**: Color and icons provide clear status information
- **Responsive Text**: Font sizes adapt to screen size

### Screen Reader Support
- Progress counter announces "X out of 7 days recorded"
- Day indicators can be read with date information
- Progress bar percentage is calculable from counter

---

## Future Enhancements

Potential improvements:
1. **Tap to View**: Tap on a day to see video details
2. **Week Navigation**: Swipe to view previous/next weeks
3. **Streak Highlighting**: Special styling for consecutive days
4. **Animation**: Smooth transitions when checkmarks appear
5. **Statistics**: Show total videos, average per day, etc.

---

## Testing Checklist

- [ ] New users see all 7 days immediately
- [ ] Dates are correct for current week
- [ ] Day letters match actual days
- [ ] Progress counter updates when recording
- [ ] Progress bar fills correctly
- [ ] Checkmarks appear on recorded days
- [ ] Works in both light and dark mode
- [ ] Responsive on tablet and mobile
- [ ] Week transitions correctly on Monday
- [ ] Handles edge cases (no videos, partial week)

---

**Last Updated:** December 20, 2025
**Version:** 1.0

