class AppConstants {
  // App Information
  static const String appName = 'GymW3dlat';
  static const String appVersion = '1.0.0';

  // Collections
  static const String nutritionCollection = 'nutrition';
  static const String mealLogsCollection = 'meal_logs';
  static const String workoutsCollection = 'workout_templates';
  static const String exercisesCollection = 'exercises';
  static const String workoutLogsCollection = 'workout_logs';
  static const String userFitnessProfilesCollection = 'user_fitness_profiles';
  static const String workoutPerformanceAnalysisCollection =
      'workout_performance_analysis';

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
  static const double extraLargePadding = 32.0;
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
  static const double extraLargeIconSize = 48.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration defaultAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Layout Constraints
  static const double maxContentWidth = 600.0;
  static const double maxCardWidth = 400.0;
  static const double minCardHeight = 120.0;
  static const double maxListItemHeight = 100.0;
  static const int maxDescriptionLength = 500;
  static const int maxNotesLength = 1000;

  // Snackbar Duration
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Nutrition Goals (default values)
  static const double defaultDailyCalories = 2000.0;
  static const double defaultProteinPercentage = 30.0;
  static const double defaultCarbsPercentage = 45.0;
  static const double defaultFatPercentage = 25.0;

  // Fitness Levels
  static const List<String> fitnessLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert'
  ];

  // Fitness Goals
  static const List<String> fitnessGoals = [
    'Build Muscle',
    'Lose Weight',
    'Improve Endurance',
    'Increase Strength',
    'General Fitness',
    'Athletic Performance',
    'Rehabilitation',
    'Flexibility'
  ];

  // Exercise Types
  static const List<String> exerciseTypes = [
    'Strength Training',
    'Cardio',
    'Flexibility',
    'Balance',
    'Sports',
    'Functional Training',
    'Bodyweight',
    'Powerlifting',
    'Olympic Lifting'
  ];

  // Available Equipment
  static const List<String> availableEquipment = [
    'Body Weight',
    'Barbell',
    'Dumbbell',
    'Cable',
    'Machine',
    'Band',
    'Kettlebell',
    'Plate',
    'Suspension',
    'Stability Ball',
    'Foam Roll',
    'Medicine Ball'
  ];

  // Common Injuries
  static const List<String> commonInjuries = [
    'Lower Back',
    'Knee',
    'Shoulder',
    'Wrist',
    'Ankle',
    'Hip',
    'Neck',
    'Elbow',
    'Hamstring',
    'Achilles Tendon'
  ];

  // Workout Intensities
  static const List<String> workoutIntensities = [
    'Light',
    'Moderate',
    'Vigorous',
    'Extreme'
  ];

  // Recovery Status
  static const List<String> recoveryStatuses = [
    'Fully Recovered',
    'Partially Recovered',
    'Fatigued',
    'Overreached'
  ];

  // Progression Plan Types
  static const List<String> progressionPlanTypes = [
    'Weight Loss',
    'Muscle Building',
    'Strength Gain',
    'Endurance Improvement',
    'Athletic Performance',
    'General Fitness',
    'Rehabilitation',
    'Competition Prep'
  ];

  // API Limits
  static const int maxRecommendations = 10;
  static const int defaultRecommendations = 3;
  static const int maxWorkoutDuration = 180; // minutes
  static const int minWorkoutDuration = 10; // minutes
  static const int maxSets = 10;
  static const int maxReps = 50;
  static const double maxWeight = 500.0; // kg

  // Performance Thresholds
  static const double excellentPerformance = 0.9;
  static const double goodPerformance = 0.8;
  static const double averagePerformance = 0.6;
  static const double poorPerformance = 0.4;

  // Confidence Thresholds
  static const double highConfidence = 0.8;
  static const double mediumConfidence = 0.6;
  static const double lowConfidence = 0.4;

  // Difficulty Levels (1-10 scale)
  static const double beginnerDifficulty = 3.0;
  static const double intermediateDifficulty = 5.0;
  static const double advancedDifficulty = 7.0;
  static const double expertDifficulty = 9.0;

  // Strength Level Scale (1-10)
  static const double minStrengthLevel = 1.0;
  static const double maxStrengthLevel = 10.0;
  static const double defaultStrengthLevel = 3.0;

  // Cardio Endurance Scale (1-10)
  static const double minCardioEndurance = 1.0;
  static const double maxCardioEndurance = 10.0;
  static const double defaultCardioEndurance = 3.0;

  // Rest Time Ranges (seconds)
  static const int minRestTime = 30;
  static const int maxRestTime = 300;
  static const int defaultRestTime = 90;

  // Adaptation Factors
  static const double minAdaptationFactor = 0.5;
  static const double maxAdaptationFactor = 1.5;
  static const double defaultAdaptationFactor = 1.0;

  // Database Limits
  static const int maxRecommendationsPerUser = 50;
  static const int maxAnalysisHistoryPerUser = 100;
  static const int maxMilestonesPerPlan = 20;

  // Notification Types
  static const String workoutReminderNotification = 'workout_reminder';
  static const String progressMilestoneNotification = 'progress_milestone';
  static const String performanceInsightNotification = 'performance_insight';
  static const String adaptationSuggestionNotification =
      'adaptation_suggestion';

  // Error Messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String serverErrorMessage =
      'Server error. Please try again later.';
  static const String authErrorMessage =
      'Authentication error. Please log in again.';
  static const String dataErrorMessage =
      'Data error. Please refresh and try again.';
  static const String validationErrorMessage =
      'Please check your input and try again.';

  // Success Messages
  static const String profileUpdatedMessage = 'Profile updated successfully!';
  static const String recommendationGeneratedMessage =
      'New recommendations generated!';
  static const String workoutCompletedMessage =
      'Workout completed successfully!';
  static const String progressUpdatedMessage = 'Progress updated successfully!';
  static const String planCreatedMessage =
      'Progression plan created successfully!';

  // Feature Flags
  static const bool enableWorkoutAdaptation = true;
  static const bool enablePerformanceAnalysis = true;
  static const bool enableProgressionPlanning = true;
  static const bool enableNotifications = true;
  static const bool enableAdvancedMetrics = true;

  // Cache Durations
  static const Duration recommendationCacheDuration = Duration(hours: 1);
  static const Duration profileCacheDuration = Duration(hours: 24);
  static const Duration analysisCacheDuration = Duration(hours: 6);
}
