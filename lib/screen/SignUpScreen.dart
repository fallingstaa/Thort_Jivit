import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // State variable to toggle password visibility
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSignUpForm(),
              const SizedBox(height: 24),
              _buildFooter(),
              
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the top back button.
  Widget _buildAppBar() {
    return InkWell(
      onTap: () {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.arrow_back, color: Color(0xFF007A55)),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          // Logo
          Container(
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
          ),
          const SizedBox(height: 24),
          const Text(
            'Create Your Account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start recording your life journey today',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Sign-up form 
  Widget _buildSignUpForm() {
    return Container(
      padding: const EdgeInsets.all(24.0),
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
          // Full Name Field
          _buildFormLabel('Full Name'),
          const SizedBox(height: 8),
          _buildTextField(hint: 'Meng heng', icon: Icons.person_outline),

          const SizedBox(height: 20),

          // Email Field
          _buildFormLabel('Email'),
          const SizedBox(height: 8),
          _buildTextField(hint: 'your@email.com', icon: Icons.email_outlined),

          const SizedBox(height: 20),

          // Password Field
          _buildFormLabel('Password'),
          const SizedBox(height: 8),
          _buildPasswordField(),
          const SizedBox(height: 12),
          _buildPasswordRequirement(),

          const SizedBox(height: 24),

          // Create Account Button
          _buildCreateAccountButton(),

          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),

          // Social Logins
          _buildSocialLoginButtons(),

          const SizedBox(height: 24),

          Center(
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
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Go back to the previous screen (Sign In Screen)
                        Navigator.of(context).pop();
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  

  // --- Helper methods for _buildSignUpForm ---

  Widget _buildFormLabel(String label) {
    return Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54));
  }

  Widget _buildTextField({required String hint, required IconData icon}) {
    return TextField(
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
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: '********',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
    return Row(
      children: [
        Icon(Icons.radio_button_unchecked, color: Colors.grey.shade500, size: 20),
        const SizedBox(width: 8),
        Text('Must be at least 8 characters', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.person_outline, color: Colors.white),
        label: const Text(
          'Create Account',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
          child: Text('or sign up with', style: TextStyle(color: Colors.grey.shade600)),
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
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
            },
            child: const Text(
              'Back to welcome screen',
              style: TextStyle(
                color: Color(0xFF008060),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
