import 'package:flutter/material.dart';
import 'package:thort_jivit/screen/welcome_screen.dart';
import 'package:thort_jivit/screen/splash_screen.dart';
import 'package:thort_jivit/screen/auth/SignInScreen.dart';
import 'package:thort_jivit/screen/auth/SignUpScreen.dart';

import 'package:thort_jivit/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep green as primary, just add festive accents in December
    final Color primary = primaryBrandGreen;

    return MaterialApp(
      title: 'THOT JIVIT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primary,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: primary,
            fontWeight: FontWeight.w900,
            fontSize: 32,
            letterSpacing: 2.0,
          ),
          bodyMedium: const TextStyle(color: Color(0xFF666666), height: 1.5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(55),
            backgroundColor: primary,
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
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}
