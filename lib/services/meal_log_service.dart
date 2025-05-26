import 'package:gymw3dlat/models/meal_log_model.dart';
import 'package:gymw3dlat/models/food_model.dart';
import 'package:gymw3dlat/services/supabase_service.dart';
import 'package:gymw3dlat/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

class MealLogService {
  static final MealLogService _instance = MealLogService._internal();
  factory MealLogService() => _instance;
  MealLogService._internal();

  final _supabase = SupabaseService.client;

  Future<void> logMeal(MealLog mealLog) async {
    try {
      debugPrint('Logging meal: ${mealLog.toJson()}');

      // Start a transaction
      await _supabase.rpc('begin_transaction');

      try {
        // Insert the meal log
        final mealLogResponse = await _supabase
            .from('meal_logs')
            .insert({
              'id': mealLog.id,
              'user_id': mealLog.userId,
              'meal_type': mealLog.mealType.name,
              'logged_at': mealLog.loggedAt.toIso8601String(),
              'notes': mealLog.notes,
            })
            .select()
            .single();

        // Insert each food in the meal_log_foods table
        for (final food in mealLog.foods) {
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
        }

        // Commit the transaction
        await _supabase.rpc('commit_transaction');
        debugPrint('Meal logged successfully');
      } catch (e) {
        // Rollback on error
        await _supabase.rpc('rollback_transaction');
        throw e;
      }
    } catch (e) {
      debugPrint('Error logging meal: $e');
      throw Exception('Failed to log meal: $e');
    }
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
          .from('meal_logs_with_foods')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startOfDay.toIso8601String())
          .lt('logged_at', endOfDay.toIso8601String())
          .order('logged_at');

      return (response as List).map((json) => MealLog.fromJson(json)).toList();
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
        totalCalories += log.totalCalories;
        totalProtein += log.totalProtein;
        totalCarbs += log.totalCarbs;
        totalFat += log.totalFat;
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
          .from('meal_logs_with_foods')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startOfDay.toIso8601String())
          .lt('logged_at', endOfDay.toIso8601String())
          .order('logged_at');

      return (response as List).map((json) => MealLog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get meal logs: $e');
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

      await _supabase
          .from('meal_logs')
          .delete()
          .eq('id', mealLogId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete meal log: $e');
    }
  }

  /// Get meal logs for a user within a date range
  Future<List<MealLog>> getMealLogs({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query =
          _supabase.from('meal_logs_with_foods').select().eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('logged_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('logged_at', endDate.toIso8601String());
      }

      final response = await query.order('logged_at', ascending: false);

      return (response as List).map((json) => MealLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting meal logs: $e');
      throw Exception('Failed to get meal logs: $e');
    }
  }

  /// Get meal logs for today
  Future<List<MealLog>> getTodaysMealLogs(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getMealLogs(
      userId: userId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Get nutrition summary for a date range
  Future<NutritionSummary> getNutritionSummary(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final logs = await getMealLogs(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final log in logs) {
      totalCalories += log.totalCalories;
      totalProtein += log.totalProtein;
      totalCarbs += log.totalCarbs;
      totalFat += log.totalFat;
    }

    return NutritionSummary(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

class NutritionSummary {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime startDate;
  final DateTime endDate;

  const NutritionSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.startDate,
    required this.endDate,
  });
}
