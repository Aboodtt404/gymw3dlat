import '../models/food_model.dart';
import '../models/meal_log_model.dart';
import '../models/nutrition_models.dart';
import 'supabase_service.dart';
import 'nutritionix_service.dart';

class FoodService {
  final _supabase = SupabaseService.client;
  final _nutritionixService = NutritionixService();

  Future<List<Food>> searchFoods(String query) async {
    try {
      // Check if user is authenticated
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Search using Nutritionix API
      final nutritionixFoods = await _nutritionixService.searchFoods(query);
      return nutritionixFoods;
    } catch (e) {
      throw Exception('Failed to search foods: $e');
    }
  }

  Future<void> logFood(Food food, MealType mealType) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final mealLog = MealLog(
        userId: userId,
        foods: [food],
        mealType: mealType,
        loggedAt: DateTime.now(),
        storedCalories: food.calories,
        storedProtein: food.protein,
        storedCarbs: food.carbs,
        storedFat: food.fat,
      );

      // Start a transaction
      await _supabase.rpc('begin_transaction');

      try {
        // Create a new meal log
        final mealLogResponse = await _supabase
            .from('meal_logs')
            .insert({
              'id': mealLog.id,
              'user_id': mealLog.userId,
              'meal_type': mealLog.mealType.name,
              'logged_at': mealLog.loggedAt.toIso8601String(),
              'notes': mealLog.notes,
              'total_calories': mealLog.storedCalories,
              'total_protein': mealLog.storedProtein,
              'total_carbs': mealLog.storedCarbs,
              'total_fat': mealLog.storedFat,
            })
            .select()
            .single();

        // Add the food to the meal_log_foods table
        await _supabase.from('meal_log_foods').insert({
          'meal_log_id': mealLogResponse['id'],
          'food_id': food.id,
          'name': food.name,
          'brand': food.brand,
          'calories': food.calories,
          'protein': food.protein,
          'carbs': food.carbs,
          'fat': food.fat,
          'serving_size': food.servingSize,
          'serving_unit': food.servingUnit,
        });

        // Commit the transaction
        await _supabase.rpc('commit_transaction');
      } catch (e) {
        // Rollback on error
        await _supabase.rpc('rollback_transaction');
        throw e;
      }
    } catch (e) {
      throw Exception('Failed to log food: $e');
    }
  }

  Future<Map<MealType, List<Food>>> getMealsByType() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('meal_logs_with_foods')
          .select()
          .eq('user_id', userId)
          .gte('logged_at',
              DateTime.now().toUtc().subtract(const Duration(days: 1)))
          .order('logged_at', ascending: false);

      final meals = {
        MealType.breakfast: <Food>[],
        MealType.lunch: <Food>[],
        MealType.dinner: <Food>[],
        MealType.snack: <Food>[],
      };

      for (final log in response) {
        final mealLog = MealLog.fromJson(log);
        // Add each food with its mealLogId
        for (final food in mealLog.foods) {
          meals[mealLog.mealType]?.add(
            food.copyWith(mealLogId: mealLog.id),
          );
        }
      }

      return meals;
    } catch (e) {
      throw Exception('Failed to load meals: $e');
    }
  }

  Future<void> deleteMealLog(String mealLogId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Start a transaction
      await _supabase.rpc('begin_transaction');

      try {
        // Delete the meal_log_foods entries first
        await _supabase
            .from('meal_log_foods')
            .delete()
            .eq('meal_log_id', mealLogId);

        // Then delete the meal log
        await _supabase
            .from('meal_logs')
            .delete()
            .eq('id', mealLogId)
            .eq('user_id', userId);

        // Commit the transaction
        await _supabase.rpc('commit_transaction');
      } catch (e) {
        // Rollback on error
        await _supabase.rpc('rollback_transaction');
        throw e;
      }
    } catch (e) {
      throw Exception('Failed to delete meal log: $e');
    }
  }

  Future<void> deleteFoodFromMealLog(String mealLogId, String foodId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Delete only the specific food from meal_log_foods
      await _supabase
          .from('meal_log_foods')
          .delete()
          .eq('meal_log_id', mealLogId)
          .eq('food_id', foodId);
    } catch (e) {
      throw Exception('Failed to delete food: $e');
    }
  }

  Future<NutritionStatus> getNutritionStatus({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user's nutrition goals
      final userGoalsResponse = await _supabase
          .from('user_nutrition_goals')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // Default goals if none are set
      final userGoals = userGoalsResponse ??
          {
            'calorie_goal': 2000,
            'protein_goal': 150,
            'carbs_goal': 250,
            'fat_goal': 65,
          };

      // Get meal logs for the date range
      final mealLogs = await getMealLogsForDateRange(startDate, endDate);

      // Calculate averages
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      int days = endDate.difference(startDate).inDays + 1;

      for (final log in mealLogs) {
        totalCalories += log.totalCalories;
        totalProtein += log.totalProtein;
        totalCarbs += log.totalCarbs;
        totalFat += log.totalFat;
      }

      double avgCalories = totalCalories / days;
      double avgProtein = totalProtein / days;
      double avgCarbs = totalCarbs / days;
      double avgFat = totalFat / days;

      // Calculate percentages of goals
      double caloriesPercentage =
          avgCalories / (userGoals['calorie_goal'] ?? 2000) * 100;
      double proteinPercentage =
          avgProtein / (userGoals['protein_goal'] ?? 150) * 100;
      double carbsPercentage =
          avgCarbs / (userGoals['carbs_goal'] ?? 250) * 100;
      double fatsPercentage = avgFat / (userGoals['fat_goal'] ?? 65) * 100;

      // Check if values are within acceptable range (80-120% of goal)
      bool caloriesInRange =
          caloriesPercentage >= 80 && caloriesPercentage <= 120;
      bool proteinInRange = proteinPercentage >= 80 && proteinPercentage <= 120;
      bool carbsInRange = carbsPercentage >= 80 && carbsPercentage <= 120;
      bool fatsInRange = fatsPercentage >= 80 && fatsPercentage <= 120;

      return NutritionStatus(
        caloriesInRange: caloriesInRange,
        proteinInRange: proteinInRange,
        carbsInRange: carbsInRange,
        fatsInRange: fatsInRange,
        caloriesPercentage: caloriesPercentage,
        proteinPercentage: proteinPercentage,
        carbsPercentage: carbsPercentage,
        fatsPercentage: fatsPercentage,
      );
    } catch (e) {
      throw Exception('Failed to get nutrition status: $e');
    }
  }

  Future<List<MealLog>> getMealLogsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('meal_logs_with_foods')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startDate.toIso8601String())
          .lte('logged_at', endDate.toIso8601String())
          .order('logged_at');

      return (response as List).map((json) => MealLog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get meal logs: $e');
    }
  }
}
