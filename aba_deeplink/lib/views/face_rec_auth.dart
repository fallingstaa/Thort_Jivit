// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:local_auth/local_auth.dart';
//
// class FaceRecAuth extends StatefulWidget {
//   const FaceRecAuth({super.key});
//
//   @override
//   State<FaceRecAuth> createState() => _FaceRecAuthState();
// }
//
// class _FaceRecAuthState extends State<FaceRecAuth> {
//   late final LocalAuthentication auth;
//   bool _supportState = false;
//   List<BiometricType> _availableBiometrics = [];
//
//   @override
//   void initState() {
//     super.initState();
//     auth = LocalAuthentication();
//     _checkDeviceSupport();
//   }
//
//   // Check if the device supports biometric authentication
//   Future<void> _checkDeviceSupport() async {
//     bool isSupported = await auth.isDeviceSupported();
//     List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
//
//     setState(() {
//       _supportState = isSupported;
//       _availableBiometrics = availableBiometrics;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Flutter Biometric Authentication'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (_supportState)
//               const Text('This device supports biometric authentication')
//             else
//               const Text('This device does not support biometric authentication'),
//
//             Divider(height: 40),
//
//             if (_availableBiometrics.isNotEmpty)
//               Column(
//                 children: [
//                   const Text('Available Biometrics:'),
//                   for (var biometric in _availableBiometrics)
//                     Text(biometric.toString().split('.').last),
//                 ],
//               ),
//
//             Divider(height: 40),
//
//             ElevatedButton(
//               onPressed: _authenticate,
//               child: const Text('Authenticate with Biometric'),
//             ),
//
//             Divider(height: 40),
//
//             ElevatedButton(
//               onPressed: _navigateToAnotherPage,
//               child: const Text('Go to Another Page (No Authentication)'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Handle the authentication process
//   Future<void> _authenticate() async {
//     try {
//       // Check if face recognition is available, prioritize it over fingerprint
//       if (_availableBiometrics.contains(BiometricType.face)) {
//         bool isAuthenticated = await auth.authenticate(
//           localizedReason: 'Please authenticate using Face Recognition',
//           options: const AuthenticationOptions(
//             stickyAuth: true,
//             biometricOnly: true, // Only biometric authentication is allowed
//           ),
//         );
//
//         if (isAuthenticated) {
//           // If authentication is successful, navigate to another page
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const SuccessPage()),
//           );
//         } else {
//           // If authentication fails
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Authentication failed')),
//           );
//         }
//       } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
//         bool isAuthenticated = await auth.authenticate(
//           localizedReason: 'Please authenticate using Fingerprint',
//           options: const AuthenticationOptions(
//             stickyAuth: true,
//             biometricOnly: true, // Only biometric authentication is allowed
//           ),
//         );
//
//         if (isAuthenticated) {
//           // If authentication is successful, navigate to another page
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const SuccessPage()),
//           );
//         } else {
//           // If authentication fails
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Authentication failed')),
//           );
//         }
//       } else {
//         // Handle the case when no biometrics are available
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No biometric authentication available')),
//         );
//       }
//     } on PlatformException catch (e) {
//       print('Error: $e');
//     }
//   }
//
//   // Navigate to another page without authentication
//   void _navigateToAnotherPage() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const SuccessPage()),
//     );
//   }
// }
//
// // Success page that will be shown after successful authentication
// class SuccessPage extends StatelessWidget {
//   const SuccessPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Success')),
//       body: const Center(
//         child: Text('Authentication Successful!'),
//       ),
//     );
//   }
// }
