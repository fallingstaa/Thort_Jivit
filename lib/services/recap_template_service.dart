// lib/services/recap_template_service.dart

import 'dart:math';
import '../models/recap_template.dart';

/// Service for generating recap videos with different templates
class RecapTemplateService {
  /// Generate recap parameters for the Highlight Reel style
  Map<String, dynamic> generateHighlightReel({
    required List<VideoSegment> segments,
    required RecapEffectsConfig effects,
    required int musicBPM,
  }) {
    print('[TEMPLATE] Generating Highlight Reel style');

    // Sort segments by day index
    segments.sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

    // Build FFmpeg filter parameters
    final filters = <String>[];
    final transitionType = ['fadewhite', 'fadeblack', 'circleopen', 'wiperight'];
    
    // Apply color saturation for vibrant look
    for (int i = 0; i < segments.length; i++) {
      if (effects.colorFilters) {
        filters.add('[${i}:v]scale=1080:1920,eq=saturation=1.3,eq=brightness=0.05[v$i]');
      } else {
        filters.add('[${i}:v]scale=1080:1920[v$i]');
      }
    }

    // Add transitions between clips
    if (effects.transitions && segments.length > 1) {
      String currentLabel = 'v0';
      
      for (int i = 1; i < segments.length; i++) {
        final transition = transitionType[i % transitionType.length];
        final offset = _calculateOffset(segments, i, musicBPM, effects.musicSync);
        final nextLabel = i == segments.length - 1 ? 'vout' : 'vtemp$i';
        
        filters.add('[$currentLabel][v$i]xfade=transition=$transition:duration=0.4:offset=$offset[$nextLabel]');
        currentLabel = nextLabel;
      }
    }

    // Add text overlays
    if (effects.textOverlays) {
      final textFilters = <String>[];
      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i];
        final text = '${seg.emoji} ${_truncateDescription(seg.description, 15)}';
        textFilters.add(
          "drawtext=text='$text':fontsize=48:x=(w-tw)/2:y=80:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=10",
        );
      }
      
      if (textFilters.isNotEmpty) {
        final lastLabel = segments.length > 1 && effects.transitions ? 'vout' : 'v0';
        filters.add('[$lastLabel]${textFilters.join(',')}[vfinal]');
      }
    }

    return {
      'templateStyle': 'highlight',
      'filters': filters,
      'transitionDuration': 0.4,
      'colorFilter': effects.colorFilters ? 'vibrant' : 'none',
      'textOverlays': effects.textOverlays,
      'musicSync': effects.musicSync,
      'musicBPM': musicBPM,
    };
  }

  /// Generate recap parameters for the Cinematic Story style
  Map<String, dynamic> generateCinematicStory({
    required List<VideoSegment> segments,
    required RecapEffectsConfig effects,
    required int musicBPM,
  }) {
    print('[TEMPLATE] Generating Cinematic Story style');

    // Sort segments by day index
    segments.sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

    final filters = <String>[];

    // Apply warm color grading and vignette
    for (int i = 0; i < segments.length; i++) {
      if (effects.colorFilters) {
        filters.add(
          '[${i}:v]scale=1080:1920,eq=saturation=0.8:gamma=1.1,vignette=PI/4[v$i]',
        );
      } else {
        filters.add('[${i}:v]scale=1080:1920[v$i]');
      }
    }

    // Add smooth cross-dissolve transitions
    if (effects.transitions && segments.length > 1) {
      String currentLabel = 'v0';
      
      for (int i = 1; i < segments.length; i++) {
        final offset = _calculateOffset(segments, i, musicBPM, effects.musicSync);
        final nextLabel = i == segments.length - 1 ? 'vout' : 'vtemp$i';
        
        filters.add('[$currentLabel][v$i]xfade=transition=fade:duration=0.8:offset=$offset[$nextLabel]');
        currentLabel = nextLabel;
      }
    }

    // Add text overlays with full description and date
    if (effects.textOverlays) {
      final textFilters = <String>[];
      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i];
        final mainText = '${seg.emoji} ${seg.description}';
        final dateText = seg.dayId;
        
        // Two lines: main text and date
        textFilters.add(
          "drawtext=text='$mainText':fontsize=40:x=(w-tw)/2:y=100:fontcolor=white:box=1:boxcolor=black@0.6:boxborderw=10",
        );
        textFilters.add(
          "drawtext=text='$dateText':fontsize=28:x=(w-tw)/2:y=160:fontcolor=white@0.8",
        );
      }
      
      if (textFilters.isNotEmpty) {
        final lastLabel = segments.length > 1 && effects.transitions ? 'vout' : 'v0';
        filters.add('[$lastLabel]${textFilters.join(',')}[vfinal]');
      }
    }

    return {
      'templateStyle': 'cinematic',
      'filters': filters,
      'transitionDuration': 0.8,
      'colorFilter': effects.colorFilters ? 'warm' : 'none',
      'textOverlays': effects.textOverlays,
      'musicSync': effects.musicSync,
      'musicBPM': musicBPM,
    };
  }

  /// Generate recap parameters for the Timeline style
  Map<String, dynamic> generateTimeline({
    required List<VideoSegment> segments,
    required RecapEffectsConfig effects,
    required int musicBPM,
  }) {
    print('[TEMPLATE] Generating Timeline style');

    // Sort segments by day index
    segments.sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

    final filters = <String>[];

    // Clean, neutral color grading
    for (int i = 0; i < segments.length; i++) {
      if (effects.colorFilters) {
        filters.add('[${i}:v]scale=1080:1920,eq=contrast=1.1[v$i]');
      } else {
        filters.add('[${i}:v]scale=1080:1920[v$i]');
      }
    }

    // Add slide transitions
    if (effects.transitions && segments.length > 1) {
      String currentLabel = 'v0';
      final slideTransitions = ['slideleft', 'slideright', 'slideup', 'slidedown'];
      
      for (int i = 1; i < segments.length; i++) {
        final transition = slideTransitions[i % slideTransitions.length];
        final offset = _calculateOffset(segments, i, musicBPM, effects.musicSync);
        final nextLabel = i == segments.length - 1 ? 'vout' : 'vtemp$i';
        
        filters.add('[$currentLabel][v$i]xfade=transition=$transition:duration=0.6:offset=$offset[$nextLabel]');
        currentLabel = nextLabel;
      }
    }

    // Add day labels with prominent date headers
    if (effects.textOverlays) {
      final textFilters = <String>[];
      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i];
        
        // Day header (larger, at top)
        textFilters.add(
          "drawtext=text='${seg.dayId}':fontsize=56:x=(w-tw)/2:y=60:fontcolor=white:box=1:boxcolor=0x009688@0.8:boxborderw=15",
        );
        
        // Emoji and description (smaller, below header)
        textFilters.add(
          "drawtext=text='${seg.emoji} ${seg.description}':fontsize=36:x=(w-tw)/2:y=150:fontcolor=white@0.9",
        );
      }
      
      if (textFilters.isNotEmpty) {
        final lastLabel = segments.length > 1 && effects.transitions ? 'vout' : 'v0';
        filters.add('[$lastLabel]${textFilters.join(',')}[vfinal]');
      }
    }

    return {
      'templateStyle': 'timeline',
      'filters': filters,
      'transitionDuration': 0.6,
      'colorFilter': effects.colorFilters ? 'neutral' : 'none',
      'textOverlays': effects.textOverlays,
      'musicSync': effects.musicSync,
      'musicBPM': musicBPM,
    };
  }

  /// Generate template based on style
  Map<String, dynamic> generateTemplate({
    required RecapTemplateStyle style,
    required List<VideoSegment> segments,
    required RecapEffectsConfig effects,
    int musicBPM = 120,
  }) {
    switch (style) {
      case RecapTemplateStyle.highlight:
        return generateHighlightReel(
          segments: segments,
          effects: effects,
          musicBPM: musicBPM,
        );
      case RecapTemplateStyle.cinematic:
        return generateCinematicStory(
          segments: segments,
          effects: effects,
          musicBPM: musicBPM,
        );
      case RecapTemplateStyle.timeline:
        return generateTimeline(
          segments: segments,
          effects: effects,
          musicBPM: musicBPM,
        );
    }
  }

  /// Calculate offset for transitions, optionally synced to music beats
  double _calculateOffset(
    List<VideoSegment> segments,
    int currentIndex,
    int musicBPM,
    bool syncToMusic,
  ) {
    // Calculate cumulative duration up to this point
    double offset = 0.0;
    for (int i = 0; i < currentIndex; i++) {
      offset += segments[i].duration;
    }

    // If music sync is enabled, adjust to nearest beat
    if (syncToMusic && musicBPM > 0) {
      final beatInterval = 60.0 / musicBPM;
      final nearestBeat = (offset / beatInterval).round() * beatInterval;
      
      // Only adjust if within reasonable range (0.3s)
      if ((nearestBeat - offset).abs() < 0.3) {
        return nearestBeat;
      }
    }

    return offset;
  }

  /// Truncate description to fit on screen
  String _truncateDescription(String description, int maxLength) {
    if (description.length <= maxLength) return description;
    return '${description.substring(0, maxLength - 3)}...';
  }

  /// Calculate target duration per video based on template and total videos
  double calculateTargetDurationPerVideo({
    required RecapTemplateStyle style,
    required int videoCount,
    required double totalTargetDuration,
  }) {
    if (videoCount == 0) return 0.0;

    // Account for transitions
    final transitionTime = style.transitionDuration * (videoCount - 1);
    final availableDuration = totalTargetDuration - transitionTime;

    // Distribute evenly
    return availableDuration / videoCount;
  }

  /// Validate that segments fit within target duration
  bool validateDuration({
    required List<VideoSegment> segments,
    required double targetDuration,
    required RecapTemplateStyle style,
    double tolerance = 5.0,
  }) {
    final totalClipDuration = segments.fold(0.0, (sum, seg) => sum + seg.duration);
    final transitionTime = style.transitionDuration * (segments.length - 1);
    final totalDuration = totalClipDuration + transitionTime;

    print('[TEMPLATE] Total duration: ${totalDuration}s (target: ${targetDuration}s)');

    return (totalDuration - targetDuration).abs() <= tolerance;
  }

  /// Adjust segment durations to fit target duration
  List<VideoSegment> adjustSegmentDurations({
    required List<VideoSegment> segments,
    required double targetDuration,
    required RecapTemplateStyle style,
  }) {
    final currentTotal = segments.fold(0.0, (sum, seg) => sum + seg.duration);
    final transitionTime = style.transitionDuration * (segments.length - 1);
    final availableDuration = targetDuration - transitionTime;

    if (currentTotal <= 0) return segments;

    final scaleFactor = availableDuration / currentTotal;

    return segments.map((seg) {
      final newDuration = seg.duration * scaleFactor;
      
      // Ensure duration is within template bounds
      final clampedDuration = newDuration.clamp(
        max(2.0, style.minClipDuration * 0.7),
        style.maxClipDuration,
      ).toDouble();

      return VideoSegment(
        videoUrl: seg.videoUrl,
        localPath: seg.localPath,
        startTime: seg.startTime,
        duration: clampedDuration,
        dayId: seg.dayId,
        emoji: seg.emoji,
        description: seg.description,
        score: seg.score,
        dayIndex: seg.dayIndex,
      );
    }).toList();
  }
}

