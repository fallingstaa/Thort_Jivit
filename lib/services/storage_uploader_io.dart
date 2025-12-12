import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

Future<String> uploadToStorage({
  String? filePath,
  Uint8List? bytes,
  required String storagePath,
  String? contentType,
  String? filename,
}) async {
  if (filePath == null)
    throw ArgumentError('filePath is required on IO platforms');

  final ref = FirebaseStorage.instance.ref().child(storagePath);
  final file = File(filePath);
  await ref.putFile(file);
  return await ref.getDownloadURL();
}
