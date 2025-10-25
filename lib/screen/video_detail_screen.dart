import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'homepage.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoPath;

  const VideoDetailScreen({Key? key, required this.videoPath})
    : super(key: key);

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  String _selectedEmoji = '';

  final List<String> _emojis = [
    '😊',
    '😂',
    '😍',
    '🥰',
    '😎',
    '🤩',
    '😇',
    '🤗',
    '😘',
    '😉',
    '😋',
    '😜',
    '🤪',
    '😏',
    '🥳',
    '🎉',
    '❤️',
    '💕',
    '💖',
    '💝',
    '🌟',
    '✨',
    '🎊',
    '🎈',
    '🌈',
    '☀️',
    '🌺',
    '🌸',
    '🌻',
    '🌷',
    '🍀',
    '🦋',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(File(widget.videoPath));
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.play(); // Start playing automatically
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00A991),),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video Detail',
          style: TextStyle(
            color: Color(0xFF00A991),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Video Preview
          Expanded(child: _buildVideoPreview()),

          // Bottom Sheet
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Edit your clip',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00A991),
                  ),
                ),

                const SizedBox(height: 20),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF00A991),
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: const Color(0xFF00A991),
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [Tab(text: 'Description'), Tab(text: 'Emojis')],
                  ),
                ),

                const SizedBox(height: 20),

                // Tab Content
                SizedBox(
                  height: 160,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Description Tab
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'What made you smile today?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _textController,
                              decoration: InputDecoration(
                                hintText: 'Type your answer...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Emojis Tab
                      _buildEmojisTab(),
                    ],
                  ),
                ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveClip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A991),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save Clip',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.grey[400],
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00A991)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  Widget _buildEmojisTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose an emoji that represents your mood',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                final emoji = _emojis[index];
                final isSelected = _selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF00A991).withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          isSelected
                              ? Border.all(
                                color: const Color(0xFF00A991),
                                width: 2,
                              )
                              : Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _saveClip() {
    final description = _textController.text.trim();
    final emoji = _selectedEmoji;

    print('Saving clip with description: $description and emoji: $emoji');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Clip saved successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFF00A991),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Navigate to homepage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false, // Remove all previous routes
    );
  }
}
