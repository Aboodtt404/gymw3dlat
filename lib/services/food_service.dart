import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_model.dart';
import '../models/meal_log_model.dart';
import 'supabase_service.dart';
import 'nutritionix_service.dart';

class FoodService {
  final _supabase = SupabaseService.client;
  final _nutritionixService = NutritionixService();

  Future<List<Food>> searchFoods(String query) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First, search in local database and join with meal_logs to get meal_log_id
      final localResponse = await _supabase
          .from('foods')
          .select('''
            *,
            meal_logs!inner (
              id
            )
          ''')
          .textSearch('name', query)
          .eq('meal_logs.user_id', userId)
          .order('name')
          .limit(20);

      final localFoods = localResponse
          .map((json) => Food.fromJson({
                ...json,
                'meal_log_id': json['meal_logs'][0]['id'],
              }))
          .toList();

      // If we have enough local results, return them
      if (localFoods.length >= 10) {
        return localFoods;
      }

      // Otherwise, also search in Nutritionix
      final nutritionixFoods = await _nutritionixService.searchInstant(query);

      // Combine results, removing duplicates based on name
      final allFoods = {...localFoods, ...nutritionixFoods}.toList();
      return allFoods.take(20).toList();
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

      // First, check if the food exists in our database
      final existingFoods =
          await _supabase.from('foods').select().eq('id', food.id).limit(1);

      // If food doesn't exist, add it to our database
      if (existingFoods.isEmpty) {
        await _supabase.from('foods').insert({
          'id': food.id,
          'name': food.name,
          'brand': food.brand,
          'calories': food.calories,
          'protein': food.protein,
          'carbs': food.carbs,
          'fat': food.fat,
          'serving_size': food.servingSize,
          'serving_unit': food.servingUnit,
        });
      }

      // Log the meal
      await _supabase.from('meal_logs').insert({
        'user_id': userId,
        'food_id': food.id,
        'calories': food.calories,
        'protein': food.protein,
        'carbs': food.carbs,
        'fat': food.fat,
        'serving_size': food.servingSize,
        'serving_unit': food.servingUnit,
        'meal_type': mealType.name,
      });
    } catch (e) {
      throw Exception('Failed to log food: $e');
    }
  }

  Future<void> updateMealLog(MealLog mealLog) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (mealLog.userId != userId) {
        throw Exception('Cannot update meal log: not owner');
      }

      await _supabase.from('meal_logs').update({
        'calories': mealLog.calories,
        'protein': mealLog.protein,
        'carbs': mealLog.carbs,
        'fat': mealLog.fat,
        'serving_size': mealLog.servingSize,
        'serving_unit': mealLog.servingUnit,
        'meal_type': mealLog.mealType.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', mealLog.id);
    } catch (e) {
      throw Exception('Failed to update meal log: $e');
    }
  }

  Future<void> deleteMealLog(String mealLogId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

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
