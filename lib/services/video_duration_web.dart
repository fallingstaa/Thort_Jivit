import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Duration?> getVideoDuration({String? filePath, List<int>? bytes, String? filename}) async {
  try {
    final data = bytes;
    if (data == null) return null;

    // Try to guess MIME type from filename extension when available.
    String mime = '';
    if (filename != null) {
      final ext = filename.split('.').last.toLowerCase();
      switch (ext) {
        case 'mp4':
          mime = 'video/mp4';
          break;
        case 'webm':
          mime = 'video/webm';
          break;
        case 'mov':
          mime = 'video/quicktime';
          break;
        case 'mkv':
          mime = 'video/x-matroska';
          break;
        case 'avi':
          mime = 'video/x-msvideo';
          break;
        default:
          mime = '';
      }
    }

    final blob = mime.isNotEmpty ? html.Blob([data], mime) : html.Blob([data]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final video = html.VideoElement();
    final completer = Completer<Duration?>();

    video.src = url;
    video.preload = 'metadata';
    video.muted = true;
    video.controls = false;
    video.setAttribute('playsinline', '');
    // Hide visually but keep in layout to ensure some engines load metadata
    video.style.position = 'absolute';
    video.style.left = '-9999px';
    video.style.width = '1px';
    video.style.height = '1px';
    // Some browsers need an explicit load() call
    try {
      video.load();
    } catch (_) {}

    void cleanup() {
      try {
        html.Url.revokeObjectUrl(url);
      } catch (_) {}
      try {
        video.remove();
      } catch (_) {}
    }

    // Listen for several events that may indicate duration is available.
    void tryComplete() {
      final d = video.duration;
      if (d > 0 && !completer.isCompleted) {
        final dur = Duration(milliseconds: (d * 1000).round());
        cleanup();
        completer.complete(dur);
      }
    }

    video.onLoadedMetadata.listen((_) => tryComplete());
    video.onLoadedData.listen((_) => tryComplete());
    video.onCanPlay.listen((_) => tryComplete());

    video.onError.listen((ev) {
      // Log error details to browser console to help debugging unsupported codecs or parse errors.
      try {
        final err = video.error;
        if (err != null) {
          html.window.console.error('video.onError: code=${err.code} message=${err.message}');
        } else {
          html.window.console.error('video.onError event: $ev');
        }
      } catch (e) {
        html.window.console.error('video.onError logging failed: $e');
      }

      cleanup();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    // Add to DOM so metadata loads in some browsers; append hidden video
    (html.document.body ?? html.document.documentElement)?.append(video);

    // Safety timeout: wait longer for slow files/browsers
    Future.delayed(const Duration(seconds: 10)).then((_) {
      tryComplete();
      if (!completer.isCompleted) {
        cleanup();
        completer.complete(null);
      }
    });

    final result = await completer.future;

    // If we couldn't get duration via media element but we have bytes for an MP4,
    // try parsing the 'mvhd' box from the MP4 container as a fallback.
    if (result == null && bytes != null) {
      try {
        final parsed = _parseMp4Duration(bytes);
        if (parsed != null) return parsed;
      } catch (e) {
        html.window.console.warn('mp4 parse fallback failed: $e');
      }
    }

    return result;
  } catch (_) {
    return null;
  }
}

Duration? _parseMp4Duration(List<int> data) {
  final bytes = Uint8List.fromList(data);
  int offset = 0;
  final len = bytes.length;

  int readUint32(int off) => (bytes[off] << 24) | (bytes[off + 1] << 16) | (bytes[off + 2] << 8) | bytes[off + 3];
  // no-op

  while (offset + 8 <= len) {
    final size = readUint32(offset);
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    if (type == 'moov') {
      // iterate children of moov
      int moovEnd = offset + size;
      int moovOff = offset + 8;
      while (moovOff + 8 <= moovEnd && moovOff + 8 <= len) {
        final csize = readUint32(moovOff);
        final ctype = String.fromCharCodes(bytes.sublist(moovOff + 4, moovOff + 8));
        if (ctype == 'mvhd') {
          final mvhdOff = moovOff;
          final version = bytes[mvhdOff + 8];
          if (version == 0) {
            final timescale = readUint32(mvhdOff + 20);
            final duration = readUint32(mvhdOff + 24);
            if (timescale > 0) {
              return Duration(milliseconds: ((duration * 1000) / timescale).round());
            }
          } else if (version == 1) {
            final timescale = readUint32(mvhdOff + 28);
            final durationHi = readUint32(mvhdOff + 32);
            final durationLo = readUint32(mvhdOff + 36);
            final duration = (durationHi << 32) | durationLo;
            if (timescale > 0) {
              return Duration(milliseconds: ((duration * 1000) / timescale).round());
            }
          }
        }
        if (csize <= 0) break;
        moovOff += csize;
      }
    }
    if (size <= 0) break;
    offset += size;
  }
  return null;
}
