import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'dart:io';
import 'video_detail_screen.dart';

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key}) : super(key: key);

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? cameras;
  bool _isRecording = false;
  bool _isFrontCamera = true;
  bool _isFlashOn = false;
  Duration _recordingDuration = Duration.zero;
  Duration _maxDuration = Duration(seconds: 30);
  String? _recordedVideoPath;
  final List<String> _segmentPaths = [];
  bool _isProcessingVideo = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();

      if (cameraStatus != PermissionStatus.granted ||
          microphoneStatus != PermissionStatus.granted) {
        return;
      }

      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        return;
      }

      // Dispose previous controller
      await _controller?.dispose();

      _controller = CameraController(
        cameras![_isFrontCamera ? 0 : 1],
        ResolutionPreset.medium,
        enableAudio: true,
      );

      _initializeControllerFuture = _controller!.initialize();

      // Wait for initialization to complete
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _startRecording() async {
    if (_controller != null && !_isRecording) {
      try {
        await _initializeControllerFuture;
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
          _segmentPaths.clear();
        });
        _startTimer();
      } catch (e) {
        print('Error starting recording: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_controller != null && _isRecording) {
      try {
        print('Stopping recording...');
        final xfile = await _controller!.stopVideoRecording();
        _segmentPaths.add(xfile.path);
        print('Added segment: ${xfile.path}');
        print('Total segments: ${_segmentPaths.length}');

        setState(() {
          _isRecording = false;
          _isProcessingVideo = true;
        });

        String finalPath;
        if (_segmentPaths.length == 1) {
          finalPath = _segmentPaths.first;
          print('Single segment, using: $finalPath');
        } else {
          print('Merging ${_segmentPaths.length} segments...');

          // Use the same directory as the first segment instead of path_provider
          final firstSegmentDir = Directory(_segmentPaths.first).parent;
          final listFile = File('${firstSegmentDir.path}/segments.txt');
          final outputFile = File(
            '${firstSegmentDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.mp4',
          );

          // Create the concat file with proper paths
          final listContent = _segmentPaths
              .map((p) => "file '${p.replaceAll('\\', '/')}'")
              .join('\n');
          await listFile.writeAsString(listContent);
          print('Created concat file: ${listFile.path}');
          print('Concat content:\n$listContent');

          // Execute FFmpeg command
          final command =
              "-f concat -safe 0 -i \"${listFile.path.replaceAll('\\', '/')}\" -c copy \"${outputFile.path.replaceAll('\\', '/')}\"";
          print('FFmpeg command: $command');

          final session = await FFmpegKit.executeAsync(command);
          final returnCode = await session.getReturnCode();
          final logs = await session.getLogs();

          print('FFmpeg return code: $returnCode');
          for (final log in logs) {
            print('FFmpeg log: ${log.getMessage()}');
          }

          if (returnCode != null && returnCode.isValueSuccess()) {
            finalPath = outputFile.path;
            print('Merge successful: $finalPath');
          } else {
            // Fallback: use first segment if merge fails
            finalPath = _segmentPaths.first;
            print('Merge failed, using first segment: $finalPath');
          }
        }

        setState(() {
          _recordedVideoPath = finalPath;
          _isProcessingVideo = false;
        });
        print('Final video path set: $_recordedVideoPath');

        // Add a small delay to ensure state is updated
        await Future.delayed(Duration(milliseconds: 100));

        if (mounted) {
          _navigateToVideoPreview();
        }
      } catch (e) {
        print('Error stopping recording: $e');
        // Even if there's an error, try to navigate with whatever we have
        if (_segmentPaths.isNotEmpty && mounted) {
          setState(() {
            _recordedVideoPath = _segmentPaths.first;
            _isRecording = false;
            _isProcessingVideo = false;
          });
          _navigateToVideoPreview();
        }
      }
    } else {
      print(
        'Cannot stop recording: controller=${_controller != null}, isRecording=$_isRecording',
      );
    }
  }

  void _startTimer() {
    if (_isRecording) {
      Future.delayed(Duration(seconds: 1), () {
        if (_isRecording && mounted) {
          setState(() {
            _recordingDuration = Duration(
              seconds: _recordingDuration.inSeconds + 1,
            );
          });
          print(
            'Timer tick: ${_recordingDuration.inSeconds}s / ${_maxDuration.inSeconds}s',
          );
          if (_recordingDuration < _maxDuration) {
            _startTimer();
          } else {
            print('Timer reached max duration, stopping recording...');
            _stopRecording();
          }
        }
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.setFlashMode(
          _isFlashOn ? FlashMode.off : FlashMode.torch,
        );
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
        print('Flash ${_isFlashOn ? 'on' : 'off'}');
      } catch (e) {
        print('Error toggling flash: $e');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.length <= 1) return;

    // Don't allow camera switching during recording
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot switch camera while recording'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print('Switching camera (not recording)...');
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isFlashOn = false; // Reset flash when switching camera
    });
    await _initializeCamera();
  }

  void _navigateToVideoPreview() {
    print('Navigating to video detail with path: $_recordedVideoPath');
    if (_recordedVideoPath != null && _recordedVideoPath!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => VideoDetailScreen(videoPath: _recordedVideoPath!),
        ),
      );
    } else {
      print('Error: No video path available for preview');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: No video recorded'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null &&
              _controller!.value.isInitialized) {
            final mediaSize = MediaQuery.of(context).size;
            final scale =
                1 / (_controller!.value.aspectRatio * mediaSize.aspectRatio);

            return Stack(
              children: [
                ClipRect(
                  clipper: _MediaSizeClipper(mediaSize),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: CameraPreview(_controller!),
                  ),
                ),

                // Top bar
                Positioned(
                  top: 40,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          // '${_recordingDuration.inMinutes}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}s / ${_maxDuration.inSeconds}s',
                          '${_recordingDuration.inSeconds}s / ${_maxDuration.inSeconds}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // IconButton(
                      //   icon: Icon(
                      //     _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      //     color: _isFlashOn ? Colors.yellow : Colors.white,
                      //   ),
                      //   onPressed: _toggleFlash,
                      // ),
                      IconButton(
                        icon: const Icon(
                          Icons.cameraswitch,
                          color: Colors.white,
                        ),
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                ),

                // Record button
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            print(
                              'Record button tapped. isRecording: $_isRecording',
                            );
                            if (_isRecording) {
                              print('Calling _stopRecording...');
                              _stopRecording();
                            } else {
                              print('Calling _startRecording...');
                              _startRecording();
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Center(
                              child:
                                  _isRecording
                                      ? Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Colors.white70,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      )
                                      : Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                            ),
                          ),
                        ),
                        if (!_isRecording && !_isProcessingVideo) ...[
                          SizedBox(height: 12),
                          Text(
                            'Tap to start recording',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (_isProcessingVideo) ...[
                          SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Processing video...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Recording indicator
                if (_isRecording)
                  Positioned(
                    top: 100,
                    left: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'REC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Camera Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Failed to initialize camera',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _initializeCamera();
                        });
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Initializing Camera...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;

  const VideoPreviewScreen({Key? key, required this.videoPath})
    : super(key: key);

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedEmoji;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  final List<String> _emojis = [
    '😊',
    '😄',
    '😃',
    '😁',
    '🤗',
    '😍',
    '🥰',
    '😘',
    '😌',
    '😇',
    '🤩',
    '😎',
    '🤔',
    '😏',
    '😒',
    '😔',
    '😢',
    '😭',
    '😤',
    '😠',
    '😡',
    '🤯',
    '😳',
    '😱',
    '😨',
    '😰',
    '😥',
    '😓',
    '🤗',
    '🤭',
    '🤫',
    '🤥',
    '😴',
    '🤤',
    '😪',
    '😵',
    '🤐',
    '🤢',
    '🤮',
    '🤧',
    '😷',
    '🤒',
    '🤕',
    '🤑',
    '🤠',
    '😈',
    '👿',
    '👹',
    '👺',
    '💀',
    '👻',
    '👽',
    '👾',
    '🤖',
    '💩',
    '😺',
    '😸',
    '😹',
    '😻',
    '😼',
    '😽',
    '🙀',
    '😿',
    '😾',
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.videoPath));
      await _videoController!.initialize();

      // Add listener to update UI when video state changes
      _videoController!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text('Video Preview', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _saveVideo,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Preview
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child:
                  _isVideoInitialized && _videoController != null
                      ? Stack(
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                          ),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_videoController!.value.isPlaying) {
                                    _videoController!.pause();
                                  } else {
                                    _videoController!.play();
                                  }
                                });
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _videoController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Loading video...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
            ),
          ),

          // Description Section
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What made you smile today?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Description Input
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share what made you smile today...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  SizedBox(height: 24),

                  Text(
                    'How are you feeling?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Emoji Selection
                  Container(
                    height: 120,
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        childAspectRatio: 1,
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
                                      ? Colors.green.shade100
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveVideo() {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedEmoji == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an emoji'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Here you would typically save the video with description and emoji
    // For now, just show success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Video saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
