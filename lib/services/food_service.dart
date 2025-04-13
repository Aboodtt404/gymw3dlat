import 'package:gymw3dlat/models/food_model.dart';
import 'package:gymw3dlat/services/supabase_service.dart';
import 'package:gymw3dlat/constants/app_constants.dart';

class FoodService {
  // Add a new food item
  Future<Food> addFood(Food food) async {
    final response = await SupabaseService.client
        .from(AppConstants.nutritionCollection)
        .insert(food.toJson())
        .select()
        .single();

    return Food.fromJson(response);
  }

  // Search foods by name
  Future<List<Food>> searchFoods(String query) async {
    final response = await SupabaseService.client
        .from(AppConstants.nutritionCollection)
        .select()
        .ilike('name', '%$query%')
        .limit(20);

    return (response as List).map((json) => Food.fromJson(json)).toList();
  }

  // Update food item
  Future<Food> updateFood(Food food) async {
    final response = await SupabaseService.client
        .from(AppConstants.nutritionCollection)
        .update(food.toJson())
        .eq('id', food.id)
        .select()
        .single();

    return Food.fromJson(response);
  }

  // Delete food item
  Future<void> deleteFood(String id) async {
    await SupabaseService.client
        .from(AppConstants.nutritionCollection)
        .delete()
        .eq('id', id);
  }

  // Get recent foods
  Future<List<Food>> getRecentFoods({int limit = 10}) async {
    final response = await SupabaseService.client
        .from(AppConstants.nutritionCollection)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => Food.fromJson(json)).toList();
  }
}
