import 'package:flutter/foundation.dart';

@immutable
class WorkoutTemplate {
  final String id;
  final String userId;
  final String name;
  final String description;
  final List<WorkoutExercise> exercises;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WorkoutTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.exercises,
    required this.createdAt,
    this.updatedAt,
  });

  WorkoutTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<WorkoutExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

@immutable
class WorkoutExercise {
  final String exerciseId;
  final String name;
  final String bodyPart;
  final String equipment;
  final String target;
  final String gifUrl;
  final int sets;
  final int reps;
  final double? weight;
  final String? notes;

  const WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.target,
    required this.gifUrl,
    required this.sets,
    required this.reps,
    this.weight,
    this.notes,
  });

  WorkoutExercise copyWith({
    String? exerciseId,
    String? name,
    String? bodyPart,
    String? equipment,
    String? target,
    String? gifUrl,
    int? sets,
    int? reps,
    double? weight,
    String? notes,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      bodyPart: bodyPart ?? this.bodyPart,
      equipment: equipment ?? this.equipment,
      target: target ?? this.target,
      gifUrl: gifUrl ?? this.gifUrl,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'name': name,
      'body_part': bodyPart,
      'equipment': equipment,
      'target': target,
      'gif_url': gifUrl,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'notes': notes,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exercise_id'] as String,
      name: json['name'] as String,
      bodyPart: json['body_part'] as String,
      equipment: json['equipment'] as String,
      target: json['target'] as String,
      gifUrl: json['gif_url'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      weight: json['weight'] as double?,
      notes: json['notes'] as String?,
    );
  }
}
