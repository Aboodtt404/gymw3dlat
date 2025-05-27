import 'dart:convert';
import 'package:gymw3dlat/models/workout_models.dart';
import 'package:gymw3dlat/services/supabase_service.dart';
import 'package:gymw3dlat/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/exercise_model.dart' as exercise_model;
import '../models/ai_workout_models.dart';
import 'package:uuid/uuid.dart';

class WorkoutService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  // Exercise operations
  Future<Exercise> addExercise(Exercise exercise) async {
    try {
      final response = await _client
          .from(AppConstants.exercisesCollection)
          .insert(exercise.toJson())
          .select()
          .single();

      return Exercise.fromJson(response);
    } catch (e) {
      throw _handleError('Error adding exercise', e);
    }
  }

  Future<List<Exercise>> getExercisesByCategory(
      ExerciseCategory category) async {
    try {
      final response = await _client
          .from(AppConstants.exercisesCollection)
          .select()
          .eq('category', category.toString().split('.').last)
          .order('name');

      return (response as List).map((json) => Exercise.fromJson(json)).toList();
    } catch (e) {
      throw _handleError('Error fetching exercises by category', e);
    }
  }

  // Updated to use ExerciseDB API
  Future<List<exercise_model.Exercise>> searchExercises(String query) async {
    try {
      print('Searching for exercises with name: $query');

      final apiKey = dotenv.env['EXERCISEDB_API_KEY'] ?? '';
      final headers = {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com'
      };

      final uri =
          Uri.parse('https://exercisedb.p.rapidapi.com/exercises/name/$query');
      print('Request URL: $uri');

      final response = await http.get(uri, headers: headers);

      print('Response status code: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Error response body: ${response.body}');
        throw Exception('API request failed: ${response.statusCode}');
      }

      final List<dynamic> data = json.decode(response.body);
      print('Found ${data.length} exercises');
      return data
          .map((json) => exercise_model.Exercise.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError('Error searching exercises', e);
    }
  }

  // Workout template operations
  Future<WorkoutTemplate> addWorkoutTemplate(WorkoutTemplate template) async {
    try {
      final response = await _client
          .from(AppConstants.workoutsCollection)
          .insert(template.toJson())
          .select()
          .single();

      return WorkoutTemplate.fromJson(response);
    } catch (e) {
      throw _handleError('Error adding workout template', e);
    }
  }

  Future<List<WorkoutTemplate>> getUserWorkoutTemplates(String userId) async {
    try {
      print(
          'Fetching workout templates from ${AppConstants.workoutsCollection}');
      final response = await _client
          .from(AppConstants.workoutsCollection)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('Response from Supabase: $response');
      return (response as List)
          .map((json) => WorkoutTemplate.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError('Error fetching user workout templates', e);
    }
  }

  Future<WorkoutTemplate> updateWorkoutTemplate(
      WorkoutTemplate template) async {
    try {
      final response = await _client
          .from(AppConstants.workoutsCollection)
          .update(template.toJson())
          .eq('id', template.id)
          .select()
          .single();

      return WorkoutTemplate.fromJson(response);
    } catch (e) {
      throw _handleError('Error updating workout template', e);
    }
  }

  Future<void> deleteWorkoutTemplate(String id) async {
    try {
      await _client.from(AppConstants.workoutsCollection).delete().eq('id', id);
    } catch (e) {
      throw _handleError('Error deleting workout template', e);
    }
  }

  // Workout log operations
  Future<WorkoutLog> startWorkout(WorkoutLog workout) async {
    try {
      final response = await _client
          .from(AppConstants.workoutLogsCollection)
          .insert(workout.toJson())
          .select()
          .single();

      return WorkoutLog.fromJson(response);
    } catch (e) {
      throw _handleError('Error starting workout', e);
    }
  }

  Future<WorkoutLog> endWorkout(WorkoutLog workout) async {
    try {
      final response = await _client
          .from(AppConstants.workoutLogsCollection)
          .update(workout.toJson())
          .eq('id', workout.id)
          .select()
          .single();

      return WorkoutLog.fromJson(response);
    } catch (e) {
      throw _handleError('Error ending workout', e);
    }
  }

  Future<List<WorkoutLog>> getUserWorkoutLogs(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await _client
          .from(AppConstants.workoutLogsCollection)
          .select()
          .match({'user_id': userId}).order('start_time', ascending: false);

      final logs =
          (response as List).map((json) => WorkoutLog.fromJson(json)).toList();

      // Filter dates in memory since we're having issues with the query builder
      return logs.where((log) {
        final date = log.startTime;
        if (startDate != null && date.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && date.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();
    } catch (e) {
      throw _handleError('Error fetching user workout logs', e);
    }
  }

  Future<WorkoutLog> getWorkoutLogById(String id) async {
    try {
      final response = await _client
          .from(AppConstants.workoutLogsCollection)
          .select()
          .eq('id', id)
          .single();

      return WorkoutLog.fromJson(response);
    } catch (e) {
      throw _handleError('Error fetching workout log', e);
    }
  }

  Future<void> deleteWorkoutLog(String id) async {
    try {
      await _client
          .from(AppConstants.workoutLogsCollection)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw _handleError('Error deleting workout log', e);
    }
  }

  // Helper method for consistent error handling
  Exception _handleError(String message, dynamic error) {
    print('$message: $error');
    return Exception('$message: ${error.toString()}');
  }

  // Get workout statistics
  Future<Map<String, dynamic>> getWorkoutStats(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final logs = await getUserWorkoutLogs(userId,
          startDate: startDate, endDate: endDate);

      int totalWorkouts = logs.length;
      int totalDuration = logs.fold(0, (sum, log) => sum + log.duration);
      int totalExercises =
          logs.fold(0, (sum, log) => sum + log.exercises.length);

      // Calculate most frequent exercises
      final exerciseFrequency = <String, int>{};
      for (final log in logs) {
        for (final exercise in log.exercises) {
          exerciseFrequency[exercise.name] =
              (exerciseFrequency[exercise.name] ?? 0) + 1;
        }
      }

      final mostFrequentExercises = exerciseFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'totalWorkouts': totalWorkouts,
        'totalDuration': totalDuration,
        'totalExercises': totalExercises,
        'averageDuration':
            totalWorkouts > 0 ? totalDuration ~/ totalWorkouts : 0,
        'mostFrequentExercises': mostFrequentExercises
            .take(5)
            .map((e) => {
                  'name': e.key,
                  'count': e.value,
                })
            .toList(),
      };
    } catch (e) {
      throw _handleError('Error getting workout statistics', e);
    }
  }

  Future<List<AIWorkoutRecommendation>> getWorkoutRecommendations(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get user's workout history
      final response = await _client
          .from(AppConstants.workoutLogsCollection)
          .select('*') // Explicitly select all columns
          .eq('user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      // Handle the response properly
      final workoutHistory = response as List? ?? [];

      // If no workout history, return default recommendations
      if (workoutHistory.isEmpty) {
        return [
          AIWorkoutRecommendation(
            id: _uuid.v4(),
            userId: userId,
            name: 'Beginner Full Body Workout',
            description: 'A balanced workout suitable for beginners',
            exercises: [
              SmartExerciseSet(
                exerciseId: 'pushups',
                sets: 3,
                reps: 10,
                adaptationFactor: 1.0,
                adaptationReason: 'Initial exercise',
                alternatives: ['knee pushups', 'wall pushups'],
                progressionRules: {'increase_reps': 2, 'max_sets': 5},
              ),
              SmartExerciseSet(
                exerciseId: 'squats',
                sets: 3,
                reps: 12,
                adaptationFactor: 1.0,
                adaptationReason: 'Initial exercise',
                alternatives: ['assisted squats', 'lunges'],
                progressionRules: {'increase_reps': 2, 'max_sets': 5},
              ),
            ],
            intensity: WorkoutIntensity.light,
            estimatedDuration: 30,
            difficultyScore: 2.0,
            focusAreas: ['Full Body', 'Core Strength', 'Cardio'],
            reasoning:
                'Recommended for new users to establish baseline fitness',
            confidenceScore: 0.9,
            createdAt: DateTime.now(),
            aiMetadata: {
              'recommendation_type': 'default',
              'user_history': 'none'
            },
          ),
        ];
      }

      // Analyze workout patterns
      Map<String, int> exerciseFrequency = {};
      Map<String, int> muscleGroupFrequency = {};

      for (final workout in workoutHistory) {
        try {
          final exercises = workout['exercises'] as List? ?? [];
          for (final exercise in exercises) {
            if (exercise is! Map) continue;

            final exerciseName = exercise['name'] as String? ?? '';
            if (exerciseName.isNotEmpty) {
              exerciseFrequency[exerciseName] =
                  (exerciseFrequency[exerciseName] ?? 0) + 1;
            }

            // Extract muscle groups from the exercise target
            final target = exercise['target'] as String? ?? '';
            final bodyPart = exercise['body_part'] as String? ?? '';
            final muscleGroups =
                [target, bodyPart].where((e) => e.isNotEmpty).toList();

            for (final group in muscleGroups) {
              muscleGroupFrequency[group] =
                  (muscleGroupFrequency[group] ?? 0) + 1;
            }
          }
        } catch (e) {
          print('Error processing workout: $e');
          continue; // Skip problematic workouts
        }
      }

      // Find neglected muscle groups
      List<String> neglectedMuscleGroups = muscleGroupFrequency.entries
          .where((e) => e.value < 2) // Less than 2 workouts in the period
          .map((e) => e.key)
          .toList();

      // Generate recommendations
      List<AIWorkoutRecommendation> recommendations = [];

      if (neglectedMuscleGroups.isNotEmpty) {
        // Add recommendation for neglected muscle groups
        recommendations.add(
          AIWorkoutRecommendation(
            id: _uuid.v4(),
            userId: userId,
            name: 'Balance Workout',
            description: 'Focus on muscle groups you\'ve been neglecting',
            exercises: [
              SmartExerciseSet(
                exerciseId: 'exercise1',
                sets: 3,
                reps: 12,
                adaptationFactor: 1.0,
                adaptationReason: 'Target neglected muscles',
                alternatives: ['alt1', 'alt2'],
                progressionRules: {'increase_reps': 2, 'max_sets': 5},
              ),
            ],
            intensity: WorkoutIntensity.moderate,
            estimatedDuration: 45,
            difficultyScore: 3.0,
            focusAreas: neglectedMuscleGroups,
            reasoning:
                'Targets underworked muscle groups: ${neglectedMuscleGroups.join(", ")}',
            confidenceScore: 0.85,
            createdAt: DateTime.now(),
            aiMetadata: {
              'recommendation_type': 'balance',
              'neglected_groups': neglectedMuscleGroups
            },
          ),
        );
      }

      // Add progressive overload recommendation
      recommendations.add(
        AIWorkoutRecommendation(
          id: _uuid.v4(),
          userId: userId,
          name: 'Progressive Challenge',
          description: 'Take your routine to the next level',
          exercises: [
            SmartExerciseSet(
              exerciseId: 'exercise1',
              sets: 4,
              reps: 12,
              adaptationFactor: 1.2,
              adaptationReason: 'Progressive overload',
              alternatives: ['alt1', 'alt2'],
              progressionRules: {'increase_weight': 2.5, 'max_sets': 5},
            ),
          ],
          intensity: WorkoutIntensity.vigorous,
          estimatedDuration: 50,
          difficultyScore: 3.5,
          focusAreas: ['Strength', 'Endurance', 'Power'],
          reasoning:
              'Designed to push your limits and promote continued progress',
          confidenceScore: 0.9,
          createdAt: DateTime.now(),
          aiMetadata: {
            'recommendation_type': 'progressive',
            'exercise_history': exerciseFrequency
          },
        ),
      );

      return recommendations;
    } catch (e) {
      print('Error getting workout recommendations: $e');
      // Return empty list instead of throwing
      return [];
    }
  }

  List<String> _getExercisesForMuscleGroups(List<String> muscleGroups) {
    // Simplified version - in a real app, this would come from a proper exercise database
    Map<String, List<String>> exercisesByMuscle = {
      'Chest': ['Push-ups', 'Bench Press', 'Dips'],
      'Back': ['Pull-ups', 'Rows', 'Deadlifts'],
      'Legs': ['Squats', 'Lunges', 'Leg Press'],
      'Shoulders': ['Shoulder Press', 'Lateral Raises', 'Front Raises'],
      'Arms': ['Bicep Curls', 'Tricep Extensions', 'Hammer Curls'],
      'Core': ['Planks', 'Crunches', 'Russian Twists'],
    };

    List<String> exercises = [];
    for (final group in muscleGroups) {
      if (exercisesByMuscle.containsKey(group)) {
        exercises.addAll(exercisesByMuscle[group]!.take(2));
      }
    }
    return exercises;
  }

  List<String> _getProgressiveExercises(List<String> currentExercises) {
    // Add more challenging variations of current exercises
    List<String> progressive = [];
    for (final exercise in currentExercises.take(4)) {
      progressive.add('Advanced $exercise');
    }
    return progressive;
  }
}
