import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class Styles {
  static InputDecoration textFieldDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  static ButtonStyle textButtonStyle() {
    return TextButton.styleFrom(
      minimumSize: const Size.fromHeight(AppConstants.defaultButtonHeight / 2),
    );
  }
}
