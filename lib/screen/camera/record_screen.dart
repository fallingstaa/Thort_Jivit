import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  const RecordScreen({super.key});

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
  final Duration _maxDuration = const Duration(seconds: 30);
  String? _recordedVideoPath;
  final List<String> _segmentPaths = [];
  bool _isProcessingVideo = false;
  String? _cameraError;

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
      // Clear any previous error
      if (mounted) {
        setState(() {
          _cameraError = null;
        });
      }

      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();

      if (cameraStatus != PermissionStatus.granted ||
          microphoneStatus != PermissionStatus.granted) {
        if (mounted) {
          setState(() {
            if (cameraStatus.isPermanentlyDenied) {
              _cameraError =
                  'Camera permission is required. Please grant camera access in settings.';
            } else if (microphoneStatus.isPermanentlyDenied) {
              _cameraError =
                  'Microphone permission is required. Please grant microphone access in settings.';
            } else if (cameraStatus != PermissionStatus.granted) {
              _cameraError =
                  'Camera permission is required to start recording.';
            } else if (microphoneStatus != PermissionStatus.granted) {
              _cameraError =
                  'Microphone permission is required to record audio.';
            }
          });
        }
        return;
      }

      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = 'No cameras available on this device';
          });
        }
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
        setState(() {
          _cameraError = null;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _cameraError = 'Failed to initialize camera: ${e.toString()}';
        });
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
        print('Platform: kIsWeb=$kIsWeb');

        setState(() {
          _isRecording = false;
          _isProcessingVideo = true;
        });

        String finalPath;

        // On web, skip FFmpeg processing and use the recorded path directly
        if (kIsWeb || _segmentPaths.length == 1) {
          finalPath = _segmentPaths.first;
          print('Using recorded path directly: $finalPath');
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
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          _navigateToVideoPreview();
        }
      } catch (e) {
        print('Error stopping recording: $e');
        print('Error stack trace: ${StackTrace.current}');
        // Even if there's an error, try to navigate with whatever we have
        if (_segmentPaths.isNotEmpty && mounted) {
          setState(() {
            _recordedVideoPath = _segmentPaths.first;
            _isRecording = false;
            _isProcessingVideo = false;
          });
          _navigateToVideoPreview();
        } else if (mounted) {
          // Show error message if no segments available
          setState(() {
            _isRecording = false;
            _isProcessingVideo = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save recording: $e'),
              backgroundColor: Colors.red,
            ),
          );
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
      Future.delayed(const Duration(seconds: 1), () {
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
        const SnackBar(
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
        const SnackBar(
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
          // Show permission/camera error if any
          if (_cameraError != null) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Camera Error',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _cameraError!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _cameraError = null;
                                _initializeCamera();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                            ),
                            child: const Text('Back'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          await openAppSettings();
                        },
                        child: const Text(
                          'Open App Settings',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

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
                        padding: const EdgeInsets.symmetric(
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
                                      : const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                            ),
                          ),
                        ),
                        if (!_isRecording && !_isProcessingVideo) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Tap to start recording',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (_isProcessingVideo) ...[
                          const SizedBox(height: 12),
                          const Row(
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
                      padding: const EdgeInsets.symmetric(
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
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
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Camera Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Failed to initialize camera',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _initializeCamera();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Scaffold(
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
