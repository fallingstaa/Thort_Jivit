import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:thort_jivit/services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _galleryVideoPath;
  final ImagePicker _picker = ImagePicker();
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

  Future<void> _pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _galleryVideoPath = video.path;
        _controller = VideoPlayerController.file(File(_galleryVideoPath!));
        _controller!.initialize().then((_) {
          setState(() {
            _isInitialized = true;
          });
          _controller!.play();
        });
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00A991)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video Detail',
          style: TextStyle(
            color: Color(0xFF00A991),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildVideoPreview(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: <Widget>[
                  Text('Select Emoji:', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            _emojis
                                .map(
                                  (emoji) => GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedEmoji = emoji;
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            _selectedEmoji == emoji
                                                ? Color(0xFF00A991)
                                                : Colors.white,
                                        border: Border.all(
                                          color: Color(0xFF00A991),
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        emoji,
                                        style: TextStyle(
                                          fontSize: 20,
                                          color:
                                              _selectedEmoji == emoji
                                                  ? Colors.white
                                                  : Color(0xFF00A991),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Add a note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (value) {
                  setState(() {
                    _textNote = value;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ElevatedButton.icon(
                    icon: Icon(Icons.video_library),
                    label: Text('Upload from Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00A991),
                    ),
                    onPressed: _pickVideoFromGallery,
                  ),
                  ElevatedButton.icon(
                    icon:
                        _isUploading
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Icon(Icons.cloud_upload),
                    label: Text(_isUploading ? 'Uploading...' : 'Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00A991),
                    ),
                    onPressed: _isUploading ? null : _submitRecord,
                  ),
                ],
              ),
            ),
          ],
        ),
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
      final videoPathToUpload = _galleryVideoPath ?? widget.videoPath;
      String downloadUrl;
      if (kIsWeb) {
        throw Exception('Recording on web is not yet supported');
      } else {
        // Mobile/Desktop: use file path
        downloadUrl = await _firestoreService.saveRecordedVideo(
          filePath: videoPathToUpload,
          emoji: _selectedEmoji,
          textNote: _textNote,
        );
      }
      print('[VIDEO_DETAIL] Recording saved successfully: $downloadUrl');
      if (!mounted) return;
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording saved successfully!'),
          backgroundColor: Color(0xFF00A991),
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
          content: Text('Error saving recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
