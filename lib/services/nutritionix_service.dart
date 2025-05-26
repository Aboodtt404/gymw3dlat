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
    'x-remote-user-id': '0', // Required by Nutritionix API
    'Content-Type': 'application/json',
  };

  // Validate API credentials
  bool get isConfigured => _appId.isNotEmpty && _apiKey.isNotEmpty;

  // Search for foods using natural language
  Future<List<Food>> searchFoods(String query) async {
    print('Searching foods with query: $query');
    print('API Credentials configured: $isConfigured');
    print('App ID length: ${_appId.length}');
    print('API Key length: ${_apiKey.length}');

    if (!isConfigured) {
      print('ERROR: Nutritionix API credentials not configured');
      throw Exception('Nutritionix API credentials not configured');
    }

    try {
      // First try natural language endpoint
      print('Making API request to: $_baseUrl/natural/nutrients');
      print(
          'Headers: ${_headers.map((k, v) => MapEntry(k, k.contains('key') ? '***' : v))}');
      print('Query body: ${json.encode({
            'query': query,
            'line_delimited': false,
          })}');

      final response = await http.post(
        Uri.parse('$_baseUrl/natural/nutrients'),
        headers: _headers,
        body: json.encode({
          'query': query,
          'line_delimited': false,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['foods'] == null) {
          print('No foods found in response');
          return [];
        }
        final foods = List<Map<String, dynamic>>.from(data['foods']);
        print('Found ${foods.length} foods');
        return foods.map((food) => _convertToFood(food)).toList();
      } else if (response.statusCode == 404) {
        print('404: No foods found, trying instant search endpoint');
        // Try instant search as fallback
        return await searchInstant(query.split(' ').first);
      } else {
        print('Nutritionix API Error: ${response.body}');
        throw Exception('Failed to search foods: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error searching foods: $e');
      print('Stack trace: $stackTrace');

      // Try instant search as fallback for any error
      try {
        print('Attempting fallback to instant search');
        return await searchInstant(query.split(' ').first);
      } catch (e2) {
        print('Fallback search also failed: $e2');
        throw Exception('Failed to search foods: $e2');
      }
    }
  }

  // Search food items by keyword with detailed nutrition info
  Future<List<Food>> searchInstant(String query) async {
    print('Using instant search endpoint with query: $query');

    if (!isConfigured) {
      throw Exception('Nutritionix API credentials not configured');
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/search/instant?query=${Uri.encodeComponent(query)}'),
        headers: _headers,
      );

      print('Instant search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> commonFoods = data['common'] ?? [];
        final List<dynamic> brandedFoods = data['branded'] ?? [];
        final foods = [...commonFoods, ...brandedFoods];
        print('Found ${foods.length} foods in instant search');

        // For each food item, get detailed nutrition info
        List<Food> detailedFoods = [];
        for (var food in foods.take(5)) {
          try {
            final detailedFood = await _getDetailedNutrition(food);
            if (detailedFood != null) {
              detailedFoods.add(detailedFood);
            }
          } catch (e) {
            print(
                'Error getting detailed nutrition for ${food['food_name']}: $e');
          }
        }

        return detailedFoods;
      } else {
        print('Instant search API Error: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error in instant search: $e');
      return [];
    }
  }

  Future<Food?> _getDetailedNutrition(Map<String, dynamic> foodItem) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/natural/nutrients'),
        headers: _headers,
        body: json.encode({
          'query': foodItem['food_name'] ?? foodItem['item_name'],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['foods']?.isNotEmpty) {
          return _convertToFood(data['foods'][0]);
        }
      } else {
        print('Nutritionix API Error: ${response.body}');
      }
      return null;
    } catch (e) {
      print('Error in _getDetailedNutrition: $e');
      return null;
    }
  }

  Food _convertToFood(Map<String, dynamic> data) {
    // Print the raw data for debugging
    print('Raw food data: $data');

    return Food(
      id: data['nix_item_id'] ?? const Uuid().v4(),
      name: data['food_name'] ?? data['item_name'] ?? '',
      brand: data['brand_name'],
      calories: (data['nf_calories'] ?? 0).toDouble(),
      protein: (data['nf_protein'] ?? 0).toDouble(),
      carbs: (data['nf_total_carbohydrate'] ?? 0).toDouble(),
      fat: (data['nf_total_fat'] ?? 0).toDouble(),
      servingSize:
          (data['serving_qty'] ?? data['serving_weight_grams'] ?? 1).toDouble(),
      servingUnit: data['serving_unit'] ?? 'g',
    );
  }
}
