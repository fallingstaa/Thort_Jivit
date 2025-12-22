# Final Fix - Enable Parameter Syntax Error

## Issue Found
The `enable` parameter in drawtext was using commas without proper escaping:
```
enable='between(t,0,10)'  ❌ WRONG - commas break filter chain
```

## Solution Applied
Escaped commas in enable parameter:
```
enable='between(t\,0.00\,10.52)'  ✅ CORRECT
```

## Additional Fixes
1. **Underscore Handling**: `day6_recorded_1766268639858` → `day6 recorded 1766268639858`
   - Underscores can cause parsing issues
   - Replaced with spaces for safety

2. **Timing Precision**: Using `.toFixed(2)` for exact timing
   - `0` → `0.00`
   - `10.523` → `10.52`

3. **Proper Escaping**: Commas in enable expressions must be escaped
   - `between(t,X,Y)` → `between(t\,X\,Y)`

## Changes Made

### File: functions/lib/index.js

**Line 518**: Added underscore replacement
```javascript
// Replace underscores with spaces (they can cause issues)
cleaned = cleaned.replace(/_/g, ' ');
```

**Lines 577-602**: Fixed enable parameter syntax
```javascript
const tStart = timing.startTime.toFixed(2);
const tEnd = timing.endTime.toFixed(2);

// Changed from:
enable='between(t,${timing.startTime},${timing.endTime})'

// To:
enable='between(t\\,${tStart}\\,${tEnd})'
```

## Why This Matters

FFmpeg's filter parser treats commas as special characters:
- In filter chains, `,` separates filter parameters
- In expressions within quotes, commas must be escaped with `\,`
- Without escaping, FFmpeg thinks the enable parameter ends early

## Expected Result

Now the filter should be:
```bash
[vbase]drawtext=text='No description':fontsize=40:x=(w-tw)/2:y=140:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=8:enable='between(t\,0.00\,2.57)',drawtext=text='day6 recorded 1766268639858':fontsize=26:x=(w-tw)/2:y=200:fontcolor=white@0.8:enable='between(t\,0.00\,2.57)'[vfinal]
```

Notice:
- ✅ Commas escaped: `t\,0.00\,2.57`
- ✅ Underscores removed: `day6 recorded...`
- ✅ Precision formatting: `.00` instead of just `0`

## Test Now

Generate a recap and check logs for:
```
[ENHANCED_RECAP] Template applied successfully  ✅
```

Should NO LONGER see:
```
Template processing failed: Command failed  ❌
```

This should be the FINAL fix! 🎯

