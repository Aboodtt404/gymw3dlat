import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class NutritionAnalyticsService {
  static final NutritionAnalyticsService _instance =
      NutritionAnalyticsService._internal();
  factory NutritionAnalyticsService() => _instance;
  NutritionAnalyticsService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Get daily calorie trends for the last n days
  Future<List<FlSpot>> getCalorieTrends(int days) async {
    try {
      final response = await _client
          .from('meal_logs')
          .select('created_at, calories')
          .gte('created_at',
              DateTime.now().subtract(Duration(days: days)).toIso8601String())
          .order('created_at');

      // Group by date and sum calories
      Map<String, double> dailyCalories = {};
      for (final row in response) {
        String date =
            DateTime.parse(row['created_at']).toIso8601String().split('T')[0];
        double calories = (row['calories'] ?? 0).toDouble();
        dailyCalories[date] = (dailyCalories[date] ?? 0) + calories;
      }

      // Convert to FlSpot for charts
      List<FlSpot> spots = [];
      int index = 0;
      dailyCalories.forEach((date, calories) {
        spots.add(FlSpot(index.toDouble(), calories));
        index++;
      });

      return spots;
    } catch (e) {
      throw Exception('Failed to get calorie trends: $e');
    }
  }

  // Get macro distribution for a specific date
  Future<Map<String, double>> getMacroDistribution(DateTime date) async {
    try {
      final startOfDay =
          DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59)
          .toIso8601String();

      final response = await _client
          .from('meal_logs')
          .select('protein, carbs, fat')
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay);

      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final row in response) {
        totalProtein += (row['protein'] ?? 0).toDouble();
        totalCarbs += (row['carbs'] ?? 0).toDouble();
        totalFat += (row['fat'] ?? 0).toDouble();
      }

      return {
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
      };
    } catch (e) {
      throw Exception('Failed to get macro distribution: $e');
    }
  }

  // Get meal timing patterns
  Future<Map<String, List<int>>> getMealTimingPatterns(int days) async {
    try {
      final response = await _client
          .from('meal_logs')
          .select('meal_type, created_at')
          .gte('created_at',
              DateTime.now().subtract(Duration(days: days)).toIso8601String());

      Map<String, List<int>> mealTimes = {
        'breakfast': [],
        'lunch': [],
        'dinner': [],
        'snacks': [],
      };

      for (final row in response) {
        String mealType = row['meal_type'];
        DateTime mealTime = DateTime.parse(row['created_at']);
        int hour = mealTime.hour;

        mealTimes[mealType]?.add(hour);
      }

      return mealTimes;
    } catch (e) {
      throw Exception('Failed to get meal timing patterns: $e');
    }
  }

  // Get most frequent foods
  Future<List<Map<String, dynamic>>> getMostFrequentFoods(int limit) async {
    try {
      final response = await _client
          .rpc('get_most_frequent_foods', params: {'limit_count': limit});

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get most frequent foods: $e');
    }
  }

  // Get progress towards daily goals
  Future<Map<String, double>> getGoalsProgress(DateTime date) async {
    try {
      // Get user's goals
      final userGoals =
          await _client.from('user_nutrition_goals').select().single();

      // Get today's totals
      final startOfDay =
          DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59)
          .toIso8601String();

      final totals = await _client
          .from('meal_logs')
          .select('calories, protein, carbs, fat')
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final row in totals) {
        totalCalories += (row['calories'] ?? 0).toDouble();
        totalProtein += (row['protein'] ?? 0).toDouble();
        totalCarbs += (row['carbs'] ?? 0).toDouble();
        totalFat += (row['fat'] ?? 0).toDouble();
      }

      return {
        'calories': totalCalories / (userGoals['calorie_goal'] ?? 2000),
        'protein': totalProtein / (userGoals['protein_goal'] ?? 150),
        'carbs': totalCarbs / (userGoals['carbs_goal'] ?? 250),
        'fat': totalFat / (userGoals['fat_goal'] ?? 70),
      };
    } catch (e) {
      throw Exception('Failed to get goals progress: $e');
    }
  }
}
