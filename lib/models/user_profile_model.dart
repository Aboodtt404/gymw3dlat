import 'package:flutter/foundation.dart';

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive,
}

enum FitnessGoal {
  weightLoss,
  maintenance,
  muscleGain,
}

@immutable
class UserProfile {
  final String userId;
  final int age;
  final double weight; // in kg
  final double height; // in cm
  final String gender;
  final ActivityLevel activityLevel;
  final FitnessGoal goal;
  final double targetWeight;
  final DateTime lastUpdated;

  const UserProfile({
    required this.userId,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.targetWeight,
    required this.lastUpdated,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'],
      age: json['age'],
      weight: json['weight'].toDouble(),
      height: json['height'].toDouble(),
      gender: json['gender'],
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['activity_level'],
      ),
      goal: FitnessGoal.values.firstWhere(
        (e) => e.toString().split('.').last == json['goal'],
      ),
      targetWeight: json['target_weight'].toDouble(),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'activity_level': activityLevel.toString().split('.').last,
      'goal': goal.toString().split('.').last,
      'target_weight': targetWeight,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
