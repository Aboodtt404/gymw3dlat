class AppConstants {
  // App Information
  static const String appName = 'GymW3dlat';
  static const String appVersion = '1.0.0';

  // Collection Names
  static const String usersCollection = 'users';
  static const String workoutsCollection = 'workouts';
  static const String nutritionCollection = 'nutrition';

  // Workout Goals
  static const List<String> workoutGoals = [
    'Build Muscle',
    'Lose Weight',
    'Maintain Weight',
    'Improve Strength',
    'Improve Endurance',
  ];

  // Default Values
  static const int defaultWeeklyWorkoutDays = 3;
  static const double defaultRestBetweenSets = 90; // seconds

  // Validation
  static const int minPasswordLength = 6;
  static const int maxWorkoutNameLength = 50;
  static const int maxExerciseNameLength = 50;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultIconSize = 24.0;
  static const double defaultButtonHeight = 48.0;

  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
}
