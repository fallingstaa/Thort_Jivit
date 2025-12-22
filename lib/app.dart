import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:thort_jivit/screen/splash_screen.dart';
import 'package:thort_jivit/screen/auth/SignInScreen.dart';
import 'package:thort_jivit/screen/auth/SignUpScreen.dart';
import 'package:thort_jivit/controllers/favorites_controller.dart';
import 'package:thort_jivit/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize GetX controllers
    Get.put(FavoritesController(), permanent: true);
    
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return GetMaterialApp(
            title: 'THOT JIVIT',
            debugShowCheckedModeBanner: false,
            theme: getLightTheme(),
            darkTheme: getDarkTheme(),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/signin': (context) => const SignInScreen(),
              '/signup': (context) => const SignUpScreen(),
            },
          );
        },
      ),
    );
  }
}
