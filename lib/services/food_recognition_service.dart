import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/food_model.dart';

class FoodRecognitionService {
  static const String _logMealBaseUrl = 'https://api.logmeal.es/v2';
  static const String _nutritionixBaseUrl =
      'https://trackapi.nutritionix.com/v2';
  static const String _modelVersion = 'v1.0'; // Use the latest model version

  // Food type grouping to prevent duplicates
  static const Map<String, List<String>> _foodGroups = {
    'rice': [
      'white rice',
      'brown rice',
      'black rice',
      'rice salad',
      'fried rice'
    ],
    'chicken': [
      'grilled chicken',
      'roasted chicken',
      'chicken breast',
      'fried chicken'
    ],
    'salad': [
      'cucumber salad',
      'green salad',
      'vegetable salad',
      'mixed salad'
    ],
  };

  String get _logMealApiKey => dotenv.env['LOGMEAL_API_KEY'] ?? '';
  String get _nutritionixAppId => dotenv.env['NUTRITIONIX_APP_ID'] ?? '';
  String get _nutritionixApiKey => dotenv.env['NUTRITIONIX_API_KEY'] ?? '';

  // Helper method to get the base food type
  String _getBaseFoodType(String foodName) {
    for (final entry in _foodGroups.entries) {
      if (entry.value.any((variant) =>
          foodName.toLowerCase().contains(variant.toLowerCase()) ||
          variant.toLowerCase().contains(foodName.toLowerCase()))) {
        return entry.key;
      }
    }
    return foodName.toLowerCase();
  }

  Future<List<Food>> analyzeFoodImage(String imageUrl) async {
    print(
        '==================== FOOD IMAGE ANALYSIS START ====================');
    print('Analyzing image URL: $imageUrl');

    if (_logMealApiKey.isEmpty ||
        _nutritionixAppId.isEmpty ||
        _nutritionixApiKey.isEmpty) {
      print('API Configuration Status:');
      print(
          '  LogMeal API Key: ${_logMealApiKey.isEmpty ? 'Missing' : 'Present'}');
      print(
          '  Nutritionix App ID: ${_nutritionixAppId.isEmpty ? 'Missing' : 'Present'}');
      print(
          '  Nutritionix API Key: ${_nutritionixApiKey.isEmpty ? 'Missing' : 'Present'}');
      throw Exception('API keys not configured. Please check your .env file.');
    }

    try {
      // Download image
      print('Downloading image from URL...');
      final imageResponse = await http.get(Uri.parse(imageUrl));
      print('Image download status: ${imageResponse.statusCode}');
      print('Image size: ${imageResponse.bodyBytes.length} bytes');

      if (imageResponse.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Use segmentation endpoint for multiple food items
      print('Getting segmentation analysis from LogMeal API...');
      final segmentationUri = Uri.parse(
          '$_logMealBaseUrl/image/segmentation/complete/$_modelVersion');
      final request = http.MultipartRequest('POST', segmentationUri)
        ..headers['Authorization'] = 'Bearer $_logMealApiKey'
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageResponse.bodyBytes,
            filename: 'food.jpg',
          ),
        );

      final segmentationResponse = await request.send();
      final segmentationData =
          json.decode(await segmentationResponse.stream.bytesToString());
      print('Segmentation Response:');
      print(json.encode(segmentationData));

      if (segmentationResponse.statusCode != 200) {
        throw Exception(
            'Failed to segment food items: ${json.encode(segmentationData)}');
      }

      // Extract all detected food items
      final Map<String, double> confidenceScores = {};
      final Map<String, String> originalNames = {};
      final List<String> detectedFoods = [];

      // Process each detected segment
      if (segmentationData['segmentation_results'] != null) {
        for (final segment in segmentationData['segmentation_results']) {
          if (segment is Map && segment['recognition_results'] != null) {
            for (final result in segment['recognition_results']) {
              // Remove minimum threshold, just check if it's a valid result
              if (result['name'] != null && result['prob'] != null) {
                final foodName = result['name'] as String;
                final baseFoodType = _getBaseFoodType(foodName);
                final probability = (result['prob'] as num) * 100;

                // Keep the highest confidence score for each base food type
                if (!confidenceScores.containsKey(baseFoodType) ||
                    confidenceScores[baseFoodType]! < probability) {
                  confidenceScores[baseFoodType] = probability.toDouble();
                  originalNames[baseFoodType] = foodName;

                  if (!detectedFoods.contains(baseFoodType)) {
                    print('  - $foodName (${probability.toStringAsFixed(1)}%)');
                    detectedFoods.add(baseFoodType);
                  }
                }
              }
            }
          }
        }
      }

      // Sort detected foods by confidence score
      detectedFoods.sort((a, b) =>
          (confidenceScores[b] ?? 0).compareTo(confidenceScores[a] ?? 0));

      if (detectedFoods.isEmpty) {
        throw Exception('No food items detected in the image');
      }

      // Take only the top 3 detected foods to avoid noise
      if (detectedFoods.length > 3) {
        detectedFoods.length = 3;
      }

      // Get nutrition data from Nutritionix using original food names
      print('\nGetting nutrition data from Nutritionix');
      final nutritionQuery = detectedFoods
          .map((type) => originalNames[type] ?? type)
          .join(' and ');
      print('Querying Nutritionix API with: $nutritionQuery');

      final nutritionixUri =
          Uri.parse('$_nutritionixBaseUrl/natural/nutrients');
      final nutritionixResponse = await http.post(
        nutritionixUri,
        headers: {
          'Content-Type': 'application/json',
          'x-app-id': _nutritionixAppId,
          'x-app-key': _nutritionixApiKey,
        },
        body: json.encode({'query': nutritionQuery}),
      );

      if (nutritionixResponse.statusCode != 200) {
        final errorBody = nutritionixResponse.body;
        print('Nutritionix API error response: $errorBody');
        throw Exception('Failed to get nutrition data: $errorBody');
      }

      final nutritionixData = json.decode(nutritionixResponse.body);
      print('\nNutritionix API response:');
      print(json.encode(nutritionixData));

      final foods = (nutritionixData['foods'] as List)
          .map((food) => Food(
                id: const Uuid().v4(),
                name: food['food_name'] as String,
                calories: (food['nf_calories'] as num).toDouble(),
                protein: (food['nf_protein'] as num).toDouble(),
                carbs: (food['nf_total_carbohydrate'] as num).toDouble(),
                fat: (food['nf_total_fat'] as num).toDouble(),
                servingSize: (food['serving_qty'] as num).toDouble(),
                servingUnit: food['serving_unit'] as String,
              ))
          .toList();

      print('\nParsed foods:');
      for (final food in foods) {
        final baseType = _getBaseFoodType(food.name);
        final confidence = confidenceScores[baseType];
        print('  - ${food.name}:');
        print('    * ID: ${food.id}');
        if (confidence != null) {
          print('    * Confidence: ${confidence.toStringAsFixed(1)}%');
        }
        print('    * Calories: ${food.calories}');
        print('    * Protein: ${food.protein}g');
        print('    * Carbs: ${food.carbs}g');
        print('    * Fat: ${food.fat}g');
        print('    * Serving: ${food.servingSize} ${food.servingUnit}');
      }

      print(
          '==================== FOOD IMAGE ANALYSIS END ====================');
      return foods;
    } catch (e, stackTrace) {
      print(
          '==================== FOOD IMAGE ANALYSIS ERROR ====================');
      print('Error analyzing food image: $e');
      print('Stack trace: $stackTrace');
      print('=============================================================');
      throw Exception('Failed to analyze image: $e');
    }
  }
}
