class UserModel {
  final String id;
  final String email;
  final String name;
  final double? weight;
  final double? height;
  final String? goal;
  final int? weeklyWorkoutDays;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.weight,
    this.height,
    this.goal,
    this.weeklyWorkoutDays,
    this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      weight: json['weight'] as double?,
      height: json['height'] as double?,
      goal: json['goal'] as String?,
      weeklyWorkoutDays: json['weeklyWorkoutDays'] as int?,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'weight': weight,
      'height': height,
      'goal': goal,
      'weeklyWorkoutDays': weeklyWorkoutDays,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    double? weight,
    double? height,
    String? goal,
    int? weeklyWorkoutDays,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goal: goal ?? this.goal,
      weeklyWorkoutDays: weeklyWorkoutDays ?? this.weeklyWorkoutDays,
      preferences: preferences ?? this.preferences,
    );
  }
}
