import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class Styles {
  // Color scheme
  static const Color primaryColor = Color(0xFF1E88E5); // Strong blue
  static const Color accentColor = Color(0xFFFF4081); // Energetic pink
  static const Color darkBackground = Color(0xFF1A1A1A); // Dark background
  static const Color surfaceColor = Color(0xFF2C2C2C); // Slightly lighter dark
  static const Color textColor = Color(0xFFFFFFFF); // White text
  static const Color subtleText = Color(0xFFB3B3B3); // Subtle gray

  static InputDecoration textFieldDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: subtleText),
      prefixIcon: icon != null ? Icon(icon, color: subtleText) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide: const BorderSide(color: subtleText),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide: const BorderSide(color: subtleText),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.defaultPadding / 2,
      ),
    );
  }

  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(AppConstants.defaultButtonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      backgroundColor: primaryColor,
      foregroundColor: textColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 4,
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return accentColor;
          }
          return null;
        },
      ),
    );
  }

  static ButtonStyle textButtonStyle() {
    return TextButton.styleFrom(
      minimumSize: const Size.fromHeight(AppConstants.defaultButtonHeight / 2),
      foregroundColor: subtleText,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return primaryColor.withOpacity(0.1);
          }
          return null;
        },
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: darkBackground,
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
        backgroundColor: surfaceColor,
        contentTextStyle: TextStyle(color: textColor),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
