import 'package:gymw3dlat/models/workout_models.dart';
import 'package:gymw3dlat/services/supabase_service.dart';
import 'package:gymw3dlat/constants/app_constants.dart';

class WorkoutService {
  // Exercise operations
  Future<Exercise> addExercise(Exercise exercise) async {
    try {
      final response = await SupabaseService.client
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
      final response = await SupabaseService.client
          .from(AppConstants.exercisesCollection)
          .select()
          .eq('category', category.toString().split('.').last)
          .order('name');

      return (response as List).map((json) => Exercise.fromJson(json)).toList();
    } catch (e) {
      throw _handleError('Error fetching exercises by category', e);
    }
  }

  Future<List<Exercise>> searchExercises(String query) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.exercisesCollection)
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      return (response as List).map((json) => Exercise.fromJson(json)).toList();
    } catch (e) {
      throw _handleError('Error searching exercises', e);
    }
  }

  // Workout template operations
  Future<WorkoutTemplate> addWorkoutTemplate(WorkoutTemplate template) async {
    try {
      final response = await SupabaseService.client
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
      final response = await SupabaseService.client
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
      final response = await SupabaseService.client
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
      await SupabaseService.client
          .from(AppConstants.workoutsCollection)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw _handleError('Error deleting workout template', e);
    }
  }

  // Workout log operations
  Future<WorkoutLog> startWorkout(WorkoutLog workout) async {
    try {
      final response = await SupabaseService.client
          .from('workout_logs')
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
      final response = await SupabaseService.client
          .from('workout_logs')
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
      final response = await SupabaseService.client
          .from('workout_logs')
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
      final response = await SupabaseService.client
          .from('workout_logs')
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
      await SupabaseService.client.from('workout_logs').delete().eq('id', id);
    } catch (e) {
      throw _handleError('Error deleting workout log', e);
    }
  }

  // Helper method for consistent error handling
  Exception _handleError(String message, dynamic error) {
    print('$message: $error');
    if (error is Exception) {
      return Exception('$message: ${error.toString()}');
    }
    return Exception(message);
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
}
