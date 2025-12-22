// lib/screen/videos/clip_selection_screen.dart (MERGE & TITLE PROMPT VERSION)

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:thort_jivit/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

// Model to simplify clip data display
class ClipData {
  final String downloadUrl;
  final String dayId;
  final double durationSeconds;
  final String description;
  final String emoji;

  ClipData.fromMap(Map<String, dynamic> data)
    : downloadUrl = data['storageDownloadUrl'] as String? ?? 'N/A',
      dayId = data['dayId'] as String? ?? 'N/A',
      durationSeconds =
          (data['clipDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      description = data['description'] as String? ?? 'No Description',
      emoji = data['emoji'] as String? ?? '📹';
}

class _ClipInput {
  File? file;
  VideoPlayerController? videoController;
  String description = '';
  String emoji = '';
}

class ClipSelectionScreen extends StatefulWidget {
  final String weekId;
  // Clips are passed from VideosScreen, already filtered and ready to go
  final List<Map<String, dynamic>> clips;

  const ClipSelectionScreen({
    super.key,
    required this.weekId,
    required this.clips,
  });

  @override
  State<ClipSelectionScreen> createState() => _ClipSelectionScreenState();
}

class _ClipSelectionScreenState extends State<ClipSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isProcessingMerge = false;

  final List<_ClipInput> _clips = [];

  // ------------------------------------------------------------------------
  // CLOUD FUNCTION CALL AND TITLE PROMPT
  // ------------------------------------------------------------------------
  Future<void> _startMergeProcess() async {
    if (_isProcessingMerge) return;

    setState(() {
      _isProcessingMerge = true;
    });

    try {
      // 1. Call the Cloud Function
      const functionName = 'processVideoMerge';
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'processVideoMerge',
      );

      final weekToMerge = widget.weekId;

      final result = await callable.call({'weekId': weekToMerge});

      final resultData = result.data as Map<dynamic, dynamic>;

      if (resultData['status'] == 'success') {
        if (mounted) {
          // 2. Merge succeeded - Show title dialog
          await _showTitleDialog(context, weekToMerge);

          // 3. Pop back to VideosScreen
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video merge complete! Check the Processed tab.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        }
      } else {
        throw Exception(resultData['message'] ?? 'Unknown merge error.');
      }
    } on FirebaseFunctionsException catch (e) {
      print('FirebaseFunctionsException: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Merge failed: ${e.message}')));
      }
    } catch (e) {
      print('Merge error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred during merge.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingMerge = false;
        });
      }
    }
  }

  // ------------------------------------------------------------------------
  // TITLE POPUP DIALOG
  // ------------------------------------------------------------------------
  Future<void> _showTitleDialog(BuildContext context, String weekId) async {
    final TextEditingController titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      barrierDismissible: false, // User must enter a title
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Name Your Video'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Give your new compilation a memorable title.'),
                const SizedBox(height: 15),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Video Title',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  onSubmitted: (value) {
                    // Automatically submit when pressing Enter/Done
                    Navigator.of(dialogContext).pop(value);
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(dialogContext).pop(titleController.text);
              },
            ),
          ],
        );
      },
    );
    if (title != null && title.trim().isNotEmpty) {
      // Save the title to the compilation document
      await _firestoreService.updateCompilationTitle(
        weekId: weekId,
        title: title.trim(),
      );
    }
  }

  // ------------------------------------------------------------------------
  // VIDEO PICKING LOGIC
  // ------------------------------------------------------------------------
  Future<void> _pickVideo(int index) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        if (kIsWeb && result.files.single.bytes != null) {
          // Web: create Blob URL and use VideoPlayerController.network
          final blob = html.Blob([result.files.single.bytes!]);
          final blobUrl = html.Url.createObjectUrlFromBlob(blob);
          _clips[index].videoController = VideoPlayerController.network(blobUrl)
            ..initialize().then((_) {
              setState(() {});
            });
        } else if (result.files.single.path != null) {
          // Mobile/Desktop: use file path
          _clips[index].file = File(result.files.single.path!);
          _clips[index].videoController = VideoPlayerController.file(
              _clips[index].file!,
            )
            ..initialize().then((_) {
              setState(() {});
            });
        }
      });
    }
  }

  // ------------------------------------------------------------------------
  // UI BUILDER
  // ------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Convert maps to the ClipData model for easier display
    final List<ClipData> clipData =
        widget.clips.map((map) => ClipData.fromMap(map)).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Confirm Clips for Merge',
          style: TextStyle(
            color: const Color(0xFF009688),
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF009688)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week ID: ${widget.weekId}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 18 : 16,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: isTablet ? 10 : 8),
                Text(
                  'Clips ready for merge: ${clipData.length}',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                SizedBox(height: isTablet ? 18 : 15),
                ElevatedButton.icon(
                  onPressed: _isProcessingMerge ? null : _startMergeProcess,
                  icon:
                      _isProcessingMerge
                          ? SizedBox(
                            width: isTablet ? 22 : 20,
                            height: isTablet ? 22 : 20,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Icon(Icons.merge_type, size: isTablet ? 22 : 20),
                  label: Text(
                    _isProcessingMerge
                        ? 'PROCESSING MERGE...'
                        : 'CONFIRM & START MERGE',
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(isTablet ? 56 : 50),
                    backgroundColor: const Color(0xFF009688),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              itemCount: clipData.length,
              itemBuilder: (context, index) {
                final clip = clipData[index];
                return Container(
                  margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 12 : 8,
                    ),
                    leading: CircleAvatar(
                      radius: isTablet ? 24 : 20,
                      backgroundColor: const Color(0xFF009688).withOpacity(0.1),
                      child: Text(
                        clip.emoji,
                        style: TextStyle(fontSize: isTablet ? 22 : 18),
                      ),
                    ),
                    title: Text(
                      clip.description,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Day: ${clip.dayId} | Duration: ${clip.durationSeconds.toStringAsFixed(1)}s',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: const Color(0xFF666666),
                        ),
                      ),
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
}
