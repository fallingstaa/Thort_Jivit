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
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check if user is admin - admins can upload any day (1-7) without restrictions
    final isAdmin = user.email == 'lyya87396@gmail.com';
    if (isAdmin) {
      print('[FIRESTORE] Admin upload allowed - no day restrictions');
      // For admins, just check if we're in the active week
      final week = await _getWeekContainingDate(date);
      if (week != null) {
        final DateTime start = week['startDate'] as DateTime;
        final DateTime weekEnd = start.add(const Duration(days: 7));
        final now = DateTime.now();
        // Must be within the active week
        if (now.isBefore(start) || !now.isBefore(weekEnd)) return false;

        final diff = date.difference(start).inDays;
        // Date must be inside the week range (any day 1-7)
        return diff >= 0 && diff < 7;
      }
      return false;
    }

    // For normal users: keep original restrictions (today + 2 days = 3 days total)
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

          final durationText = data['duration'] as String? ?? '';
          final durationSeconds = _parseDurationSeconds(
            data['durationSeconds'] ?? durationText,
          );

          allVideos.add({
            'id': '${weekId}_${videoDoc.id}',
            'weekId': weekId,
            'dayId': videoDoc.id,
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
}
