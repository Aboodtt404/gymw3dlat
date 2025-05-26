// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_nutrition_goals_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserNutritionGoals _$UserNutritionGoalsFromJson(Map<String, dynamic> json) =>
    UserNutritionGoals(
      id: json['id'] as String,
      userId: json['userId'] as String,
      calorieGoal: (json['calorieGoal'] as num).toDouble(),
      proteinPercentage: (json['proteinPercentage'] as num).toDouble(),
      carbsPercentage: (json['carbsPercentage'] as num).toDouble(),
      fatPercentage: (json['fatPercentage'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserNutritionGoalsToJson(UserNutritionGoals instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'calorieGoal': instance.calorieGoal,
      'proteinPercentage': instance.proteinPercentage,
      'carbsPercentage': instance.carbsPercentage,
      'fatPercentage': instance.fatPercentage,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
