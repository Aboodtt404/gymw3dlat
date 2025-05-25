import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/exercise_model.dart';

class ExerciseService {
  static const String _baseUrl = 'https://exercisedb.p.rapidapi.com/exercises';
  static final String _apiKey = dotenv.env['EXERCISEDB_API_KEY'] ?? '';

  final Map<String, String> _headers = {
    'X-RapidAPI-Key': _apiKey,
    'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com'
  };

  // Get all exercises
  Future<List<Exercise>> getAllExercises() async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Exercise.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load exercises');
    }
  }

  // Search exercises by name
  Future<List<Exercise>> searchExercisesByName(String name) async {
    print('Searching for exercises with name: $name');
    print(
        'API Key: ${_apiKey.substring(0, 5)}...'); // Print first few chars for safety

    // Fix the URL to match the correct API endpoint format
    final uri =
        Uri.parse('https://exercisedb.p.rapidapi.com/exercises/name/$name');
    print('Request URL: $uri');

    final response = await http.get(
      uri,
      headers: _headers,
    );

    print('Response status code: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('Error response body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Found ${data.length} exercises');
      return data.map((json) => Exercise.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to search exercises for "$name" (Status: ${response.statusCode})');
    }
  }

  // Get exercises by body part
  Future<List<Exercise>> getExercisesByBodyPart(String bodyPart) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/bodyPart/$bodyPart'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Exercise.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load exercises for $bodyPart');
    }
  }

  // Get exercises by target muscle
  Future<List<Exercise>> getExercisesByTarget(String target) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/target/$target'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Exercise.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load exercises for target $target');
    }
  }

  // Get exercises by equipment
  Future<List<Exercise>> getExercisesByEquipment(String equipment) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/equipment/$equipment'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Exercise.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load exercises for equipment $equipment');
    }
  }

  // Get exercise by ID
  Future<Exercise> getExerciseById(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/exercise/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Exercise.fromJson(data);
    } else {
      throw Exception('Failed to load exercise with ID $id');
    }
  }
}
