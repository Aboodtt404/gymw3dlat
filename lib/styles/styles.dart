import 'package:flutter/material.dart';

class Styles {
  // Colors
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color onSurfaceColor = Colors.black87;

  // Nutrition Colors
  static const Color proteinColor = Color(0xFF4CAF50); // Green
  static const Color carbsColor = Color(0xFFFFA726); // Orange
  static const Color fatColor = Color(0xFFEF5350); // Red
  static const Color caloriesColor = Color(0xFF42A5F5); // Blue

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: onSurfaceColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: onSurfaceColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: onSurfaceColor,
  );

  // Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Border Radius
  static const double defaultBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  // Shadows
  static const List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Card Style
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(defaultBorderRadius),
    boxShadow: defaultShadow,
  );

  // Button Style
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: defaultPadding,
      vertical: smallPadding,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(defaultBorderRadius),
    ),
  );

  // Input Decoration
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: smallPadding,
      ),
    );
  }
}
