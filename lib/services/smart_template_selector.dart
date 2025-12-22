// lib/services/smart_template_selector.dart

import 'dart:math';
import '../models/recap_template.dart';
import '../models/video.dart';

/// Automatically selects the best template and duration based on video content
class SmartTemplateSelector {
  /// Analyzes videos and selects the best template style
  static RecapTemplateStyle selectBestTemplate(List<Video> videos) {
    if (videos.isEmpty) {
      return RecapTemplateStyle.highlight; // Default
    }

    // Calculate mood scores based on emojis and descriptions
    int energeticScore = 0;
    int emotionalScore = 0;
    int neutralScore = 0;

    for (final video in videos) {
      final emoji = video.emoji ?? '';
      final description = video.description?.toLowerCase() ?? '';

      // Energetic indicators (Highlight Reel)
      if (_isEnergeticEmoji(emoji) || 
          description.contains('fun') ||
          description.contains('party') ||
          description.contains('exciting') ||
          description.contains('active') ||
          description.contains('sport')) {
        energeticScore += 2;
      }

      // Emotional indicators (Cinematic Story)
      if (_isEmotionalEmoji(emoji) ||
          description.contains('love') ||
          description.contains('beautiful') ||
          description.contains('memory') ||
          description.contains('special') ||
          description.contains('moment')) {
        emotionalScore += 2;
      }

      // Neutral/Daily indicators (Timeline)
      if (_isNeutralEmoji(emoji) ||
          description.contains('day') ||
          description.contains('work') ||
          description.contains('routine') ||
          description.contains('normal')) {
        neutralScore += 2;
      }

      // No emoji/description = slightly favor timeline
      if (emoji.isEmpty && description.isEmpty) {
        neutralScore += 1;
      }
    }

    // Select template based on highest score
    final maxScore = [energeticScore, emotionalScore, neutralScore].reduce(max);

    if (maxScore == energeticScore) {
      print('[SMART_SELECTOR] Selected Highlight Reel (energetic: $energeticScore)');
      return RecapTemplateStyle.highlight;
    } else if (maxScore == emotionalScore) {
      print('[SMART_SELECTOR] Selected Cinematic Story (emotional: $emotionalScore)');
      return RecapTemplateStyle.cinematic;
    } else {
      print('[SMART_SELECTOR] Selected Timeline (neutral: $neutralScore)');
      return RecapTemplateStyle.timeline;
    }
  }

  /// Calculates optimal duration based on number of videos
  static double calculateOptimalDuration(List<Video> videos) {
    final count = videos.length;

    if (count <= 3) {
      return 30.0; // Short week, keep it brief
    } else if (count <= 5) {
      return 40.0; // Medium week
    } else if (count <= 6) {
      return 50.0; // Full week
    } else {
      return 60.0; // Many videos, max duration
    }
  }

  /// Creates preferences with smart selections
  static RecapPreferences createSmartPreferences(List<Video> videos) {
    final template = selectBestTemplate(videos);
    final duration = calculateOptimalDuration(videos);

    print('[SMART_SELECTOR] Auto-selected: ${template.name}, ${duration.toInt()}s for ${videos.length} videos');

    return RecapPreferences(
      defaultTemplate: template,
      targetDuration: duration,
      autoGenerate: false,
      effects: RecapEffectsConfig(
        transitions: true,
        textOverlays: false, // Disabled for now
        colorFilters: true,
        musicSync: true,
      ),
    );
  }

  // Helper methods for emoji classification
  static bool _isEnergeticEmoji(String emoji) {
    const energeticEmojis = [
      '😄', '😃', '😁', '🤩', '🥳', '🎉', '🎊', '🏃', '⚡', '🔥',
      '💪', '🎮', '🏀', '⚽', '🎯', '🚀', '✨', '🌟'
    ];
    return energeticEmojis.any((e) => emoji.contains(e));
  }

  static bool _isEmotionalEmoji(String emoji) {
    const emotionalEmojis = [
      '❤️', '💕', '💖', '💗', '🥰', '😊', '😌', '🌹', '🌸', '🌺',
      '🌅', '🌄', '⭐', '💫', '🕊️', '👨‍👩‍👧', '👨‍👩‍👧‍👦', '🤗'
    ];
    return emotionalEmojis.any((e) => emoji.contains(e));
  }

  static bool _isNeutralEmoji(String emoji) {
    const neutralEmojis = [
      '📅', '📆', '🏠', '🏢', '☕', '🍔', '📚', '💼', '🚗', '🚌',
      '🌤️', '☀️', '🌧️', '📱', '💻', '🖊️'
    ];
    return neutralEmojis.any((e) => emoji.contains(e));
  }
}

