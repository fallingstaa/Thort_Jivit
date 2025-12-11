# Thort-Jivit User Guidelines

## Overview
Thort-Jivit is a daily memory recording and recap creation app that helps users build their life story, one video at a time. Users record or upload daily videos to create weekly video recaps.

---

## App Flow

### 1. **Recording Videos** 📹

#### Same-Day Recording
- Users can **only record videos on the current day**
- Recording cannot happen on past or future dates
- Users can record **one video per day**
- Once recorded for a day, the "Record Now" button changes to "Already Recorded" (greyed out)

**Example:**
- Today is Monday, December 11 → User can only record for December 11
- User cannot record for December 10 (past) or December 12 (future)

---

### Recommended Video Duration 🎯

To keep your memories punchy and engaging, we recommend recording or uploading short clips — ideally between **10–15 seconds**.

- This is a suggestion, not a limit: longer videos still work.
- Shorter clips are often more **memorable** and **eye‑catching**.
- Tip: Focus on one highlight, keep framing steady, add a quick intro if helpful.

The recap creator handles mixed lengths, but shorter clips generally produce a tighter, more enjoyable weekly recap.

---

### 2. **Uploading Videos** 📤

#### Pre-recorded Video Upload (Optional)
- Users can upload **pre-recorded videos up to 2 days in advance**
- This allows users to plan ahead and build their weekly collection early

**Example:**
- If a user starts using the app on Thursday:
  - Can upload videos for Thursday (today)
  - Can upload videos for Friday (tomorrow)
  - Can upload videos for Saturday (day after tomorrow)
  - Cannot upload for Sunday or beyond

**Note:** This is optional. Users don't need to upload—they can use the daily recording feature instead.

---

### 3. **Creating a Recap** 🎬

#### Minimum Requirements
- **Minimum of 3 videos required** (mix of recorded or uploaded)
- Videos can be a combination of same-day recordings and pre-uploaded videos
- Once a recap is created, **it is final for that week** (cannot be edited or deleted)

**Example:**
- Week of Dec 8-14:
  - Record Monday (Dec 9) - 1 video
  - Record Tuesday (Dec 10) - 1 video
  - Upload Wednesday-Friday videos on Monday (Dec 9) - 3 videos
  - Total: 5 videos available for recap creation

---

### 4. **When Can Users Create a Recap?** ⏰

#### Timing Rules

**Standard Users:**
- Must wait **7 days (full week)** before creating their first recap
- Example: If they record/upload videos starting Monday Dec 9, they can create the recap on Monday Dec 16 or later

**First-Time Users:**
- Can create a recap **immediately** once they have **3+ videos**
- This allows new users to preview the app and understand the recap feature
- After the first recap, they follow standard timing rules

**Recap Window:**
- Recaps are created for a **weekly cycle** (Monday-Sunday or the defined week period)
- After creating a recap for a week, that week is locked
- Users automatically start fresh the following week

---

### 5. **What Happens After Creating a Recap?** ♻️

#### Week Lock
- Once a recap is created, **that week is permanently locked**
- Users cannot:
  - Add more videos to that week
  - Delete the recap
  - Modify the recap
  - Record additional videos for that week

#### Fresh Start
- Users **automatically start fresh the following week**
- They can begin recording/uploading videos for the new week
- The cycle repeats

**Example Timeline:**
- **Week 1 (Dec 9-15):** Record 3+ videos → Create recap on Dec 16 → Week locked
- **Week 2 (Dec 16-22):** Start fresh → Record/upload new videos → Create recap on Dec 23 or later

---

## Daily Recording Rules Summary

| Rule | Details |
|------|---------|
| **Recording** | Same day only, one per day |
| **Upload** | Up to 2 days in advance |
| **Minimum Videos** | 3 videos (mix allowed) |
| **Wait Time (Standard)** | 7 days before creating recap |
| **Wait Time (New Users)** | Immediate with 3+ videos |
| **Recap Finality** | Cannot edit or delete once created |
| **Week Lock** | Week locked after recap creation |
| **Restart** | Fresh start each new week |

---

## User Journey Example

### Week 1: First-Time User
1. **Monday, Dec 9**
   - Records 1 video (same day)
   - Records 2 more videos on Dec 9
   - Total: 3 videos on Day 1

2. **Recap Creation (Immediate)**
   - Has 3+ videos
   - Creates recap on Dec 9 (first-time user privilege)
   - Week 1 locked

### Week 2: Standard User
3. **Monday, Dec 16**
   - Records 1 video
   - Uploads 2 videos for Dec 17-18 (in advance)
   - Total: 3 videos available

4. **Recap Wait Period**
   - Cannot create recap until Monday, Dec 23 (7 days later)
   - Can record/upload more videos during this time
   - Accumulates 5-7 videos by recap time

5. **Monday, Dec 23**
   - Creates recap with 5-7 videos
   - Week 2 locked

### Week 3 Onwards
- Repeat the standard 7-day wait cycle
- Week 3: Dec 30 or later for recap creation
- Continues indefinitely

---

## Feature Highlights

### ✅ What Users Can Do
- Record one video per day on the same day
- Upload pre-recorded videos (up to 2 days in advance)
- View all their daily videos in the Videos gallery
- Share daily videos to Instagram
- Mark videos as favorites
- View their weekly progress on the home screen
- Maintain a daily streak
- Get daily inspirational prompts

### ❌ What Users Cannot Do
- Record on past or future dates
- Edit or delete recaps
- Modify locked weeks
- Record more than once per day
- Upload videos beyond 2 days in advance
- Delete daily videos after creating a recap

---

## In-App Help

Users can access these guidelines anytime by:
1. Tapping the **"Guide" button** (pulsing green button in bottom right)
2. Viewing the help modal with all rules explained
3. Referring back whenever they have questions

---

## Special Features (December Only - Holiday Season)

During December, the app includes special holiday-themed elements:
- ❄️ Falling snow animation on all screens
- 🎄 Custom Christmas tree decorations
- 🎅 Holiday-themed emojis in navigation
- Festive messaging ("Holiday spark is on", "Keep the merry streak rolling")

---

## Notes for Dev Team

1. **Validation Required:** Ensure backend enforces 7-day wait for standard users and same-day recording rules
2. **Week Definition:** Clarify if weeks are Monday-Sunday or calendar weeks
3. **Timezone Handling:** Ensure consistent timezone handling for "same day" validation
4. **First-Time Detection:** Implement logic to identify first-time users (0 recaps created)
5. **Week Locking:** Implement permanent week locks after recap creation
6. **Video Tracking:** Track recording vs. uploaded videos separately for analytics

---

**Last Updated:** December 11, 2025
**Version:** 1.0
