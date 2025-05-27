import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'food_model.dart';

enum MealType { breakfast, lunch, dinner, snack }

@immutable
class MealLog {
  final String id;
  final String userId;
  final List<Food> foods;
  final MealType mealType;
  final DateTime loggedAt;
  final String? notes;
  final double storedCalories;
  final double storedProtein;
  final double storedCarbs;
  final double storedFat;

  MealLog({
    String? id,
    required this.userId,
    required this.foods,
    required this.mealType,
    required this.loggedAt,
    this.notes,
    required this.storedCalories,
    required this.storedProtein,
    required this.storedCarbs,
    required this.storedFat,
  }) : id = id ?? const Uuid().v4();

  double get totalCalories => storedCalories > 0
      ? storedCalories
      : foods.fold(0, (sum, food) => sum + food.calories);
  double get totalProtein => storedProtein > 0
      ? storedProtein
      : foods.fold(0, (sum, food) => sum + food.protein);
  double get totalCarbs => storedCarbs > 0
      ? storedCarbs
      : foods.fold(0, (sum, food) => sum + food.carbs);
  double get totalFat =>
      storedFat > 0 ? storedFat : foods.fold(0, (sum, food) => sum + food.fat);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'meal_type': mealType.name,
      'logged_at': loggedAt.toIso8601String(),
      'notes': notes,
      'foods': foods.map((f) => f.toJson()).toList(),
      'total_calories': storedCalories,
      'total_protein': storedProtein,
      'total_carbs': storedCarbs,
      'total_fat': storedFat,
    };
  }

  factory MealLog.fromJson(Map<String, dynamic> json) {
    final foodsList = (json['foods'] as List?)
            ?.where((f) => f != null)
            ?.map((f) => Food.fromJson(f as Map<String, dynamic>))
            ?.toList() ??
        [];

    return MealLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      foods: foodsList,
      mealType: MealType.values.firstWhere(
        (type) => type.name == json['meal_type'],
      ),
      loggedAt: DateTime.parse(json['logged_at'] as String),
      notes: json['notes'] as String?,
      storedCalories: (json['total_calories'] as num?)?.toDouble() ?? 0.0,
      storedProtein: (json['total_protein'] as num?)?.toDouble() ?? 0.0,
      storedCarbs: (json['total_carbs'] as num?)?.toDouble() ?? 0.0,
      storedFat: (json['total_fat'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          listEquals(foods, other.foods) &&
          mealType == other.mealType &&
          loggedAt == other.loggedAt &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      foods.hashCode ^
      mealType.hashCode ^
      loggedAt.hashCode ^
      notes.hashCode;
}
