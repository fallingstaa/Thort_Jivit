import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _webViewFailed = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeWebView();
    } else {
      // For web, open in external browser
      _openInBrowser();
    }
  }

  Future<void> _initializeWebView() async {
    if (kIsWeb) return;
    
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _webViewFailed = false;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _webViewFailed = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading page: ${error.description}'),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Open in Browser',
                      textColor: Colors.white,
                      onPressed: _openInBrowser,
                    ),
                  ),
                );
              }
            },
          ),
        )
        ..loadRequest(Uri.parse('https://www.google.com'));
      
      // Wait a bit to see if initialization succeeds
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      // If webview initialization fails, fall back to browser
      print('[PRIVACY_POLICY] WebView initialization failed: $e');
      if (mounted) {
        setState(() {
          _webViewFailed = true;
        });
        // Automatically fall back to browser
        await Future.delayed(const Duration(milliseconds: 500));
        _openInBrowser();
      }
    }
  }

  Future<void> _openInBrowser() async {
    final url = Uri.parse('https://www.google.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      // Close this screen after opening browser
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: const Color(0xFF009688),
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!kIsWeb && _controller != null)
            IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.arrowRotateRight,
                color: Color(0xFF009688),
                size: 20,
              ),
              onPressed: () {
                _controller?.reload();
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            height: 1,
          ),
        ),
      ),
      body: kIsWeb
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.globe,
                    size: 64,
                    color: Color(0xFF009688),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Opening in browser...',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFE0E0E0)
                          : const Color(0xFF1A1A1A),
                      fontSize: isTablet ? 18 : 16,
                    ),
                  ),
                ],
              ),
            )
          : _webViewFailed
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 32 : 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.triangleExclamation,
                          size: 64,
                          color: Color(0xFFE53935),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Unable to load webview',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFE0E0E0)
                                : const Color(0xFF1A1A1A),
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Opening in external browser instead...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFF6B6B6B),
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _openInBrowser,
                          icon: const FaIcon(
                            FontAwesomeIcons.globe,
                            size: 18,
                          ),
                          label: const Text('Open in Browser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 32 : 24,
                              vertical: isTablet ? 16 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _controller != null
                  ? Stack(
                      children: [
                        WebViewWidget(controller: _controller!),
                        if (_isLoading)
                          Container(
                            color: isDark
                                ? const Color(0xFF121212)
                                : const Color(0xFFF7F8FA),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF009688),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading...',
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
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF009688),
                        ),
                      ),
                    ),
    );
  }
}

