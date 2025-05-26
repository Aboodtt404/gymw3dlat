// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealLog _$MealLogFromJson(Map<String, dynamic> json) => MealLog(
      id: json['id'] as String,
      userId: json['userId'] as String,
      foodId: json['foodId'] as String,
      food: Food.fromJson(json['food'] as Map<String, dynamic>),
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      servingSize: (json['servingSize'] as num).toDouble(),
      servingUnit: json['servingUnit'] as String,
      nutritionixId: json['nutritionixId'] as String?,
      mealType: $enumDecode(_$MealTypeEnumMap, json['mealType']),
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      foods: (json['foods'] as List<dynamic>)
          .map((e) => Food.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MealLogToJson(MealLog instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'foodId': instance.foodId,
      'food': instance.food,
      'calories': instance.calories,
      'protein': instance.protein,
      'carbs': instance.carbs,
      'fat': instance.fat,
      'servingSize': instance.servingSize,
      'servingUnit': instance.servingUnit,
      'nutritionixId': instance.nutritionixId,
      'mealType': _$MealTypeEnumMap[instance.mealType]!,
      'loggedAt': instance.loggedAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'foods': instance.foods,
    };

const _$MealTypeEnumMap = {
  MealType.breakfast: 'breakfast',
  MealType.lunch: 'lunch',
  MealType.dinner: 'dinner',
  MealType.snack: 'snack',
};
