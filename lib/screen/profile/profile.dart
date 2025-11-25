import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thort_jivit/screen/auth/SignInScreen.dart';
import 'edit_profile_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool notificationsEnabled = true;
  bool autoSaveEnabled = true;
  bool darkModeEnabled = false;
  bool soundEffectsEnabled = true;

  // Firebase user
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Get user display name
  String get userName {
    if (currentUser?.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      return currentUser!.displayName!;
    } else if (currentUser?.email != null) {
      return currentUser!.email!.split('@')[0];
    }
    return 'User';
  }

  // Get user email
  String get userEmail {
    return currentUser?.email ?? 'No email';
  }

  // Get user initials for avatar
  String get userInitials {
    if (userName.isNotEmpty) {
      final nameParts = userName.split(' ');
      if (nameParts.length >= 2) {
        return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
      }
      return userName[0].toUpperCase();
    }
    return 'U';
  }

  // Get member since date
  String get memberSince {
    if (currentUser?.metadata.creationTime != null) {
      final date = currentUser!.metadata.creationTime!;
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return 'Member since ${months[date.month - 1]} ${date.year}';
    }
    return 'Member since 2025';
  }

  // Navigate to edit profile screen
  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );

    // Refresh profile if changes were made
    if (result == true && mounted) {
      setState(() {
        // Reload the current user to get updated data
        FirebaseAuth.instance.currentUser?.reload();
      });
    }
  }

  // Sign out function
  Future<void> _signOut() async {
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (shouldSignOut == true) {
      try {
        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();

        // Navigate to SignInScreen and remove all previous routes
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF009688),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Profile Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8D6E63), // Brown
                                    Color(0xFFFF8A65), // Orange
                                    Color(0xFF81C784), // Light green
                                    Color(0xFF4FC3F7), // Light blue
                                  ],
                                  stops: [0.0, 0.3, 0.7, 1.0],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child:
                                  currentUser?.photoURL != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(38),
                                        child: Image.network(
                                          currentUser!.photoURL!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Center(
                                              child: Text(
                                                userInitials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                      : Center(
                                        child: Text(
                                          userInitials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00BFA5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                        height: 1.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    '👑',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF6B6B6B),
                                  height: 1.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                memberSince,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF9E9E9E),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 38,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF4DB6AC).withOpacity(0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton.icon(
                        onPressed: _navigateToEditProfile,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF009688),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 17,
                          color: Color(0xFF009688),
                        ),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF009688),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Privacy & Security Section
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 14),
              child: Text(
                'Privacy & Security',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.2,
                ),
              ),
            ),

            _buildSettingItem(
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF009688),
              title: 'Privacy Settings',
              subtitle: 'Control who can see your content',
              showArrow: true,
            ),

            const SizedBox(height: 10),

            _buildSettingItem(
              icon: Icons.notifications_outlined,
              iconColor: const Color(0xFF009688),
              title: 'Notifications',
              subtitle: 'Daily recording reminders',
              trailing: Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setState(() => notificationsEnabled = value);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF009966),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE0E0E0),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // App Preferences Section
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 14),
              child: Text(
                'App Preferences',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.2,
                ),
              ),
            ),

            _buildSettingItem(
              icon: Icons.camera_alt_outlined,
              iconColor: const Color(0xFF009688),
              title: 'Auto-save recordings',
              subtitle: 'Automatically save after recording',
              trailing: Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: autoSaveEnabled,
                  onChanged: (value) {
                    setState(() => autoSaveEnabled = value);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF009966),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE0E0E0),
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildSettingItem(
              icon: Icons.nightlight_round_outlined,
              iconColor: const Color(0xFF009688),
              title: 'Dark Mode',
              subtitle: 'Switch to dark theme',
              trailing: Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: darkModeEnabled,
                  onChanged: (value) {
                    setState(() => darkModeEnabled = value);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF009966),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE0E0E0),
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildSettingItem(
              icon: Icons.volume_up_outlined,
              iconColor: const Color(0xFF009688),
              title: 'Sound Effects',
              subtitle: 'Play sounds for interactions',
              trailing: Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: soundEffectsEnabled,
                  onChanged: (value) {
                    setState(() => soundEffectsEnabled = value);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF009966),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE0E0E0),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Support Section
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 14),
              child: Text(
                'Support',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.2,
                ),
              ),
            ),

            _buildSettingItem(
              icon: Icons.help_outline_rounded,
              iconColor: const Color(0xFF009688),
              title: 'Help & Support',
              subtitle: 'FAQs and contact support',
              showArrow: true,
            ),

            const SizedBox(height: 10),

            _buildSettingItem(
              icon: Icons.smartphone_outlined,
              iconColor: const Color(0xFF009688),
              title: 'App Version',
              subtitle: '1.2.3 (Latest)',
              showArrow: true,
            ),

            const SizedBox(height: 24),

            // Sign Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE53935).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _signOut,
                    borderRadius: BorderRadius.circular(20),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.logout,
                            size: 19,
                            color: Color(0xFFE53935),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE53935),
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool showArrow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 84),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: showArrow ? () {} : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD0FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Color(0xFF009966), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6B6B6B),
                            height: 1.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: trailing,
                    )
                  else if (showArrow)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.chevron_right,
                        color: Color(0xFFBDBDBD),
                        size: 26,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
