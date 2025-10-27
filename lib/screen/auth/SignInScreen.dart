import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'SignUpScreen.dart';
import 'ForgotPasswordScreen.dart'; // <-- Forgot password screen

// --- Firebase imports ---
import 'package:firebase_auth/firebase_auth.dart';
import '../../main_navigation.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isPasswordVisible = false;

  // --- Controllers for email/password ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- Firebase Auth instance ---
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSignInForm(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
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
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006045),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to continue your life story',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // --- Sign-in form ---
  Widget _buildSignInForm() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            hint: 'your@email.com',
            icon: Icons.email_outlined,
            controller: _emailController,
          ),
          const SizedBox(height: 16),
          _buildPasswordHeader(),
          const SizedBox(height: 8),
          _buildPasswordField(),
          const SizedBox(height: 20),
          _buildSignInButton(),
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          _buildSocialLoginButtons(),
        ],
      ),
    );
  }

  // --- Password row with forgot link ---
  Widget _buildPasswordHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Password',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        GestureDetector(
          onTap: () {
            // Navigate to ForgotPasswordScreen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ForgotPasswordScreen(),
              ),
            );
          },
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: Color(0xFF008060),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: '********',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  // --- Show error dialog ---
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFE53935),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 15, color: Color(0xFF424242)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFF008060),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // --- Validate inputs ---
  bool _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog('Email Required', 'Please enter your email address.');
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showErrorDialog('Invalid Email', 'Please enter a valid email address.');
      return false;
    }

    if (password.isEmpty) {
      _showErrorDialog('Password Required', 'Please enter your password.');
      return false;
    }

    return true;
  }

  // --- Sign in button with Firebase logic ---
  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Validate inputs first
          if (!_validateInputs()) return;

          try {
            await _auth.signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
            // --- Navigate to MainNavigation on success ---
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainNavigation()),
              );
            }
          } on FirebaseAuthException catch (e) {
            String errorMessage = 'Sign in failed';
            if (e.code == 'user-not-found') {
              errorMessage = 'No account found with this email.';
            } else if (e.code == 'wrong-password') {
              errorMessage = 'Incorrect password. Please try again.';
            } else if (e.code == 'invalid-email') {
              errorMessage = 'Invalid email address format.';
            } else if (e.code == 'user-disabled') {
              errorMessage = 'This account has been disabled.';
            } else if (e.message != null) {
              errorMessage = e.message!;
            }
            _showErrorDialog('Sign In Failed', errorMessage);
          } catch (e) {
            _showErrorDialog('Error', 'An unexpected error occurred.');
          }
        },
        icon: const Icon(Icons.email_outlined, color: Colors.white),
        label: const Text(
          'Sign in with Email',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008060),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(500),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'or continue with',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        _buildSocialButton(
          label: 'Continue with Google',
          iconAsset: 'assets/images/icons8-google-48.png',
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        _buildSocialButton(
          label: 'Continue with Facebook',
          iconAsset: 'assets/images/icons8-facebook-logo-48.png',
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        _buildSocialButton(
          isIconData: true,
          iconData: Icons.person_outline,
          label: 'Continue as Guest',
          onPressed: () {},
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            children: [
              const TextSpan(text: "Don't have an account? "),
              TextSpan(
                text: 'Sign up',
                style: const TextStyle(
                  color: Color(0xFF008060),
                  fontWeight: FontWeight.bold,
                ),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    String? iconAsset,
    IconData? iconData,
    bool isIconData = false,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon:
            isIconData
                ? Icon(iconData, color: Colors.black54)
                : Image.asset(iconAsset!, height: 20),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: GestureDetector(
          onTap: () {
            // TODO: Add navigation logic to welcome screen
          },
          child: const Text(
            'Back to welcome screen',
            style: TextStyle(
              color: Color(0xFF008060),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
