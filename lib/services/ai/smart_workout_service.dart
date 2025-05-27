import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/ai_workout_models.dart';
import '../../models/workout_models.dart'
    show WorkoutIntensity, WorkoutLog, ExerciseCategory;
import '../../models/exercise_model.dart' as exercise_api;
import '../exercise_db_service.dart';
import '../supabase_service.dart';

class SmartWorkoutService {
  static final SmartWorkoutService _instance = SmartWorkoutService._internal();
  factory SmartWorkoutService() => _instance;
  SmartWorkoutService._internal();

  final _supabase = SupabaseService.client;
  final ExerciseDBService _exerciseDBService = ExerciseDBService();

  // State cache for exercises to avoid repeated API calls
  static Map<String, List<exercise_api.Exercise>> _exerciseCache = {};

  /// Generate personalized workout recommendations based on user profile and history
  Future<List<AIWorkoutRecommendation>> generateWorkoutRecommendations({
    required String userId,
    int count = 3,
  }) async {
    try {
      // Get user fitness profile
      final fitnessProfile = await getUserFitnessProfile(userId);

      // If no profile exists, return empty list - user needs to set up profile first
      if (fitnessProfile == null) {
        debugPrint('No fitness profile found for user $userId');
        return [];
      }

      // Get recent workout history
      final recentWorkouts = await _getRecentWorkouts(userId, limit: 10);

      // Get performance analysis
      final performanceData = await _getPerformanceAnalysis(userId);

      // Analyze current state
      final muscleGroupBalance = _analyzeMuscleGroupBalance(recentWorkouts);
      final workoutFrequency = _analyzeWorkoutFrequency(recentWorkouts);
      final averagePerformance = _calculateAveragePerformance(performanceData);

      final recommendations = <AIWorkoutRecommendation>[];

      for (int i = 0; i < count; i++) {
        // Determine workout type based on muscle group balance and goals
        final workoutType = _selectWorkoutType(
          fitnessProfile,
          muscleGroupBalance,
          workoutFrequency,
          i,
        );

        // Calculate intensity based on recovery and performance
        final intensity =
            _calculateIntensity(fitnessProfile, averagePerformance);

        // Generate workout recommendation
        final recommendation = await _generateWorkoutRecommendation(
          fitnessProfile: fitnessProfile,
          workoutType: workoutType,
          intensity: intensity,
          averagePerformance: averagePerformance,
          index: i,
        );

        recommendations.add(recommendation);
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error generating workout recommendations: $e');
      return [];
    }
  }

  /// Get user fitness profile (returns null if none exists)
  Future<UserFitnessProfile?> getUserFitnessProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_fitness_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return UserFitnessProfile.fromJson(response);
      } else {
        // Return null if no profile exists - user needs to set up profile
        return null;
      }
    } catch (e) {
      debugPrint('Error getting fitness profile: $e');
      return null;
    }
  }

  /// Update user fitness profile
  Future<void> updateFitnessProfile(UserFitnessProfile profile) async {
    try {
      await _supabase.from('user_fitness_profiles').upsert(profile.toJson());
    } catch (e) {
      debugPrint('Error updating fitness profile: $e');
      rethrow;
    }
  }

  /// Delete user fitness profile (for testing)
  Future<void> deleteFitnessProfile(String userId) async {
    try {
      await _supabase
          .from('user_fitness_profiles')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error deleting fitness profile: $e');
      rethrow;
    }
  }

  /// Analyze workout performance and provide insights
  Future<WorkoutPerformanceAnalysis> analyzeWorkoutPerformance(
    WorkoutLog workoutLog,
  ) async {
    try {
      final analysis = await _performWorkoutAnalysis(workoutLog);

      // Get existing analyses for this user
      final existingAnalyses = await getPerformanceAnalysis(workoutLog.userId);

      // Calculate cumulative performance
      double cumulativeScore = analysis.performanceScore;
      if (existingAnalyses.isNotEmpty) {
        // Average with previous performance, weighted towards new performance
        cumulativeScore = (analysis.performanceScore * 0.7 +
                existingAnalyses.first.performanceScore * 0.3)
            .clamp(0.0, 1.0);
      }

      // Update analysis with cumulative score
      final updatedAnalysis = WorkoutPerformanceAnalysis(
        workoutLogId: analysis.workoutLogId,
        userId: analysis.userId,
        performanceScore: cumulativeScore,
        recoveryStatus: analysis.recoveryStatus,
        exercisePerformance: analysis.exercisePerformance,
        strengths: analysis.strengths,
        weaknesses: analysis.weaknesses,
        recommendations: analysis.recommendations,
        analyzedAt: DateTime.now(),
      );

      // Save analysis to database
      await _supabase
          .from('workout_performance_analysis')
          .upsert(updatedAnalysis.toJson());

      return updatedAnalysis;
    } catch (e) {
      debugPrint('Error analyzing workout performance: $e');
      rethrow;
    }
  }

  /// Get progression plan for user
  Future<ProgressionPlan?> getProgressionPlan(String userId) async {
    try {
      final response = await _supabase
          .from('progression_plans')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return ProgressionPlan.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting progression plan: $e');
      return null;
    }
  }

  /// Create or update progression plan
  Future<ProgressionPlan> createProgressionPlan({
    required String userId,
    required String goalType,
    required DateTime targetDate,
    required Map<String, dynamic> targetMetrics,
  }) async {
    try {
      // Get current metrics
      final currentMetrics = await _getCurrentMetrics(userId);

      // Generate milestones
      final milestones = _generateMilestones(
        currentMetrics: currentMetrics,
        targetMetrics: targetMetrics,
        startDate: DateTime.now(),
        targetDate: targetDate,
      );

      final plan = ProgressionPlan(
        userId: userId,
        goalType: goalType,
        startDate: DateTime.now(),
        targetDate: targetDate,
        currentMetrics: currentMetrics,
        targetMetrics: targetMetrics,
        milestones: milestones,
        lastUpdated: DateTime.now(),
      );

      await _supabase.from('progression_plans').upsert(plan.toJson());

      return plan;
    } catch (e) {
      debugPrint('Error creating progression plan: $e');
      rethrow;
    }
  }

  /// Adapt workout based on real-time performance
  Future<AIWorkoutRecommendation> adaptWorkout({
    required AIWorkoutRecommendation originalWorkout,
    required Map<String, double> currentPerformance,
    required RecoveryStatus recoveryStatus,
  }) async {
    try {
      final adaptedExercises = <SmartExerciseSet>[];

      for (final exercise in originalWorkout.exercises) {
        final exercisePerformance =
            currentPerformance[exercise.exerciseId] ?? 1.0;
        final adaptedExercise =
            _adaptExercise(exercise, exercisePerformance, recoveryStatus);
        adaptedExercises.add(adaptedExercise);
      }

      final adaptedWorkout = AIWorkoutRecommendation(
        id: '${originalWorkout.id}_adapted_${DateTime.now().millisecondsSinceEpoch}',
        userId: originalWorkout.userId,
        name: '${originalWorkout.name} (Adapted)',
        description:
            '${originalWorkout.description}\n\nAdapted based on current performance.',
        exercises: adaptedExercises,
        intensity: _adjustIntensity(originalWorkout.intensity, recoveryStatus),
        estimatedDuration: originalWorkout.estimatedDuration,
        difficultyScore: originalWorkout.difficultyScore *
            _getAdaptationFactor(recoveryStatus),
        focusAreas: originalWorkout.focusAreas,
        reasoning:
            'Adapted from original workout based on current performance and recovery status.',
        confidenceScore: originalWorkout.confidenceScore *
            0.9, // Slightly lower confidence for adapted workouts
        createdAt: DateTime.now(),
        aiMetadata: {
          ...originalWorkout.aiMetadata,
          'adaptation_reason': 'Performance and recovery based adaptation',
          'original_workout_id': originalWorkout.id,
        },
      );

      return adaptedWorkout;
    } catch (e) {
      debugPrint('Error adapting workout: $e');
      rethrow;
    }
  }

  /// Get performance analysis data for a user
  Future<List<WorkoutPerformanceAnalysis>> getPerformanceAnalysis(
      String userId) async {
    try {
      final response = await _supabase
          .from('workout_performance_analysis')
          .select()
          .eq('user_id', userId)
          .order('analyzed_at', ascending: false)
          .limit(5);

      return response
          .map((json) => WorkoutPerformanceAnalysis.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting performance analysis: $e');
      return [];
    }
  }

  // Private helper methods

  Future<UserFitnessProfile> _createDefaultFitnessProfile(String userId) async {
    final profile = UserFitnessProfile(
      userId: userId,
      fitnessLevel: FitnessLevel.beginner,
      fitnessGoals: ['Build Muscle'],
      preferredExerciseTypes: ['strength_training'],
      availableEquipment: ['bodyweight'],
      maxWorkoutDuration: 60,
      injuries: [],
      strengthLevels: {
        for (final category in ExerciseCategory.values)
          category: 3.0, // Default beginner level
      },
      cardioEndurance: 3.0,
      lastUpdated: DateTime.now(),
    );

    await _supabase.from('user_fitness_profiles').insert(profile.toJson());

    return profile;
  }

  Future<List<WorkoutLog>> _getRecentWorkouts(String userId,
      {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('workout_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => WorkoutLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting recent workouts: $e');
      return [];
    }
  }

  Future<List<WorkoutPerformanceAnalysis>> _getPerformanceAnalysis(
      String userId) async {
    return getPerformanceAnalysis(userId);
  }

  String _selectWorkoutType(
    UserFitnessProfile fitnessProfile,
    Map<ExerciseCategory, int> muscleGroupBalance,
    int workoutFrequency,
    int index,
  ) {
    // Prioritize muscle groups that haven't been worked recently
    final leastWorkedMuscles = muscleGroupBalance.entries
        .where((entry) => entry.key != ExerciseCategory.cardio)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Select workout type based on goals and muscle group balance
    if (fitnessProfile.fitnessGoals.contains('weight_loss') && index == 0) {
      return 'cardio';
    } else if (leastWorkedMuscles.isNotEmpty) {
      return leastWorkedMuscles.first.key.toString().split('.').last;
    } else {
      return 'full_body';
    }
  }

  Future<AIWorkoutRecommendation> _generateWorkoutRecommendation({
    required UserFitnessProfile fitnessProfile,
    required String workoutType,
    required WorkoutIntensity intensity,
    required double averagePerformance,
    required int index,
  }) async {
    // Generate exercises using real ExerciseDB API
    final exercises = await _generateExercisesForWorkout(
      fitnessProfile: fitnessProfile,
      workoutType: workoutType,
      averagePerformance: averagePerformance,
    );

    final difficulty = _calculateDifficulty(fitnessProfile, exercises);

    return AIWorkoutRecommendation(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}_$index',
      userId: fitnessProfile.userId,
      name: _generateWorkoutName(workoutType, intensity),
      description: _generateWorkoutDescription(workoutType, fitnessProfile),
      exercises: exercises,
      intensity: intensity,
      estimatedDuration: _calculateDuration(exercises),
      difficultyScore: difficulty,
      focusAreas: _getFocusAreas(workoutType),
      reasoning:
          _generateReasoning(workoutType, fitnessProfile, averagePerformance),
      confidenceScore: _calculateConfidence(fitnessProfile, averagePerformance),
      createdAt: DateTime.now(),
      aiMetadata: {
        'workout_type': workoutType,
        'fitness_level': fitnessProfile.fitnessLevel.toString(),
        'average_performance': averagePerformance,
        'generation_algorithm': 'smart_workout_v2_exercisedb',
      },
    );
  }

  Future<List<SmartExerciseSet>> _generateExercisesForWorkout({
    required UserFitnessProfile fitnessProfile,
    required String workoutType,
    required double averagePerformance,
  }) async {
    // Get exercises from ExerciseDB API based on workout type
    List<exercise_api.Exercise> availableExercises = [];

    // Use cache to avoid repeated API calls
    final cacheKey = workoutType;
    if (_exerciseCache.containsKey(cacheKey)) {
      availableExercises = _exerciseCache[cacheKey]!;
    } else {
      // Map workout types to ExerciseDB body parts
      final bodyPart = _mapWorkoutTypeToBodyPart(workoutType);

      if (bodyPart != null) {
        availableExercises =
            await _exerciseDBService.getExercisesByBodyPart(bodyPart);
      } else if (workoutType == 'full_body') {
        // For full body, get exercises from multiple body parts
        final bodyParts = [
          'chest',
          'back',
          'shoulders',
          'lower legs',
          'upper legs'
        ];
        for (final part in bodyParts) {
          final exercises =
              await _exerciseDBService.getExercisesByBodyPart(part);
          availableExercises
              .addAll(exercises.take(2)); // Take 2 from each body part
        }
      } else if (workoutType == 'cardio') {
        // For cardio, get cardio equipment exercises
        availableExercises =
            await _exerciseDBService.getExercisesByEquipment('cardio');
      }

      print(
          'Before equipment filtering: ${availableExercises.length} exercises');
      print('Available equipment: ${fitnessProfile.availableEquipment}');

      print(
          'Before equipment filtering: ${availableExercises.length} exercises');
      print('Available equipment: ${fitnessProfile.availableEquipment}');

      // Filter by available equipment with more flexible matching
      availableExercises = availableExercises.where((exercise) {
        // If no equipment restrictions, allow all exercises
        if (fitnessProfile.availableEquipment.isEmpty) {
          return true;
        }

        // Always allow bodyweight exercises
        if (exercise.equipment.toLowerCase() == 'body weight') {
          return true;
        }

        // Check if any of the user's available equipment matches the normalized exercise equipment
        final normalizedExerciseEquip =
            _normalizeEquipmentName(exercise.equipment);
        final isAllowed = fitnessProfile.availableEquipment.any((equipment) {
          final normalizedUserEquip = _normalizeEquipmentName(equipment);
          return normalizedExerciseEquip == normalizedUserEquip;
        });

        if (!isAllowed) {
          print(
              'Filtered out exercise: ${exercise.name} (equipment: ${exercise.equipment})');
        }
        return isAllowed;
      }).toList();

      print(
          'After equipment filtering: ${availableExercises.length} exercises');

      print(
          'After equipment filtering: ${availableExercises.length} exercises');

      // Cache the result
      _exerciseCache[cacheKey] = availableExercises;
    }

    if (availableExercises.isEmpty) {
      throw Exception(
          'No exercises found in ExerciseDB API for workout type: $workoutType');
    }

    // Select 3-5 exercises randomly from available exercises
    final exerciseCount =
        (3 + Random().nextInt(3)).clamp(1, availableExercises.length);
    final selectedExercises = <exercise_api.Exercise>[];
    final shuffledExercises =
        List<exercise_api.Exercise>.from(availableExercises)..shuffle();

    for (int i = 0; i < exerciseCount; i++) {
      selectedExercises.add(shuffledExercises[i]);
    }

    // Convert to SmartExerciseSet with appropriate sets/reps/weight
    final smartExercises = <SmartExerciseSet>[];
    final baseReps = _getBaseReps(fitnessProfile.fitnessLevel);
    final baseSets = _getBaseSets(fitnessProfile.fitnessLevel);

    for (final exercise in selectedExercises) {
      final reps = baseReps + Random().nextInt(5); // Add some variety
      final sets = baseSets;
      final weight = exercise.equipment == 'body weight'
          ? null
          : _calculateWeight(fitnessProfile, averagePerformance);
      final restTime = _calculateRestTime(fitnessProfile.fitnessLevel);

      smartExercises.add(SmartExerciseSet(
        exerciseId: exercise.id,
        sets: sets,
        reps: reps,
        weight: weight,
        restTime: restTime,
        notes:
            'Target: ${exercise.target}\nEquipment: ${exercise.equipment}\nInstructions: ${exercise.instructions}',
        adaptationFactor: 1.0 + (averagePerformance - 0.5) * 0.2,
        adaptationReason: 'Based on recent performance trends',
        alternatives: [], // Will be populated with similar exercises from ExerciseDB
        progressionRules: {
          'weight_increase': 2.5,
          'rep_increase': 1,
          'performance_threshold': 0.8,
        },
      ));
    }

    return smartExercises;
  }

  String? _mapWorkoutTypeToBodyPart(String workoutType) {
    switch (workoutType.toLowerCase()) {
      case 'chest':
        return 'chest';
      case 'back':
        return 'back';
      case 'shoulders':
        return 'shoulders';
      case 'arms':
        return 'upper arms';
      case 'legs':
        return 'upper legs';
      case 'core':
        return 'waist';
      default:
        return null; // For full_body, cardio, etc.
    }
  }

  // Helper methods for calculations

  Map<ExerciseCategory, int> _analyzeMuscleGroupBalance(
      List<WorkoutLog> workouts) {
    final balance = <ExerciseCategory, int>{};
    for (final category in ExerciseCategory.values) {
      balance[category] = 0;
    }

    // Count workouts by analyzing exercise names/body parts
    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        final category = _categorizeExercise(exercise.name);
        balance[category] = (balance[category] ?? 0) + 1;
      }
    }

    return balance;
  }

  ExerciseCategory _categorizeExercise(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('chest') || name.contains('push'))
      return ExerciseCategory.chest;
    if (name.contains('back') || name.contains('pull'))
      return ExerciseCategory.back;
    if (name.contains('shoulder')) return ExerciseCategory.shoulders;
    if (name.contains('arm') ||
        name.contains('bicep') ||
        name.contains('tricep')) return ExerciseCategory.arms;
    if (name.contains('leg') ||
        name.contains('squat') ||
        name.contains('lunge')) return ExerciseCategory.legs;
    if (name.contains('core') || name.contains('abs') || name.contains('plank'))
      return ExerciseCategory.core;
    if (name.contains('cardio') ||
        name.contains('run') ||
        name.contains('bike')) return ExerciseCategory.cardio;
    return ExerciseCategory.other;
  }

  int _analyzeWorkoutFrequency(List<WorkoutLog> workouts) {
    if (workouts.isEmpty) return 0;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return workouts.where((w) => w.createdAt.isAfter(weekAgo)).length;
  }

  double _calculateAveragePerformance(
      List<WorkoutPerformanceAnalysis> analyses) {
    if (analyses.isEmpty) return 0.5; // Default neutral performance

    // Calculate weighted average with more recent workouts having higher weight
    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < analyses.length; i++) {
      final weight = 1.0 / (i + 1); // More recent workouts have higher weight
      weightedSum += analyses[i].performanceScore * weight;
      totalWeight += weight;
    }

    return weightedSum / totalWeight;
  }

  WorkoutIntensity _calculateIntensity(
      UserFitnessProfile profile, double performance) {
    switch (profile.fitnessLevel) {
      case FitnessLevel.beginner:
        return performance > 0.7
            ? WorkoutIntensity.moderate
            : WorkoutIntensity.light;
      case FitnessLevel.intermediate:
        return performance > 0.8
            ? WorkoutIntensity.vigorous
            : WorkoutIntensity.moderate;
      case FitnessLevel.advanced:
      case FitnessLevel.expert:
        return performance > 0.9
            ? WorkoutIntensity.extreme
            : WorkoutIntensity.vigorous;
    }
  }

  double _calculateDifficulty(
      UserFitnessProfile profile, List<SmartExerciseSet> exercises) {
    final baseDifficulty = switch (profile.fitnessLevel) {
      FitnessLevel.beginner => 3.0,
      FitnessLevel.intermediate => 5.0,
      FitnessLevel.advanced => 7.0,
      FitnessLevel.expert => 9.0,
    };

    final exerciseComplexity = exercises.length * 0.2;
    return (baseDifficulty + exerciseComplexity).clamp(1.0, 10.0);
  }

  int _getBaseReps(FitnessLevel level) {
    return switch (level) {
      FitnessLevel.beginner => 8,
      FitnessLevel.intermediate => 10,
      FitnessLevel.advanced => 12,
      FitnessLevel.expert => 15,
    };
  }

  int _getBaseSets(FitnessLevel level) {
    return switch (level) {
      FitnessLevel.beginner => 2,
      FitnessLevel.intermediate => 3,
      FitnessLevel.advanced => 4,
      FitnessLevel.expert => 5,
    };
  }

  double? _calculateWeight(UserFitnessProfile profile, double performance) {
    // This would be based on user's previous performance and strength levels
    // For now, return null for bodyweight exercises or basic weights
    final strengthLevel = profile.strengthLevels[ExerciseCategory.other] ?? 0.5;
    final baseWeight = strengthLevel * 20; // Basic calculation
    return performance > 0.7 ? baseWeight * 1.1 : baseWeight;
  }

  int _calculateRestTime(FitnessLevel level) {
    return switch (level) {
      FitnessLevel.beginner => 90,
      FitnessLevel.intermediate => 75,
      FitnessLevel.advanced => 60,
      FitnessLevel.expert => 45,
    };
  }

  int _calculateDuration(List<SmartExerciseSet> exercises) {
    int totalMinutes = 0;

    // Add warm-up time
    totalMinutes += 5;

    // Calculate exercise time
    for (final exercise in exercises) {
      // Time per set including rest
      final setTime =
          (exercise.reps * 4) + (exercise.restTime ?? 60); // 4 seconds per rep
      final exerciseTime = exercise.sets * setTime;

      // Add transition time between exercises (equipment setup, etc.)
      totalMinutes += (exerciseTime ~/ 60) + 2; // 2 minutes transition time
    }

    // Add cool-down time
    totalMinutes += 5;

    // Add buffer for unexpected delays
    totalMinutes = (totalMinutes * 1.1).round(); // 10% buffer

    return totalMinutes;
  }

  List<String> _getFocusAreas(String workoutType) {
    return switch (workoutType) {
      'chest' => ['Chest', 'Triceps'],
      'back' => ['Back', 'Biceps'],
      'legs' => ['Quadriceps', 'Hamstrings', 'Glutes'],
      'full_body' => ['Full Body', 'Functional Strength'],
      'cardio' => ['Cardiovascular Endurance', 'Fat Burning'],
      _ => ['Strength', 'Muscle Building'],
    };
  }

  String _generateWorkoutName(String workoutType, WorkoutIntensity intensity) {
    final intensityName = intensity.toString().split('.').last.toUpperCase();
    final typeName = workoutType.replaceAll('_', ' ').toUpperCase();
    return '$intensityName $typeName WORKOUT';
  }

  String _generateWorkoutDescription(
      String workoutType, UserFitnessProfile profile) {
    return 'AI-generated $workoutType workout tailored for your ${profile.fitnessLevel.toString().split('.').last} fitness level. '
        'This workout focuses on your goals: ${profile.fitnessGoals.join(', ')}.';
  }

  String _generateReasoning(
      String workoutType, UserFitnessProfile profile, double performance) {
    return 'This workout was selected based on your fitness level (${profile.fitnessLevel.toString().split('.').last}), '
        'recent performance (${(performance * 100).toInt()}%), and training goals. '
        'The exercises are adapted to your available equipment and time constraints.';
  }

  double _calculateConfidence(UserFitnessProfile profile, double performance) {
    // Higher confidence for users with more data and consistent performance
    final baseConfidence = 0.7;
    final performanceBonus = (performance - 0.5) * 0.2;
    return (baseConfidence + performanceBonus).clamp(0.0, 1.0);
  }

  // Workout adaptation methods

  SmartExerciseSet _adaptExercise(
      SmartExerciseSet exercise, double performance, RecoveryStatus recovery) {
    final adaptationFactor = _getAdaptationFactor(recovery) * performance;

    final newReps = (exercise.reps * adaptationFactor).round().clamp(1, 50);
    final newWeight =
        exercise.weight != null ? exercise.weight! * adaptationFactor : null;

    return SmartExerciseSet(
      exerciseId: exercise.exerciseId,
      sets: exercise.sets,
      reps: newReps,
      weight: newWeight,
      restTime: exercise.restTime,
      notes: '${exercise.notes} (Adapted based on performance)',
      adaptationFactor: adaptationFactor,
      adaptationReason:
          'Adapted for ${recovery.toString().split('.').last} recovery',
      alternatives: exercise.alternatives,
      progressionRules: exercise.progressionRules,
    );
  }

  WorkoutIntensity _adjustIntensity(
      WorkoutIntensity original, RecoveryStatus recovery) {
    final intensityIndex = WorkoutIntensity.values.indexOf(original);

    return switch (recovery) {
      RecoveryStatus.fullyRecovered => original,
      RecoveryStatus.partiallyRecovered => intensityIndex > 0
          ? WorkoutIntensity.values[intensityIndex - 1]
          : original,
      RecoveryStatus.fatigued => WorkoutIntensity.light,
      RecoveryStatus.overreached => WorkoutIntensity.light,
    };
  }

  double _getAdaptationFactor(RecoveryStatus recovery) {
    return switch (recovery) {
      RecoveryStatus.fullyRecovered => 1.0,
      RecoveryStatus.partiallyRecovered => 0.85,
      RecoveryStatus.fatigued => 0.7,
      RecoveryStatus.overreached => 0.5,
    };
  }

  Future<WorkoutPerformanceAnalysis> _performWorkoutAnalysis(
      WorkoutLog workoutLog) async {
    final totalSets =
        workoutLog.exercises.fold(0, (sum, ex) => sum + ex.sets.length);
    final completedSets = workoutLog.exercises.fold(
        0, (sum, ex) => sum + ex.sets.where((set) => set.completed).length);

    final completionRate = totalSets > 0 ? completedSets / totalSets : 0.0;

    // Calculate performance score with multiple factors
    double performanceScore = 0.0;

    // Base completion rate (50% of total score) - Increased weight for completion
    performanceScore += completionRate * 0.5;

    // Exercise complexity factor (15% of total score)
    final exerciseCount = workoutLog.exercises.length;
    final complexityFactor =
        min(exerciseCount / 3.0, 1.0); // Normalize to 3 exercises as base
    performanceScore += complexityFactor * 0.15;

    // Duration factor (15% of total score) - More lenient duration scoring
    final targetDuration = 45.0; // Target duration in minutes
    final actualDuration = workoutLog.duration;
    final durationRatio = actualDuration / targetDuration;
    final durationFactor = durationRatio >= 0.8
        ? 1.0
        : durationRatio; // Full score if at least 80% of target duration
    performanceScore += durationFactor * 0.15;

    // Progressive overload factor (20% of total score)
    double overloadScore = 0.0;
    int exercisesWithWeight = 0;

    // Generate exercise-specific performance
    final exercisePerformance = <String, double>{};
    for (final exercise in workoutLog.exercises) {
      // Calculate exercise-specific score considering weight and completion
      double exerciseScore = 0.0;
      final completedSets = exercise.sets.where((s) => s.completed).length;
      exerciseScore +=
          completedSets / exercise.sets.length * 0.7; // 70% completion weight

      // Add weight progression bonus (30%)
      if (exercise.sets.any((s) => s.weight != null)) {
        final weightedSets =
            exercise.sets.where((s) => s.weight != null && s.completed);
        if (weightedSets.isNotEmpty) {
          exerciseScore += 0.3; // Weight progression bonus
        }
      } else {
        // For bodyweight exercises, give full weight progression bonus if completed
        if (completedSets == exercise.sets.length) {
          exerciseScore += 0.3;
        }
      }

      // Store performance with exercise name instead of ID
      final formattedName = _formatExerciseName(exercise.name);
      exercisePerformance[formattedName] = exerciseScore;

      if (exercise.sets.any((s) => s.weight != null)) {
        overloadScore += exerciseScore;
        exercisesWithWeight++;
      }
    }

    if (exercisesWithWeight > 0) {
      overloadScore /= exercisesWithWeight;
      performanceScore += (overloadScore * 0.2);
    } else {
      // If no exercises with weight, redistribute the 20% to completion rate
      performanceScore += completionRate * 0.2;
    }

    // Ensure minimum performance score of 0.6 if all sets are completed
    if (completionRate >= 0.95) {
      performanceScore = max(performanceScore, 0.6);
    }

    // Ensure performance score is between 0 and 1
    performanceScore = performanceScore.clamp(0.0, 1.0);

    // Determine recovery status based on multiple factors
    final RecoveryStatus recoveryStatus;
    if (workoutLog.duration > 90) {
      recoveryStatus = RecoveryStatus.fatigued;
    } else if (performanceScore < 0.4) {
      recoveryStatus = RecoveryStatus.overreached;
    } else if (performanceScore < 0.7) {
      recoveryStatus = RecoveryStatus.partiallyRecovered;
    } else {
      recoveryStatus = RecoveryStatus.fullyRecovered;
    }

    return WorkoutPerformanceAnalysis(
      workoutLogId: workoutLog.id,
      userId: workoutLog.userId,
      performanceScore: performanceScore,
      recoveryStatus: recoveryStatus,
      exercisePerformance: exercisePerformance,
      strengths: _identifyStrengths(exercisePerformance),
      weaknesses: _identifyWeaknesses(exercisePerformance),
      recommendations:
          _generatePerformanceRecommendations(performanceScore, recoveryStatus),
      analyzedAt: DateTime.now(),
    );
  }

  String _formatExerciseName(String name) {
    return name
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  List<String> _identifyStrengths(Map<String, double> exercisePerformance) {
    return exercisePerformance.entries
        .where((entry) => entry.value >= 0.8)
        .map((entry) => 'Excellent performance in ${entry.key}')
        .toList();
  }

  List<String> _identifyWeaknesses(Map<String, double> exercisePerformance) {
    return exercisePerformance.entries
        .where((entry) => entry.value < 0.6)
        .map((entry) => 'Consider adjusting difficulty for ${entry.key}')
        .toList();
  }

  List<String> _generatePerformanceRecommendations(
      double score, RecoveryStatus recovery) {
    final recommendations = <String>[];

    if (score < 0.7) {
      recommendations.add('Consider reducing workout intensity');
      recommendations.add('Focus on proper form over heavy weights');
    }

    if (recovery == RecoveryStatus.fatigued) {
      recommendations.add('Take an extra rest day');
      recommendations.add('Focus on sleep and nutrition');
    }

    if (score > 0.9) {
      recommendations.add('Great performance! Consider progressive overload');
      recommendations.add('You might be ready for more challenging exercises');
    }

    return recommendations;
  }

  Future<Map<String, dynamic>> _getCurrentMetrics(String userId) async {
    // This would fetch current user metrics from various sources
    return {
      'strength_level': 5.0,
      'endurance_level': 5.0,
      'body_weight': 70.0,
      'body_fat_percentage': 15.0,
    };
  }

  List<ProgressionMilestone> _generateMilestones({
    required Map<String, dynamic> currentMetrics,
    required Map<String, dynamic> targetMetrics,
    required DateTime startDate,
    required DateTime targetDate,
  }) {
    final milestones = <ProgressionMilestone>[];
    final totalDays = targetDate.difference(startDate).inDays;
    final milestoneCount = (totalDays / 30).ceil(); // Monthly milestones

    for (int i = 1; i <= milestoneCount; i++) {
      final milestoneDate = startDate
          .add(Duration(days: (totalDays * i / milestoneCount).round()));
      final progress = i / milestoneCount;

      final milestoneMetrics = <String, dynamic>{};
      targetMetrics.forEach((key, value) {
        final current = currentMetrics[key] ?? 0.0;
        final target = value as double;
        milestoneMetrics[key] = current + (target - current) * progress;
      });

      milestones.add(ProgressionMilestone(
        id: 'milestone_${DateTime.now().millisecondsSinceEpoch}_$i',
        description:
            'Milestone $i: ${(progress * 100).toInt()}% progress towards goal',
        targetDate: milestoneDate,
        targetMetrics: milestoneMetrics,
        isCompleted: false,
      ));
    }

    return milestones;
  }

  String _normalizeEquipmentName(String equipment) {
    final normalized = equipment.toLowerCase();
    switch (normalized) {
      case 'body weight':
      case 'bodyweight':
      case 'body':
        return 'Body Weight';
      case 'barbell':
      case 'ez barbell':
        return 'Barbell';
      case 'dumbbell':
      case 'dumbbells':
        return 'Dumbbell';
      case 'cable':
      case 'cables':
        return 'Cable';
      case 'leverage machine':
      case 'smith machine':
      case 'machines':
        return 'Machine';
      case 'resistance band':
      case 'bands':
        return 'Band';
      case 'kettlebell':
      case 'kettlebells':
        return 'Kettlebell';
      case 'weight plate':
      case 'plates':
        return 'Plate';
      case 'trx':
      case 'suspension trainer':
        return 'Suspension';
      case 'exercise ball':
      case 'swiss ball':
        return 'Stability Ball';
      case 'foam roller':
        return 'Foam Roll';
      case 'med ball':
        return 'Medicine Ball';
      default:
        return equipment; // Return original if no match
    }
  }
}
