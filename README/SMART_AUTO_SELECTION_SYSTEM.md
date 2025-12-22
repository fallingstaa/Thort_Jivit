# Smart Auto-Selection System

## Overview

Replaced manual template selection with **intelligent automatic selection** based on video content. The system now chooses the best template style and duration without requiring user input!

## How It Works

### 🤖 Smart Template Selection

The system analyzes all videos and selects the best template based on:

1. **Emoji Analysis** - Categorizes emojis into three groups:
   - **Energetic** (😄🤩🥳⚡🔥💪🎮) → Highlight Reel
   - **Emotional** (❤️💕🥰😊🌹🌸⭐) → Cinematic Story
   - **Neutral** (📅🏠☕📚💼🚗☀️) → Timeline

2. **Description Analysis** - Looks for keywords:
   - **Energetic**: "fun", "party", "exciting", "active", "sport"
   - **Emotional**: "love", "beautiful", "memory", "special", "moment"
   - **Neutral**: "day", "work", "routine", "normal"

3. **Scoring System** - Calculates mood scores and picks highest:
   ```
   Video 1: 😄 "Fun day at the park" → +2 energetic
   Video 2: ❤️ "Beautiful sunset" → +2 emotional
   Video 3: 📅 "Work meeting" → +2 neutral
   
   Result: Tie → Defaults to first highest (energetic)
   ```

### ⏱️ Smart Duration Selection

Duration is calculated based on number of videos:

| Videos | Duration | Reason |
|--------|----------|--------|
| 1-3 | 30s | Short week, keep brief |
| 4-5 | 40s | Medium week |
| 6 | 50s | Full week |
| 7+ | 60s | Many videos, max time |

## Implementation

### New Files

1. **`lib/services/smart_template_selector.dart`**
   - `selectBestTemplate()` - Analyzes videos and picks template
   - `calculateOptimalDuration()` - Determines duration from count
   - `createSmartPreferences()` - Combines both into preferences
   - Helper methods for emoji classification

2. **`lib/models/video.dart`**
   - Simple model to hold video data
   - Used by smart selector

### Modified Files

**`lib/screen/videos/videos_screen.dart`**
- Removed template selection dialog
- Added automatic selection before generation
- Shows selected template in loading dialog
- Updated success message

**Changes:**
```dart
// OLD: Show dialog and wait for user
final templateResult = await showDialog<RecapPreferences>(...);
if (templateResult == null) return; // User cancelled

// NEW: Auto-select based on content
final videoModels = weekVideos.map((v) => Video.fromMap(v)).toList();
final smartPrefs = SmartTemplateSelector.createSmartPreferences(videoModels);
```

## User Experience

### Before (Manual)
1. Click "Roll into the Memories Now"
2. **Wait for dialog to appear**
3. **Read 3 template options**
4. **Choose template**
5. **Adjust duration slider**
6. **Click Generate**
7. Wait for processing

### After (Automatic)
1. Click "Roll into the Memories Now"
2. Wait for processing ✨

**That's it!** The system does everything automatically.

## Benefits

### For Users
- ✅ **Faster** - No decision paralysis
- ✅ **Simpler** - One tap and done
- ✅ **Smarter** - Algorithm picks best style
- ✅ **Consistent** - Always optimal duration

### For Developers
- ✅ **Less UI complexity**
- ✅ **Fewer user errors**
- ✅ **Better data** (no random selections)
- ✅ **Easier to improve** (tune algorithm vs UI)

## Examples

### Example 1: Party Week
```
Videos:
- 🥳 "Birthday party!"
- 🎉 "Dancing all night"
- 😄 "Fun with friends"

Selection: Highlight Reel (energetic: 6, emotional: 0, neutral: 0)
Duration: 40s (3 videos)
```

### Example 2: Romantic Week
```
Videos:
- ❤️ "Anniversary dinner"
- 💕 "Beautiful sunset together"
- 🥰 "Special moment"

Selection: Cinematic Story (energetic: 0, emotional: 6, neutral: 0)
Duration: 40s (3 videos)
```

### Example 3: Work Week
```
Videos:
- 📅 "Monday morning"
- 💼 "Office meeting"
- ☕ "Coffee break"
- 🏠 "Back home"

Selection: Timeline (energetic: 0, emotional: 0, neutral: 8)
Duration: 40s (4 videos)
```

### Example 4: Mixed Week (No clear mood)
```
Videos:
- (no emoji) "Tuesday"
- (no emoji) "Wednesday"  
- (no emoji) "Thursday"

Selection: Timeline (default for neutral/empty)
Duration: 40s (3 videos)
```

## Logging

The system logs its decisions:

```
[SMART_SELECTOR] Selected Cinematic Story (emotional: 6)
[SMART_SELECTOR] Auto-selected: Cinematic Story, 40s for 3 videos
[VIDEOS] 🤖 Smart selection: Cinematic Story (40s) for 3 videos
```

## Future Enhancements

Possible improvements:
1. **Machine Learning** - Train on user feedback
2. **Time-based** - Morning videos → Timeline, Evening → Cinematic
3. **Location-based** - Travel videos → Highlight, Home → Timeline
4. **User Override** - Option to manually pick if desired
5. **Smart Transitions** - Match transition style to mood

## Testing

Try generating recaps with different video combinations:
- All happy emojis → Should pick Highlight
- All love emojis → Should pick Cinematic
- No emojis → Should pick Timeline
- Mixed emojis → Should pick highest score

The system will always make a choice (no null/error states)!

