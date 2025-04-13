import 'package:gymw3dlat/models/meal_log_model.dart';
import 'package:gymw3dlat/models/food_model.dart';
import 'package:gymw3dlat/services/supabase_service.dart';
import 'package:gymw3dlat/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealLogService {
  final _supabase = SupabaseService.client;

  // Add a new meal log
  Future<MealLog> addMealLog(MealLog mealLog) async {
    final response = await SupabaseService.client
        .from('meal_logs')
        .insert(mealLog.toJson())
        .select()
        .single();

    // Fetch the associated food
    final foodResponse = await SupabaseService.client
        .from(AppConstants.nutritionCollection)
        .select()
        .eq('id', mealLog.foodId)
        .single();

    final food = Food.fromJson(foodResponse);
    return MealLog.fromJson(response, food: food);
  }

  Future<List<MealLog>> getMealLogsForDate(DateTime date) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('meal_logs')
          .select('*, foods(*)')
          .eq('user_id', userId)
          .gte('logged_at', startOfDay.toIso8601String())
          .lt('logged_at', endOfDay.toIso8601String())
          .order('logged_at');

      return response.map((json) {
        final foodJson = json['foods'] as Map<String, dynamic>;
        final food = Food.fromJson(foodJson);
        return MealLog.fromJson(json, food: food);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get meal logs: $e');
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

      final startOfDay =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day)
          .add(const Duration(days: 1));

      final response = await _supabase
          .from('meal_logs')
          .select('*, foods(*)')
          .eq('user_id', userId)
          .gte('logged_at', startOfDay.toIso8601String())
          .lt('logged_at', endOfDay.toIso8601String())
          .order('logged_at');

      return response.map((json) {
        final foodJson = json['foods'] as Map<String, dynamic>;
        final food = Food.fromJson(foodJson);
        return MealLog.fromJson(json, food: food);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get meal logs: $e');
    }
  }

  Future<Map<String, double>> getNutritionSummaryForDate(DateTime date) async {
    try {
      final mealLogs = await getMealLogsForDate(date);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final log in mealLogs) {
        totalCalories += log.calories;
        totalProtein += log.protein;
        totalCarbs += log.carbs;
        totalFat += log.fat;
      }

      return {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
      };
    } catch (e) {
      throw Exception('Failed to get nutrition summary: $e');
    }
  }

  // Get nutrition summary for a specific date
  Future<NutritionSummary> getNutritionSummary(DateTime date) async {
    final logs = await getMealLogsForDate(date);

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    final mealTypeTotals = {
      MealType.breakfast: 0.0,
      MealType.lunch: 0.0,
      MealType.dinner: 0.0,
      MealType.snack: 0.0,
    };

    for (final log in logs) {
      totalCalories += log.calories;
      totalProtein += log.protein;
      totalCarbs += log.carbs;
      totalFat += log.fat;
      mealTypeTotals[log.mealType] =
          (mealTypeTotals[log.mealType] ?? 0) + log.calories;
    }

    return NutritionSummary(
      date: date,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      mealTypeTotals: mealTypeTotals,
      numberOfMeals: logs.length,
    );
  }

  // Get nutrition summary for a date range
  Future<List<NutritionSummary>> getNutritionSummaryRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final summaries = <NutritionSummary>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final summary = await getNutritionSummary(currentDate);
      summaries.add(summary);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return summaries;
  }

  // Delete a meal log
  Future<void> deleteMealLog(String id) async {
    await SupabaseService.client.from('meal_logs').delete().eq('id', id);
  }

  // Update a meal log
  Future<MealLog> updateMealLog(MealLog mealLog) async {
    final response = await SupabaseService.client
        .from('meal_logs')
        .update(mealLog.toJson())
        .eq('id', mealLog.id)
        .select()
        .single();

    return MealLog.fromJson(response, food: mealLog.food);
  }
}

class NutritionSummary {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final Map<MealType, double> mealTypeTotals;
  final int numberOfMeals;

  NutritionSummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.mealTypeTotals,
    required this.numberOfMeals,
  });

  // Calculate macronutrient percentages
  double get proteinPercentage => (totalProtein * 4 / totalCalories) * 100;
  double get carbsPercentage => (totalCarbs * 4 / totalCalories) * 100;
  double get fatPercentage => (totalFat * 9 / totalCalories) * 100;
}
