import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:thort_jivit/services/firestore_service.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoPath;

  const VideoDetailScreen({Key? key, required this.videoPath})
    : super(key: key);

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  final FirestoreService _firestoreService = FirestoreService();

  // Form state
  String _selectedEmoji = '';
  String _textNote = '';
  bool _isUploading = false;

  final List<String> _emojis = ['😊', '😢', '😡', '😰', '😌'];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(File(widget.videoPath));
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.play();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00A991)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Save Recording',
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
          Expanded(
            child: Container(color: Colors.black, child: _buildVideoPreview()),
          ),

          // Bottom Sheet with form
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Add Recording Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Text note input
                      TextField(
                        enabled: !_isUploading,
                        decoration: const InputDecoration(
                          labelText: 'Text note (optional)',
                        ),
                        onChanged: (v) => _textNote = v,
                      ),
                      const SizedBox(height: 12),

                      // Emoji picker
                      Wrap(
                        spacing: 8,
                        children:
                            _emojis.map((e) {
                              final isSel = _selectedEmoji == e;
                              return ChoiceChip(
                                label: Text(
                                  e,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                selected: isSel,
                                onSelected:
                                    _isUploading
                                        ? null
                                        : (_) =>
                                            setState(() => _selectedEmoji = e),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (_selectedEmoji.isEmpty || _isUploading)
                                  ? null
                                  : _submitRecord,
                          child:
                              _isUploading
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Submit Record'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A991)),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  Future<void> _submitRecord() async {
    if (_selectedEmoji.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an emoji')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      print('[VIDEO_DETAIL] Saving recording: ${widget.videoPath}');
      print('[VIDEO_DETAIL] Emoji: $_selectedEmoji, Note: $_textNote');

      // Check if can record today
      final canRecord = await _firestoreService.canRecordToday();
      if (!canRecord) {
        throw Exception('You can only record once per day');
      }

      String downloadUrl;
      if (kIsWeb) {
        throw Exception('Recording on web is not yet supported');
      } else {
        // Mobile/Desktop: use file path
        downloadUrl = await _firestoreService.saveRecordedVideo(
          filePath: widget.videoPath,
          emoji: _selectedEmoji,
          textNote: _textNote,
          timestamp: DateTime.now(),
        );
      }

      print('[VIDEO_DETAIL] Recording saved successfully: $downloadUrl');

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Recording saved successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF00A991),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Go back to home (MainNavigation will handle it)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      print('[VIDEO_DETAIL] Error saving recording: $e');

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
