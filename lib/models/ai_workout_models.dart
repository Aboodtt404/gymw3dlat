import 'package:flutter/foundation.dart';
import 'workout_models.dart';
import 'user_model.dart';

enum FitnessLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

enum WorkoutIntensity {
  light,
  moderate,
  vigorous,
  extreme,
}

enum RecoveryStatus {
  fullyRecovered,
  partiallyRecovered,
  fatigued,
  overreached,
}

@immutable
class UserFitnessProfile {
  final String userId;
  final FitnessLevel fitnessLevel;
  final List<String> fitnessGoals;
  final List<String> preferredExerciseTypes;
  final List<String> availableEquipment;
  final int maxWorkoutDuration; // in minutes
  final List<String> injuries;
  final Map<ExerciseCategory, double> strengthLevels; // 1-10 scale
  final double cardioEndurance; // 1-10 scale
  final DateTime lastUpdated;

  const UserFitnessProfile({
    required this.userId,
    required this.fitnessLevel,
    required this.fitnessGoals,
    required this.preferredExerciseTypes,
    required this.availableEquipment,
    required this.maxWorkoutDuration,
    required this.injuries,
    required this.strengthLevels,
    required this.cardioEndurance,
    required this.lastUpdated,
  });

  factory UserFitnessProfile.fromJson(Map<String, dynamic> json) {
    return UserFitnessProfile(
      userId: json['user_id'] as String,
      fitnessLevel: FitnessLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['fitness_level'],
      ),
      fitnessGoals: List<String>.from(json['fitness_goals']),
      preferredExerciseTypes:
          List<String>.from(json['preferred_exercise_types']),
      availableEquipment: List<String>.from(json['available_equipment']),
      maxWorkoutDuration: json['max_workout_duration'] as int,
      injuries: List<String>.from(json['injuries']),
      strengthLevels: Map<ExerciseCategory, double>.from(
        (json['strength_levels'] as Map).map(
          (key, value) => MapEntry(
            ExerciseCategory.values.firstWhere(
              (e) => e.toString().split('.').last == key,
            ),
            value.toDouble(),
          ),
        ),
      ),
      cardioEndurance: json['cardio_endurance'].toDouble(),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'fitness_level': fitnessLevel.toString().split('.').last,
      'fitness_goals': fitnessGoals,
      'preferred_exercise_types': preferredExerciseTypes,
      'available_equipment': availableEquipment,
      'max_workout_duration': maxWorkoutDuration,
      'injuries': injuries,
      'strength_levels': strengthLevels.map(
        (key, value) => MapEntry(key.toString().split('.').last, value),
      ),
      'cardio_endurance': cardioEndurance,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

@immutable
class WorkoutRecommendation {
  final String id;
  final String userId;
  final String name;
  final String description;
  final List<SmartExerciseSet> exercises;
  final WorkoutIntensity intensity;
  final int estimatedDuration;
  final double difficultyScore; // 1-10 scale
  final List<String> focusAreas;
  final String reasoning;
  final double confidenceScore; // 0-1 scale
  final DateTime createdAt;
  final Map<String, dynamic> aiMetadata;

  const WorkoutRecommendation({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.exercises,
    required this.intensity,
    required this.estimatedDuration,
    required this.difficultyScore,
    required this.focusAreas,
    required this.reasoning,
    required this.confidenceScore,
    required this.createdAt,
    required this.aiMetadata,
  });

  factory WorkoutRecommendation.fromJson(Map<String, dynamic> json) {
    return WorkoutRecommendation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => SmartExerciseSet.fromJson(e))
          .toList(),
      intensity: WorkoutIntensity.values.firstWhere(
        (e) => e.toString().split('.').last == json['intensity'],
      ),
      estimatedDuration: json['estimated_duration'] as int,
      difficultyScore: json['difficulty_score'].toDouble(),
      focusAreas: List<String>.from(json['focus_areas']),
      reasoning: json['reasoning'] as String,
      confidenceScore: json['confidence_score'].toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      aiMetadata: Map<String, dynamic>.from(json['ai_metadata']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'intensity': intensity.toString().split('.').last,
      'estimated_duration': estimatedDuration,
      'difficulty_score': difficultyScore,
      'focus_areas': focusAreas,
      'reasoning': reasoning,
      'confidence_score': confidenceScore,
      'created_at': createdAt.toIso8601String(),
      'ai_metadata': aiMetadata,
    };
  }
}

@immutable
class SmartExerciseSet extends ExerciseSet {
  final double adaptationFactor; // How much to adjust based on performance
  final String adaptationReason;
  final List<String> alternatives; // Alternative exercise IDs
  final Map<String, dynamic> progressionRules;

  SmartExerciseSet({
    required String exerciseId,
    required int sets,
    required int reps,
    double? weight,
    int? restTime,
    String? notes,
    required this.adaptationFactor,
    required this.adaptationReason,
    required this.alternatives,
    required this.progressionRules,
  }) : super(
          exerciseId: exerciseId,
          sets: sets,
          reps: reps,
          weight: weight,
          restTime: restTime,
          notes: notes,
        );

  factory SmartExerciseSet.fromJson(Map<String, dynamic> json) {
    return SmartExerciseSet(
      exerciseId: json['exercise_id'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      weight: json['weight'] as double?,
      restTime: json['rest_time'] as int?,
      notes: json['notes'] as String?,
      adaptationFactor: json['adaptation_factor'].toDouble(),
      adaptationReason: json['adaptation_reason'] as String,
      alternatives: List<String>.from(json['alternatives']),
      progressionRules: Map<String, dynamic>.from(json['progression_rules']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'adaptation_factor': adaptationFactor,
      'adaptation_reason': adaptationReason,
      'alternatives': alternatives,
      'progression_rules': progressionRules,
    });
    return baseJson;
  }
}

@immutable
class WorkoutPerformanceAnalysis {
  final String workoutLogId;
  final String userId;
  final double performanceScore; // 0-1 scale
  final RecoveryStatus recoveryStatus;
  final Map<String, double>
      exercisePerformance; // exercise_id -> performance score
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;
  final DateTime analyzedAt;

  const WorkoutPerformanceAnalysis({
    required this.workoutLogId,
    required this.userId,
    required this.performanceScore,
    required this.recoveryStatus,
    required this.exercisePerformance,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    required this.analyzedAt,
  });

  factory WorkoutPerformanceAnalysis.fromJson(Map<String, dynamic> json) {
    return WorkoutPerformanceAnalysis(
      workoutLogId: json['workout_log_id'] as String,
      userId: json['user_id'] as String,
      performanceScore: json['performance_score'].toDouble(),
      recoveryStatus: RecoveryStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['recovery_status'],
      ),
      exercisePerformance:
          Map<String, double>.from(json['exercise_performance']),
      strengths: List<String>.from(json['strengths']),
      weaknesses: List<String>.from(json['weaknesses']),
      recommendations: List<String>.from(json['recommendations']),
      analyzedAt: DateTime.parse(json['analyzed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workout_log_id': workoutLogId,
      'user_id': userId,
      'performance_score': performanceScore,
      'recovery_status': recoveryStatus.toString().split('.').last,
      'exercise_performance': exercisePerformance,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'recommendations': recommendations,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }
}

@immutable
class ProgressionPlan {
  final String userId;
  final String goalType;
  final DateTime startDate;
  final DateTime targetDate;
  final Map<String, dynamic> currentMetrics;
  final Map<String, dynamic> targetMetrics;
  final List<ProgressionMilestone> milestones;
  final DateTime lastUpdated;

  const ProgressionPlan({
    required this.userId,
    required this.goalType,
    required this.startDate,
    required this.targetDate,
    required this.currentMetrics,
    required this.targetMetrics,
    required this.milestones,
    required this.lastUpdated,
  });

  factory ProgressionPlan.fromJson(Map<String, dynamic> json) {
    return ProgressionPlan(
      userId: json['user_id'] as String,
      goalType: json['goal_type'] as String,
      startDate: DateTime.parse(json['start_date']),
      targetDate: DateTime.parse(json['target_date']),
      currentMetrics: Map<String, dynamic>.from(json['current_metrics']),
      targetMetrics: Map<String, dynamic>.from(json['target_metrics']),
      milestones: (json['milestones'] as List)
          .map((e) => ProgressionMilestone.fromJson(e))
          .toList(),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'goal_type': goalType,
      'start_date': startDate.toIso8601String(),
      'target_date': targetDate.toIso8601String(),
      'current_metrics': currentMetrics,
      'target_metrics': targetMetrics,
      'milestones': milestones.map((e) => e.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

@immutable
class ProgressionMilestone {
  final String id;
  final String description;
  final DateTime targetDate;
  final Map<String, dynamic> targetMetrics;
  final bool isCompleted;
  final DateTime? completedAt;

  const ProgressionMilestone({
    required this.id,
    required this.description,
    required this.targetDate,
    required this.targetMetrics,
    required this.isCompleted,
    this.completedAt,
  });

  factory ProgressionMilestone.fromJson(Map<String, dynamic> json) {
    return ProgressionMilestone(
      id: json['id'] as String,
      description: json['description'] as String,
      targetDate: DateTime.parse(json['target_date']),
      targetMetrics: Map<String, dynamic>.from(json['target_metrics']),
      isCompleted: json['is_completed'] as bool,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'target_date': targetDate.toIso8601String(),
      'target_metrics': targetMetrics,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
