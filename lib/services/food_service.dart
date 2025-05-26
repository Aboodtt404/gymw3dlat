import '../models/food_model.dart';
import '../models/meal_log_model.dart';
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

      // Start a transaction
      await _supabase.rpc('begin_transaction');

      try {
        // Create a new meal log
        final mealLogResponse = await _supabase
            .from('meal_logs')
            .insert({
              'user_id': userId,
              'meal_type': mealType.name,
              'logged_at': DateTime.now().toIso8601String(),
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
          .order('logged_at');

      final meals = {
        MealType.breakfast: <Food>[],
        MealType.lunch: <Food>[],
        MealType.dinner: <Food>[],
        MealType.snack: <Food>[],
      };

      for (final log in response) {
        final mealLog = MealLog.fromJson(log);
        meals[mealLog.mealType]?.addAll(mealLog.foods);
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

      // The meal_log_foods entries will be automatically deleted due to CASCADE
      await _supabase
          .from('meal_logs')
          .delete()
          .eq('id', mealLogId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete meal log: $e');
    }
  }
}
