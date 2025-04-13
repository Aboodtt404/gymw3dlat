import 'package:flutter/foundation.dart';
import 'food_model.dart';

enum MealType { breakfast, lunch, dinner, snack }

@immutable
class MealLog {
  final String id;
  final String userId;
  final String foodId;
  final Food food;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;
  final String servingUnit;
  final String? nutritionixId;
  final MealType mealType;
  final DateTime loggedAt;
  final DateTime? updatedAt;

  const MealLog({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.food,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.servingUnit,
    this.nutritionixId,
    required this.mealType,
    required this.loggedAt,
    this.updatedAt,
  });

  MealLog copyWith({
    String? id,
    String? userId,
    String? foodId,
    Food? food,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? servingSize,
    String? servingUnit,
    String? nutritionixId,
    MealType? mealType,
    DateTime? loggedAt,
    DateTime? updatedAt,
  }) {
    return MealLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      food: food ?? this.food,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      nutritionixId: nutritionixId ?? this.nutritionixId,
      mealType: mealType ?? this.mealType,
      loggedAt: loggedAt ?? this.loggedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'food_id': foodId,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'nutritionix_id': nutritionixId,
      'meal_type': mealType.name,
      'logged_at': loggedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory MealLog.fromJson(Map<String, dynamic> json, {required Food food}) {
    return MealLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      foodId: json['food_id'] as String,
      food: food,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      servingSize: (json['serving_size'] as num).toDouble(),
      servingUnit: json['serving_unit'] as String,
      nutritionixId: json['nutritionix_id'] as String?,
      mealType: MealType.values.firstWhere(
        (e) => e.name == json['meal_type'] as String,
      ),
      loggedAt: DateTime.parse(json['logged_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          foodId == other.foodId &&
          food == other.food &&
          calories == other.calories &&
          protein == other.protein &&
          carbs == other.carbs &&
          fat == other.fat &&
          servingSize == other.servingSize &&
          servingUnit == other.servingUnit &&
          nutritionixId == other.nutritionixId &&
          mealType == other.mealType &&
          loggedAt == other.loggedAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      foodId.hashCode ^
      food.hashCode ^
      calories.hashCode ^
      protein.hashCode ^
      carbs.hashCode ^
      fat.hashCode ^
      servingSize.hashCode ^
      servingUnit.hashCode ^
      nutritionixId.hashCode ^
      mealType.hashCode ^
      loggedAt.hashCode ^
      updatedAt.hashCode;
}
