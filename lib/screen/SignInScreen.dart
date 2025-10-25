import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'SignUpScreen.dart';
import 'homepage.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F9), // A light background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          // Using a Column with an Expanded ListView to keep it on one screen
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView(
                  children: [
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

  /// Builds the header with logo and welcome text.
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          // Logo
          Container(
            width: 100, // Reduced logo size
            height: 100, // Reduced logo size
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main sign-in form container.
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
          const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 8),
          _buildTextField(hint: 'your@email.com', icon: Icons.email_outlined),
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

  // --- Helper widgets for the form ---

  Widget _buildPasswordHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        GestureDetector(
          onTap: () {
            // Handle forgot password
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

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        },
        icon: const Icon(Icons.email_outlined, color: Colors.white),
        label: const Text(
          'Sign in with Email',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
          child: Text('or continue with', style: TextStyle(color: Colors.grey.shade600)),
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
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
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
        icon: isIconData
            ? Icon(iconData, color: Colors.black54)
            : Image.asset(iconAsset!, height: 20),
        label: Text(
          label,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
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
  
  /// Builds the footer text at the bottom.
  Widget _buildFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: GestureDetector(
          onTap: () {
            // Add navigation logic to welcome screen if needed
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
