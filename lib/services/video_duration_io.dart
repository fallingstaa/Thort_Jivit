import 'dart:io';
import 'package:video_player/video_player.dart';

/// Returns the duration of a video file (native platforms) or null if it cannot be determined.
Future<Duration?> getVideoDuration({String? filePath, List<int>? bytes, String? filename}) async {
  try {
    if (filePath == null) return null;
    final controller = VideoPlayerController.file(File(filePath));
    await controller.initialize();
    final dur = controller.value.duration;
    await controller.dispose();
    return dur;
  } catch (_) {
    return null;
  }
}
