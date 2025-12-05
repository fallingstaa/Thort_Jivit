import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

Future<String> uploadToStorage({
  String? filePath,
  Uint8List? bytes,
  required String storagePath,
  String? contentType,
  String? filename,
}) async {
  if (bytes == null) throw ArgumentError('bytes are required on web platforms');

  final ref = FirebaseStorage.instance.ref().child(storagePath);
  final metadata = SettableMetadata(contentType: contentType ?? 'video/mp4');
  await ref.putData(bytes, metadata);
  return await ref.getDownloadURL();
}
