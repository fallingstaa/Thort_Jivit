import 'package:firebase_storage/firebase_storage.dart';

class MusicService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Fetch all music files from music_library folder in Firebase Storage
  Future<List<String>> getMusicLibrary() async {
    try {
      final listResult = await _storage.ref('music_library/').listAll();

      // Filter only audio files (mp3, m4a, wav, etc.)
      final musicFiles =
          listResult.items
              .where((item) {
                final name = item.name.toLowerCase();
                return name.endsWith('.mp3') ||
                    name.endsWith('.m4a') ||
                    name.endsWith('.wav') ||
                    name.endsWith('.flac') ||
                    name.endsWith('.aac');
              })
              .map((item) => item.name)
              .toList();

      return musicFiles;
    } catch (e) {
      print('[MUSIC_SERVICE] Error fetching music library: $e');
      return [];
    }
  }

  /// Get download URL for a specific music file
  Future<String?> getMusicUrl(String musicFileName) async {
    try {
      final url =
          await _storage.ref('music_library/$musicFileName').getDownloadURL();
      return url;
    } catch (e) {
      print('[MUSIC_SERVICE] Error getting music URL: $e');
      return null;
    }
  }
}
