import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/firestore_service.dart';
import '../payment/aba_payment_screen.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  State<PremiumSubscriptionScreen> createState() =>
      _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isPremium = false;
  DateTime? _premiumSince;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final premiumInfo = await _firestoreService.getPremiumInfo();
      if (mounted) {
        setState(() {
          _isPremium = premiumInfo?['isPremium'] as bool? ?? false;
          _premiumSince = premiumInfo?['premiumSince'] as DateTime?;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[PREMIUM_SUBSCRIPTION] Error loading premium status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool get _isExpired {
    if (!_isPremium || _premiumSince == null) return false;
    final expiryDate = _premiumSince!.add(const Duration(days: 30));
    return DateTime.now().isAfter(expiryDate);
  }

  String get _premiumExpiryDate {
    if (_premiumSince == null) {
      final expiryDate = DateTime.now().add(const Duration(days: 30));
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[expiryDate.month - 1]} ${expiryDate.day}, ${expiryDate.year}';
    }
    final expiryDate = _premiumSince!.add(const Duration(days: 30));
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[expiryDate.month - 1]} ${expiryDate.day}, ${expiryDate.year}';
  }

  int get _daysRemaining {
    if (!_isPremium || _premiumSince == null) return 0;
    final expiryDate = _premiumSince!.add(const Duration(days: 30));
    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;
    return expiryDate.difference(now).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 20.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF009688)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isPremium ? 'Premium Subscription' : 'Go Premium',
          style: TextStyle(
            color: const Color(0xFF009688),
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            height: 1,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF009688)),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isTablet ? 32 : 24),

                      if (_isPremium && !_isExpired) ...[
                        // Premium Active Card
                        Container(
                          padding: EdgeInsets.all(isTablet ? 28 : 24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF009688), Color(0xFF00796B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF009688).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.star,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              SizedBox(height: isTablet ? 20 : 16),
                              const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: isTablet ? 8 : 6),
                              const Text(
                                'Premium Active',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: isTablet ? 12 : 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 20 : 16,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_daysRemaining days remaining',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isTablet ? 32 : 24),

                        // Subscription Details Card
                        Container(
                          padding: EdgeInsets.all(isTablet ? 24 : 20),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.3 : 0.04,
                                ),
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
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF009688,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const FaIcon(
                                      FontAwesomeIcons.calendar,
                                      size: 20,
                                      color: Color(0xFF009688),
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 14 : 12),
                                  Text(
                                    'Subscription Details',
                                    style: TextStyle(
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isDark
                                              ? const Color(0xFFE0E0E0)
                                              : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 24 : 20),
                              _buildDetailRow(
                                icon: FontAwesomeIcons.calendarXmark,
                                label: 'Expires On',
                                value: _premiumExpiryDate,
                                isDark: isDark,
                              ),
                              SizedBox(height: isTablet ? 16 : 14),
                              _buildDetailRow(
                                icon: FontAwesomeIcons.dollarSign,
                                label: 'Renewal Price',
                                value: '\$2.00',
                                isDark: isDark,
                              ),
                              SizedBox(height: isTablet ? 20 : 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.circleInfo,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: isTablet ? 12 : 10),
                                    Expanded(
                                      child: Text(
                                        'Your subscription is active. You can renew after it expires on $_premiumExpiryDate.',
                                        style: TextStyle(
                                          fontSize: isTablet ? 14 : 13,
                                          color:
                                              isDark
                                                  ? const Color(0xFFB0B0B0)
                                                  : const Color(0xFF666666),
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isTablet ? 32 : 24),

                        // PRO Benefits Section
                        Container(
                          padding: EdgeInsets.all(isTablet ? 24 : 20),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.3 : 0.04,
                                ),
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
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF009688,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const FaIcon(
                                      FontAwesomeIcons.star,
                                      size: 20,
                                      color: Color(0xFF009688),
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 14 : 12),
                                  Text(
                                    'PRO Benefits',
                                    style: TextStyle(
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isDark
                                              ? const Color(0xFFE0E0E0)
                                              : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 20 : 16),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.cloudArrowUp,
                                text: 'Cloud Backup',
                                description:
                                    'All your videos are automatically backed up to the cloud',
                                isDark: isDark,
                              ),
                              SizedBox(height: isTablet ? 16 : 14),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.video,
                                text: 'Weekly Recaps',
                                description:
                                    'Automatically generate beautiful weekly video recaps',
                                isDark: isDark,
                              ),
                              SizedBox(height: isTablet ? 16 : 14),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.arrowsRotate,
                                text: 'Auto Sync',
                                description:
                                    'Nightly sync when connected to WiFi and charging',
                                isDark: isDark,
                              ),
                              SizedBox(height: isTablet ? 16 : 14),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.shield,
                                text: 'Secure Storage',
                                description:
                                    'Your videos are safely stored in Firebase cloud storage',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isTablet ? 24 : 20),

                        // Disabled Renew Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const FaIcon(FontAwesomeIcons.lock, size: 18),
                            label: const Text(
                              'Renewal Available After Expiry',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.withOpacity(0.3),
                              foregroundColor: Colors.grey,
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 18 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ] else if (_isPremium && _isExpired) ...[
                        // Premium Expired Card
                        Container(
                          padding: EdgeInsets.all(isTablet ? 28 : 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.red.shade400,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.clockRotateLeft,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              SizedBox(height: isTablet ? 20 : 16),
                              const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: isTablet ? 8 : 6),
                              const Text(
                                'Subscription Expired',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: isTablet ? 12 : 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 20 : 16,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Renew now to continue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isTablet ? 32 : 24),

                        // Renew Button (Enabled)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ABAPaymentScreen(),
                                ),
                              ).then((_) {
                                _loadPremiumStatus();
                              });
                            },
                            icon: const FaIcon(
                              FontAwesomeIcons.creditCard,
                              size: 18,
                            ),
                            label: const Text(
                              'Renew Subscription - \$2.00',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF009688),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 18 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Free User - Upgrade Card
                        Container(
                          padding: EdgeInsets.all(isTablet ? 28 : 24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF009688), Color(0xFF00796B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF009688).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.star,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                              SizedBox(height: isTablet ? 24 : 20),
                              const Text(
                                'Upgrade to Premium',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: isTablet ? 12 : 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24 : 20,
                                  vertical: isTablet ? 10 : 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '\$2.00 per month',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isTablet ? 32 : 24),

                        // PRO Benefits Section
                        Container(
                          padding: EdgeInsets.all(isTablet ? 24 : 20),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.3 : 0.04,
                                ),
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
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF009688,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const FaIcon(
                                      FontAwesomeIcons.star,
                                      size: 20,
                                      color: Color(0xFF009688),
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 14 : 12),
                                  Text(
                                    'PRO Benefits',
                                    style: TextStyle(
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isDark
                                              ? const Color(0xFFE0E0E0)
                                              : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 20 : 16),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.cloudArrowUp,
                                text: 'Cloud Backup',
                                description:
                                    'All your videos are automatically backed up to the cloud',
                                isDark: isDark,
                              ),
                              SizedBox(height: isTablet ? 16 : 14),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.video,
                                text: 'Weekly Recaps',
                                description:
                                    'Automatically generate beautiful weekly video recaps',
                                isDark: isDark,
                              ),
                              SizedBox(height: isTablet ? 16 : 14),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.arrowsRotate,
                                text: 'Auto Sync',
                                description:
                                    'Nightly sync when connected to WiFi and charging',
                                isDark: isDark,
                              ),
                              SizedBox(height: isTablet ? 16 : 14),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.shield,
                                text: 'Secure Storage',
                                description:
                                    'Your videos are safely stored in Firebase cloud storage',
                                isDark: isDark,
                              ),
                              SizedBox(height: isTablet ? 16 : 14),
                              _buildBenefitItem(
                                icon: FontAwesomeIcons.infinity,
                                text: 'Unlimited Uploads',
                                description:
                                    'Upload videos for any day in the current week',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isTablet ? 24 : 20),

                        // Upgrade Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ABAPaymentScreen(),
                                ),
                              ).then((_) {
                                _loadPremiumStatus();
                              });
                            },
                            icon: const FaIcon(FontAwesomeIcons.star, size: 18),
                            label: const Text(
                              'Upgrade to Premium',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF009688),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 18 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: isTablet ? 40 : 32),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF009688).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, size: 16, color: const Color(0xFF009688)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF009688),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String text,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF009688).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FaIcon(icon, size: 20, color: const Color(0xFF009688)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009688).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF009688),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFF666666),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
