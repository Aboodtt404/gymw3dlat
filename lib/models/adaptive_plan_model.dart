import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'meal_plan_model.dart';
import 'workout_template_model.dart';

@immutable
class AdaptivePlan {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? lastActiveDate;
  final int daysAway;
  final double progressScore; // 0-1 scale
  final MealPlan currentMealPlan;
  final WorkoutTemplate currentWorkoutPlan;
  final List<PlanAdjustment> adjustments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AdaptivePlan({
    required this.id,
    required this.userId,
    required this.startDate,
    this.lastActiveDate,
    required this.daysAway,
    required this.progressScore,
    required this.currentMealPlan,
    required this.currentWorkoutPlan,
    required this.adjustments,
    required this.createdAt,
    this.updatedAt,
  });

  // Calculate how much to adjust the plan based on days away
  double get adjustmentFactor {
    if (daysAway <= 3) return 1.0;
    if (daysAway <= 7) return 0.8;
    if (daysAway <= 14) return 0.6;
    if (daysAway <= 30) return 0.4;
    return 0.2;
  }

  AdaptivePlan copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? lastActiveDate,
    int? daysAway,
    double? progressScore,
    MealPlan? currentMealPlan,
    WorkoutTemplate? currentWorkoutPlan,
    List<PlanAdjustment>? adjustments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdaptivePlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      daysAway: daysAway ?? this.daysAway,
      progressScore: progressScore ?? this.progressScore,
      currentMealPlan: currentMealPlan ?? this.currentMealPlan,
      currentWorkoutPlan: currentWorkoutPlan ?? this.currentWorkoutPlan,
      adjustments: adjustments ?? this.adjustments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_date': startDate.toIso8601String(),
      'last_active_date': lastActiveDate?.toIso8601String(),
      'days_away': daysAway,
      'progress_score': progressScore,
      'current_meal_plan': currentMealPlan.toJson(),
      'current_workout_plan': currentWorkoutPlan.toJson(),
      'adjustments': adjustments.map((a) => a.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory AdaptivePlan.fromJson(Map<String, dynamic> json) {
    return AdaptivePlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.parse(json['last_active_date'] as String)
          : null,
      daysAway: json['days_away'] as int,
      progressScore: (json['progress_score'] as num).toDouble(),
      currentMealPlan: MealPlan.fromJson(json['current_meal_plan']),
      currentWorkoutPlan:
          WorkoutTemplate.fromJson(json['current_workout_plan']),
      adjustments: (json['adjustments'] as List)
          .map((a) => PlanAdjustment.fromJson(a))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

@immutable
class PlanAdjustment {
  final String id;
  final DateTime date;
  final String type; // 'meal' or 'workout'
  final String reason;
  final Map<String, dynamic> changes;
  final DateTime createdAt;

  const PlanAdjustment({
    required this.id,
    required this.date,
    required this.type,
    required this.reason,
    required this.changes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'reason': reason,
      'changes': changes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PlanAdjustment.fromJson(Map<String, dynamic> json) {
    return PlanAdjustment(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      reason: json['reason'] as String,
      changes: json['changes'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
