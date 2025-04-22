import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/adaptive_plan_model.dart';
import '../models/meal_plan_model.dart';
import '../models/workout_template_model.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

/// AIPlanService provides machine learning capabilities for generating
/// and adapting workout and diet plans based on user inactivity periods.
class AIPlanService {
  static const String _tableName = 'ai_training_data';

  // Factors that influence plan adjustments
  static const double _maxInactivityPenalty = 0.5;
  static const int _severePenaltyDays = 30;
  static const double _progressWeight = 0.7;
  static const double _inactivityWeight = 0.3;

  /// Calculate how much to adjust the plan based on days away and previous progress
  double calculateAdjustmentFactor(int daysAway, double previousProgress) {
    // Base adjustment factor based on days away
    double inactivityFactor;
    if (daysAway <= 3) {
      inactivityFactor = 1.0; // No penalty for short breaks
    } else if (daysAway <= 7) {
      inactivityFactor = 0.9; // Slight reduction for 4-7 days away
    } else if (daysAway <= 14) {
      inactivityFactor = 0.8; // Moderate reduction for 1-2 weeks away
    } else if (daysAway <= 30) {
      inactivityFactor = 0.7; // Significant reduction for 2-4 weeks away
    } else {
      // Progressive penalty for longer periods
      double daysOverSevere = min((daysAway - _severePenaltyDays).toDouble(),
          _severePenaltyDays.toDouble());
      double severePenaltyRatio = daysOverSevere / _severePenaltyDays;
      inactivityFactor = 0.6 - (severePenaltyRatio * _maxInactivityPenalty);
    }

    // Consider previous progress (higher progress = less penalty)
    double progressFactor = 0.5 + (previousProgress * 0.5);

    // Combine factors with weights
    return (progressFactor * _progressWeight) +
        (inactivityFactor * _inactivityWeight);
  }

  /// Generate a workout plan based on user's history, inactivity period, and goals
  Future<WorkoutTemplate> generateWorkoutPlan(
    UserModel user,
    WorkoutTemplate? previousPlan,
    int daysAway,
    double progressScore,
  ) async {
    if (previousPlan == null) {
      // If no previous plan, get a default template for the user's goal
      return await _getDefaultWorkoutTemplate(user);
    }

    // Calculate the adjustment factor
    final adjustmentFactor = calculateAdjustmentFactor(daysAway, progressScore);

    // Adjust exercise intensity based on inactivity and previous progress
    final adjustedExercises = previousPlan.exercises.map((exercise) {
      int newSets = _adjustExerciseSets(exercise.sets, adjustmentFactor, user);
      int newReps = _adjustExerciseReps(exercise.reps, adjustmentFactor, user);
      double? newWeight = exercise.weight != null
          ? _adjustExerciseWeight(exercise.weight!, adjustmentFactor, user)
          : null;

      return exercise.copyWith(
        sets: newSets,
        reps: newReps,
        weight: newWeight,
      );
    }).toList();

    // Create a new workout template with the adjusted exercises
    return previousPlan.copyWith(
      exercises: adjustedExercises,
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a meal plan based on user's history, inactivity period, and goals
  Future<MealPlan> generateMealPlan(
    UserModel user,
    MealPlan? previousPlan,
    int daysAway,
    double progressScore,
  ) async {
    if (previousPlan == null) {
      // If no previous plan, get a default template for the user's goal
      return await _getDefaultMealPlan(user);
    }

    // Calculate the adjustment factor
    final adjustmentFactor = calculateAdjustmentFactor(daysAway, progressScore);

    // Calculate target calories based on user metrics and goal
    final targetCalories = _calculateTargetCalories(user, adjustmentFactor);

    // Adjust each meal's macros based on inactivity and previous progress
    final adjustedMeals = previousPlan.meals.map((meal) {
      // Adjust calories while maintaining the meal's original proportion of daily intake
      final originalProportion = meal.calories / previousPlan.totalCalories;
      final newCalories = targetCalories * originalProportion;

      // Adjust macros proportionally
      final calorieRatio = newCalories / meal.calories;
      return meal.copyWith(
        calories: newCalories,
        protein: meal.protein * calorieRatio,
        carbs: meal.carbs * calorieRatio,
        fat: meal.fat * calorieRatio,
      );
    }).toList();

    // Create a new meal plan with the adjusted meals
    return previousPlan.copyWith(
      meals: adjustedMeals,
      date: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Store training data for model improvement
  Future<void> storeTrainingData({
    required String userId,
    required int daysAway,
    required double adjustmentFactor,
    required double beforeProgressScore,
    required double afterProgressScore,
    required Map<String, dynamic> planChanges,
  }) async {
    final data = {
      'user_id': userId,
      'days_away': daysAway,
      'adjustment_factor': adjustmentFactor,
      'before_progress_score': beforeProgressScore,
      'after_progress_score': afterProgressScore,
      'plan_changes': planChanges,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await SupabaseService.client.from(_tableName).insert(data);
  }

  /// Get training data for model improvement
  Future<List<Map<String, dynamic>>> getTrainingData(String userId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // PRIVATE HELPER METHODS

  int _adjustExerciseSets(int currentSets, double factor, UserModel user) {
    // Determine new sets count based on adjustment factor and user's fitness goal
    int direction = _getAdjustmentDirection(user);
    double baseChange = currentSets * (1 - factor) * direction;

    // Apply changes, ensure minimum 1 set
    return max(1, (currentSets + baseChange).round());
  }

  int _adjustExerciseReps(int currentReps, double factor, UserModel user) {
    // Determine new reps count based on adjustment factor and user's fitness goal
    int direction = _getAdjustmentDirection(user);
    double baseChange = currentReps * (1 - factor) * direction;

    // Apply changes, ensure minimum 1 rep
    return max(1, (currentReps + baseChange).round());
  }

  double _adjustExerciseWeight(
      double currentWeight, double factor, UserModel user) {
    // Determine weight adjustment based on factor and goal
    int direction = _getAdjustmentDirection(user);
    double baseChange = currentWeight * (1 - factor) * direction;

    // Apply changes, ensure minimum weight (could be bodyweight = 0)
    return max(0, currentWeight + baseChange);
  }

  int _getAdjustmentDirection(UserModel user) {
    // Return adjustment direction based on user goal
    // Negative = reduce intensity for longer inactivity
    // Positive = increase intensity for certain goals when returning
    final goal = user.goal?.toLowerCase() ?? 'general fitness';

    switch (goal) {
      case 'build muscle':
      case 'strength':
        return -1; // Reduce intensity after break
      case 'endurance':
      case 'cardio':
        return -1; // Reduce intensity after break
      case 'weight loss':
        return 1; // Increase intensity to compensate for lost time
      default:
        return -1; // By default, reduce intensity after inactivity
    }
  }

  double _calculateTargetCalories(UserModel user, double adjustmentFactor) {
    // Base calories from Harris-Benedict equation (simplified)
    double bmr;

    // Use user metrics if available, otherwise use defaults
    final weight = user.weight ?? 70.0; // kg
    final height = user.height ?? 170.0; // cm
    final age = _calculateAge(user) ?? 30;

    // Calculate BMR based on gender (simplified, would need gender in user model)
    final isMale = true; // Simplified, would need to check user's gender

    if (isMale) {
      bmr = 66.5 + (13.75 * weight) + (5.003 * height) - (6.75 * age);
    } else {
      bmr = 655.1 + (9.563 * weight) + (1.850 * height) - (4.676 * age);
    }

    // Apply activity multiplier based on weekly workout days
    final activityMultiplier =
        _getActivityMultiplier(user.weeklyWorkoutDays ?? 3);

    // Base calories
    double baseCalories = bmr * activityMultiplier;

    // Adjust based on goal
    final goal = user.goal?.toLowerCase() ?? 'general fitness';

    switch (goal) {
      case 'lose weight':
      case 'weight loss':
        return baseCalories * 0.8 * adjustmentFactor; // Caloric deficit
      case 'build muscle':
      case 'muscle gain':
        return baseCalories * 1.1 * adjustmentFactor; // Caloric surplus
      default:
        return baseCalories * adjustmentFactor; // Maintenance
    }
  }

  int? _calculateAge(UserModel user) {
    // Would calculate age from user's birth date if available
    // Simplified here as birth date isn't in the user model
    return null;
  }

  double _getActivityMultiplier(int weeklyWorkoutDays) {
    // Return activity multiplier based on weekly workout frequency
    switch (weeklyWorkoutDays) {
      case 0:
      case 1:
        return 1.2; // Sedentary
      case 2:
      case 3:
        return 1.375; // Lightly active
      case 4:
      case 5:
        return 1.55; // Moderately active
      case 6:
      case 7:
        return 1.725; // Very active
      default:
        return 1.375; // Default to lightly active
    }
  }

  Future<WorkoutTemplate> _getDefaultWorkoutTemplate(UserModel user) async {
    // In a real implementation, you would have predefined templates for different goals
    // or fetch from a template database

    // Simplified example for demonstration
    final goal = user.goal?.toLowerCase() ?? 'general fitness';

    // Get exercises appropriate for the user's goal
    final exercises = await _getExercisesForGoal(goal);

    return WorkoutTemplate(
      id: Uuid().v4(),
      userId: user.id,
      name: "Adaptive ${goal.toUpperCase()} Program",
      description:
          "Automatically generated program based on your goals and profile",
      exercises: exercises,
      createdAt: DateTime.now(),
    );
  }

  Future<MealPlan> _getDefaultMealPlan(UserModel user) async {
    // In a real implementation, you would have predefined meal plans for different goals
    // or use a nutrition API to generate one

    // Calculate target calories for this user
    final targetCalories = _calculateTargetCalories(user, 1.0);

    // Create default meal entries for different meal times
    final meals = [
      MealEntry(
        id: Uuid().v4(),
        foodName: "Breakfast",
        type: MealType.breakfast,
        servingSize: 1.0,
        servingUnit: "serving",
        calories: targetCalories * 0.3,
        protein:
            targetCalories * 0.3 * 0.25 / 4, // 25% of calories from protein
        carbs: targetCalories * 0.3 * 0.5 / 4, // 50% of calories from carbs
        fat: targetCalories * 0.3 * 0.25 / 9, // 25% of calories from fat
        loggedAt: DateTime.now().copyWith(hour: 8, minute: 0),
      ),
      MealEntry(
        id: Uuid().v4(),
        foodName: "Lunch",
        type: MealType.lunch,
        servingSize: 1.0,
        servingUnit: "serving",
        calories: targetCalories * 0.35,
        protein:
            targetCalories * 0.35 * 0.3 / 4, // 30% of calories from protein
        carbs: targetCalories * 0.35 * 0.45 / 4, // 45% of calories from carbs
        fat: targetCalories * 0.35 * 0.25 / 9, // 25% of calories from fat
        loggedAt: DateTime.now().copyWith(hour: 13, minute: 0),
      ),
      MealEntry(
        id: Uuid().v4(),
        foodName: "Dinner",
        type: MealType.dinner,
        servingSize: 1.0,
        servingUnit: "serving",
        calories: targetCalories * 0.35,
        protein:
            targetCalories * 0.35 * 0.3 / 4, // 30% of calories from protein
        carbs: targetCalories * 0.35 * 0.4 / 4, // 40% of calories from carbs
        fat: targetCalories * 0.35 * 0.3 / 9, // 30% of calories from fat
        loggedAt: DateTime.now().copyWith(hour: 19, minute: 0),
      ),
    ];

    return MealPlan(
      id: Uuid().v4(),
      userId: user.id,
      date: DateTime.now(),
      meals: meals,
      createdAt: DateTime.now(),
    );
  }

  Future<List<WorkoutExercise>> _getExercisesForGoal(String goal) async {
    // In a real implementation, fetch exercises from a database based on the goal
    // This is a simplified example

    // Exercises would come from your exercises database
    // For now, return placeholder exercises
    switch (goal) {
      case 'build muscle':
      case 'strength':
        return [
          _createExercise("Bench Press", "chest", 4, 8),
          _createExercise("Squat", "legs", 4, 8),
          _createExercise("Deadlift", "back", 3, 6),
          _createExercise("Shoulder Press", "shoulders", 3, 10),
          _createExercise("Pull-ups", "back", 3, 8),
        ];
      case 'lose weight':
      case 'weight loss':
        return [
          _createExercise("Jump Rope", "cardio", 3, 60), // 60 secs
          _createExercise("Burpees", "full body", 3, 15),
          _createExercise("Mountain Climbers", "core", 3, 30),
          _createExercise("Squat Jumps", "legs", 3, 15),
          _createExercise("Plank", "core", 3, 45), // 45 secs
        ];
      case 'endurance':
      case 'cardio':
        return [
          _createExercise("Running", "cardio", 1, 20), // 20 mins
          _createExercise("Cycling", "cardio", 1, 30), // 30 mins
          _createExercise("Jump Rope", "cardio", 3, 120), // 120 secs
          _createExercise("Jumping Jacks", "cardio", 3, 60), // 60 secs
          _createExercise("Burpees", "cardio", 3, 20),
        ];
      default: // general fitness
        return [
          _createExercise("Push-ups", "chest", 3, 12),
          _createExercise("Squats", "legs", 3, 15),
          _createExercise("Planks", "core", 3, 30), // 30 secs
          _createExercise("Lunges", "legs", 3, 10), // per leg
          _createExercise("Dumbbell Rows", "back", 3, 12), // per arm
        ];
    }
  }

  WorkoutExercise _createExercise(
      String name, String target, int sets, int reps,
      {double? weight}) {
    return WorkoutExercise(
      exerciseId: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      bodyPart: target,
      equipment: "bodyweight",
      target: target,
      gifUrl: "", // Would need actual URL from your exercise database
      sets: sets,
      reps: reps,
      weight: weight,
      notes: null,
    );
  }
}
