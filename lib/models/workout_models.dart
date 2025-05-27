enum ExerciseCategory {
  chest,
  back,
  shoulders,
  arms,
  legs,
  core,
  cardio,
  other,
}

enum WorkoutIntensity { light, moderate, vigorous, extreme }

class Exercise {
  final String id;
  final String name;
  final String description;
  final ExerciseCategory category;
  final String? equipment;
  final String? videoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.equipment,
    this.videoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: ExerciseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
      ),
      equipment: json['equipment'] as String?,
      videoUrl: json['video_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'equipment': equipment,
      'video_url': videoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class WorkoutTemplate {
  final String id;
  final String userId;
  final String name;
  final String description;
  final List<ExerciseSet> exercises;
  final int estimatedDuration; // in minutes
  final DateTime createdAt;
  final DateTime? updatedAt;

  WorkoutTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.exercises,
    required this.estimatedDuration,
    required this.createdAt,
    this.updatedAt,
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => ExerciseSet.fromJson(e))
          .toList(),
      estimatedDuration: json['estimated_duration'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'estimated_duration': estimatedDuration,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class ExerciseSet {
  final String exerciseId;
  final int sets;
  final int reps;
  final double? weight;
  final int? restTime; // in seconds
  final String? notes;

  ExerciseSet({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.weight,
    this.restTime,
    this.notes,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      exerciseId: json['exercise_id'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      weight: json['weight'] as double?,
      restTime: json['rest_time'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'rest_time': restTime,
      'notes': notes,
    };
  }
}

class WorkoutLog {
  final String id;
  final String userId;
  final String? templateId;
  final String name;
  final List<ExerciseLog> exercises;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WorkoutLog({
    required this.id,
    required this.userId,
    this.templateId,
    required this.name,
    required this.exercises,
    required this.startTime,
    this.endTime,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      templateId: json['template_id'] as String?,
      name: json['name'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => ExerciseLog.fromJson(e))
          .toList(),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'template_id': templateId,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Calculate workout duration in minutes
  int get duration {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inMinutes;
  }

  WorkoutLog copyWith({
    String? id,
    String? userId,
    String? templateId,
    String? name,
    List<ExerciseLog>? exercises,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ExerciseLog {
  final String exerciseId;
  final String name;
  final List<SetLog> sets;
  final String? notes;
  final String? gifUrl;

  ExerciseLog({
    required this.exerciseId,
    required this.name,
    required this.sets,
    this.notes,
    this.gifUrl,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exerciseId: json['exercise_id'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as List).map((e) => SetLog.fromJson(e)).toList(),
      notes: json['notes'] as String?,
      gifUrl: json['gif_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'name': name,
      'sets': sets.map((e) => e.toJson()).toList(),
      'notes': notes,
      'gif_url': gifUrl,
    };
  }
}

class SetLog {
  final int setNumber;
  final int reps;
  final double? weight;
  final bool completed;
  final String? notes;

  SetLog({
    required this.setNumber,
    required this.reps,
    this.weight,
    required this.completed,
    this.notes,
  });

  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      setNumber: json['set_number'] as int,
      reps: json['reps'] as int,
      weight: json['weight'] as double?,
      completed: json['completed'] as bool,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'set_number': setNumber,
      'reps': reps,
      'weight': weight,
      'completed': completed,
      'notes': notes,
    };
  }

  SetLog copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    bool? completed,
    String? notes,
  }) {
    return SetLog(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
    );
  }
}
