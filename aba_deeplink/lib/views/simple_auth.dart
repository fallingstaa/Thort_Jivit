import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class FaceRecAuth extends StatefulWidget {
  const FaceRecAuth({super.key});

  @override
  State<FaceRecAuth> createState() => _FaceRecAuthState();
}

class _FaceRecAuthState extends State<FaceRecAuth> {
  late final LocalAuthentication auth;
  bool _supportState = false;
  List<BiometricType> availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    auth = LocalAuthentication();
    _checkDeviceSupport();
  }

  // Check if the device supports biometrics
  Future<void> _checkDeviceSupport() async {
    bool isSupported = await auth.isDeviceSupported();
    setState(() {
      _supportState = isSupported;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Biometric'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_supportState)
            const Text('This Device is Supported')
          else
            const Text("This Device is not Supported"),
          Divider(height: 100),
          ElevatedButton(
            onPressed: _getAvailableBiometric,
            child: const Text('Get Available Biometric'),
          ),
          Divider(height: 100),
          ElevatedButton(
            onPressed: _authenticate,
            child: const Text('Authenticate'),
          ),
        ],
      ),
    );
  }

  // Authenticate using the available biometric method
  Future<void> _authenticate() async {
    try {
      bool authenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to proceed',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      print('Authenticated: $authenticate');
    } on PlatformException catch (e) {
      print('Error: $e');
    }
  }

  // Get the available biometric types
  Future<void> _getAvailableBiometric() async {
    List<BiometricType> biometrics = await auth.getAvailableBiometrics();
    setState(() {
      availableBiometrics = biometrics;
    });

    print('Available biometrics: $availableBiometrics');

    // You can check here if the device supports face recognition
    if (availableBiometrics.contains(BiometricType.face)) {
      print("Face recognition is available!");
    } else {
      print("Face recognition is not available.");
    }
  }
}
