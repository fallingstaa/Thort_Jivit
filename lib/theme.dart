import 'package:flutter/material.dart';

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
