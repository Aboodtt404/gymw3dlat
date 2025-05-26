import 'package:gymw3dlat/models/meal_plan_model.dart';
import 'package:gymw3dlat/services/supabase_service.dart';

class MealPlanService {
  static const String tableName = 'meal_plans';

  // Get all meal plans for a user
  Future<List<MealPlan>> getUserMealPlans(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = SupabaseService.client.from(tableName).select();

      // Add filters using match for exact and conditional filters
      Map<String, Object> filters = {'user_id': userId};

      if (startDate != null) {
        // We'll filter results in-memory for date ranges
      }

      if (endDate != null) {
        // We'll filter results in-memory for date ranges
      }

      // Apply the base filter with match
      final response =
          await query.match(filters).order('date', ascending: false);
      List<MealPlan> plans =
          (response as List).map((json) => MealPlan.fromJson(json)).toList();

      // Apply date range filters in-memory if needed
      if (startDate != null || endDate != null) {
        plans = plans.where((plan) {
          bool passesFilter = true;
          if (startDate != null && plan.date.isBefore(startDate)) {
            passesFilter = false;
          }
          if (endDate != null && plan.date.isAfter(endDate)) {
            passesFilter = false;
          }
          return passesFilter;
        }).toList();
      }

      return plans;
    } catch (e) {
      print('Error fetching user meal plans: $e');
      throw Exception('Failed to fetch meal plans: $e');
    }
  }

  // Get a meal plan by date
  Future<MealPlan?> getMealPlanByDate(String userId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await SupabaseService.client
          .from(tableName)
          .select()
          .eq('user_id', userId)
          .eq('date', dateStr)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return MealPlan.fromJson(response);
    } catch (e) {
      print('Error fetching meal plan by date: $e');
      throw Exception('Failed to fetch meal plan: $e');
    }
  }

  // Create a new meal plan
  Future<MealPlan> createMealPlan(MealPlan mealPlan) async {
    try {
      final response = await SupabaseService.client
          .from(tableName)
          .insert(mealPlan.toJson())
          .select()
          .single();

      return MealPlan.fromJson(response);
    } catch (e) {
      print('Error creating meal plan: $e');
      throw Exception('Failed to create meal plan: $e');
    }
  }

  // Create a new plan
  Future<MealPlan> createPlan(MealPlan mealPlan) async {
    return createMealPlan(mealPlan);
  }

  // Get the current plan for a user
  Future<MealPlan?> getCurrentPlan(String userId) async {
    try {
      final response = await SupabaseService.client
          .from(tableName)
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return MealPlan.fromJson(response);
    } catch (e) {
      print('Error getting current meal plan: $e');
      throw Exception('Failed to get current meal plan: $e');
    }
  }

  // Update an existing meal plan
  Future<MealPlan> updateMealPlan(MealPlan mealPlan) async {
    try {
      // Add updated timestamp
      final updatedMealPlan = mealPlan.copyWith(updatedAt: DateTime.now());

      final response = await SupabaseService.client
          .from(tableName)
          .update(updatedMealPlan.toJson())
          .eq('id', mealPlan.id)
          .select()
          .single();

      return MealPlan.fromJson(response);
    } catch (e) {
      print('Error updating meal plan: $e');
      throw Exception('Failed to update meal plan: $e');
    }
  }

  // Delete a meal plan
  Future<void> deleteMealPlan(String id) async {
    try {
      await SupabaseService.client.from(tableName).delete().eq('id', id);
    } catch (e) {
      print('Error deleting meal plan: $e');
      throw Exception('Failed to delete meal plan: $e');
    }
  }

  // Add a meal to a meal plan
  Future<MealPlan> addMealToMealPlan(String mealPlanId, Meal meal) async {
    try {
      // First get the current meal plan
      final response = await SupabaseService.client
          .from(tableName)
          .select()
          .eq('id', mealPlanId)
          .single();

      final mealPlan = MealPlan.fromJson(response);

      // Add the meal to the list
      final updatedMeals = [...mealPlan.meals, meal];

      // Update the meal plan
      final updatedMealPlan = mealPlan.copyWith(
        meals: updatedMeals,
        updatedAt: DateTime.now(),
      );

      return await updateMealPlan(updatedMealPlan);
    } catch (e) {
      print('Error adding meal to meal plan: $e');
      throw Exception('Failed to add meal to meal plan: $e');
    }
  }

  // Remove a meal from a meal plan
  Future<MealPlan> removeMealFromMealPlan(
      String mealPlanId, String mealId) async {
    try {
      // First get the current meal plan
      final response = await SupabaseService.client
          .from(tableName)
          .select()
          .eq('id', mealPlanId)
          .single();

      final mealPlan = MealPlan.fromJson(response);

      // Remove the meal from the list
      final updatedMeals =
          mealPlan.meals.where((meal) => meal.id != mealId).toList();

      // Update the meal plan
      final updatedMealPlan = mealPlan.copyWith(
        meals: updatedMeals,
        updatedAt: DateTime.now(),
      );

      return await updateMealPlan(updatedMealPlan);
    } catch (e) {
      print('Error removing meal from meal plan: $e');
      throw Exception('Failed to remove meal from meal plan: $e');
    }
  }

  // Get nutrition statistics for a user
  Future<Map<String, dynamic>> getNutritionStats(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final mealPlans = await getUserMealPlans(userId,
          startDate: startDate, endDate: endDate);

      if (mealPlans.isEmpty) {
        return {
          'avgCalories': 0,
          'avgProtein': 0,
          'avgFat': 0,
          'avgCarbs': 0,
          'daysTracked': 0,
          'calorieGoalReached': 0,
          'proteinGoalReached': 0,
          'fatGoalReached': 0,
          'carbsGoalReached': 0,
        };
      }

      double totalCalories = 0;
      double totalProtein = 0;
      double totalFat = 0;
      double totalCarbs = 0;
      int calorieGoalReached = 0;
      int proteinGoalReached = 0;
      int fatGoalReached = 0;
      int carbsGoalReached = 0;

      for (final plan in mealPlans) {
        totalCalories += plan.totalCalories;
        totalProtein += plan.totalProtein;
        totalFat += plan.totalFat;
        totalCarbs += plan.totalCarbs;

        if (plan.targetCalories != null &&
            plan.totalCalories >= plan.targetCalories!) {
          calorieGoalReached++;
        }

        if (plan.targetProtein != null &&
            plan.totalProtein >= plan.targetProtein!) {
          proteinGoalReached++;
        }

        if (plan.targetFat != null && plan.totalFat >= plan.targetFat!) {
          fatGoalReached++;
        }

        if (plan.targetCarbs != null && plan.totalCarbs >= plan.targetCarbs!) {
          carbsGoalReached++;
        }
      }

      final daysTracked = mealPlans.length;

      return {
        'avgCalories': daysTracked > 0 ? totalCalories / daysTracked : 0,
        'avgProtein': daysTracked > 0 ? totalProtein / daysTracked : 0,
        'avgFat': daysTracked > 0 ? totalFat / daysTracked : 0,
        'avgCarbs': daysTracked > 0 ? totalCarbs / daysTracked : 0,
        'daysTracked': daysTracked,
        'calorieGoalReached': calorieGoalReached,
        'proteinGoalReached': proteinGoalReached,
        'fatGoalReached': fatGoalReached,
        'carbsGoalReached': carbsGoalReached,
      };
    } catch (e) {
      print('Error calculating nutrition stats: $e');
      throw Exception('Failed to calculate nutrition stats: $e');
    }
  }
}
