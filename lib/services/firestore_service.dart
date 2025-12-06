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
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('weeks')
        .doc(weekId)
        .collection('videos')
        .doc('day$dayIndex');

    final dataToSet = {
      'emoji': emoji,
      'textNote': textNote,
      'uploadedAt': FieldValue.serverTimestamp(),
      'dayIndex': dayIndex,
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

  /// Whether the user may upload for the given [date]. Rules:
  /// - If a week exists that contains [date], uploads allowed only if date in [start, start+2]
  ///   AND current time is within the active week (start..start+6).
  /// - If no week exists for date, allow only if date == today (starting a new week).
  Future<bool> canUploadForDate(DateTime date) async {
    final now = DateTime.now();
    final week = await _getWeekContainingDate(date);
    if (week != null) {
      final DateTime start = week['startDate'] as DateTime;
      final DateTime weekEnd = start.add(const Duration(days: 7));
      // Now must be within the active week (start .. start+6)
      if (now.isBefore(start) || !now.isBefore(weekEnd)) return false;

      final diff = date.difference(start).inDays; // 0-based
      // Date must be inside the week range
      if (diff < 0 || diff >= 7) return false;

      // Only allow upload for today + next 2 days (3 days total)
      final localDate = DateTime(date.year, date.month, date.day);
      final localNow = DateTime(now.year, now.month, now.day);
      final daysDifference = localDate.difference(localNow).inDays;

      // Can only upload for today (0) and next 2 days (1, 2)
      return daysDifference >= 0 && daysDifference <= 2;
    } else {
      // allow starting a new week only if date is today
      final localDate = DateTime(date.year, date.month, date.day);
      final localNow = DateTime(now.year, now.month, now.day);
      return localDate == localNow;
    }
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

      for (final videoDoc in videosSnapshot.docs) {
        final data = videoDoc.data();

        // Only include videos that have been successfully uploaded
        if (data['status'] == 'uploaded' &&
            data['storageDownloadUrl'] != null &&
            (data['storageDownloadUrl'] as String).isNotEmpty) {
          final dayIndex = data['dayIndex'] as int?;
          DateTime? videoDate;
          if (startDate != null && dayIndex != null) {
            videoDate = startDate.add(Duration(days: dayIndex - 1));
          }

          allVideos.add({
            'id': '${weekId}_${videoDoc.id}',
            'weekId': weekId,
            'dayId': videoDoc.id,
            'emoji': data['emoji'] ?? '',
            'textNote': data['textNote'] ?? '',
            'storageDownloadUrl': data['storageDownloadUrl'],
            'uploadedAt': data['uploadedAt'],
            'timestamp': data['timestamp'],
            'date':
                videoDate != null
                    ? '${_getMonthName(videoDate.month)} ${videoDate.day}, ${videoDate.year}'
                    : '',
            'isFavorite': false, // Can be extended later with favorites feature
          });
        }
      }
    }

    // Sort by date (newest first)
    allVideos.sort((a, b) {
      final aTime = a['uploadedAt'] as Timestamp?;
      final bTime = b['uploadedAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    print('[FIRESTORE] Found ${allVideos.length} uploaded videos');
    return allVideos;
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

    // Recalculate and update the streak
    print('[FIRESTORE] Recalculating streak after deletion...');
    await updateUserStreak();
    print('[FIRESTORE] Streak recalculated after deletion');
  }
}
