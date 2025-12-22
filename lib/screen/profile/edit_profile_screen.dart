import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _currentPhotoURL;
  String? _originalPhotoURL; // Track original photo URL to delete it if changed

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  void _loadCurrentUserData() {
    _nameController.text = currentUser?.displayName ?? '';
    _currentPhotoURL = currentUser?.photoURL;
    _originalPhotoURL = currentUser?.photoURL; // Store original to track changes
  }

  // Get user initials for avatar
  String get userInitials {
    final name =
        _nameController.text.isNotEmpty
            ? _nameController.text
            : (currentUser?.displayName ?? 'U');

    if (name.isNotEmpty) {
      final nameParts = name.split(' ');
      if (nameParts.length >= 2) {
        return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return 'U';
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  // Show image source selection dialog
  Future<void> _showImageSourceDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose Profile Picture',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFE0E0E0) : Colors.black),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library,
                      color: Color(0xFF009688),
                    ),
                    title: Text('Choose from Gallery', style: TextStyle(color: isDark ? const Color(0xFFE0E0E0) : Colors.black)),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF009688),
                    ),
                    title: Text('Take a Photo', style: TextStyle(color: isDark ? const Color(0xFFE0E0E0) : Colors.black)),
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                  if (_currentPhotoURL != null || _selectedImage != null)
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: Text('Remove Photo', style: TextStyle(color: isDark ? const Color(0xFFE0E0E0) : Colors.black)),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedImage = null;
                          _currentPhotoURL = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
    );
  }

  // Delete old profile picture from Firebase Storage
  Future<void> _deleteOldProfilePicture(String? oldPhotoURL) async {
    if (oldPhotoURL == null || oldPhotoURL.isEmpty) return;

    try {
      final userId = currentUser?.uid;
      if (userId == null) return;

      // Try to extract the path from the URL or use the standard path
      // Firebase Storage URLs contain the path, but we can also use the standard path
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      // Check if file exists and delete it
      try {
        await storageRef.getMetadata();
        // File exists, delete it
        await storageRef.delete();
        print('Old profile picture deleted successfully');
      } catch (e) {
        // File doesn't exist or error accessing it - that's okay
        print('Old profile picture not found or already deleted: $e');
      }
    } catch (e) {
      // Log error but don't fail the upload if deletion fails
      print('Error deleting old profile picture: $e');
    }
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(File imageFile) async {
    try {
      setState(() => _isUploadingImage = true);

      final userId = currentUser?.uid;
      if (userId == null) return null;

      // Delete old profile picture if it exists (use original photo URL)
      if (_originalPhotoURL != null && _originalPhotoURL!.isNotEmpty) {
        await _deleteOldProfilePicture(_originalPhotoURL);
      }

      // Create reference to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      // Upload file
      final uploadTask = await storageRef.putFile(imageFile);

      // Get download URL
      final downloadURL = await uploadTask.ref.getDownloadURL();

      setState(() => _isUploadingImage = false);
      return downloadURL;
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showErrorSnackBar('Error uploading image: $e');
      return null;
    }
  }

  // Save profile changes
  Future<void> _saveProfile() async {
    if (_isLoading) return;

    // Validate name
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoURL = _currentPhotoURL;

      // Upload new image if selected
      if (_selectedImage != null) {
        photoURL = await _uploadImage(_selectedImage!);
        if (photoURL == null) {
          setState(() => _isLoading = false);
          return;
        }
      } else if (_currentPhotoURL == null && _selectedImage == null) {
        // User removed photo - delete old one from storage if it existed
        if (_originalPhotoURL != null && _originalPhotoURL!.isNotEmpty) {
          await _deleteOldProfilePicture(_originalPhotoURL);
        }
        photoURL = null;
      }

      // Update Firebase Auth profile
      await currentUser?.updateDisplayName(_nameController.text.trim());

      if (photoURL != null) {
        await currentUser?.updatePhotoURL(photoURL);
      } else {
        await currentUser?.updatePhotoURL(null);
      }

      // Reload user to get updated data
      await currentUser?.reload();

      if (mounted) {
        _showSuccessSnackBar('Profile updated successfully!');
        // Wait a bit to show the success message
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate changes were made
      }
    } catch (e) {
      _showErrorSnackBar('Error updating profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? const Color(0xFF009688) : const Color(0xFF009688)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF009688),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile Picture Section
              _buildProfilePictureSection(),

              const SizedBox(height: 40),

              // Name Input Section
              _buildNameInputSection(),

              const SizedBox(height: 30),

              // Email Display (Read-only)
              _buildEmailSection(),

              const SizedBox(height: 40),

              // Save Button
              _buildSaveButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Stack(
          children: [
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildAvatarContent(),
            ),

            // Camera button
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploadingImage ? null : _showImageSourceDialog,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009688),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child:
                      _isUploadingImage
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to change photo',
          style: TextStyle(color: isDark ? const Color(0xFFB0B0B0) : Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAvatarContent() {
    // Show selected image
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      );
    }

    // Show current profile picture
    if (_currentPhotoURL != null && _currentPhotoURL!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.network(
          _currentPhotoURL!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar();
          },
        ),
      );
    }

    // Show initials
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        userInitials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNameInputSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFFE0E0E0) : Colors.black),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF757575) : Colors.grey),
              prefixIcon: const Icon(
                Icons.person_outline,
                color: Color(0xFF009688),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF009688),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6B6B6B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Read-only',
                  style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6B6B6B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined, color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6B6B6B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentUser?.email ?? 'No email',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6B6B6B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading || _isUploadingImage ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF009688),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }
}
