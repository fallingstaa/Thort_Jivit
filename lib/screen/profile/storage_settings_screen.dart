import 'package:flutter/material.dart';
import 'package:thort_jivit/services/local_video_storage_service.dart';
import 'package:thort_jivit/services/video_compression_service.dart';
import 'package:thort_jivit/services/background_sync_service.dart';
import 'package:thort_jivit/services/firestore_service.dart';
import '../payment/aba_payment_screen.dart';

class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  final LocalVideoStorageService _localStorage = LocalVideoStorageService();
  final VideoCompressionService _compressionService = VideoCompressionService();
  final BackgroundSyncService _syncService = BackgroundSyncService();
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, dynamic> _storageUsage = {};
  Map<String, dynamic> _compressionStats = {};
  Map<String, dynamic> _compressionSavings = {};
  Map<String, dynamic> _syncStats = {};
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usage = await _localStorage.getStorageUsage();
      final stats = await _compressionService.getCompressionStats();
      final savings = await _compressionService.calculateCompressionSavings();
      final syncStats = await _syncService.getSyncStats();
      final isPremium = await _firestoreService.isUserPremium();

      setState(() {
        _storageUsage = usage;
        _compressionStats = stats;
        _compressionSavings = savings;
        _syncStats = syncStats;
        _isPremium = isPremium;
        _isLoading = false;
      });
    } catch (e) {
      print('[STORAGE_SETTINGS] Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _compressOldVideos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compress Old Videos'),
        content: Text(
          'This will compress videos older than 4 weeks to save space.\n\n'
          'Estimated savings: ${(_compressionSavings['estimatedSavingsMB'] ?? 0.0).toStringAsFixed(1)} MB\n'
          'Videos to compress: ${_compressionSavings['videoCount'] ?? 0}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Compress'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _compressionService.compressOldVideos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['compressed'] > 0
                  ? 'Compressed ${result['compressed']} videos, saved ${(result['savedMB'] as double).toStringAsFixed(1)} MB'
                  : 'No videos to compress',
            ),
            backgroundColor: result['success'] ? Colors.green : Colors.orange,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _syncNow() async {
    // Free users cannot trigger cloud sync; show message instead of syncing.
    final isPremium = await _firestoreService.isUserPremium();
    if (!isPremium) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cloud sync is a premium feature. Your videos are stored safely on this device.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _syncService.performSync(forceSync: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['uploaded'] > 0
                  ? 'Synced ${result['uploaded']} videos to cloud'
                  : 'All videos already synced',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF009688)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Storage Settings',
          style: TextStyle(
            color: Color(0xFF009688),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF009688)),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF009688),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Storage Overview Card
                  _buildCard(
                    isDark: isDark,
                    title: 'Storage Overview',
                    icon: Icons.storage,
                    children: [
                      _buildStatRow(
                        'Total Storage Used',
                        '${(_storageUsage['totalMB'] ?? 0.0).toStringAsFixed(1)} MB',
                        isDark,
                      ),
                      _buildStatRow(
                        'Total Videos',
                        '${_storageUsage['videoCount'] ?? 0}',
                        isDark,
                      ),
                      _buildStatRow(
                        'Compressed Videos',
                        '${_storageUsage['compressedCount'] ?? 0}',
                        isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Compression Stats Card
                  _buildCard(
                    isDark: isDark,
                    title: 'Compression',
                    icon: Icons.compress,
                    children: [
                      _buildStatRow(
                        'Videos Compressed',
                        '${_compressionStats['compressedVideos'] ?? 0} / ${_compressionStats['totalVideos'] ?? 0}',
                        isDark,
                      ),
                      _buildStatRow(
                        'Space Saved',
                        '${(_compressionStats['savedMB'] ?? 0.0).toStringAsFixed(1)} MB',
                        isDark,
                      ),
                      if (_compressionSavings['videoCount'] != null &&
                          _compressionSavings['videoCount'] > 0)
                        _buildStatRow(
                          'Potential Savings',
                          '${(_compressionSavings['estimatedSavingsMB'] ?? 0.0).toStringAsFixed(1)} MB',
                          isDark,
                          color: Colors.green,
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _compressOldVideos,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.compress, size: 20),
                          label: Text(
                            _isProcessing
                                ? 'Compressing...'
                                : 'Compress Old Videos',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sync Status Card
                  _buildCard(
                    isDark: isDark,
                    title: 'Cloud Sync',
                    icon: Icons.cloud_sync,
                    children: [
                      if (_isPremium) ...[
                        _buildStatRow(
                          'Synced to Cloud',
                          '${_syncStats['uploaded'] ?? 0}',
                          isDark,
                          color: Colors.green,
                        ),
                        _buildStatRow(
                          'Pending Upload',
                          '${_syncStats['pending'] ?? 0}',
                          isDark,
                          color: _syncStats['pending'] != null &&
                                  _syncStats['pending'] > 0
                              ? Colors.orange
                              : null,
                        ),
                        if (_syncStats['failed'] != null &&
                            _syncStats['failed'] > 0)
                          _buildStatRow(
                            'Failed Uploads',
                            '${_syncStats['failed']}',
                            isDark,
                            color: Colors.red,
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _syncNow,
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.sync, size: 20),
                            label: Text(
                              _isProcessing ? 'Syncing...' : 'Force Sync Now',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF009688),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF009688).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF009688).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                size: 48,
                                color: Color(0xFF009688),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Cloud Sync is Premium',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upgrade to premium to automatically back up your videos to the cloud.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFFB0B0B0)
                                      : const Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ABAPaymentScreen(),
                                      ),
                                    ).then((_) {
                                      // Reload data after returning from payment
                                      _loadData();
                                    });
                                  },
                                  icon: const Icon(Icons.star, size: 20),
                                  label: const Text('Go Premium'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF009688),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info Card
                  _buildCard(
                    isDark: isDark,
                    title: 'About Storage',
                    icon: Icons.info_outline,
                    children: [
                      Text(
                        _isPremium
                            ? '• Videos are saved locally first for fast access\n'
                                '• Automatic sync to cloud happens nightly (WiFi + charging)\n'
                                '• Old videos (4+ weeks) can be compressed to save space\n'
                                '• Weekly recaps are kept in both local and cloud storage'
                            : '• Videos are saved locally on your device\n'
                                '• Old videos (4+ weeks) can be compressed to save space\n'
                                '• Upgrade to premium for cloud backup and automatic sync',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFFB0B0B0)
                              : const Color(0xFF666666),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF009688),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    bool isDark, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? const Color(0xFFB0B0B0)
                  : const Color(0xFF666666),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ??
                  (isDark ? Colors.white : const Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }
}

