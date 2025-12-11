import 'package:flutter/material.dart';
// Using PNG for logo to ensure compatibility

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F9F9), Color(0xFFEFF7F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // PNG Logo at top
              SizedBox(
                width: 140,
                height: 140,
                child: Image.asset(
                  'assets/images/THOT.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              // Tagline
              const Text(
                'Capture your life, one moment at a time',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Record short daily clips and watch your life story unfold through beautiful weekly and monthly compilations.',
                  style: TextStyle(fontSize: 15, color: Color(0xFF666666)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              // Sign In Button
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: const Color(0xFF006045),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/signin');
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Create Account Button
              SizedBox(
                width: 260,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: const BorderSide(color: Color(0xFF006045), width: 2),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/signup');
                  },
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF006045),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Terms and Privacy
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'By continuing, you agree to our Terms and Privacy Policy',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
