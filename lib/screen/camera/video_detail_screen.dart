import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:thort_jivit/services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thort_jivit/screen/videos/videos_screen.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoPath;

  const VideoDetailScreen({super.key, required this.videoPath});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
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
    print('[VIDEO_DETAIL] Initializing with video path: ${widget.videoPath}');
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print('[VIDEO_DETAIL] Creating VideoPlayerController...');
      print('[VIDEO_DETAIL] Platform: kIsWeb=$kIsWeb');
      print('[VIDEO_DETAIL] Video path: ${widget.videoPath}');

      if (kIsWeb) {
        // On web, the path is likely a blob URL
        print('[VIDEO_DETAIL] Using network controller for web');
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoPath),
        );
      } else {
        // On mobile/desktop, use file controller
        final videoFile = File(widget.videoPath);

        // Check if file exists
        if (!await videoFile.exists()) {
          throw Exception('Video file does not exist: ${widget.videoPath}');
        }

        print(
          '[VIDEO_DETAIL] Video file exists, size: ${await videoFile.length()} bytes',
        );
        _controller = VideoPlayerController.file(videoFile);
      }

      print('[VIDEO_DETAIL] Initializing controller...');
      await _controller!.initialize();
      print('[VIDEO_DETAIL] Controller initialized successfully');

      _controller!.setLooping(true);
      _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
      print('[VIDEO_DETAIL] Video is now playing');
    } catch (e) {
      print('[VIDEO_DETAIL] Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        print('[VIDEO_DETAIL] Gallery video selected: ${video.path}');

        // Dispose old controller
        await _controller?.dispose();

        setState(() {
          _galleryVideoPath = video.path;
          _isInitialized = false;
          _hasError = false;
        });

        print('[VIDEO_DETAIL] Gallery video file, initializing...');

        if (kIsWeb) {
          // On web, use network URL
          _controller = VideoPlayerController.networkUrl(
            Uri.parse(_galleryVideoPath!),
          );
        } else {
          // On mobile/desktop, use file
          final videoFile = File(_galleryVideoPath!);

          // Check if file exists
          if (!await videoFile.exists()) {
            throw Exception('Selected video file does not exist');
          }

          _controller = VideoPlayerController.file(videoFile);
        }

        await _controller!.initialize();
        _controller!.setLooping(true);
        _controller!.play();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
        print('[VIDEO_DETAIL] Gallery video initialized successfully');
      }
    } catch (e) {
      print('[VIDEO_DETAIL] Error picking/loading gallery video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error loading gallery video: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: Color(0xFF008060),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Video Detail',
          style: TextStyle(
            color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildVideoPreview(),
            ),
            
            // Emoji Selection Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF008060).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.faceSmile,
                              color: Color(0xFF008060),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'How are you feeling?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
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
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient:
                                            _selectedEmoji == emoji
                                                ? const LinearGradient(
                                                    colors: [Color(0xFF008060), Color(0xFF00A978)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : null,
                                        color:
                                            _selectedEmoji == emoji
                                                ? null
                                                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F8)),
                                        borderRadius: BorderRadius.circular(16),
                                        border: _selectedEmoji == emoji
                                            ? null
                                            : Border.all(
                                                color: isDark
                                                    ? const Color(0xFF3A3A3A)
                                                    : const Color(0xFFE0E0E0),
                                                width: 1.5,
                                              ),
                                        boxShadow: _selectedEmoji == emoji
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF008060).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(
                                          fontSize: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Note Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF008060).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.penToSquare,
                              color: Color(0xFF008060),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Add a note',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'What made this moment special? (optional)',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF757575) : const Color(0xFF999999),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF008060),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
                      ),
                      style: TextStyle(
                        color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        setState(() {
                          _textNote = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Column(
                children: [
                  // Upload from Gallery Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.fileVideo, size: 18),
                      label: const Text(
                        'Upload from Gallery',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F8),
                        foregroundColor: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF008060),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF3A3A3A)
                                : const Color(0xFF008060).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onPressed: _pickVideoFromGallery,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon:
                          _isUploading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                              : const FaIcon(FontAwesomeIcons.cloudArrowUp, size: 18),
                      label: Text(
                        _isUploading ? 'Uploading...' : 'Save Recording',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008060),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: Colors.grey.shade400,
                        shadowColor: const Color(0xFF008060).withOpacity(0.3),
                      ),
                      onPressed: _isUploading ? null : _submitRecord,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_hasError) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 54,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008060),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = '';
                });
                _initializeVideo();
              },
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF008060),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(
                  color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use LayoutBuilder to get available width for proper AspectRatio calculation
    return LayoutBuilder(
      builder: (context, constraints) {
        double aspectRatio = _controller!.value.aspectRatio;

        // Safety check for invalid aspect ratio
        if (aspectRatio <= 0) {
          print(
            '[VIDEO_DETAIL] Invalid aspect ratio: $aspectRatio, defaulting to 1.0',
          );
          aspectRatio = 1.0;
        }

        final width = constraints.maxWidth;
        // Calculate height with a safety cap to prevent extremely tall widgets
        double height = width / aspectRatio;

        // If width is infinite (shouldn't happen in Column but just in case)
        if (width.isInfinite) {
          print('[VIDEO_DETAIL] Warning: Infinite width constraint');
          return AspectRatio(
            aspectRatio: aspectRatio,
            child: VideoPlayer(_controller!),
          );
        }

        // Print debug info
        print(
          '[VIDEO_DETAIL] Layout: width=$width, height=$height, ratio=$aspectRatio',
        );

        return Container(
          width: width,
          height: height,
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height *
                0.8, // Cap height at 80% screen height
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: width,
              height: width / aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
        );
      },
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
      
      // Wait a moment for Firestore to be ready (eventual consistency)
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Show success message - video is saved locally
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording saved! Will sync to cloud automatically.'),
          backgroundColor: Color(0xFF00A991),
          duration: Duration(seconds: 3),
        ),
      );
      
      // Trigger videos screen refresh BEFORE navigating
      VideosScreen.triggerRefresh();
      
      // Go back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      // Force refresh after navigation completes (double trigger for reliability)
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1000));
        VideosScreen.triggerRefresh();
      }
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
