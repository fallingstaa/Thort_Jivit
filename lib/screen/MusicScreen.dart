import 'package:flutter/material.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
  }


// A simple data model for a song
class Song {
  final String title;
  final String artist;
  final String album;
  final String imagePath;
  bool isFavorite; // <-- 1. ADDED: To track favorite status

  Song({
    required this.title,
    required this.artist,
    required this.album,
    required this.imagePath,
    this.isFavorite = false, // <-- Default to not favorite
  });
}

class _MusicScreenState extends State<MusicScreen> {
  final List<String> _songImages = [
    'music/1.jpg',
    'music/2.jpg',
    'music/3.png',
  ];

  // --- 2. ADDED: More mock data for variety ---
  final List<String> _titles = [
    'Shattered',
    'Echoes in the Void',
    'Driftwood',
    'Starlight Chase',
    'Digital Odyssey'
  ];
  final List<String> _artists = [
    'Vectorsonic',
    'AuraProgram',
    'Glyph',
    'NovaPulse',
    'Mirage'
  ];
  final List<String> _albums = [
    'Digital',
    'Ascension',
    'Nomad',
    'Celestial',
    'Reflections'
  ];
  // --- End of new data ---

  late final List<Song> _recentlyPlayed;

  @override
  void initState() {
    super.initState();
    _recentlyPlayed = List.generate(
      10,
      (index) {
        // MODIFIED: Use modulo to cycle through new mock data
        final dataIndex = index % _titles.length;
        return Song(
          title: _titles[dataIndex],
          artist: _artists[dataIndex],
          album: _albums[dataIndex],
          imagePath: _songImages[index % _songImages.length],
        );
      },
    );
  }

  final Song _currentlyPlaying = Song(
    title: 'Shattered Reality',
    artist: 'Vectorsonic',
    album: 'Digital',
    imagePath: 'music/1.jpg',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 178, 228, 192),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildSongList(),
          _buildBottomPlayer(),
        ],
      ),
    );
  }

  // --- UI Widget Builders ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 224, 240, 229),
      elevation: 0,
      title: const Text(
        'Music flows',
        style: TextStyle(
          color: Color(0xFF006045),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSongList() {
    // Add padding to the bottom to ensure the list doesn't hide behind the player
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 160), // Increased bottom padding for player
      itemCount: _recentlyPlayed.length,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Library',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              const Text('Recently played tracks',
                  style: TextStyle(
                      color: Color.fromARGB(255, 128, 127, 127),
                      fontSize: 14)),
              const SizedBox(height: 16),
              _buildSongListItem(_recentlyPlayed[index]),
            ],
          );
        }
        return _buildSongListItem(_recentlyPlayed[index]);
      },
    );
  }

  Widget _buildSongListItem(Song song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 224, 240, 229),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              song.imagePath,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${song.artist} • ${song.album}',
                    style: const TextStyle(color: Colors.black)),
              ],
            ),
          ),
          // --- 3. MODIFIED: Favorite Icon Button ---
          IconButton(
            icon: Icon(
              // Change icon based on favorite status
              song.isFavorite ? Icons.favorite : Icons.favorite_border,
              // Change color based on favorite status
              color: song.isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: () {
              // Use setState to rebuild the widget with the new state
              setState(() {
                song.isFavorite = !song.isFavorite;
              });
            },
          ),
          // --- End of modification ---
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPlayer() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF006045),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    _currentlyPlaying.imagePath,
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.music_note,
                            size: 45, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentlyPlaying.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      Text(
                        '${_currentlyPlaying.artist} • ${_currentlyPlaying.album}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                // --- 4. MODIFIED: Favorite Icon for Bottom Player ---
                IconButton(
                  icon: Icon(
                    _currentlyPlaying.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _currentlyPlaying.isFavorite
                        ? Colors.red
                        : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentlyPlaying.isFavorite =
                          !_currentlyPlaying.isFavorite;
                    });
                  },
                ),
                // --- End of modification ---
              ],
            ),
            const SizedBox(height: 8),
            // Linear Progress Bar
            LinearProgressIndicator(
              value: 0.3, // Mock progress
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 2,
            ),
            const SizedBox(height: 4),
            // Player Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    icon: const Icon(Icons.shuffle, color: Colors.white),
                    onPressed: () {}),
                IconButton(
                    icon: const Icon(Icons.skip_previous,
                        size: 32, color: Colors.white),
                    onPressed: () {}),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill,
                      size: 50, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                    icon: const Icon(Icons.skip_next,
                        size: 32, color: Colors.white),
                    onPressed: () {}),
                IconButton(
                    icon: const Icon(Icons.repeat, color: Colors.white),
                    onPressed: () {}),
              ],
            )
          ],
        ),
      ),
    );
  }
}