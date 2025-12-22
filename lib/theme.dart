import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryBrandGreen = Color(0xFF008060);

// Christmas palette (blend of red & green for harmony)
const Color christmasRed = Color(0xFFC62828);
const Color christmasGreen = Color(0xFF2E7D32);
const Color christmasGold = Color(0xFFFFD700);
const Color christmasWhite = Color(0xFFF5F5F5);

// Helper to determine if Christmas season and return blended primary
Color getSeasonalPrimary() {
  final bool isChristmas = DateTime.now().month == 12;
  // Blend red and green for a balanced Christmas look
  return isChristmas ? const Color(0xFFB71C1C) : primaryBrandGreen;
}

// Helper for secondary/accent colors (green counterpart)
Color getSeasonalSecondary() {
  final bool isChristmas = DateTime.now().month == 12;
  return isChristmas ? christmasGreen : primaryBrandGreen;
}

// Gold accent for festive touches
Color getSeasonalAccent() {
  final bool isChristmas = DateTime.now().month == 12;
  return isChristmas ? christmasGold : const Color(0xFFFF8C42);
}

// Theme Provider for managing theme state
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themeKey = 'theme_mode';

  ThemeProvider() {
    _themeMode = ThemeMode.light; // Default to light mode
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    } catch (e) {
      // If loading fails, use default light theme
      _themeMode = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      // If saving fails, continue with theme change
    }
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setThemeMode(newMode);
  }
}

// Light Theme Configuration
ThemeData getLightTheme() {
  final primaryColor = getSeasonalPrimary();
  
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: getSeasonalSecondary(),
      surface: Colors.white,
      background: const Color(0xFFF7F8FA),
      error: const Color(0xFFB00020),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1A1A1A),
      onBackground: const Color(0xFF1A1A1A),
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Color(0xFF1A1A1A)),
      displayMedium: TextStyle(color: Color(0xFF1A1A1A)),
      displaySmall: TextStyle(color: Color(0xFF1A1A1A)),
      headlineLarge: TextStyle(color: Color(0xFF1A1A1A)),
      headlineMedium: TextStyle(color: Color(0xFF1A1A1A)),
      headlineSmall: TextStyle(color: Color(0xFF1A1A1A)),
      titleLarge: TextStyle(color: Color(0xFF1A1A1A)),
      titleMedium: TextStyle(color: Color(0xFF1A1A1A)),
      titleSmall: TextStyle(color: Color(0xFF1A1A1A)),
      bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
      bodyMedium: TextStyle(color: Color(0xFF666666)),
      bodySmall: TextStyle(color: Color(0xFF666666)),
      labelLarge: TextStyle(color: Color(0xFF1A1A1A)),
      labelMedium: TextStyle(color: Color(0xFF666666)),
      labelSmall: TextStyle(color: Color(0xFF666666)),
    ),
    dividerColor: const Color(0xFFEEEEEE),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );
}

// Dark Theme Configuration
ThemeData getDarkTheme() {
  final primaryColor = getSeasonalPrimary();
  
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: getSeasonalSecondary(),
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      error: const Color(0xFFCF6679),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFFE0E0E0),
      onBackground: const Color(0xFFE0E0E0),
      onError: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFE0E0E0),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFE0E0E0)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Color(0xFFE0E0E0)),
      displayMedium: TextStyle(color: Color(0xFFE0E0E0)),
      displaySmall: TextStyle(color: Color(0xFFE0E0E0)),
      headlineLarge: TextStyle(color: Color(0xFFE0E0E0)),
      headlineMedium: TextStyle(color: Color(0xFFE0E0E0)),
      headlineSmall: TextStyle(color: Color(0xFFE0E0E0)),
      titleLarge: TextStyle(color: Color(0xFFE0E0E0)),
      titleMedium: TextStyle(color: Color(0xFFE0E0E0)),
      titleSmall: TextStyle(color: Color(0xFFE0E0E0)),
      bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
      bodyMedium: TextStyle(color: Color(0xFFB0B0B0)),
      bodySmall: TextStyle(color: Color(0xFFB0B0B0)),
      labelLarge: TextStyle(color: Color(0xFFE0E0E0)),
      labelMedium: TextStyle(color: Color(0xFFB0B0B0)),
      labelSmall: TextStyle(color: Color(0xFFB0B0B0)),
    ),
    dividerColor: const Color(0xFF2A2A2A),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );
}
