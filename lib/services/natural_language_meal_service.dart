import 'package:flutter/foundation.dart';
import '../models/food_model.dart';
import '../models/meal_log_model.dart';
import 'nutritionix_service.dart';

class NaturalLanguageMealService {
  static final NaturalLanguageMealService _instance =
      NaturalLanguageMealService._internal();
  factory NaturalLanguageMealService() => _instance;
  NaturalLanguageMealService._internal();

  final _nutritionixService = NutritionixService();

  /// Parse natural language input into structured meal data
  Future<List<Food>> parseNaturalLanguageInput(String input) async {
    try {
      debugPrint('Parsing natural language input: $input');

      // Use Nutritionix API to parse the natural language input
      final foods = await _nutritionixService.searchFoods(input);

      if (foods.isEmpty) {
        throw Exception('No foods found for the given input');
      }

      return foods;
    } catch (e) {
      debugPrint('Error parsing natural language input: $e');
      throw Exception('Failed to parse meal input: $e');
    }
  }

  /// Extract quantities and units from natural language input
  Map<String, dynamic> _extractQuantities(String input) {
    // This is a basic implementation - could be enhanced with more sophisticated NLP
    final quantities = RegExp(
            r'(\d+(?:\.\d+)?)\s*(cup|cups|tbsp|tsp|oz|ounce|ounces|g|gram|grams|piece|pieces|slice|slices|serving|servings)s?\b')
        .allMatches(input)
        .map((match) => {
              'amount': double.parse(match.group(1)!),
              'unit': match.group(2)!,
            })
        .toList();

    return {
      'quantities': quantities,
      'remainingText': input
          .replaceAll(
              RegExp(
                  r'\d+\s*(cup|cups|tbsp|tsp|oz|ounce|ounces|g|gram|grams|piece|pieces|slice|slices|serving|servings)s?\b'),
              '')
          .trim(),
    };
  }

  /// Learn from user's common meals and create shortcuts
  Future<void> learnFromMealLog(MealLog log) async {
    try {
      // TODO: Implement machine learning to identify patterns in user's meal logs
      // This could include:
      // 1. Common food combinations
      // 2. Typical portion sizes
      // 3. Meal timing patterns
      // 4. Frequently used ingredients
    } catch (e) {
      debugPrint('Error learning from meal log: $e');
    }
  }

  /// Get suggestions based on partial input
  Future<List<String>> getSuggestions(String partialInput) async {
    try {
      // TODO: Implement autocomplete suggestions based on:
      // 1. User's meal history
      // 2. Common food combinations
      // 3. Time of day
      // 4. User's dietary preferences
      return [];
    } catch (e) {
      debugPrint('Error getting suggestions: $e');
      return [];
    }
  }

  /// Format the meal data for display
  String formatMealForDisplay(List<Food> foods) {
    return foods
        .map((food) => '${food.name} (${food.calories.round()} cal, '
            '${food.protein.round()}g protein, '
            '${food.carbs.round()}g carbs, '
            '${food.fat.round()}g fat)')
        .join('\n');
  }
}
