class AppConstants {
  // App Information
  static const String appName = 'GymW3dlat';
  static const String appVersion = '1.0.0';

  // Collections
  static const String nutritionCollection = 'nutrition';
  static const String mealLogsCollection = 'meal_logs';
  static const String workoutsCollection = 'workouts';
  static const String exercisesCollection = 'exercises';

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
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double largeBorderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double defaultButtonHeight = 56.0;
  static const double smallButtonHeight = 40.0;
  static const double defaultElevation = 2.0;
  static const double largeElevation = 4.0;
  static const double defaultIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double smallIconSize = 16.0;

  // Animation Durations
  static const int defaultAnimationDuration = 300; // milliseconds

  // Layout Constraints
  static const double maxContentWidth = 600.0;
  static const double maxCardWidth = 400.0;

  // Snackbar Duration
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Nutrition Goals (default values)
  static const double defaultDailyCalories = 2000.0;
  static const double defaultProteinPercentage = 30.0;
  static const double defaultCarbsPercentage = 45.0;
  static const double defaultFatPercentage = 25.0;
}
