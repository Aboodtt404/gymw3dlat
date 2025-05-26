import 'package:flutter/foundation.dart';

@immutable
class WorkoutPlan {
  final String id;
  final String userId;
  final DateTime date;
  final WorkoutIntensity intensity;
  final int durationMinutes;
  final double estimatedCaloriesBurn;
  final List<String> targetMuscleGroups;

  const WorkoutPlan({
    required this.id,
    required this.userId,
    required this.date,
    required this.intensity,
    required this.durationMinutes,
    required this.estimatedCaloriesBurn,
    required this.targetMuscleGroups,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      intensity: WorkoutIntensity.values.firstWhere(
        (e) => e.toString().split('.').last == json['intensity'],
      ),
      durationMinutes: json['duration_minutes'],
      estimatedCaloriesBurn: json['estimated_calories_burn'].toDouble(),
      targetMuscleGroups: List<String>.from(json['target_muscle_groups']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'intensity': intensity.toString().split('.').last,
      'duration_minutes': durationMinutes,
      'estimated_calories_burn': estimatedCaloriesBurn,
      'target_muscle_groups': targetMuscleGroups,
    };
  }
}

enum WorkoutIntensity {
  light,
  moderate,
  vigorous,
  extreme,
}
