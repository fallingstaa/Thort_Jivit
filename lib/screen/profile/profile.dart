import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:thort_jivit/screen/auth/SignInScreen.dart';
import 'package:thort_jivit/services/notification_service.dart';
import 'package:thort_jivit/theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'edit_profile_screen.dart';
import 'storage_settings_screen.dart';
import 'favorites_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'premium_subscription_screen.dart';
import '../../services/firestore_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  bool notificationsEnabled = true;
  bool _isLoadingNotificationStatus = true;
  String _appVersion = 'Loading...';
  bool _isPremium = false;
  DateTime? _premiumSince;

  // Get current user dynamically
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Notification service
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotificationStatus();
    _loadAppVersion();
    _loadPremiumStatus();
    _reloadUserProfile(); // Reload user data to sync profile picture across devices
  }

  /// Load premium status
  Future<void> _loadPremiumStatus() async {
    try {
      final firestoreService = FirestoreService();
      final premiumInfo = await firestoreService.getPremiumInfo();
      if (mounted) {
        setState(() {
          _isPremium = premiumInfo?['isPremium'] as bool? ?? false;
          _premiumSince = premiumInfo?['premiumSince'] as DateTime?;
        });
      }
    } catch (e) {
      print('[PROFILE] Error loading premium status: $e');
    }
  }

  /// Get premium renewal date (30 days from premiumSince)
  String get _premiumRenewalDate {
    if (_premiumSince == null) {
      // If no premiumSince date, assume it was today (fallback)
      final renewalDate = DateTime.now().add(const Duration(days: 30));
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
      return '${months[renewalDate.month - 1]} ${renewalDate.day}, ${renewalDate.year}';
    }
    final renewalDate = _premiumSince!.add(const Duration(days: 30));
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
    return '${months[renewalDate.month - 1]} ${renewalDate.day}, ${renewalDate.year}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload profile when app comes to foreground to sync profile picture
    if (state == AppLifecycleState.resumed) {
      _reloadUserProfile();
    }
  }


  /// Reload user profile data from Firebase Auth to sync profile picture across devices
  Future<void> _reloadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Reload user data to get latest profile picture from Firebase Auth
        await user.reload();
        // Force rebuild to show updated profile picture
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('[PROFILE] Error reloading user profile: $e');
    }
  }

  /// Load app version from package info
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = '1.0.0 (1)';
        });
      }
    }
  }


  /// Load notification status from preferences
  Future<void> _loadNotificationStatus() async {
    final enabled = await _notificationService.getNotificationEnabled();
    if (mounted) {
      setState(() {
        notificationsEnabled = enabled;
        _isLoadingNotificationStatus = false;
      });
    }
  }

  /// Toggle notification status
  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      notificationsEnabled = value;
    });

    // Update notification service
    await _notificationService.setNotificationEnabled(value);

    // Show feedback to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '🔔 Daily reminders enabled at 12 PM'
                : '🔕 Daily reminders disabled',
          ),
          backgroundColor: value ? const Color(0xFF009966) : Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


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
      // Reload the current user to get updated data
      await FirebaseAuth.instance.currentUser?.reload();
      // Force rebuild to show updated profile picture
      if (mounted) {
        setState(() {});
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 20.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
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
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isTablet ? 24 : 20),

                // Profile Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      isTablet ? 28 : 24,
                      horizontalPadding,
                      isTablet ? 24 : 20,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
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
                                  width: isTablet ? 92 : 76,
                                  height: isTablet ? 92 : 76,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF8D6E63),
                                        Color(0xFFFF8A65),
                                        Color(0xFF81C784),
                                        Color(0xFF4FC3F7),
                                      ],
                                      stops: [0.0, 0.3, 0.7, 1.0],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child:
                                      currentUser?.photoURL != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              isTablet ? 46 : 38,
                                            ),
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
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          isTablet ? 34 : 28,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                          : Center(
                                            child: Text(
                                              userInitials,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: isTablet ? 34 : 28,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(isTablet ? 8 : 6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00BFA5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: FaIcon(
                                        FontAwesomeIcons.camera,
                                        size: isTablet ? 14 : 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: isTablet ? 18 : 14),
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
                                          style: TextStyle(
                                            fontSize: isTablet ? 22 : 19,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isDark
                                                    ? const Color(0xFFE0E0E0)
                                                    : const Color(0xFF1A1A1A),
                                            height: 1.2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_isPremium) ...[
                                    SizedBox(height: isTablet ? 10 : 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 14 : 12,
                                        vertical: isTablet ? 7 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFFD700),
                                            Color(0xFFFFA500),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFD700)
                                                .withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const FaIcon(
                                              FontAwesomeIcons.star,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                          SizedBox(width: isTablet ? 8 : 6),
                                          Text(
                                            'PRO',
                                            style: TextStyle(
                                              fontSize: isTablet ? 14 : 13,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: isTablet ? 6 : 5),
                                  Text(
                                    userEmail,
                                    style: TextStyle(
                                      fontSize: isTablet ? 15 : 13.5,
                                      color:
                                          isDark
                                              ? const Color(0xFFB0B0B0)
                                              : const Color(0xFF6B6B6B),
                                      height: 1.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    memberSince,
                                    style: TextStyle(
                                      fontSize: isTablet ? 13 : 11.5,
                                      color:
                                          isDark
                                              ? const Color(0xFF909090)
                                              : const Color(0xFF9E9E9E),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 22 : 18),
                        Container(
                          height: isTablet ? 44 : 38,
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
                            icon: const FaIcon(
                              FontAwesomeIcons.penToSquare,
                              size: 16,
                              color: Color(0xFF009688),
                            ),
                            label: Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF009688),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isTablet ? 32 : 28),

                // App Preferences Section
                Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    bottom: isTablet ? 16 : 14,
                  ),
                  child: Text(
                    'App Preferences',
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 15.5,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFF1A1A1A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                _buildSettingItem(
                  icon: FontAwesomeIcons.bell,
                  iconColor: const Color(0xFF009688),
                  title: 'Notifications',
                  subtitle: 'Daily recording reminders at 12 PM',
                  isTablet: isTablet,
                  horizontalPadding: horizontalPadding,
                  trailing:
                      _isLoadingNotificationStatus
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF009966),
                              ),
                            ),
                          )
                          : Transform.scale(
                            scale: isTablet ? 1.0 : 0.9,
                            child: Switch(
                              value: notificationsEnabled,
                              onChanged: _toggleNotifications,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF009966),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: const Color(0xFFE0E0E0),
                            ),
                          ),
                ),

                SizedBox(height: isTablet ? 12 : 10),

                _buildSettingItem(
                  icon: FontAwesomeIcons.solidHeart,
                  iconColor: const Color(0xFFE53935),
                  title: 'Favorite Videos',
                  subtitle: 'View your favorite videos',
                  isTablet: isTablet,
                  horizontalPadding: horizontalPadding,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF999999),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),

                SizedBox(height: isTablet ? 12 : 10),

                _buildSettingItem(
                  icon: FontAwesomeIcons.database,
                  iconColor: const Color(0xFF009688),
                  title: 'Storage Settings',
                  subtitle: 'Manage video storage and compression',
                  isTablet: isTablet,
                  horizontalPadding: horizontalPadding,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF999999),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StorageSettingsScreen(),
                      ),
                    );
                  },
                ),

                SizedBox(height: isTablet ? 12 : 10),

                _buildSettingItem(
                  icon: FontAwesomeIcons.star,
                  iconColor: const Color(0xFF009688),
                  title: _isPremium ? 'Premium Subscription' : 'Go Premium',
                  subtitle: _isPremium
                      ? 'Expires $_premiumRenewalDate • View details'
                      : 'Unlock cloud backup & weekly recaps',
                  isTablet: isTablet,
                  horizontalPadding: horizontalPadding,
                  trailing: _isPremium
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF009688).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF009688).withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF009688),
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF009688).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF009688).withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'Upgrade',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF009688),
                            ),
                          ),
                        ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumSubscriptionScreen(),
                      ),
                    ).then((_) {
                      // Reload premium status after returning
                      _loadPremiumStatus();
                    });
                  },
                ),

                SizedBox(height: isTablet ? 12 : 10),

                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return _buildSettingItem(
                      icon:
                          themeProvider.isDarkMode
                              ? FontAwesomeIcons.solidMoon
                              : FontAwesomeIcons.moon,
                      iconColor: const Color(0xFF009688),
                      title: 'Dark Mode',
                      subtitle:
                          themeProvider.isDarkMode
                              ? 'Using dark theme'
                              : 'Switch to dark theme',
                      isTablet: isTablet,
                      horizontalPadding: horizontalPadding,
                      trailing: Transform.scale(
                        scale: isTablet ? 1.0 : 0.9,
                        child: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) async {
                            // Show loading snackbar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? '🌙 Switching to dark mode...'
                                      : '☀️ Switching to light mode...',
                                ),
                                duration: const Duration(milliseconds: 800),
                                backgroundColor: const Color(0xFF009966),
                              ),
                            );

                            // Toggle theme
                            await themeProvider.setThemeMode(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF009966),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFE0E0E0),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: isTablet ? 32 : 28),

                // Support Section
                Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    bottom: isTablet ? 16 : 14,
                  ),
                  child: Text(
                    'Support',
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 15.5,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFF1A1A1A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                _buildSettingItem(
                  icon: FontAwesomeIcons.circleQuestion,
                  iconColor: const Color(0xFF009688),
                  title: 'Help & Support',
                  subtitle: 'FAQs and contact support',
                  showArrow: true,
                  isTablet: isTablet,
                  horizontalPadding: horizontalPadding,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),

                SizedBox(height: isTablet ? 12 : 10),

                _buildSettingItem(
                  icon: FontAwesomeIcons.shield,
                  iconColor: const Color(0xFF009688),
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  showArrow: true,
                  isTablet: isTablet,
                  horizontalPadding: horizontalPadding,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),

                SizedBox(height: isTablet ? 12 : 10),

                _buildSettingItem(
                  icon: FontAwesomeIcons.mobileScreen,
                  iconColor: const Color(0xFF009688),
                  title: 'App Version',
                  subtitle: _appVersion,
                  isTablet: isTablet,
                  horizontalPadding: horizontalPadding,
                ),

                SizedBox(height: isTablet ? 28 : 24),

                // Sign Out Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Container(
                    height: isTablet ? 62 : 56,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
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
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.rightFromBracket,
                                size: 18,
                                color: Color(0xFFE53935),
                              ),
                              SizedBox(width: isTablet ? 12 : 10),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontSize: isTablet ? 16.5 : 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFE53935),
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

                SizedBox(height: isTablet ? 120 : 100),
              ],
            ),
          ),
        ],
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
    bool isTablet = false,
    double horizontalPadding = 20.0,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        constraints: BoxConstraints(minHeight: isTablet ? 96 : 84),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? (showArrow ? () {} : null),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 22 : 18,
                vertical: isTablet ? 20 : 18,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: isTablet ? 56 : 48,
                    height: isTablet ? 56 : 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD0FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        icon,
                        color: const Color(0xFF009966),
                        size: isTablet ? 22 : 20,
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 18 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14.5,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? const Color(0xFFE0E0E0)
                                    : const Color(0xFF1A1A1A),
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: isTablet ? 4 : 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12.5,
                            color:
                                isDark
                                    ? const Color(0xFFB0B0B0)
                                    : const Color(0xFF6B6B6B),
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
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: const FaIcon(
                        FontAwesomeIcons.chevronRight,
                        color: Color(0xFFBDBDBD),
                        size: 20,
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
