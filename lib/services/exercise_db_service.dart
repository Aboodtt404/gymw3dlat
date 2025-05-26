import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/exercise_model.dart';

class ExerciseDBService {
  static const String _baseUrl = 'https://exercisedb.p.rapidapi.com';

  final http.Client _client;

  ExerciseDBService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'X-RapidAPI-Key': dotenv.env['EXERCISEDB_API_KEY'] ?? '',
        'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
      };

  // Get all exercises
  Future<List<Exercise>> getAllExercises() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/exercises'),
        headers: _headers,
      );
      return _handleExerciseListResponse(response);
    } catch (e) {
      throw Exception('Failed to get exercises: $e');
    }
  }

  // Search exercises by name
  Future<List<Exercise>> searchExercises(String name) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/exercises/name/$name'),
        headers: _headers,
      );
      return _handleExerciseListResponse(response);
    } catch (e) {
      throw Exception('Failed to search exercises: $e');
    }
  }

  // Get exercises by target muscle
  Future<List<Exercise>> getExercisesByTarget(String target) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/exercises/target/$target'),
        headers: _headers,
      );
      return _handleExerciseListResponse(response);
    } catch (e) {
      throw Exception('Failed to get exercises by target: $e');
    }
  }

  // Get exercises by equipment
  Future<List<Exercise>> getExercisesByEquipment(String equipment) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/exercises/equipment/$equipment'),
        headers: _headers,
      );
      return _handleExerciseListResponse(response);
    } catch (e) {
      throw Exception('Failed to get exercises by equipment: $e');
    }
  }

  // Get exercises by body part
  Future<List<Exercise>> getExercisesByBodyPart(String bodyPart) async {
    try {
      print('Fetching exercises for body part: $bodyPart');
      print('API Key: ${_headers['X-RapidAPI-Key']?.substring(0, 5)}...');

      final uri = Uri.parse('$_baseUrl/exercises/bodyPart/$bodyPart');
      print('Request URL: $uri');

      final response = await _client.get(uri, headers: _headers);

      print('Response status code: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Error response body: ${response.body}');
      }

      return _handleExerciseListResponse(response);
    } catch (e) {
      print('Error getting exercises by body part: $e');
      throw Exception('Failed to get exercises by body part: $e');
    }
  }

  // Helper method to format exercise names
  String _formatExerciseName(String name) {
    // Split by spaces or hyphens
    final words = name.split(RegExp(r'[ -]'));
    // Capitalize first letter of each word and join back
    return words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Get single exercise by ID
  Future<Exercise> getExerciseById(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/exercises/exercise/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Format the exercise name before creating the Exercise object
        data['name'] = _formatExerciseName(data['name']);
        return Exercise.fromJson(data);
      } else {
        throw Exception('Failed to get exercise: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get exercise: $e');
    }
  }

  // Get list of all body parts
  Future<List<String>> getBodyPartList() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/exercises/bodyPartList'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception('Failed to get body part list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get body part list: $e');
    }
  }

  // Get list of all equipment
  Future<List<String>> getEquipmentList() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/exercises/equipmentList'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception('Failed to get equipment list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get equipment list: $e');
    }
  }

  // Get list of all target muscles
  Future<List<String>> getTargetList() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/exercises/targetList'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception('Failed to get target list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get target list: $e');
    }
  }

  // Helper method to handle exercise list responses
  List<Exercise> _handleExerciseListResponse(http.Response response) {
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) {
        // Format the exercise name before creating the Exercise object
        item['name'] = _formatExerciseName(item['name']);
        return Exercise.fromJson(item);
      }).toList();
    } else {
      throw Exception('API request failed: ${response.statusCode}');
    }
  }
}
