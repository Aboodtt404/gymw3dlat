import 'package:gymw3dlat/services/workout_service.dart';
import 'package:gymw3dlat/services/meal_plan_service.dart';

class RecommendationService {
  final WorkoutService _workoutService = WorkoutService();
  final MealPlanService _mealPlanService = MealPlanService();

  // Main function to get recommendations for a user
  Future<UserRecommendation> getUserRecommendations(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    // Default to analyzing the last 30 days if no dates are provided
    final endDateTime = endDate ?? DateTime.now();
    final startDateTime =
        startDate ?? endDateTime.subtract(const Duration(days: 30));

    // Analyze workout data
    final workoutAnalysis =
        await _analyzeWorkouts(userId, startDateTime, endDateTime);

    // Analyze nutrition data
    final nutritionAnalysis =
        await _analyzeNutrition(userId, startDateTime, endDateTime);

    // Build comprehensive recommendation
    return UserRecommendation(
      userId: userId,
      workoutRecommendations: workoutAnalysis,
      nutritionRecommendations: nutritionAnalysis,
      generatedDate: DateTime.now(),
    );
  }

  // Analyze workout data to find neglected body parts
  Future<WorkoutRecommendation> _analyzeWorkouts(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      // Get user workout logs for the time period
      final logs = await _workoutService.getUserWorkoutLogs(userId,
          startDate: startDate, endDate: endDate);

      if (logs.isEmpty) {
        return WorkoutRecommendation(
            neglectedBodyParts: [],
            overtrainedBodyParts: [],
            recommendedExercises: [],
            message:
                "No workout data available for analysis. Try to log some workouts first!");
      }

      // Count frequency of body parts trained
      final bodyPartFrequency = <String, int>{};
      final bodyPartLastTrained = <String, DateTime>{};
      final allBodyParts = [
        'chest',
        'back',
        'shoulders',
        'upper arms',
        'lower arms',
        'upper legs',
        'lower legs',
        'waist',
        'cardio'
      ];

      // Initialize all body parts to zero
      for (final part in allBodyParts) {
        bodyPartFrequency[part] = 0;
      }

      // Count frequency from workout logs
      for (final log in logs) {
        for (final exercise in log.exercises) {
          final bodyPart = exercise.exerciseId;
          bodyPartFrequency[bodyPart] = (bodyPartFrequency[bodyPart] ?? 0) + 1;
          bodyPartLastTrained[bodyPart] = log.startTime;
        }
      }

      // Identify neglected body parts (trained less than 20% of the average)
      final averageTraining =
          bodyPartFrequency.values.fold<int>(0, (sum, freq) => sum + freq) /
              bodyPartFrequency.length;
      final neglectedParts = bodyPartFrequency.entries
          .where((entry) => entry.value < averageTraining * 0.2)
          .map((entry) => entry.key)
          .toList();

      // Identify potentially overtrained body parts (trained more than 2x the average)
      final overtrainedParts = bodyPartFrequency.entries
          .where((entry) => entry.value > averageTraining * 2)
          .map((entry) => entry.key)
          .toList();

      // Generate recommended exercises for neglected body parts
      final recommendedExercises = <String>[];
      for (final bodyPart in neglectedParts) {
        final exercises = await _getRecommendedExercisesForBodyPart(bodyPart);
        recommendedExercises.addAll(exercises);
      }

      // Generate recommendation message
      String message = "";
      if (neglectedParts.isNotEmpty) {
        message =
            "We noticed you've been neglecting your ${neglectedParts.join(', ')}. "
            "Consider adding exercises targeting these areas to maintain balance.";
      } else {
        message =
            "Great job! You've been training all body parts consistently.";
      }

      if (overtrainedParts.isNotEmpty) {
        message +=
            " You might be overtraining your ${overtrainedParts.join(', ')}. "
            "Consider giving these areas more rest between intense sessions.";
      }

      return WorkoutRecommendation(
          neglectedBodyParts: neglectedParts,
          overtrainedBodyParts: overtrainedParts,
          recommendedExercises: recommendedExercises,
          message: message);
    } catch (e) {
      return WorkoutRecommendation(
          neglectedBodyParts: [],
          overtrainedBodyParts: [],
          recommendedExercises: [],
          message: "Error analyzing workout data: $e");
    }
  }

  // Get recommended exercises for a specific body part
  Future<List<String>> _getRecommendedExercisesForBodyPart(
      String bodyPart) async {
    // This would ideally come from your exercises database
    // Simplified for now with placeholder recommendations
    switch (bodyPart.toLowerCase()) {
      case 'chest':
        return ['Bench Press', 'Push-ups', 'Dumbbell Flyes'];
      case 'back':
        return ['Pull-ups', 'Rows', 'Lat Pulldowns'];
      case 'shoulders':
        return ['Shoulder Press', 'Lateral Raises', 'Face Pulls'];
      case 'upper arms':
        return ['Bicep Curls', 'Tricep Extensions', 'Hammer Curls'];
      case 'lower arms':
        return ['Wrist Curls', 'Reverse Wrist Curls', 'Farmers Walk'];
      case 'upper legs':
        return ['Squats', 'Lunges', 'Leg Press'];
      case 'lower legs':
        return ['Calf Raises', 'Seated Calf Raises', 'Box Jumps'];
      case 'waist':
        return ['Planks', 'Russian Twists', 'Leg Raises'];
      case 'cardio':
        return ['Running', 'Cycling', 'Jumping Rope'];
      default:
        return ['Full Body Workout'];
    }
  }

  // Analyze nutrition data to find deficits
  Future<NutritionRecommendation> _analyzeNutrition(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      // Get user meal logs for the time period
      final mealPlans = await _mealPlanService.getUserMealPlans(userId,
          startDate: startDate, endDate: endDate);

      if (mealPlans.isEmpty) {
        return NutritionRecommendation(
            calorieDeficit: false,
            proteinDeficit: false,
            fatDeficit: false,
            carbDeficit: false,
            recommendedFoods: [],
            message:
                "No nutrition data available for analysis. Try logging your meals first!");
      }

      // Calculate daily averages
      double totalCalories = 0;
      double totalProtein = 0;
      double totalFat = 0;
      double totalCarbs = 0;
      int daysWithData = 0;

      for (final plan in mealPlans) {
        if (plan.meals.isNotEmpty) {
          daysWithData++;
          double dailyCalories = 0;
          double dailyProtein = 0;
          double dailyFat = 0;
          double dailyCarbs = 0;

          for (final meal in plan.meals) {
            dailyCalories += meal.calories;
            dailyProtein += meal.protein;
            dailyFat += meal.fat;
            dailyCarbs += meal.carbs;
          }

          totalCalories += dailyCalories;
          totalProtein += dailyProtein;
          totalFat += dailyFat;
          totalCarbs += dailyCarbs;
        }
      }

      if (daysWithData == 0) {
        return NutritionRecommendation(
            calorieDeficit: false,
            proteinDeficit: false,
            fatDeficit: false,
            carbDeficit: false,
            recommendedFoods: [],
            message: "No meal data found in the selected time period.");
      }

      final avgCalories = totalCalories / daysWithData;
      final avgProtein = totalProtein / daysWithData;
      final avgFat = totalFat / daysWithData;
      final avgCarbs = totalCarbs / daysWithData;

      // Check for deficits (using general recommendations - customize based on user goals)
      // These thresholds should actually be personalized based on user stats
      final calorieDeficit = avgCalories < 1800; // Example threshold
      final proteinDeficit = avgProtein < 50; // Example threshold in grams
      final fatDeficit = avgFat < 50; // Example threshold in grams
      final carbDeficit = avgCarbs < 150; // Example threshold in grams

      // Generate recommended foods based on deficits
      final recommendedFoods = <String>[];

      if (proteinDeficit) {
        recommendedFoods
            .addAll(['Chicken breast', 'Greek yogurt', 'Eggs', 'Whey protein']);
      }

      if (fatDeficit) {
        recommendedFoods.addAll(['Avocado', 'Nuts', 'Olive oil', 'Fatty fish']);
      }

      if (carbDeficit) {
        recommendedFoods.addAll(['Rice', 'Sweet potatoes', 'Oats', 'Fruits']);
      }

      // Generate recommendation message
      String message = "";
      if (calorieDeficit) {
        message =
            "You're not consuming enough calories. Consider increasing your portion sizes. ";
      }

      if (proteinDeficit) {
        message +=
            "Your protein intake is below recommended levels. Try adding more protein-rich foods. ";
      }

      if (fatDeficit) {
        message +=
            "Your fat intake is below recommended levels. Consider adding healthy fats to your diet. ";
      }

      if (carbDeficit) {
        message +=
            "Your carbohydrate intake is low. Consider adding more quality carbs for energy. ";
      }

      if (message.isEmpty) {
        message = "Your nutrition looks well-balanced! Keep up the good work.";
      }

      return NutritionRecommendation(
          calorieDeficit: calorieDeficit,
          proteinDeficit: proteinDeficit,
          fatDeficit: fatDeficit,
          carbDeficit: carbDeficit,
          recommendedFoods: recommendedFoods,
          message: message);
    } catch (e) {
      return NutritionRecommendation(
          calorieDeficit: false,
          proteinDeficit: false,
          fatDeficit: false,
          carbDeficit: false,
          recommendedFoods: [],
          message: "Error analyzing nutrition data: $e");
    }
  }
}

// Model classes for recommendations
class UserRecommendation {
  final String userId;
  final WorkoutRecommendation workoutRecommendations;
  final NutritionRecommendation nutritionRecommendations;
  final DateTime generatedDate;

  UserRecommendation({
    required this.userId,
    required this.workoutRecommendations,
    required this.nutritionRecommendations,
    required this.generatedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'workout_recommendations': workoutRecommendations.toJson(),
      'nutrition_recommendations': nutritionRecommendations.toJson(),
      'generated_date': generatedDate.toIso8601String(),
    };
  }
}

class WorkoutRecommendation {
  final List<String> neglectedBodyParts;
  final List<String> overtrainedBodyParts;
  final List<String> recommendedExercises;
  final String message;

  WorkoutRecommendation({
    required this.neglectedBodyParts,
    required this.overtrainedBodyParts,
    required this.recommendedExercises,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'neglected_body_parts': neglectedBodyParts,
      'overtrained_body_parts': overtrainedBodyParts,
      'recommended_exercises': recommendedExercises,
      'message': message,
    };
  }
}

class NutritionRecommendation {
  final bool calorieDeficit;
  final bool proteinDeficit;
  final bool fatDeficit;
  final bool carbDeficit;
  final List<String> recommendedFoods;
  final String message;

  NutritionRecommendation({
    required this.calorieDeficit,
    required this.proteinDeficit,
    required this.fatDeficit,
    required this.carbDeficit,
    required this.recommendedFoods,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'calorie_deficit': calorieDeficit,
      'protein_deficit': proteinDeficit,
      'fat_deficit': fatDeficit,
      'carb_deficit': carbDeficit,
      'recommended_foods': recommendedFoods,
      'message': message,
    };
  }
}
