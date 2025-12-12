import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_navigation.dart';
import 'welcome_screen.dart';
// Removed flutter_svg import, using PNG instead

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User session is persisted → go straight to app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        // Not signed in → go to welcome/auth flow
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F9),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.15).round()),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    'assets/images/THOT.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'THOT JIVIT',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006045),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Daily Record Yourself',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
