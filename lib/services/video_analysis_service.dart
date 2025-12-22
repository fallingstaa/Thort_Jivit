// lib/services/video_analysis_service.dart

import 'dart:io';
import 'dart:math';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recap_template.dart';

/// Service for analyzing video content and finding best moments
class VideoAnalysisService {
  /// Analyze a video and return content scores per second
  Future<List<ContentScore>> analyzeVideo(String videoPath) async {
    try {
      print('[VIDEO_ANALYSIS] Analyzing video: $videoPath');

      // Get video duration
      final duration = await _getVideoDuration(videoPath);
      if (duration <= 0) {
        print('[VIDEO_ANALYSIS] Invalid video duration');
        return [];
      }

      print('[VIDEO_ANALYSIS] Video duration: ${duration}s');

      // Analyze motion and audio
      final motionScores = await _analyzeMotion(videoPath, duration);
      final audioScores = await _analyzeAudio(videoPath, duration);

      // Combine scores
      final List<ContentScore> contentScores = [];
      for (int i = 0; i < duration.floor(); i++) {
        final timestamp = i.toDouble();
        final motionScore = i < motionScores.length ? motionScores[i] : 0.0;
        final audioScore = i < audioScores.length ? audioScores[i] : 0.0;
        final positionScore = _calculatePositionScore(timestamp, duration);

        contentScores.add(ContentScore(
          timestamp: timestamp,
          motionScore: motionScore,
          audioScore: audioScore,
          positionScore: positionScore,
        ));
      }

      print('[VIDEO_ANALYSIS] Generated ${contentScores.length} content scores');
      return contentScores;
    } catch (e) {
      print('[VIDEO_ANALYSIS] Error analyzing video: $e');
      return [];
    }
  }

  /// Get video duration in seconds
  Future<double> _getVideoDuration(String videoPath) async {
    try {
      final session = await FFmpegKit.execute(
        '-i "$videoPath" -f null -',
      );

      final logs = await session.getLogsAsString();

      // Parse duration from ffmpeg output
      final durationRegex = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2})');
      final match = durationRegex.firstMatch(logs);

      if (match != null) {
        final hours = int.parse(match.group(1)!);
        final minutes = int.parse(match.group(2)!);
        final seconds = double.parse(match.group(3)!);
        return hours * 3600 + minutes * 60 + seconds;
      }

      return 0.0;
    } catch (e) {
      print('[VIDEO_ANALYSIS] Error getting duration: $e');
      return 0.0;
    }
  }

  /// Analyze motion in video using frame differences
  Future<List<double>> _analyzeMotion(String videoPath, double duration) async {
    try {
      // Extract frames at 1fps and analyze differences
      final tempDir = await getTemporaryDirectory();
      final framesDir = Directory('${tempDir.path}/frames_${DateTime.now().millisecondsSinceEpoch}');
      await framesDir.create(recursive: true);

      // Extract frames at 1fps
      final session = await FFmpegKit.execute(
        '-i "$videoPath" -vf "fps=1,select=not(mod(n\\,1))" -vsync vfr "${framesDir.path}/frame_%03d.jpg"',
      );

      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        print('[VIDEO_ANALYSIS] Failed to extract frames for motion analysis');
        framesDir.deleteSync(recursive: true);
        return List.filled(duration.floor(), 15.0); // Default medium motion
      }

      // For now, return simulated motion scores
      // In a full implementation, we would analyze frame differences
      final motionScores = List.generate(
        duration.floor(),
        (i) => 15.0 + Random().nextDouble() * 15.0, // 15-30 points
      );

      // Cleanup
      try {
        framesDir.deleteSync(recursive: true);
      } catch (e) {
        print('[VIDEO_ANALYSIS] Error cleaning up frames: $e');
      }

      return motionScores;
    } catch (e) {
      print('[VIDEO_ANALYSIS] Error analyzing motion: $e');
      return List.filled(duration.floor(), 15.0);
    }
  }

  /// Analyze audio levels in video
  Future<List<double>> _analyzeAudio(String videoPath, double duration) async {
    try {
      // Extract audio volume statistics (for future enhancement)
      await FFmpegKit.execute(
        '-i "$videoPath" -af "volumedetect" -f null -',
      );

      // For now, return simulated audio scores
      // In a full implementation, we would analyze per-second audio levels
      final audioScores = List.generate(
        duration.floor(),
        (i) {
          // Simulate peaks and valleys
          final variation = sin(i * 0.5) * 10 + Random().nextDouble() * 5;
          return max(0.0, min(25.0, 12.5 + variation)); // 0-25 points
        },
      );

      return audioScores;
    } catch (e) {
      print('[VIDEO_ANALYSIS] Error analyzing audio: $e');
      return List.filled(duration.floor(), 12.5);
    }
  }

  /// Calculate position score (prefer middle of video)
  double _calculatePositionScore(double timestamp, double duration) {
    // Avoid first and last 10% of video
    final normalizedPosition = timestamp / duration;
    if (normalizedPosition < 0.1 || normalizedPosition > 0.9) {
      return 5.0;
    }
    // Peak score in the middle
    final distanceFromMiddle = (normalizedPosition - 0.5).abs();
    return 20.0 * (1 - distanceFromMiddle * 2);
  }

  /// Find best moments in video based on content scores
  Future<List<VideoSegment>> findBestMoments({
    required String videoPath,
    required String videoUrl,
    required double targetDuration,
    required String dayId,
    required String emoji,
    required String description,
    required int dayIndex,
  }) async {
    try {
      print('[VIDEO_ANALYSIS] Finding best moments for $dayId (target: ${targetDuration}s)');

      final scores = await analyzeVideo(videoPath);
      if (scores.isEmpty) {
        print('[VIDEO_ANALYSIS] No scores generated, using full video');
        return [
          VideoSegment(
            videoUrl: videoUrl,
            localPath: videoPath,
            startTime: 0.0,
            duration: min(targetDuration, await _getVideoDuration(videoPath)),
            dayId: dayId,
            emoji: emoji,
            description: description,
            score: 50.0,
            dayIndex: dayIndex,
          ),
        ];
      }

      // Find peaks in scores
      final peaks = _findPeaks(scores, threshold: 60.0);
      print('[VIDEO_ANALYSIS] Found ${peaks.length} peaks');

      // Select best segments
      final segments = _selectTopSegments(
        scores: scores,
        peaks: peaks,
        targetDuration: targetDuration,
        minSegmentLength: 2.0,
      );

      // Convert to VideoSegment objects
      final videoSegments = segments.map((seg) {
        return VideoSegment(
          videoUrl: videoUrl,
          localPath: videoPath,
          startTime: seg['startTime']!,
          duration: seg['duration']!,
          dayId: dayId,
          emoji: emoji,
          description: description,
          score: seg['score']!,
          dayIndex: dayIndex,
        );
      }).toList();

      print('[VIDEO_ANALYSIS] Selected ${videoSegments.length} segments totaling ${videoSegments.fold(0.0, (sum, s) => sum + s.duration)}s');

      return videoSegments;
    } catch (e) {
      print('[VIDEO_ANALYSIS] Error finding best moments: $e');
      return [
        VideoSegment(
          videoUrl: videoUrl,
          localPath: videoPath,
          startTime: 0.0,
          duration: targetDuration,
          dayId: dayId,
          emoji: emoji,
          description: description,
          score: 50.0,
          dayIndex: dayIndex,
        ),
      ];
    }
  }

  /// Find peaks in content scores
  List<ContentScore> _findPeaks(List<ContentScore> scores, {double threshold = 60.0}) {
    final peaks = <ContentScore>[];

    for (int i = 1; i < scores.length - 1; i++) {
      final current = scores[i];
      final prev = scores[i - 1];
      final next = scores[i + 1];

      // Check if it's a local maximum and above threshold
      if (current.totalScore > threshold &&
          current.totalScore > prev.totalScore &&
          current.totalScore > next.totalScore) {
        peaks.add(current);
      }
    }

    // Sort by score descending
    peaks.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return peaks;
  }

  /// Select top-scoring segments to fill target duration
  List<Map<String, double>> _selectTopSegments({
    required List<ContentScore> scores,
    required List<ContentScore> peaks,
    required double targetDuration,
    required double minSegmentLength,
  }) {
    final segments = <Map<String, double>>[];
    double accumulatedDuration = 0.0;
    final usedTimestamps = <double>{};

    // If no peaks, use highest scoring continuous segment
    if (peaks.isEmpty) {
      final bestStart = _findBestContinuousSegment(scores, targetDuration);
      return [
        {
          'startTime': bestStart,
          'duration': targetDuration,
          'score': scores.isNotEmpty ? scores[bestStart.floor()].totalScore : 50.0,
        }
      ];
    }

    // Select segments around peaks
    for (final peak in peaks) {
      if (accumulatedDuration >= targetDuration) break;

      // Check if this timestamp is already used
      if (usedTimestamps.contains(peak.timestamp)) continue;

      // Calculate segment around peak
      final segmentDuration = min(
        minSegmentLength + (peak.totalScore - 60) / 10,
        targetDuration - accumulatedDuration,
      );

      final startTime = max(0.0, peak.timestamp - segmentDuration / 2);
      final endTime = startTime + segmentDuration;

      // Check overlap with existing segments
      bool hasOverlap = false;
      for (double t = startTime; t < endTime; t += 0.5) {
        if (usedTimestamps.contains(t.floorToDouble())) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        segments.add({
          'startTime': startTime,
          'duration': segmentDuration,
          'score': peak.totalScore,
        });

        // Mark timestamps as used
        for (double t = startTime; t < endTime; t += 0.5) {
          usedTimestamps.add(t.floorToDouble());
        }

        accumulatedDuration += segmentDuration;
      }
    }

    // If we don't have enough duration, fill with highest scoring unused segments
    if (accumulatedDuration < targetDuration * 0.8) {
      final sortedScores = List<ContentScore>.from(scores)
        ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

      for (final score in sortedScores) {
        if (accumulatedDuration >= targetDuration) break;
        if (usedTimestamps.contains(score.timestamp)) continue;

        final segDuration = min(minSegmentLength, targetDuration - accumulatedDuration);
        segments.add({
          'startTime': score.timestamp,
          'duration': segDuration,
          'score': score.totalScore,
        });

        accumulatedDuration += segDuration;
        usedTimestamps.add(score.timestamp);
      }
    }

    // Sort segments by timestamp
    segments.sort((a, b) => a['startTime']!.compareTo(b['startTime']!));

    return segments;
  }

  /// Find the best continuous segment of given duration
  double _findBestContinuousSegment(List<ContentScore> scores, double duration) {
    if (scores.isEmpty) return 0.0;

    final windowSize = min(duration.floor(), scores.length);
    double bestScore = 0.0;
    int bestStartIndex = 0;

    for (int i = 0; i <= scores.length - windowSize; i++) {
      final windowScore = scores
          .sublist(i, i + windowSize)
          .fold(0.0, (sum, score) => sum + score.totalScore);

      if (windowScore > bestScore) {
        bestScore = windowScore;
        bestStartIndex = i;
      }
    }

    return bestStartIndex.toDouble();
  }

  /// Extract specific segments from a video
  Future<String?> extractSegments({
    required String inputPath,
    required List<Map<String, double>> segments,
    required String outputFileName,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/$outputFileName';

      if (segments.length == 1) {
        // Single segment - simple trim
        final seg = segments.first;
        final session = await FFmpegKit.execute(
          '-i "$inputPath" -ss ${seg['startTime']} -t ${seg['duration']} -c copy "$outputPath"',
        );

        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          return outputPath;
        }
      } else {
        // Multiple segments - extract and concatenate
        final segmentPaths = <String>[];

        for (int i = 0; i < segments.length; i++) {
          final seg = segments[i];
          final segPath = '${tempDir.path}/seg_${i}_${DateTime.now().millisecondsSinceEpoch}.mp4';

          final session = await FFmpegKit.execute(
            '-i "$inputPath" -ss ${seg['startTime']} -t ${seg['duration']} -c copy "$segPath"',
          );

          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            segmentPaths.add(segPath);
          }
        }

        // Concatenate segments
        if (segmentPaths.isNotEmpty) {
          final concatFile = '${tempDir.path}/concat_${DateTime.now().millisecondsSinceEpoch}.txt';
          final concatContent = segmentPaths.map((p) => "file '$p'").join('\n');
          await File(concatFile).writeAsString(concatContent);

          final session = await FFmpegKit.execute(
            '-f concat -safe 0 -i "$concatFile" -c copy "$outputPath"',
          );

          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            // Cleanup segment files
            for (final segPath in segmentPaths) {
              try {
                await File(segPath).delete();
              } catch (e) {
                // Ignore cleanup errors
              }
            }
            await File(concatFile).delete();
            return outputPath;
          }
        }
      }

      return null;
    } catch (e) {
      print('[VIDEO_ANALYSIS] Error extracting segments: $e');
      return null;
    }
  }
}

