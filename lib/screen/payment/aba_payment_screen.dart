import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/aba_payment_service.dart';
import '../../services/firestore_service.dart';
import 'aba_card_payment_screen.dart';

class ABAPaymentScreen extends StatefulWidget {
  const ABAPaymentScreen({super.key});

  @override
  State<ABAPaymentScreen> createState() => _ABAPaymentScreenState();
}

class _ABAPaymentScreenState extends State<ABAPaymentScreen> with WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String _statusMessage = "";
  String? _pendingTranId;
  bool _isCheckingPayment = false;
  int _checkAttempts = 0;
  static const int _maxCheckAttempts = 30; // Check for up to 5 minutes (30 * 10 seconds)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes, check payment status if we have a pending transaction
    if (state == AppLifecycleState.resumed && _pendingTranId != null && !_isCheckingPayment) {
      _checkPaymentStatus();
    }
  }

  Future<void> _markPaymentSuccess() async {
    try {
      await _firestoreService.setUserPremium(true);
      if (!mounted) return;
      setState(() {
        _statusMessage =
            "Payment successful! Your account is now premium. Cloud backup and weekly processing are enabled.";
        _pendingTranId = null; // Clear pending transaction
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful. Premium features unlocked.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      // Wait a moment before navigating back
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = "Payment succeeded but failed to update account: $e";
      });
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_pendingTranId == null || _isCheckingPayment) return;
    if (_checkAttempts >= _maxCheckAttempts) {
      setState(() {
        _statusMessage = "Payment check timeout. Please refresh or try again.";
        _isCheckingPayment = false;
      });
      return;
    }

    setState(() {
      _isCheckingPayment = true;
      _checkAttempts++;
      if (_checkAttempts == 1) {
        _statusMessage = "Checking payment status...";
      } else {
        _statusMessage = "Checking payment status... (attempt $_checkAttempts)";
      }
    });

    try {
      final result = await ABAPaymentService.checkTransactionStatus(_pendingTranId!);
      
      if (!mounted) return;

      if (result['success'] == true && result['status'] == 'success') {
        // Payment successful
        await _markPaymentSuccess();
      } else {
        // Payment not yet completed or failed - retry after delay
        setState(() {
          _isCheckingPayment = false;
          _statusMessage = result['message'] ?? 'Payment is still pending. Please complete the payment in ABA Mobile.';
        });
        
        // Schedule next check in 10 seconds if not exceeded max attempts
        if (_checkAttempts < _maxCheckAttempts && mounted) {
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted && _pendingTranId != null) {
              _checkPaymentStatus();
            }
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingPayment = false;
        _statusMessage = "Error checking payment: $e";
      });
      
      // Retry on error after delay
      if (_checkAttempts < _maxCheckAttempts && mounted) {
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _pendingTranId != null) {
            _checkPaymentStatus();
          }
        });
      }
    }
  }

  Future<void> _handlePayment() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Initiating transaction...";
    });

    // Hardcoded test values as per ABA example
    const amount = "2.00"; // Premium subscription price
    const firstName = "Thort"; // Test Name
    const lastName = "Jivit";
    const phone = "012345678";
    const email = "test@thortjivit.com";

    final items = [
      {'name': 'Premium Plan', 'quantity': '1', 'price': amount},
    ];

    try {
      final result = await ABAPaymentService.createDeeplinkPayment(
        amount: amount,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        itemsData: items,
        returnUrl: "https://example.com/payway/return",
        continueSuccessUrl: "https://example.com/payway/success",
      );

      if (result != null && result['deeplink'] != null) {
        final deeplink = result['deeplink'] as String;
        final tranId = result['tranId'] as String;
        
        // Store transaction ID for later verification
        setState(() {
          _pendingTranId = tranId;
          _statusMessage = "Launching ABA Mobile... Complete the payment and return to this app.";
        });
        
        await ABAPaymentService.launchDeepLink(deeplink);
        
        // Wait a moment, then start checking payment status
        await Future.delayed(const Duration(seconds: 2));
        if (mounted && _pendingTranId != null) {
          _checkPaymentStatus();
        }
      } else {
        setState(() {
          _statusMessage = "Failed to get payment link. Check console.";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          'Upgrade to Premium',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isTablet ? 32 : 24),

              // Premium Plan Card
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
                      'Premium Plan',
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

              // Benefits Card
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
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
                            color: const Color(0xFF009688).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.checkCircle,
                            size: 20,
                            color: Color(0xFF009688),
                          ),
                        ),
                        SizedBox(width: isTablet ? 14 : 12),
                        Text(
                          'What\'s Included',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFE0E0E0)
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildBenefitRow(
                      icon: FontAwesomeIcons.cloudArrowUp,
                      text: 'Cloud Backup',
                      isDark: isDark,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: isTablet ? 16 : 14),
                    _buildBenefitRow(
                      icon: FontAwesomeIcons.video,
                      text: 'Weekly Recaps',
                      isDark: isDark,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: isTablet ? 16 : 14),
                    _buildBenefitRow(
                      icon: FontAwesomeIcons.shield,
                      text: 'Secure Storage',
                      isDark: isDark,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: isTablet ? 16 : 14),
                    _buildBenefitRow(
                      icon: FontAwesomeIcons.infinity,
                      text: 'Unlimited Uploads',
                      isDark: isDark,
                      isTablet: isTablet,
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 32 : 24),

              // Payment Methods Card
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
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
                            color: const Color(0xFF009688).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.creditCard,
                            size: 20,
                            color: Color(0xFF009688),
                          ),
                        ),
                        SizedBox(width: isTablet ? 14 : 12),
                        Text(
                          'Payment Methods',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFE0E0E0)
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 24 : 20),

                    // ABA Mobile Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handlePayment,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const FaIcon(FontAwesomeIcons.mobileScreen, size: 18),
                        label: Text(
                          _isLoading ? 'Processing...' : 'Pay with ABA Mobile',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF009688).withOpacity(0.5),
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

                    SizedBox(height: isTablet ? 16 : 14),

                    // Divider with "OR"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFEEEEEE),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                          ),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFB0B0B0)
                                  : const Color(0xFF666666),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFEEEEEE),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isTablet ? 16 : 14),

                    // Credit Card Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result =
                              await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ABACardPaymentScreen(
                                amount: "2.00",
                                firstName: "Thort",
                                lastName: "Jivit",
                                phone: "012345678",
                                email: "test@thortjivit.com",
                              ),
                            ),
                          );

                          // Card payment screen returns {'success': bool, 'tranId': String}
                          if (result != null &&
                              result['success'] == true &&
                              mounted) {
                            await _markPaymentSuccess();
                          } else if (result != null &&
                              result['tranId'] != null &&
                              mounted) {
                            // Payment initiated but not confirmed, check status
                            setState(() {
                              _pendingTranId = result['tranId'] as String;
                            });
                            _checkPaymentStatus();
                          }
                        },
                        icon: const FaIcon(FontAwesomeIcons.creditCard, size: 18),
                        label: const Text(
                          'Pay with Credit/Debit Card',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF009688),
                          side: const BorderSide(
                            color: Color(0xFF009688),
                            width: 2,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 18 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 24 : 20),

              // Status Message
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: _isCheckingPayment
                        ? Colors.blue.withOpacity(0.1)
                        : _statusMessage.contains('successful') ||
                                _statusMessage.contains('success')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isCheckingPayment
                          ? Colors.blue.withOpacity(0.3)
                          : _statusMessage.contains('successful') ||
                                  _statusMessage.contains('success')
                              ? Colors.green.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FaIcon(
                        _isCheckingPayment
                            ? FontAwesomeIcons.clockRotateLeft
                            : _statusMessage.contains('successful') ||
                                    _statusMessage.contains('success')
                                ? FontAwesomeIcons.circleCheck
                                : FontAwesomeIcons.circleInfo,
                        size: 20,
                        color: _isCheckingPayment
                            ? Colors.blue
                            : _statusMessage.contains('successful') ||
                                    _statusMessage.contains('success')
                                ? Colors.green
                                : Colors.orange,
                      ),
                      SizedBox(width: isTablet ? 14 : 12),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 13,
                            color: isDark
                                ? const Color(0xFFE0E0E0)
                                : const Color(0xFF1A1A1A),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: isTablet ? 40 : 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String text,
    required bool isDark,
    required bool isTablet,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF009688).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(
            icon,
            size: 18,
            color: const Color(0xFF009688),
          ),
        ),
        SizedBox(width: isTablet ? 14 : 12),
        Text(
          text,
          style: TextStyle(
            fontSize: isTablet ? 16 : 15,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
