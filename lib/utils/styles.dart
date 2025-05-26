import 'package:flutter/material.dart';

class Styles {
  // Primary colors
  static const primaryColor = Color(0xFF6C63FF);
  static const primaryVariantColor = Color(0xFF3700B3);
  static const secondaryColor = Color(0xFF00BFA6);
  static const secondaryVariantColor = Color(0xFF018786);
  static const accentColor = Color(0xFFFF5252);

  // Background colors
  static const backgroundColor = Color(0xFF1A1A1A);
  static const darkBackground = Color(0xFF121212);
  static const surfaceColor = Colors.white;
  static const darkSurfaceColor = Color(0xFF1E1E1E);
  static const cardBackground = Color(0xFF2D2D2D);

  // Text colors
  static const primaryText = Color(0xFF000000);
  static const secondaryText = Color(0xFF666666);
  static const subtleText = Color(0xFFB3B3B3);
  static const onPrimaryText = Colors.white;
  static const textColor = Color(0xFFF7F7F7);

  // Status colors
  static const successColor = Color(0xFF4CAF50);
  static const warningColor = Color(0xFFFFC107);
  static const errorColor = Color(0xFFFF5252);

  // Nutrition colors
  static const proteinColor = Color(0xFF4CAF50);
  static const carbsColor = Color(0xFFFFA726);
  static const fatColor = Color(0xFFEF5350);

  // Dimensions
  static const double cardElevation = 2.0;
  static const double buttonElevation = 4.0;

  // Gradients
  static final backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      backgroundColor,
      backgroundColor.withOpacity(0.8),
    ],
  );

  static final sportGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryColor,
      primaryColor.withOpacity(0.8),
    ],
  );

  static final cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      cardBackground.withOpacity(0.9),
      cardBackground.withOpacity(0.7),
    ],
  );

  // Text Styles
  static const headingStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const subheadingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static const bodyStyle = TextStyle(
    fontSize: 16,
    color: subtleText,
    height: 1.5,
    letterSpacing: 0.2,
  );

  // Button Styles
  static final elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 8,
    shadowColor: primaryColor.withOpacity(0.5),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  static final outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
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
  static final inputDecoration = InputDecoration(
    filled: true,
    fillColor: cardBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor),
    ),
  );

  // Card Decoration
  static final cardDecoration = BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static final sportCardDecoration = BoxDecoration(
    gradient: sportGradient,
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.3),
        blurRadius: 15,
        offset: const Offset(0, 8),
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

  // Text Field Decoration
  static InputDecoration textFieldDecoration(
    String labelText,
    IconData? icon, {
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cardBackground,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
    );
  }

  // Button Styles
  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
      shadowColor: primaryColor.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}
