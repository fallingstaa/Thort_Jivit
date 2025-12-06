import 'package:firebase_auth/firebase_auth.dart';

/// Utility to check if the current user is the web admin.
Future<bool> isWebAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  // Hardcoded admin email
  return user.email == 'lyya87396@gmail.com';
}
