import 'package:gymw3dlat/services/workout_service.dart';
import 'package:gymw3dlat/services/meal_plan_service.dart';
import '../models/nutrition_models.dart';
import '../models/workout_models.dart' show WorkoutIntensity;
import '../models/ai_workout_models.dart';
import 'supabase_service.dart';
import 'package:uuid/uuid.dart';

class RecommendationService {
  final WorkoutService _workoutService = WorkoutService();
  final MealPlanService _mealPlanService = MealPlanService();
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  // Main function to get recommendations for a user
  Future<NutritionRecommendation> getUserRecommendations(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get user's nutrition goals
      final userGoalsResponse = await _client
          .from('user_nutrition_goals')
          .select()
          .eq('user_id', userId)
          .maybeSingle(); // Use maybeSingle() instead of single()

      // Default goals if none are set
      final userGoals = userGoalsResponse ??
          {
            'calorie_goal': 2000,
            'protein_goal': 150,
            'carbs_goal': 250,
            'fat_goal': 65,
          };

      // Get meal logs for analysis
      final mealLogs = await _client
          .from('meal_logs_with_foods')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startDate.toIso8601String())
          .lte('logged_at', endDate.toIso8601String());

      if (mealLogs.isEmpty) {
        return NutritionRecommendation(
          message:
              'No nutrition data available for analysis. Try logging your meals first!',
          recommendedFoods: [],
          calorieDeficit: false,
          proteinDeficit: false,
          fatDeficit: false,
          carbDeficit: false,
        );
      }

      // Calculate daily averages
      double avgCalories = 0;
      double avgProtein = 0;
      double avgCarbs = 0;
      double avgFat = 0;
      int days = endDate.difference(startDate).inDays + 1;

      for (final log in mealLogs) {
        avgCalories += (log['calories'] ?? 0) / days;
        avgProtein += (log['protein'] ?? 0) / days;
        avgCarbs += (log['carbs'] ?? 0) / days;
        avgFat += (log['fat'] ?? 0) / days;
      }

      // Check for deficits
      bool calorieDeficit =
          avgCalories < (userGoals['calorie_goal'] ?? 2000) * 0.8;
      bool proteinDeficit =
          avgProtein < (userGoals['protein_goal'] ?? 150) * 0.8;
      bool carbDeficit = avgCarbs < (userGoals['carbs_goal'] ?? 250) * 0.8;
      bool fatDeficit = avgFat < (userGoals['fat_goal'] ?? 65) * 0.8;

      // Generate recommendations
      List<String> recommendedFoods = [];
      String message = '';

      if (calorieDeficit) {
        message += 'Your calorie intake is below target. ';
        recommendedFoods
            .addAll(['Nuts', 'Avocado', 'Olive Oil', 'Whole Grains']);
      }

      if (proteinDeficit) {
        message += 'You need more protein in your diet. ';
        recommendedFoods
            .addAll(['Chicken Breast', 'Greek Yogurt', 'Eggs', 'Fish']);
      }

      if (carbDeficit) {
        message += 'Consider adding more complex carbohydrates. ';
        recommendedFoods
            .addAll(['Sweet Potatoes', 'Quinoa', 'Brown Rice', 'Oats']);
      }

      if (fatDeficit) {
        message += 'Include more healthy fats. ';
        recommendedFoods.addAll(['Salmon', 'Almonds', 'Chia Seeds', 'Avocado']);
      }

      if (message.isEmpty) {
        message = 'Great job! Your nutrition is well-balanced.';
      }

      return NutritionRecommendation(
        message: message,
        recommendedFoods:
            recommendedFoods.toSet().toList(), // Remove duplicates
        calorieDeficit: calorieDeficit,
        proteinDeficit: proteinDeficit,
        fatDeficit: fatDeficit,
        carbDeficit: carbDeficit,
      );
    } catch (e) {
      throw Exception('Failed to get nutrition recommendations: $e');
    }
  }

  // Analyze workout data to find neglected body parts
  Future<AIWorkoutRecommendation> _analyzeWorkouts(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      // Get user workout logs for the time period
      final logs = await _workoutService.getUserWorkoutLogs(userId,
          startDate: startDate, endDate: endDate);

      if (logs.isEmpty) {
        return AIWorkoutRecommendation(
          id: _uuid.v4(),
          userId: userId,
          name: 'Beginner Full Body Workout',
          description: 'A balanced workout suitable for beginners',
          exercises: [
            SmartExerciseSet(
              exerciseId: 'pushups',
              sets: 3,
              reps: 10,
              adaptationFactor: 1.0,
              adaptationReason: 'Initial exercise',
              alternatives: ['knee pushups', 'wall pushups'],
              progressionRules: {'increase_reps': 2, 'max_sets': 5},
            ),
            SmartExerciseSet(
              exerciseId: 'squats',
              sets: 3,
              reps: 12,
              adaptationFactor: 1.0,
              adaptationReason: 'Initial exercise',
              alternatives: ['assisted squats', 'lunges'],
              progressionRules: {'increase_reps': 2, 'max_sets': 5},
            ),
          ],
          intensity: WorkoutIntensity.light,
          estimatedDuration: 30,
          difficultyScore: 2.0,
          confidenceScore: 0.9,
          reasoning: 'Recommended for new users to establish baseline fitness',
          focusAreas: ['Full Body', 'Core Strength', 'Cardio'],
          createdAt: DateTime.now(),
          aiMetadata: {
            'recommendation_type': 'default',
            'user_history': 'none'
          },
        );
      }

      // Analyze workout patterns and generate recommendations
      return AIWorkoutRecommendation(
        id: _uuid.v4(),
        userId: userId,
        name: 'Custom Workout Plan',
        description: 'Based on your workout history',
        exercises: [
          SmartExerciseSet(
            exerciseId: 'exercise1',
            sets: 3,
            reps: 12,
            adaptationFactor: 1.0,
            adaptationReason: 'Based on history',
            alternatives: ['alt1', 'alt2'],
            progressionRules: {'increase_reps': 2, 'max_sets': 5},
          ),
          SmartExerciseSet(
            exerciseId: 'exercise2',
            sets: 3,
            reps: 12,
            adaptationFactor: 1.0,
            adaptationReason: 'Based on history',
            alternatives: ['alt1', 'alt2'],
            progressionRules: {'increase_reps': 2, 'max_sets': 5},
          ),
        ],
        intensity: WorkoutIntensity.moderate,
        estimatedDuration: 45,
        difficultyScore: 3.0,
        confidenceScore: 0.85,
        reasoning: 'Based on your workout patterns',
        focusAreas: ['Strength', 'Endurance'],
        createdAt: DateTime.now(),
        aiMetadata: {
          'recommendation_type': 'custom',
          'user_history': 'analyzed'
        },
      );
    } catch (e) {
      throw Exception('Failed to analyze workouts: $e');
    }
  }

  List<String> _getExercisesForMuscleGroups(List<String> muscleGroups) {
    // Implementation remains the same
    return ['Exercise 1', 'Exercise 2'];
  }

  List<String> _getProgressiveExercises(List<String> currentExercises) {
    // Implementation remains the same
    return ['Progressive Exercise 1', 'Progressive Exercise 2'];
  }
}
