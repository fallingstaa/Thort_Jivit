import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String emoji;
  final String description;
  final String date;

  const VideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.emoji,
    required this.description,
    required this.date,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
      });
    } catch (e) {
      print('[VIDEO_PLAYER] Error initializing video: $e');
    }
  }

  void _togglePlayPause() {
    if (_controller != null && _isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.date, style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Video Player
          Expanded(
            child: Center(
              child:
                  _isInitialized
                      ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_controller!),
                              if (!_isPlaying)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      size: 64,
                                      color: Colors.white,
                                    ),
                                    onPressed: _togglePlayPause,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                      : const CircularProgressIndicator(color: Colors.white),
            ),
          ),

          // Video Info Section
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji and Description
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.emoji.isNotEmpty) ...[
                      Text(widget.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        widget.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Video Controls
                if (_isInitialized)
                  Column(
                    children: [
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF009688),
                          bufferedColor: Colors.grey,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatDuration(_controller!.value.position),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Text(
                            ' / ',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            _formatDuration(_controller!.value.duration),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
