import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// --- Added Firebase imports ---
import 'package:firebase_auth/firebase_auth.dart';
import '../../main_navigation.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // --- State variable to toggle password visibility ---
  bool _isPasswordVisible = false;

  // --- Added controllers to capture name, email, and password ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- Firebase Auth instance ---
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _nameController.dispose();
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
                    _buildSignUpForm(),
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
            'Create Your Account',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start recording your life journey today',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // --- Sign-up form ---
  Widget _buildSignUpForm() {
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
          _buildFormLabel('Full Name'),
          const SizedBox(height: 8),
          _buildTextField(
            hint: 'Meng heng',
            icon: Icons.person_outline,
            controller: _nameController,
          ),
          const SizedBox(height: 16),
          _buildFormLabel('Email'),
          const SizedBox(height: 8),
          _buildTextField(
            hint: 'your@email.com',
            icon: Icons.email_outlined,
            controller: _emailController,
          ),
          const SizedBox(height: 16),
          _buildFormLabel('Password'),
          const SizedBox(height: 8),
          _buildPasswordField(),
          const SizedBox(height: 8),
          _buildPasswordRequirement(),
          const SizedBox(height: 20),
          _buildCreateAccountButton(),
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          _buildSocialLoginButtons(),
          const SizedBox(height: 16),
          _buildSignInLink(),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
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
      onChanged: (value) {
        setState(() {}); // Rebuild to update the tick mark
      },
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

  Widget _buildPasswordRequirement() {
    final bool isValid = _passwordController.text.length >= 8;

    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isValid ? const Color(0xFF4CAF50) : Colors.grey.shade500,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Must be at least 8 characters',
          style: TextStyle(
            color: isValid ? const Color(0xFF4CAF50) : Colors.grey.shade600,
            fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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

  // --- Show success dialog ---
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Success!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: const Text(
              'Your account has been created successfully!',
              style: TextStyle(fontSize: 15, color: Color(0xFF424242)),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const MainNavigation(),
                    ),
                  );
                },
                child: const Text(
                  'Continue',
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
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty) {
      _showErrorDialog('Name Required', 'Please enter your full name.');
      return false;
    }

    if (email.isEmpty) {
      _showErrorDialog('Email Required', 'Please enter your email address.');
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showErrorDialog('Invalid Email', 'Please enter a valid email address.');
      return false;
    }

    if (password.isEmpty) {
      _showErrorDialog('Password Required', 'Please enter a password.');
      return false;
    }

    if (password.length < 8) {
      _showErrorDialog(
        'Weak Password',
        'Password must be at least 8 characters long.',
      );
      return false;
    }

    return true;
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Validate inputs first
          if (!_validateInputs()) return;

          // --- Firebase Authentication logic for sign up ---
          try {
            UserCredential userCredential = await _auth
                .createUserWithEmailAndPassword(
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim(),
                );

            // --- Optionally, you can update the display name ---
            await userCredential.user?.updateDisplayName(
              _nameController.text.trim(),
            );

            // --- Show success dialog and then navigate ---
            if (mounted) {
              _showSuccessDialog();
            }
          } on FirebaseAuthException catch (e) {
            String errorMessage = 'Sign up failed';
            if (e.code == 'email-already-in-use') {
              errorMessage =
                  'This email is already registered. Please sign in instead.';
            } else if (e.code == 'invalid-email') {
              errorMessage = 'Invalid email address format.';
            } else if (e.code == 'weak-password') {
              errorMessage =
                  'Password is too weak. Please use a stronger password.';
            } else if (e.code == 'operation-not-allowed') {
              errorMessage = 'Email/password accounts are not enabled.';
            } else if (e.message != null) {
              errorMessage = e.message!;
            }
            _showErrorDialog('Sign Up Failed', errorMessage);
          } catch (e) {
            _showErrorDialog('Error', 'An unexpected error occurred.');
          }
        },
        icon: const Icon(Icons.person_outline, color: Colors.white),
        label: const Text(
          'Create Account',
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
            borderRadius: BorderRadius.circular(50),
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
            'or sign up with',
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
          label: 'Sign up with Facebook',
          iconAsset: 'assets/images/icons8-facebook-logo-48.png',
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required String iconAsset,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Image.asset(iconAsset, height: 20),
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

  Widget _buildSignInLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          children: [
            const TextSpan(text: "Already have an account? "),
            TextSpan(
              text: 'Sign in',
              style: const TextStyle(
                color: Color(0xFF008060),
                fontWeight: FontWeight.bold,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.of(context).pop(); // Back to SignInScreen
                    },
            ),
          ],
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
