import 'package:flutter/material.dart';
import 'auth/SignInScreen.dart';
import 'auth/SignUpScreen.dart';
import 'package:thort_jivit/screen/auth/SignInScreen.dart';
import 'package:thort_jivit/screen/auth/SignUpScreen.dart';

class WelcomeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path1 = Path();
    path1.moveTo(size.width, 0);
    path1.lineTo(size.width, size.height * 0.4);
    path1.cubicTo(
      size.width * 0.85,
      size.height * 0.55,
      size.width * 0.7,
      size.height * 0.45,
      size.width * 0.65,
      size.height * 0.35,
    );
    path1.lineTo(size.width, size.height * 0.3);
    path1.close();

    final Paint paint2 = Paint()
      ..color = const Color(0xFFF0F4F6)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width, size.height);
    path2.lineTo(size.width * 0.5, size.height);
    path2.cubicTo(
      size.width * 0.7,
      size.height * 0.9,
      size.width * 0.95,
      size.height * 0.8,
      size.width,
      size.height * 0.7,
    );
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Widget _buildLogo(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(4),
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
      child: ClipOval(
        child: Image.asset('assets/images/THOT.png', fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    const Color primaryBrandGreen = Color(0xFF008060);

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 600,
              height: 750,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/image.png"),
                  fit: BoxFit.cover,
                  alignment: Alignment(0.0, 100.0),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Container(
              height: screenSize.height,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),
                  Center(child: _buildLogo(context)),
                  const SizedBox(height: 32),
                  Text(
                    'THOTH JIVIT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: primaryBrandGreen,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Capture your life, one moment at',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Record short daily clips and watch your life story unfold through beautiful weekly and monthly compilations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),

                  // Sign In Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBrandGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Create Account Button
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryBrandGreen, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBrandGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'By continuing, you agree to our Terms and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black45),
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
