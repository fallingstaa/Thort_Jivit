// lib/models/recap_template.dart

/// Represents a video segment with timing and metadata
class VideoSegment {
  final String videoUrl;
  final String localPath;
  final double startTime;
  final double duration;
  final String dayId;
  final String emoji;
  final String description;
  final double score;
  final int dayIndex;

  VideoSegment({
    required this.videoUrl,
    required this.localPath,
    required this.startTime,
    required this.duration,
    required this.dayId,
    required this.emoji,
    required this.description,
    required this.score,
    required this.dayIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': videoUrl,
      'localPath': localPath,
      'startTime': startTime,
      'duration': duration,
      'dayId': dayId,
      'emoji': emoji,
      'description': description,
      'score': score,
      'dayIndex': dayIndex,
    };
  }
}

/// Scoring data for video content analysis
class ContentScore {
  final double timestamp;
  final double motionScore;
  final double audioScore;
  final double positionScore;
  final double totalScore;

  ContentScore({
    required this.timestamp,
    required this.motionScore,
    required this.audioScore,
    required this.positionScore,
  }) : totalScore = motionScore + audioScore + positionScore;

  @override
  String toString() =>
      'ContentScore(t=$timestamp, total=$totalScore, motion=$motionScore, audio=$audioScore, pos=$positionScore)';
}

/// Template style configuration
enum RecapTemplateStyle {
  highlight,
  cinematic,
  timeline,
}

extension RecapTemplateStyleExtension on RecapTemplateStyle {
  String get name {
    switch (this) {
      case RecapTemplateStyle.highlight:
        return 'Highlight Reel';
      case RecapTemplateStyle.cinematic:
        return 'Cinematic Story';
      case RecapTemplateStyle.timeline:
        return 'Timeline';
    }
  }

  String get description {
    switch (this) {
      case RecapTemplateStyle.highlight:
        return 'Fast-paced with quick cuts and energetic music';
      case RecapTemplateStyle.cinematic:
        return 'Smooth narrative with emotional storytelling';
      case RecapTemplateStyle.timeline:
        return 'Day-by-day progression with clear structure';
    }
  }

  String get identifier {
    switch (this) {
      case RecapTemplateStyle.highlight:
        return 'highlight';
      case RecapTemplateStyle.cinematic:
        return 'cinematic';
      case RecapTemplateStyle.timeline:
        return 'timeline';
    }
  }

  double get minClipDuration {
    switch (this) {
      case RecapTemplateStyle.highlight:
        return 5.0;
      case RecapTemplateStyle.cinematic:
        return 8.0;
      case RecapTemplateStyle.timeline:
        return 7.0;
    }
  }

  double get maxClipDuration {
    switch (this) {
      case RecapTemplateStyle.highlight:
        return 7.0;
      case RecapTemplateStyle.cinematic:
        return 10.0;
      case RecapTemplateStyle.timeline:
        return 8.0;
    }
  }

  double get transitionDuration {
    switch (this) {
      case RecapTemplateStyle.highlight:
        return 0.4;
      case RecapTemplateStyle.cinematic:
        return 0.8;
      case RecapTemplateStyle.timeline:
        return 0.6;
    }
  }

  static RecapTemplateStyle fromString(String str) {
    switch (str.toLowerCase()) {
      case 'cinematic':
        return RecapTemplateStyle.cinematic;
      case 'timeline':
        return RecapTemplateStyle.timeline;
      case 'highlight':
      default:
        return RecapTemplateStyle.highlight;
    }
  }
}

/// Template configuration for video effects
class RecapEffectsConfig {
  final bool transitions;
  final bool textOverlays;
  final bool colorFilters;
  final bool musicSync;
  final String colorFilter;

  RecapEffectsConfig({
    this.transitions = true,
    this.textOverlays = true,
    this.colorFilters = true,
    this.musicSync = true,
    this.colorFilter = 'vibrant',
  });

  Map<String, dynamic> toJson() {
    return {
      'transitions': transitions,
      'textOverlays': textOverlays,
      'colorFilter': colorFilters ? colorFilter : 'none',
      'musicSync': musicSync,
    };
  }
}

/// User preferences for recap generation
class RecapPreferences {
  final RecapTemplateStyle defaultTemplate;
  final double targetDuration;
  final bool autoGenerate;
  final RecapEffectsConfig effects;
  final int musicBPM;

  RecapPreferences({
    this.defaultTemplate = RecapTemplateStyle.highlight,
    this.targetDuration = 45.0,
    this.autoGenerate = true,
    RecapEffectsConfig? effects,
    this.musicBPM = 120,
  }) : effects = effects ?? RecapEffectsConfig();

  Map<String, dynamic> toJson() {
    return {
      'defaultTemplate': defaultTemplate.identifier,
      'targetDuration': targetDuration,
      'autoGenerate': autoGenerate,
      'effects': effects.toJson(),
      'musicBPM': musicBPM,
    };
  }

  factory RecapPreferences.fromJson(Map<String, dynamic> json) {
    return RecapPreferences(
      defaultTemplate: RecapTemplateStyleExtension.fromString(
        json['defaultTemplate'] ?? 'highlight',
      ),
      targetDuration: (json['targetDuration'] ?? 45.0).toDouble(),
      autoGenerate: json['autoGenerate'] ?? true,
      effects: json['effects'] != null
          ? RecapEffectsConfig(
              transitions: json['effects']['transitions'] ?? true,
              textOverlays: json['effects']['textOverlays'] ?? true,
              colorFilters: json['effects']['colorFilter'] != 'none',
              musicSync: json['effects']['musicSync'] ?? true,
              colorFilter: json['effects']['colorFilter'] ?? 'vibrant',
            )
          : RecapEffectsConfig(),
      musicBPM: json['musicBPM'] ?? 120,
    );
  }
}

