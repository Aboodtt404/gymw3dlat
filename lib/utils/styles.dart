import 'package:flutter/material.dart';

class Styles {
  // Primary colors
  static const primaryColor = Color(0xFF6200EE);
  static const primaryVariantColor = Color(0xFF3700B3);
  static const secondaryColor = Color(0xFF03DAC6);
  static const secondaryVariantColor = Color(0xFF018786);
  static const accentColor = Color(0xFF00BFA6);

  // Background colors
  static const backgroundColor = Color(0xFFF5F5F5);
  static const darkBackground = Color(0xFF121212);
  static const surfaceColor = Colors.white;
  static const darkSurfaceColor = Color(0xFF1E1E1E);
  static const cardBackground = Color(0xFF242438);

  // Text colors
  static const primaryText = Color(0xFF000000);
  static const secondaryText = Color(0xFF666666);
  static const subtleText = Color(0xFF999999);
  static const onPrimaryText = Colors.white;
  static const textColor = Color(0xFFF7F7F7);

  // Status colors
  static const successColor = Color(0xFF4CAF50);
  static const warningColor = Color(0xFFFFC107);
  static const errorColor = Color(0xFFFF6B6B);

  // Nutrition colors
  static const proteinColor = Color(0xFF4CAF50);
  static const carbsColor = Color(0xFFFFA726);
  static const fatColor = Color(0xFFEF5350);

  // Dimensions
  static const double cardElevation = 2.0;
  static const double buttonElevation = 4.0;

  // Gradients
  static LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryColor.withOpacity(0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      darkBackground,
      primaryColor.withOpacity(0.05),
      darkBackground,
    ],
  );

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    color: textColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static const TextStyle subheadingStyle = TextStyle(
    color: subtleText,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: textColor,
    fontSize: 14,
    letterSpacing: 0.2,
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      );

  static ButtonStyle secondaryButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: cardBackground,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 1,
      );

  static ButtonStyle textButtonStyle() => TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      );

  // Input Decoration
  static InputDecoration textFieldDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: subtleText),
        prefixIcon: Icon(icon, color: subtleText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: subtleText),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: subtleText.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        filled: true,
        fillColor: cardBackground,
      );

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // List Tile Style
  static ListTileThemeData listTileTheme = const ListTileThemeData(
    iconColor: subtleText,
    textColor: textColor,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  static ThemeData darkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardBackground,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        bodyLarge: TextStyle(
          color: subtleText,
          fontSize: 16,
          letterSpacing: 0.2,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: cardBackground,
        contentTextStyle: TextStyle(color: textColor),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
