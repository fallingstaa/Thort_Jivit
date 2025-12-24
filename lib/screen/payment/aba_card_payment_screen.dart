import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/aba_payment_service.dart';

class ABACardPaymentScreen extends StatefulWidget {
  final String amount;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;

  const ABACardPaymentScreen({
    super.key,
    required this.amount,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
  });

  @override
  State<ABACardPaymentScreen> createState() => _ABACardPaymentScreenState();
}

class _ABACardPaymentScreenState extends State<ABACardPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _tranId;
  bool _isCheckingPayment = false;

  static const String _successUrl = "https://example.com/payway/success";

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            // When PayWay redirects to the configured success URL, verify payment
            if (url.startsWith(_successUrl)) {
              if (_tranId != null && !_isCheckingPayment) {
                await _verifyPaymentAndClose();
              } else {
                // No transaction ID, just close
                if (mounted) {
                  Navigator.of(context).pop({
                    'success': false,
                    'tranId': _tranId,
                  });
                }
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _loadCheckout();
  }

  Future<void> _verifyPaymentAndClose() async {
    if (_tranId == null || _isCheckingPayment) return;

    setState(() {
      _isCheckingPayment = true;
      _isLoading = true;
    });

    try {
      // Check transaction status
      final result = await ABAPaymentService.checkTransactionStatus(_tranId!);
      
      if (!mounted) return;

      if (result['success'] == true && result['status'] == 'success') {
        // Payment verified successfully
        Navigator.of(context).pop({
          'success': true,
          'tranId': _tranId,
        });
      } else {
        // Payment not confirmed yet
        Navigator.of(context).pop({
          'success': false,
          'tranId': _tranId,
          'message': result['message'] ?? 'Payment verification pending',
        });
      }
    } catch (e) {
      if (!mounted) return;
      // Return transaction ID even if check failed, so parent can retry
      Navigator.of(context).pop({
        'success': false,
        'tranId': _tranId,
        'message': 'Error verifying payment: $e',
      });
    }
  }

  Future<void> _loadCheckout() async {
    setState(() => _isLoading = true);

    final result = await ABAPaymentService.generateCardCheckoutUri(
      amount: widget.amount,
      firstName: widget.firstName,
      lastName: widget.lastName,
      phone: widget.phone,
      email: widget.email,
      returnUrl: "https://example.com/payway/return",
      continueSuccessUrl: _successUrl,
    );

    _tranId = result['tranId'] as String;
    final checkoutUri = result['uri'] as Uri;

    if (!mounted) return;
    await _controller.loadRequest(checkoutUri);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
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
          onPressed: () => Navigator.of(context).pop({
            'success': false,
            'tranId': _tranId,
          }),
        ),
        title: Text(
          'Pay with Card',
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
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF009688),
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    Text(
                      'Loading payment gateway...',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFE0E0E0)
                            : const Color(0xFF1A1A1A),
                        fontSize: isTablet ? 16 : 14,
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
}
