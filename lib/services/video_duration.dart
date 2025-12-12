// Conditional export for platform-specific video duration utilities.
export 'video_duration_io.dart'
    if (dart.library.html) 'video_duration_web.dart';
