import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/food_model.dart';
import 'package:uuid/uuid.dart';

class NutritionixService {
  static const String _baseUrl = 'https://trackapi.nutritionix.com/v2';
  static final String _appId = dotenv.env['NUTRITIONIX_APP_ID'] ?? '';
  static final String _apiKey = dotenv.env['NUTRITIONIX_API_KEY'] ?? '';

  final Map<String, String> _headers = {
    'x-app-id': _appId,
    'x-app-key': _apiKey,
    'Content-Type': 'application/json',
  };

  // Search for foods using natural language
  Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/natural/nutrients'),
        headers: _headers,
        body: json.encode({
          'query': query,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['foods']);
      } else {
        throw Exception('Failed to search foods: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search foods: $e');
    }
  }

  // Search food items by keyword
  Future<List<Food>> searchInstant(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/instant?query=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> commonFoods = data['common'] ?? [];
        final List<dynamic> brandedFoods = data['branded'] ?? [];

        final foods = [...commonFoods, ...brandedFoods];
        return foods.map((item) => _convertToFood(item)).toList();
      } else {
        throw Exception('Failed to search foods: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search foods: $e');
    }
  }

  // Get detailed nutrition information for a food item
  Future<Food> getNutritionInfo(String nixItemId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/item?nix_item_id=$nixItemId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foodData = data['foods'][0];
        return _convertToFood(foodData);
      } else {
        throw Exception('Failed to get nutrition info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get nutrition info: $e');
    }
  }

  Food _convertToFood(Map<String, dynamic> data) {
    // Get full nutrition data if available, otherwise use the basic data
    final nutritionData = data['full_nutrients'] ?? {};

    return Food(
      id: data['nix_item_id'] ?? const Uuid().v4(),
      name: data['food_name'] ?? data['item_name'] ?? '',
      brand: data['brand_name'],
      calories: (data['nf_calories'] ?? data['calories'] ?? 0).toDouble(),
      protein: (data['nf_protein'] ?? nutritionData[203] ?? 0).toDouble(),
      carbs:
          (data['nf_total_carbohydrate'] ?? nutritionData[205] ?? 0).toDouble(),
      fat: (data['nf_total_fat'] ?? nutritionData[204] ?? 0).toDouble(),
      servingSize:
          (data['serving_qty'] ?? data['serving_weight_grams'] ?? 1).toDouble(),
      servingUnit: data['serving_unit'] ?? 'g',
    );
  }
}
