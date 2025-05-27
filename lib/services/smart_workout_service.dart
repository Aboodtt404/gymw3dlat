import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/ai_workout_models.dart';
import '../models/workout_models.dart' show WorkoutLog, RecoveryStatus;
import '../models/exercise_model.dart' as exercise_api;
import '../services/exercise_db_service.dart';
import '../services/supabase_service.dart';

class SmartWorkoutService {
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
        min((exerciseCount / 3.0).toDouble(), 1.0); // Ensure double
    performanceScore += complexityFactor * 0.15;

    // Duration factor (15% of total score) - More lenient duration scoring
    final targetDuration = 45.0; // Target duration in minutes
    final actualDuration = workoutLog.duration.toDouble(); // Convert to double
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
      exerciseScore += (completedSets / exercise.sets.length).toDouble() *
          0.7; // Ensure double

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
      overloadScore =
          (overloadScore / exercisesWithWeight).toDouble(); // Ensure double
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
    // Implement the logic to format the exercise name
    return name;
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
}
