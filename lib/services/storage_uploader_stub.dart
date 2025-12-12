import 'dart:typed_data';

/// Stub implementation used as a fallback for conditional exports.
Future<String> uploadToStorage({
  String? filePath,
  Uint8List? bytes,
  required String storagePath,
  String? contentType,
  String? filename,
}) async {
  throw UnsupportedError(
    'No storage uploader implementation available for this platform.',
  );
}
