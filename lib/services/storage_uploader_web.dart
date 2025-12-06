import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

Future<String> uploadToStorage({
  String? filePath,
  Uint8List? bytes,
  required String storagePath,
  String? contentType,
  String? filename,
}) async {
  print('[WEB UPLOADER] Starting upload to: $storagePath');
  print('[WEB UPLOADER] Bytes length: ${bytes?.length ?? 0}');
  print('[WEB UPLOADER] Content type: ${contentType ?? "video/mp4"}');

  if (bytes == null) {
    print('[WEB UPLOADER] ERROR: bytes are null');
    throw ArgumentError('bytes are required on web platforms');
  }

  final ref = FirebaseStorage.instance.ref().child(storagePath);
  final metadata = SettableMetadata(contentType: contentType ?? 'video/mp4');

  print('[WEB UPLOADER] Starting putData...');
  await ref.putData(bytes, metadata);

  print('[WEB UPLOADER] Getting download URL...');
  final url = await ref.getDownloadURL();
  print('[WEB UPLOADER] Upload complete. URL length: ${url.length}');

  return url;
}
