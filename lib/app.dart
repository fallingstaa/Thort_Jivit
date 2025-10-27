import 'package:flutter/material.dart';
import 'package:thort_jivit/screen/music/MusicScreen.dart';
import 'package:thort_jivit/screen/auth/SignInScreen.dart';
import 'package:thort_jivit/screen/auth/SignUpScreen.dart';
import 'package:thort_jivit/screen/home/HomePage.dart';

import 'package:thort_jivit/screen/welcome.dart'; // Ensure correct path

import 'package:thort_jivit/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'THOT JIVIT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Set the primary color for buttons and accents
        primaryColor: primaryBrandGreen,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBrandGreen,
          primary: primaryBrandGreen,
        ),
        // Define text theme for consistency
        textTheme: const TextTheme(
          // For the main app title on the welcome screen
          headlineLarge: TextStyle(
            color: primaryBrandGreen,
            fontWeight: FontWeight.w900,
            fontSize: 32,
            letterSpacing: 2.0,
          ),
          // For the body text descriptions
          bodyMedium: TextStyle(
            color: Color(0xFF666666), // Darker grey for readability
            height: 1.5,
          ),
        ),
        // Define elevated button style
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(55),
            backgroundColor: primaryBrandGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: const SignInScreen(),
    );
  }
}
