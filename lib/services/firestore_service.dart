import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thort_jivit/services/storage_uploader.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadVideoAndMetadata({
    String? filePath,
    Uint8List? bytes,
    String? filename,
    required int dayIndex,
    required String emoji,
    required String textNote,
    required String weekId,
    DateTime? timestamp,
  }) async {
    print('[FIRESTORE] Upload started');
    print('[FIRESTORE] weekId: $weekId, dayIndex: $dayIndex');
    print(
      '[FIRESTORE] filePath: ${filePath ?? "null"}, bytes: ${bytes?.length ?? 0}',
    );

    final user = _auth.currentUser;
    if (user == null) {
      print('[FIRESTORE] ERROR: User not signed in');
      throw Exception('User not signed in');
    }

    final uid = user.uid;
    print('[FIRESTORE] User ID: $uid');
    final safeName = filename ?? '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final storagePath =
        'users/$uid/weeks/$weekId/videos/day$dayIndex/${safeName}';
    print('[FIRESTORE] Storage path: $storagePath');

    if (bytes == null && filePath == null) {
      print('[FIRESTORE] ERROR: No file data provided');
      throw Exception('No file data provided: on web, bytes are required.');
    }

    // Use platform-aware uploader (putFile on IO, putData on web)
    String? downloadUrl;

    // Check if there's already a video for this day
    final existingDocRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks')
        .doc(weekId)
        .collection('videos')
        .doc('day$dayIndex');

    final existingDoc = await existingDocRef.get();

    // If a video already exists, use a suffixed ID to avoid overwriting
    final docRef =
        existingDoc.exists
            ? _firestore
                .collection('users')
                .doc(uid)
                .collection('weeks')
                .doc(weekId)
                .collection('videos')
                .doc(
                  'day${dayIndex}_upload_${DateTime.now().millisecondsSinceEpoch}',
                )
            : existingDocRef;

    final dataToSet = {
      'emoji': emoji,
      'textNote': textNote,
      'uploadedAt': FieldValue.serverTimestamp(),
      'dayIndex': dayIndex,
      'videoType': 'upload', // Mark as uploaded from calendar
    };
    if (timestamp != null) {
      dataToSet['timestamp'] = Timestamp.fromDate(timestamp);
    }

    try {
      print('[FIRESTORE] Calling uploadToStorage...');
      downloadUrl = await uploadToStorage(
        filePath: filePath,
        bytes: bytes,
        storagePath: storagePath,
        contentType: 'video/mp4',
        filename: safeName,
      );
      print(
        '[FIRESTORE] Upload successful. URL: ${downloadUrl.substring(0, downloadUrl.length > 50 ? 50 : downloadUrl.length)}...',
      );
      dataToSet['storageDownloadUrl'] = downloadUrl;
      dataToSet['storagePath'] = storagePath;
      dataToSet['status'] = 'uploaded';
    } catch (e) {
      print('[FIRESTORE] Upload error: $e');
      // If upload fails, still write metadata so we don't lose the user's note.
      dataToSet['storagePath'] = storagePath;
      dataToSet['status'] = 'upload_failed';
      dataToSet['uploadError'] = e.toString();
    }

    print('[FIRESTORE] Writing metadata to Firestore...');
    await docRef.set(dataToSet, SetOptions(merge: true));
    print('[FIRESTORE] Metadata saved.');

    // After successful metadata save, recalculate and update the user streak
    print('[FIRESTORE] Recalculating user streak...');
    await updateUserStreak();

    return downloadUrl ?? '';
  }

  /// Fetch recorded days for a given weekId.
  /// Returns a map from calendar day-of-month (int) to emoji (String).
  /// If `year` and `month` are provided, only returns records for that month.
  Future<Map<int, String>> getRecordedDays({
    required String weekId,
    int? year,
    int? month,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final uid = user.uid;
    final col = _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks')
        .doc(weekId)
        .collection('videos');

    final snapshot = await col.get();
    final Map<int, String> result = {};

    const mapping = {
      'happy_emoji': '😊',
      'sad_emoji': '😢',
      'angry_emoji': '😡',
      'stressed_emoji': '😰',
      'calm_emoji': '😌',
      // fallback short names
      'happy': '😊',
      'sad': '😢',
      'angry': '😡',
      'stressed': '😰',
      'calm': '😌',
    };

    for (final doc in snapshot.docs) {
      final id = doc.id; // expected format: 'day{index}'
      if (!id.startsWith('day')) continue;
      final idxStr = id.substring(3);
      final idx = int.tryParse(idxStr);
      if (idx == null) continue;

      final data = doc.data();
      var emojiVal = (data['emoji'] as String?) ?? '';
      if (mapping.containsKey(emojiVal)) emojiVal = mapping[emojiVal]!;

      // If document contains a timestamp, use it to determine calendar date
      if (data.containsKey('timestamp')) {
        final ts = data['timestamp'];
        if (ts is Timestamp) {
          final dt = ts.toDate().toLocal();
          if (year != null && month != null) {
            if (dt.year == year && dt.month == month) {
              final dayOfMonth = dt.day;
              if (emojiVal.isNotEmpty) result[dayOfMonth] = emojiVal;
            }
          } else {
            final dayOfMonth = dt.day;
            if (emojiVal.isNotEmpty) result[dayOfMonth] = emojiVal;
          }
          continue;
        }
      }

      // Fallback: if no timestamp and no year/month filter, map by day index
      if (year == null || month == null) {
        if (emojiVal.isNotEmpty) result[idx] = emojiVal;
      }
    }

    return result;
  }

  /// Query all video docs across all weeks for the current user within a month.
  Future<Map<int, String>> getRecordedDaysForMonth({
    required int year,
    required int month,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final uid = user.uid;

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final weeksCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks');
    final weeksSnapshot = await weeksCol.get();

    final Map<int, String> result = {};
    const mapping = {
      'happy_emoji': '😊',
      'sad_emoji': '😢',
      'angry_emoji': '😡',
      'stressed_emoji': '😰',
      'calm_emoji': '😌',
      'happy': '😊',
      'sad': '😢',
      'angry': '😡',
      'stressed': '😰',
      'calm': '😌',
    };

    for (final weekDoc in weeksSnapshot.docs) {
      final videosCol = weeksCol.doc(weekDoc.id).collection('videos');
      final snap =
          await videosCol
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where('timestamp', isLessThan: Timestamp.fromDate(end))
              .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        var emojiVal = (data['emoji'] as String?) ?? '';
        if (mapping.containsKey(emojiVal)) emojiVal = mapping[emojiVal]!;
        final ts = data['timestamp'];
        if (ts is Timestamp && emojiVal.isNotEmpty) {
          final dt = ts.toDate().toLocal();
          result[dt.day] = emojiVal;
        }
      }
    }

    return result;
  }

  /// Get the current active week's data including real dates and recorded status for each day.
  /// Returns a map with 'weekStart' (DateTime), 'days' (List of 7 maps with 'date', 'dayLetter', 'hasVideo').
  Future<Map<String, dynamic>?> getCurrentWeekData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final now = DateTime.now();
    final weekInfo = await _getWeekContainingDate(now);

    if (weekInfo == null) return null;

    final DateTime weekStart = weekInfo['startDate'] as DateTime;
    final String weekId = weekInfo['weekId'] as String;

    // Fetch recorded videos for this week
    final uid = user.uid;
    final videosCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks')
        .doc(weekId)
        .collection('videos');

    final videosSnapshot = await videosCol.get();
    final Set<int> recordedDays = {};

    for (final doc in videosSnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('timestamp')) {
        final ts = data['timestamp'];
        if (ts is Timestamp) {
          final dt = ts.toDate().toLocal();
          final dayIndex = dt.difference(weekStart).inDays;
          if (dayIndex >= 0 && dayIndex < 7) {
            recordedDays.add(dayIndex);
          }
        }
      }
    }

    // Build the 7 days data
    final List<Map<String, dynamic>> days = [];
    const dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      days.add({
        'date': date,
        'dayLetter': dayLetters[date.weekday % 7],
        'hasVideo': recordedDays.contains(i),
      });
    }

    return {'weekStart': weekStart, 'days': days};
  }

  /// Return the week document that contains [date], or null.
  Future<Map<String, dynamic>?> _getWeekContainingDate(DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final uid = user.uid;
    final col = _firestore.collection('users').doc(uid).collection('weeks');
    final snapshot = await col.get();
    Map<String, dynamic>? best;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('startDate')) continue;
      final ts = data['startDate'];
      if (ts is Timestamp) {
        final start = ts.toDate().toLocal();
        final end = start.add(const Duration(days: 7));
        if (!date.isBefore(start) && date.isBefore(end)) {
          best = {
            'weekId': doc.id,
            'startDate': start,
            'weekIndex': data['weekIndex'] ?? 0,
          };
          break;
        }
      }
    }
    return best;
  }

  /// Get the active week for 'now' (the week where now is within start..start+6).
  Future<Map<String, dynamic>?> getActiveWeekNow() async {
    return _getWeekContainingDate(DateTime.now());
  }

  /// Create a new week document with given startDate and return its id.
  Future<String> createWeek(DateTime startDate) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not signed in');
    final uid = user.uid;
    final col = _firestore.collection('users').doc(uid).collection('weeks');
    final snapshot = await col.get();
    int maxIndex = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final idx = (data['weekIndex'] as int?) ?? 0;
      if (idx > maxIndex) maxIndex = idx;
    }
    final newIndex = maxIndex + 1;
    final id = 'week_${newIndex}';
    await col.doc(id).set({
      'startDate': Timestamp.fromDate(startDate),
      'weekIndex': newIndex,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  /// Get or create a week that contains [date]. If none exists and [date] == today,
  /// creates a new week starting at [date]. Returns a map with 'weekId' and 'startDate'.
  Future<Map<String, dynamic>?> getOrCreateWeekForDate(DateTime date) async {
    final found = await _getWeekContainingDate(date);
    if (found != null) return found;
    final now = DateTime.now();
    final localDate = DateTime(date.year, date.month, date.day);
    final localNow = DateTime(now.year, now.month, now.day);
    if (localDate == localNow) {
      final id = await createWeek(date);
      return {'weekId': id, 'startDate': date, 'weekIndex': 0};
    }
    return null;
  }

  /// Check if user can record for today (only one recording per day allowed)
  /// IMPORTANT: Record type can ONLY be recorded on the actual calendar date (today only)
  /// Cannot record retroactively for past dates
  Future<bool> canRecordToday() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    // Admin bypass: always allow
    if (user.email == 'lyya87396@gmail.com') return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if there's already a recorded video for today
    final week = await _getWeekContainingDate(today);
    if (week == null) {
      // No week exists, can start a new week by recording
      return true;
    }

    final weekId = week['weekId'] as String;
    final DateTime start = week['startDate'] as DateTime;
    final diff = today.difference(start).inDays;

    // Cannot record if today is not in current week (past/future dates)
    if (diff < 0 || diff >= 7) return false;

    final uid = user.uid;

    // Check if a 'recorded' type video already exists for today
    // Get all videos for today's day index
    final dayIndex = diff + 1;
    final videosSnapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeks')
            .doc(weekId)
            .collection('videos')
            .where('dayIndex', isEqualTo: dayIndex)
            .get();

    // Check if any of them are 'recorded' type
    for (final doc in videosSnapshot.docs) {
      final data = doc.data();
      if (data['videoType'] == 'recorded') {
        // Already have a recorded video for today
        return false;
      }
    }

    // No recorded video exists for today, allow recording
    return true;
  }

  /// Save a recorded video with metadata (can only record once per day, for today only)
  Future<String> saveRecordedVideo({
    String? filePath,
    Uint8List? bytes,
    String? filename,
    required String emoji,
    required String textNote,
    DateTime? timestamp,
  }) async {
    print('[FIRESTORE] Recording save started');

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final uid = user.uid;

    // Check if can record today
    final canRecord = await canRecordToday();
    if (!canRecord) {
      throw Exception('Cannot record: already recorded today or invalid date');
    }

    // Get or create week for today
    var week = await _getWeekContainingDate(today);
    String weekId;
    DateTime startDate;

    if (week == null) {
      // Create new week starting today
      weekId = await createWeek(today);
      startDate = today;
    } else {
      weekId = week['weekId'] as String;
      startDate = week['startDate'] as DateTime;
    }

    final diff = today.difference(startDate).inDays;
    final dayIndex = diff + 1;

    print('[FIRESTORE] Recording for weekId: $weekId, dayIndex: $dayIndex');

    final safeName = filename ?? '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final storagePath =
        'users/$uid/weeks/$weekId/videos/day$dayIndex/$safeName';

    if (bytes == null && filePath == null) {
      throw Exception('No file data provided');
    }

    // Check if there's already a video for this day
    final existingDocRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks')
        .doc(weekId)
        .collection('videos')
        .doc('day$dayIndex');

    final existingDoc = await existingDocRef.get();

    // If a video already exists, use a suffixed ID to avoid overwriting
    final docRef =
        existingDoc.exists
            ? _firestore
                .collection('users')
                .doc(uid)
                .collection('weeks')
                .doc(weekId)
                .collection('videos')
                .doc(
                  'day${dayIndex}_recorded_${DateTime.now().millisecondsSinceEpoch}',
                )
            : existingDocRef;

    final dataToSet = {
      'emoji': emoji,
      'textNote': textNote,
      'uploadedAt': FieldValue.serverTimestamp(),
      'dayIndex': dayIndex,
      'videoType': 'recorded', // Mark as recorded (vs uploaded)
    };

    if (timestamp != null) {
      dataToSet['timestamp'] = Timestamp.fromDate(timestamp);
    }

    String? downloadUrl;
    try {
      print('[FIRESTORE] Uploading recorded video to storage...');
      downloadUrl = await uploadToStorage(
        filePath: filePath,
        bytes: bytes,
        storagePath: storagePath,
        contentType: 'video/mp4',
        filename: safeName,
      );
      print('[FIRESTORE] Recording upload successful');
      dataToSet['storageDownloadUrl'] = downloadUrl;
      dataToSet['storagePath'] = storagePath;
      dataToSet['status'] = 'uploaded';
    } catch (e) {
      print('[FIRESTORE] Recording upload error: $e');
      dataToSet['storagePath'] = storagePath;
      dataToSet['status'] = 'upload_failed';
      dataToSet['uploadError'] = e.toString();
    }

    print('[FIRESTORE] Writing recorded video metadata to Firestore...');
    await docRef.set(dataToSet, SetOptions(merge: true));
    print('[FIRESTORE] Recording metadata saved.');

    // Update user streak
    print('[FIRESTORE] Recalculating user streak...');
    await updateUserStreak();

    return downloadUrl ?? '';
  }

  /// Whether the user may upload for the given [date]. Rules:
  /// - Can upload for today + next 2 days (3 days total)
  /// - Maximum 2 uploads per calendar day
  /// - If user uploaded in advance (e.g., day 6 for days 7-8),
  ///   they can only upload again after those pre-uploaded days pass
  /// - Record type cannot be uploaded (must be recorded on actual date)
  Future<bool> canUploadForDate(DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    // Admin bypass: always allow
    if (user.email == 'lyya87396@gmail.com') return true;

    // For normal users: apply all restrictions
    final now = DateTime.now();
    final week = await _getWeekContainingDate(date);

    if (week != null) {
      final weekId = week['weekId'] as String;
      final DateTime start = week['startDate'] as DateTime;
      final DateTime weekEnd = start.add(const Duration(days: 7));

      // If the week already has a finalized recap, block all uploads for normal users
      final locked = await weekLockedForUploads(weekId);
      if (locked) {
        print('[FIRESTORE] Upload denied: week $weekId is locked by recap');
        return false;
      }

      // Must be within the active week
      if (now.isBefore(start) || !now.isBefore(weekEnd)) return false;

      final diff = date.difference(start).inDays; // 0-based
      // Date must be inside the week range
      if (diff < 0 || diff >= 7) return false;

      // Count total uploads in the week
      final totalWeekUploads = await countUploadedVideosInWeek(weekId);

      // RULE: Maximum 2 uploads per calendar day
      final uploadCount = await countUploadedVideosForDate(date);
      if (uploadCount >= 2) {
        print('[FIRESTORE] Upload denied: already have 2 uploads for $date');
        return false;
      }

      final localDate = DateTime(date.year, date.month, date.day);
      final localToday = DateTime(now.year, now.month, now.day);
      final isFutureInWeek = localDate.isAfter(localToday);
      // Determine current and requested day indices (1-based) within the active week
      final int dayIndexNow = now.difference(start).inDays + 1;
      final int dayIndexRequested = date.difference(start).inDays + 1;

      // Free quota: first 3 uploads are special ONLY on the first day of the week (dayIndexNow == 1)
      // Allow today and next 2 days (indices +0, +1, +2). Otherwise (not first day), treat as normal: no future uploads.
      if (totalWeekUploads < 3) {
        if (dayIndexNow == 1) {
          final int diffIdx = dayIndexRequested - dayIndexNow;
          if (diffIdx >= 0 && diffIdx <= 2) {
            print(
              '[FIRESTORE] Upload allowed (free quota on week start) for date: $date',
            );
            return true;
          } else {
            print(
              '[FIRESTORE] Upload denied: free quota on week start allows only today + next 2 days',
            );
            return false;
          }
        } else {
          // Not first day → free quota does not allow future dates; allow past/today only
          if (!isFutureInWeek) {
            print(
              '[FIRESTORE] Upload allowed (free quota, not first day) for past/today: $date',
            );
            return true;
          }
          print(
            '[FIRESTORE] Upload denied: future upload not allowed (not first day of week)',
          );
          return false;
        }
      }

      // For 4th+ upload, only allow for missed past days within the same week (no future dates)
      if (isFutureInWeek) {
        print(
          '[FIRESTORE] Upload denied: beyond free quota, future day upload not allowed for $date',
        );
        return false;
      }

      print(
        '[FIRESTORE] Upload allowed (beyond free quota) for past/today date: $date',
      );
      return true;
    } else {
      // No week exists, allow starting a new week only if date is today
      final localDate = DateTime(date.year, date.month, date.day);
      final localNow = DateTime(now.year, now.month, now.day);
      return localDate == localNow;
    }
  }

  /// Detailed upload permission with human-readable reason.
  /// Returns: { 'allowed': bool, 'reason': String }
  Future<Map<String, dynamic>> getUploadPermission(DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'allowed': false, 'reason': 'Please sign in to upload a video.'};
    }
    // Admin bypass
    if (user.email == 'lyya87396@gmail.com') {
      return {'allowed': true, 'reason': 'Admin: uploads are allowed.'};
    }

    final now = DateTime.now();
    final week = await _getWeekContainingDate(date);
    if (week != null) {
      final weekId = week['weekId'] as String;
      final DateTime start = week['startDate'] as DateTime;
      final DateTime weekEnd = start.add(const Duration(days: 7));
      if (await weekLockedForUploads(weekId)) {
        return {
          'allowed': false,
          'reason': 'Week locked after recap — uploads resume next week.',
        };
      }
      if (now.isBefore(start) || !now.isBefore(weekEnd)) {
        return {
          'allowed': false,
          'reason': 'Selected date is not within your current active week.',
        };
      }
      final diff = date.difference(start).inDays;
      if (diff < 0 || diff >= 7) {
        return {
          'allowed': false,
          'reason': 'Selected date is outside the current week.',
        };
      }
      final totalWeekUploads = await countUploadedVideosInWeek(weekId);
      final perDayCount = await countUploadedVideosForDate(date);
      if (perDayCount >= 2) {
        return {
          'allowed': false,
          'reason': 'You already have 2 uploads for this day.',
        };
      }
      final localDate = DateTime(date.year, date.month, date.day);
      final localToday = DateTime(now.year, now.month, now.day);
      final isFutureInWeek = localDate.isAfter(localToday);
      final int dayIndexNow = now.difference(start).inDays + 1;
      final int dayIndexRequested = date.difference(start).inDays + 1;
      if (totalWeekUploads < 3) {
        if (dayIndexNow == 1) {
          final diffIdx = dayIndexRequested - dayIndexNow;
          if (diffIdx >= 0 && diffIdx <= 2) {
            return {
              'allowed': true,
              'reason':
                  'Allowed: Free future uploads on week start (today + next 2 days).',
            };
          } else {
            return {
              'allowed': false,
              'reason':
                  'Free future uploads on week start allow only today + next 2 days.',
            };
          }
        } else {
          if (isFutureInWeek) {
            return {
              'allowed': false,
              'reason':
                  'Future uploads are only allowed on your first day (today + next 2).',
            };
          } else {
            return {
              'allowed': true,
              'reason': 'Allowed: Past/today uploads are permitted.',
            };
          }
        }
      } else {
        if (isFutureInWeek) {
          return {
            'allowed': false,
            'reason':
                'Future uploads not allowed after free quota. Upload for past or today only.',
          };
        } else {
          return {
            'allowed': true,
            'reason': 'Allowed: Past/today uploads are permitted.',
          };
        }
      }
    } else {
      final localDate = DateTime(date.year, date.month, date.day);
      final localNow = DateTime(now.year, now.month, now.day);
      final allowedNew = localDate == localNow;
      return {
        'allowed': allowedNew,
        'reason':
            allowedNew
                ? 'Allowed: Starting a new week today.'
                : 'You can only start a new week on today.',
      };
    }
  }

  /// Count total uploaded videos (type='upload') for the active week by [weekId]
  Future<int> countUploadedVideosInWeek(String weekId) async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final uid = user.uid;
    final videosSnapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeks')
            .doc(weekId)
            .collection('videos')
            .where('videoType', isEqualTo: 'upload')
            .get();

    return videosSnapshot.size;
  }

  /// Whether uploads are locked for the week (i.e., recap has been created with a valid URL)
  Future<bool> weekLockedForUploads(String weekId) async {
    final user = _auth.currentUser;
    if (user == null) return true; // if not signed in, treat as locked
    // Admin bypass: admin may still upload
    if (user.email == 'lyya87396@gmail.com') return false;

    final uid = user.uid;
    final weekDoc =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeks')
            .doc(weekId)
            .get();

    if (!weekDoc.exists) return false;
    final data = weekDoc.data();
    final hasRecap = data?['hasRecap'] == true;
    final recapUrl = (data?['recapUrl'] as String?) ?? '';
    // Lock only when recap exists and has a valid URL
    return hasRecap && recapUrl.isNotEmpty;
  }

  /// Count total uploaded videos (type='upload') for a specific date in the active week
  Future<int> countUploadedVideosForDate(DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final week = await _getWeekContainingDate(date);
    if (week == null) return 0;

    final weekId = week['weekId'] as String;
    final DateTime start = week['startDate'] as DateTime;
    final diff = date.difference(start).inDays;
    final dayIndex = diff + 1;

    final uid = user.uid;
    final videosSnapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeks')
            .doc(weekId)
            .collection('videos')
            .where('dayIndex', isEqualTo: dayIndex)
            .where('videoType', isEqualTo: 'upload')
            .get();

    return videosSnapshot.size;
  }

  /// Get the latest uploaded date in the week (furthest date with uploads)
  /// Used to handle 'missing days' recovery logic:
  /// - If user uploads on day 6 for days 7-8, they can only upload/record again on day 9+
  Future<DateTime?> getLatestUploadedDateInWeek(String weekId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final week = await _getWeekContainingDate(DateTime.now());
    if (week == null) return null;

    final uid = user.uid;
    final videosSnapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeks')
            .doc(weekId)
            .collection('videos')
            .where('videoType', isEqualTo: 'upload')
            .get();

    if (videosSnapshot.docs.isEmpty) return null;

    DateTime latestDate = DateTime(1970);
    final DateTime start = week['startDate'] as DateTime;

    for (final doc in videosSnapshot.docs) {
      final data = doc.data();
      final dayIndex = data['dayIndex'] as int? ?? 0;
      // dayIndex is 1-based, convert to date
      final videoDate = start.add(Duration(days: dayIndex - 1));
      if (videoDate.isAfter(latestDate)) {
        latestDate = videoDate;
      }
    }

    return latestDate == DateTime(1970) ? null : latestDate;
  }

  /// Compute day index (1-based) for a selected date relative to the week's startDate.
  Future<int?> computeDayIndexForDate(DateTime date) async {
    final week = await _getWeekContainingDate(date);
    if (week == null) return null;
    final DateTime start = week['startDate'] as DateTime;
    final diff = date.difference(start).inDays;
    if (diff < 0 || diff >= 7) return null;
    return diff + 1;
  }

  /// Calculate the current streak for the active week.
  /// Streak = total count of days that have at least one uploaded video.
  Future<int> calculateCurrentStreak() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[STREAK] No user logged in');
      return 0;
    }

    final week = await getActiveWeekNow();
    if (week == null) {
      print('[STREAK] No active week found');
      return 0;
    }

    final weekId = week['weekId'] as String;
    final uid = user.uid;
    print('[STREAK] Calculating for weekId: $weekId, uid: $uid');

    final videosCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks')
        .doc(weekId)
        .collection('videos');

    int streak = 0;
    // Count all days that have valid uploaded videos
    for (int dayIdx = 1; dayIdx <= 7; dayIdx++) {
      final doc = await videosCol.doc('day$dayIdx').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final status = data['status'];
        final storageUrl = data['storageDownloadUrl'];

        print('[STREAK] Day $dayIdx - exists: true');
        print('[STREAK]   status: $status');
        print(
          '[STREAK]   storageUrl: ${storageUrl != null ? "present (${(storageUrl as String).length} chars)" : "null"}',
        );

        // Only count as a valid video if it has uploaded status or storage download URL
        final hasUploadedVideo =
            status == 'uploaded' ||
            (storageUrl != null && (storageUrl as String).isNotEmpty);

        if (hasUploadedVideo) {
          streak++;
          print('[STREAK]   ✓ Valid video - streak now: $streak');
        } else {
          print('[STREAK]   ✗ No valid uploaded video - skipping');
        }
      } else {
        print('[STREAK] Day $dayIdx - no document - skipping');
      }
    }

    print('[STREAK] Final streak: $streak');
    return streak;
  }

  /// Update the user's streak in the user document.
  Future<void> updateUserStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final streak = await calculateCurrentStreak();

    print('[FIRESTORE] Updating user streak to: $streak');
    print('[FIRESTORE] Saving to users/$uid with streak=$streak');

    await _firestore.collection('users').doc(uid).set({
      'streak': streak,
      'lastUploadDate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    print('[FIRESTORE] Streak updated successfully');
  }

  /// Get the current streak from user document.
  Future<int> getUserStreak() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[FIRESTORE] No user, returning streak 0');
      return 0;
    }

    final uid = user.uid;
    print('[FIRESTORE] Getting streak for uid: $uid');

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data();
      print('[FIRESTORE] User document data: $data');
      final streak = (data?['streak'] as int?) ?? 0;
      print('[FIRESTORE] Retrieved streak: $streak');
      return streak;
    }

    print('[FIRESTORE] User document does not exist');
    return 0;
  }

  /// Get all uploaded videos across all weeks for the current user.
  /// Returns a list of video data with emoji, textNote, date, thumbnail, etc.
  Future<List<Map<String, dynamic>>> getAllUploadedVideos() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[FIRESTORE] No user logged in');
      return [];
    }

    final uid = user.uid;
    print('[FIRESTORE] Fetching all videos for uid: $uid');

    final weeksCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks');
    final weeksSnapshot = await weeksCol.get();

    List<Map<String, dynamic>> allVideos = [];

    for (final weekDoc in weeksSnapshot.docs) {
      final weekData = weekDoc.data();
      final weekId = weekDoc.id;
      final startDate = (weekData['startDate'] as Timestamp?)?.toDate();

      final videosCol = weeksCol.doc(weekId).collection('videos');
      final videosSnapshot = await videosCol.get();
      print(
        '[FIRESTORE] Week $weekId has ${videosSnapshot.docs.length} video docs',
      );

      for (final videoDoc in videosSnapshot.docs) {
        final data = videoDoc.data();
        final status = data['status'];
        final videoType =
            data['videoType'] ??
            'unknown'; // Handle old videos without videoType
        final hasUrl = data['storageDownloadUrl'] != null;
        final dayIndex = data['dayIndex'];
        print(
          '[FIRESTORE] Video ${videoDoc.id}: dayIndex=$dayIndex, type="$videoType", status="$status", hasUrl=$hasUrl',
        );

        // Include both uploaded AND recorded videos that have been successfully saved
        if ((data['status'] == 'uploaded' || data['status'] == 'recorded') &&
            data['storageDownloadUrl'] != null &&
            (data['storageDownloadUrl'] as String).isNotEmpty) {
          final dayIndex = data['dayIndex'] as int?;
          DateTime? videoDate;
          if (startDate != null && dayIndex != null) {
            videoDate = startDate.add(Duration(days: dayIndex - 1));
          }

          final durationText = data['duration'] as String? ?? '';
          final durationSeconds = _parseDurationSeconds(
            data['durationSeconds'] ?? durationText,
          );

          allVideos.add({
            'id': '${weekId}_${videoDoc.id}',
            'weekId': weekId,
            'dayId': videoDoc.id,
            'dayIndex': dayIndex,
            'videoType': videoType,
            'emoji': data['emoji'] ?? '',
            'textNote': data['textNote'] ?? '',
            'storageDownloadUrl': data['storageDownloadUrl'],
            'uploadedAt': data['uploadedAt'],
            'timestamp': data['timestamp'],
            'uploadedDate': (data['uploadedAt'] as Timestamp?)?.toDate(),
            'date':
                videoDate != null
                    ? '${_getMonthName(videoDate.month)} ${videoDate.day}, ${videoDate.year}'
                    : '',
            'durationSeconds': durationSeconds,
            'durationText': durationText,
            'isFavorite': false, // Can be extended later with favorites feature
          });
          print(
            '[FIRESTORE] ✓ Added ${videoDoc.id} (type=$videoType, day=$dayIndex) to allVideos list',
          );
        }
      }
    }

    print(
      '[FIRESTORE] Total videos collected before sort: ${allVideos.length}',
    );
    allVideos.sort((a, b) {
      final aTime = a['uploadedAt'] as Timestamp?;
      final bTime = b['uploadedAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    print('[FIRESTORE] Found ${allVideos.length} uploaded videos');
    return allVideos;
  }

  int _parseDurationSeconds(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    final text = value.toString();
    if (text.isEmpty) return 0;

    // Try parsing HH:MM:SS or MM:SS
    try {
      final parts = text.split(':');
      if (parts.length == 3) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = double.tryParse(parts[2]) ?? 0;
        return (h * 3600 + m * 60 + s).round();
      }
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = double.tryParse(parts[1]) ?? 0;
        return (m * 60 + s).round();
      }
      final maybeNumber = double.tryParse(text);
      if (maybeNumber != null) return maybeNumber.round();
    } catch (_) {
      return 0;
    }
    return 0;
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  /// Delete a video for a specific day and recalculate the streak.
  Future<void> deleteVideoForDay({
    required String weekId,
    required int dayIndex,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[FIRESTORE] No user to delete video for');
      return;
    }

    final uid = user.uid;
    print(
      '[FIRESTORE] Deleting video for weekId: $weekId, dayIndex: $dayIndex',
    );

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks')
        .doc(weekId)
        .collection('videos')
        .doc('day$dayIndex');

    // Delete the video document
    await docRef.delete();
    print('[FIRESTORE] Video deleted for day$dayIndex');

    // Also delete from Firebase Storage if there's a storagePath
    // (You may want to add storage deletion logic here if needed)

    // Check if this week already has a recap (hasRecap=true)
    // If yes, mark the week as deleted=true to track that videos were deleted after merge
    final weekDoc =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeks')
            .doc(weekId)
            .get();

    if (weekDoc.exists) {
      final data = weekDoc.data();
      final hasRecap = data?['hasRecap'] == true;

      if (hasRecap) {
        // User deleted videos AFTER merging - mark as deleted
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeks')
            .doc(weekId)
            .set({
              'deleted': true, // Videos were deleted after recap was created
            }, SetOptions(merge: true));
        print(
          '[FIRESTORE] Week marked as deleted=true (videos deleted after recap was created)',
        );
      }
    }

    // Recalculate and update the streak
    print('[FIRESTORE] Recalculating streak after deletion...');
    await updateUserStreak();
    print('[FIRESTORE] Streak recalculated after deletion');
  }

  /// Check if current week already has a SUCCESSFUL recap
  /// Database fields used:
  /// - hasRecap: true/false → User did a merge or not
  /// - deleted: true/false → Videos were deleted after merge (but recap data stays)
  /// - recapUrl: string → URL of merged video (empty if merge failed)
  /// - canRetryRecap: true/false → Admin permission to retry
  ///
  /// Returns true = BLOCK user from creating new recap (already merged)
  /// Returns false = ALLOW user to create recap (can merge now)
  ///
  /// Logic:
  /// 1. No recap document → Allow merge (return false)
  /// 2. hasRecap=true + recapUrl valid → Block merge (return true) - already merged
  /// 3. hasRecap=true + recapUrl empty → Allow merge (return false) - merge failed, retry allowed
  /// 4. hasRecap=true + deleted=true + recapUrl valid → Block merge (return true) - already merged, even if videos deleted
  /// 5. canRetryRecap=true → Allow merge (return false) - admin override
  Future<bool> weekHasRecap(String weekId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    // Admin bypass: always allow merge
    if (user.email == 'lyya87396@gmail.com') return false;

    final uid = user.uid;

    // Get the week document
    final weekDoc =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeks')
            .doc(weekId)
            .get();

    if (!weekDoc.exists) {
      print('[FIRESTORE] weekHasRecap: false (no week document found)');
      return false;
    }

    final data = weekDoc.data();
    final hasRecap = data?['hasRecap'] == true;
    final deleted = data?['deleted'] == true;
    final recapUrl = data?['recapUrl'] as String? ?? '';
    final canRetry = data?['canRetryRecap'] == true;

    // If no recap, allow user to create one
    if (!hasRecap) {
      print('[FIRESTORE] weekHasRecap: false (no recap)');
      return false;
    }

    // If recap exists but has no URL (failed), allow retry
    if (hasRecap && recapUrl.isEmpty) {
      print(
        '[FIRESTORE] weekHasRecap: false (recap exists but no URL - allow retry)',
      );
      return false;
    }

    // If hasRecap is true and canRetry IS true, allow (admin gave permission to retry)
    if (hasRecap && canRetry) {
      print(
        '[FIRESTORE] weekHasRecap: false (canRetryRecap is true - allow retry)',
      );
      return false;
    }

    // If hasRecap is true, has valid URL, block user (even if deleted=true)
    // This means: User already merged, can't merge again (must wait for next week)
    // Even if they deleted videos, we still have the recap record as proof
    print(
      '[FIRESTORE] weekHasRecap: true (user already has valid recap, cannot retry). deleted=$deleted',
    );
    return true; // Block user from merging again
  }

  /// Save weekly recap to Firestore
  Future<void> saveWeeklyRecap({
    required String weekId,
    required String recapUrl,
    required int clipsCount,
    required String duration,
    bool isAdmin = false,
    String firstVideoDate = '',
    String lastVideoDate = '',
    List<Map<String, dynamic>> mergeOrder = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not signed in');

    final uid = user.uid;
    print('[FIRESTORE] Saving weekly recap for weekId: $weekId');

    // Determine version label (v1, v2, ...) by counting existing recaps
    final existing =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeks')
            .doc(weekId)
            .collection('recaps')
            .get();
    final version = existing.size + 1;

    final recapData = {
      'recapUrl': recapUrl,
      'recapClipsCount': clipsCount,
      'recapDuration': duration,
      'recapCreatedAt': FieldValue.serverTimestamp(),
      'recapVersion': version,
      'recapVersionLabel': 'v$version',
      'firstVideoDate': firstVideoDate,
      'lastVideoDate': lastVideoDate,
      'mergeOrder': mergeOrder,
    };

    // Store all recaps in subcollection (both admin and normal users for testing)
    final recapsCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks')
        .doc(weekId)
        .collection('recaps');
    await recapsCol.add(recapData);

    // Update hasRecap flag on week document with the recap URL and clear canRetryRecap
    // Database structure:
    // hasRecap: true           → User did the merge (merge was successful)
    // deleted: false           → Videos still exist in database (default)
    // recapUrl: string         → URL to the merged video
    // recapCreatedAt: timestamp → When the merge happened
    //
    // When user deletes videos:
    // hasRecap: true           → STAYS TRUE (user already merged, can't merge again)
    // deleted: true            → Marks that videos were deleted after merge
    // recapUrl: string         → STAYS (proof that user did merge)
    // recapCreatedAt: timestamp → STAYS (history record)
    //
    // This way we track:
    // - User did a merge (hasRecap=true)
    // - Videos were deleted (deleted=true)
    // - But recap data remains (audit trail)
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks')
        .doc(weekId)
        .set({
          'hasRecap': true, // Mark that user successfully merged
          'deleted':
              false, // Videos not deleted (will be set to true if user deletes them)
          'recapUrl': recapUrl, // Store the URL to track successful merges
          'recapCreatedAt': FieldValue.serverTimestamp(),
          'canRetryRecap':
              FieldValue.delete(), // Clear retry permission after using it
        }, SetOptions(merge: true));

    print(
      '[FIRESTORE] Recap v$version saved. Database state: hasRecap=true, deleted=false, recapUrl stored.',
    );
  }

  /// Get all weekly recaps for the user
  Future<List<Map<String, dynamic>>> getWeeklyRecaps({
    bool isAdmin = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[FIRESTORE] No user logged in');
      return [];
    }

    final uid = user.uid;
    print('[FIRESTORE] Fetching weekly recaps for uid: $uid');

    final weeksCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks');

    List<Map<String, dynamic>> recaps = [];

    final weeksSnapshot = await weeksCol.get();
    for (final weekDoc in weeksSnapshot.docs) {
      final weekId = weekDoc.id;
      final weekData = weekDoc.data();
      final startDate = (weekData['startDate'] as Timestamp?)?.toDate();

      if (isAdmin) {
        // For admin, fetch all recaps in the recaps subcollection
        final recapsCol = weeksCol.doc(weekId).collection('recaps');
        final recapsSnapshot = await recapsCol.get();
        for (final recapDoc in recapsSnapshot.docs) {
          final data = recapDoc.data();
          // Only include recaps that have a valid recapUrl
          if (data['recapUrl'] != null &&
              data['recapUrl'].toString().isNotEmpty) {
            recaps.add({
              'id': recapDoc.id,
              'weekId': weekId,
              'title':
                  startDate != null
                      ? 'Week of ${_formatDate(startDate)}'
                      : 'Weekly Recap',
              'recapUrl': data['recapUrl'],
              'clipsCount': data['recapClipsCount'] ?? 0,
              'duration': data['recapDuration'] ?? '0:00',
              'createdAt': data['recapCreatedAt'],
              'timestamp': _formatTimestamp(data['recapCreatedAt']),
              'versionLabel': data['recapVersionLabel'] ?? 'v?',
              'firstVideoDate': data['firstVideoDate'] ?? '',
              'lastVideoDate': data['lastVideoDate'] ?? '',
              'mergeOrder': data['mergeOrder'] ?? [],
              'selectedMusicTrack': data['selectedMusicTrack'] ?? '',
            });
          }
        }
      } else {
        // Normal users: also fetch from recaps subcollection (same as admin for testing)
        final recapsCol = weeksCol.doc(weekId).collection('recaps');
        final recapsSnapshot = await recapsCol.get();
        for (final recapDoc in recapsSnapshot.docs) {
          final data = recapDoc.data();
          // Only include recaps that have a valid recapUrl
          if (data['recapUrl'] != null &&
              data['recapUrl'].toString().isNotEmpty) {
            recaps.add({
              'id': recapDoc.id,
              'weekId': weekId,
              'title':
                  startDate != null
                      ? 'Week of ${_formatDate(startDate)}'
                      : 'Weekly Recap',
              'recapUrl': data['recapUrl'],
              'clipsCount': data['recapClipsCount'] ?? 0,
              'duration': data['recapDuration'] ?? '0:00',
              'createdAt': data['recapCreatedAt'],
              'timestamp': _formatTimestamp(data['recapCreatedAt']),
              'versionLabel': data['recapVersionLabel'] ?? 'v?',
              'firstVideoDate': data['firstVideoDate'] ?? '',
              'lastVideoDate': data['lastVideoDate'] ?? '',
              'mergeOrder': data['mergeOrder'] ?? [],
              'selectedMusicTrack': data['selectedMusicTrack'] ?? '',
            });
          }
        }
      }
    }

    // Sort by creation date (newest first)
    recaps.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    print('[FIRESTORE] Found ${recaps.length} weekly recaps');
    for (int i = 0; i < recaps.length; i++) {
      print(
        '[FIRESTORE] Recap $i: versionLabel=${recaps[i]['versionLabel']}, clipsCount=${recaps[i]['clipsCount']}, url=${recaps[i]['recapUrl'].toString().substring(0, 80)}...',
      );
    }
    return recaps;
  }

  /// Delete a weekly recap
  Future<void> deleteWeeklyRecap({
    required String weekId,
    required String recapId,
    bool isAdmin = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not signed in');

    final uid = user.uid;
    final userEmail = user.email ?? '';
    final isActualAdmin = userEmail == 'lyya87396@gmail.com';

    print('[FIRESTORE] Deleting recap: $recapId from week: $weekId');

    // Delete from recaps subcollection
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks')
        .doc(weekId)
        .collection('recaps')
        .doc(recapId)
        .delete();

    // If admin deletes all recaps, also clear the hasRecap flag so they can start fresh
    if (isActualAdmin) {
      final remaining =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('weeks')
              .doc(weekId)
              .collection('recaps')
              .get();

      if (remaining.docs.isEmpty) {
        // No recaps left, clear hasRecap flag
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeks')
            .doc(weekId)
            .set({'hasRecap': false}, SetOptions(merge: true));
      }
    }
    // For normal users: keep hasRecap flag even after deletion
    // They can only merge again if admin sets canRetryRecap to true

    print('[FIRESTORE] Recap deleted from subcollection');
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"} ago';
    }
  }

  /// [ADMIN ONLY] Reset recap status for a user's week
  /// Allows admin to reset hasRecap to false so user can merge again
  /// Use case: Special situations where user needs to redo their weekly recap
  Future<void> adminResetWeekRecapStatus({
    required String userId,
    required String weekId,
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) throw Exception('Not signed in');

    print(
      '[FIRESTORE] [ADMIN] Resetting recap for userId: $userId, weekId: $weekId',
    );

    // Reset hasRecap to false so user can merge again
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('weeks')
        .doc(weekId)
        .set({
          'hasRecap': false, // Reset to allow user to merge again
          'canRetryRecap': FieldValue.delete(), // Clear any retry flag
          'adminResetBy': admin.uid, // Log which admin reset it
          'adminResetAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    print('[FIRESTORE] [ADMIN] Recap status reset for userId: $userId');
  }

  /// [ADMIN ONLY] Completely clear all recap data for a week (for special cases)
  /// This removes hasRecap, deleted, recapUrl - essentially clearing the recap record
  Future<void> adminClearWeekRecapData({
    required String userId,
    required String weekId,
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) throw Exception('Not signed in');

    print(
      '[FIRESTORE] [ADMIN] Clearing all recap data for userId: $userId, weekId: $weekId',
    );

    // Remove all recap-related fields
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('weeks')
        .doc(weekId)
        .update({
          'hasRecap': FieldValue.delete(),
          'deleted': FieldValue.delete(),
          'recapUrl': FieldValue.delete(),
          'recapCreatedAt': FieldValue.delete(),
          'canRetryRecap': FieldValue.delete(),
          'adminClearedBy': admin.uid,
          'adminClearedAt': FieldValue.serverTimestamp(),
        });

    print('[FIRESTORE] [ADMIN] All recap data cleared for userId: $userId');
  }

  /// Update the selected music track and recap URL for a recap
  Future<void> updateRecapMusicTrack({
    required String weekId,
    required String recapId,
    required String musicFileName,
    required String recapUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not signed in');

    final uid = user.uid;
    print(
      '[FIRESTORE] Updating recap music track for weekId: $weekId, recapId: $recapId, music: $musicFileName',
    );

    try {
      final recapDoc = _firestore
          .collection('users')
          .doc(uid)
          .collection('weeks')
          .doc(weekId)
          .collection('recaps')
          .doc(recapId);

      await recapDoc.set({
        'recapUrl': recapUrl,
        'selectedMusicTrack': musicFileName,
        'musicUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Keep the latest recap URL and selected track at the week level too
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('weeks')
          .doc(weekId)
          .set({
            'recapUrl': recapUrl,
            'selectedMusicTrack': musicFileName,
            'musicUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      print('[FIRESTORE] Music track updated successfully');
    } catch (e) {
      print('[FIRESTORE] Error updating music track: $e');
      rethrow;
    }
  }
}
