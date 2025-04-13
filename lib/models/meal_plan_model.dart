import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum MealType { breakfast, lunch, dinner, snack }

@immutable
class MealPlan {
  final String id;
  final String userId;
  final DateTime date;
  final List<MealEntry> meals;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MealPlan({
    required this.id,
    required this.userId,
    required this.date,
    required this.meals,
    required this.createdAt,
    this.updatedAt,
  });

  double get totalCalories => meals.fold(0, (sum, meal) => sum + meal.calories);
  double get totalProtein => meals.fold(0, (sum, meal) => sum + meal.protein);
  double get totalCarbs => meals.fold(0, (sum, meal) => sum + meal.carbs);
  double get totalFat => meals.fold(0, (sum, meal) => sum + meal.fat);

  Map<String, List<MealEntry>> get mealsByType {
    final result = <String, List<MealEntry>>{};
    for (final type in MealType.values) {
      result[type.name] = meals.where((meal) => meal.type == type).toList();
    }
    return result;
  }

  MealPlan copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<MealEntry>? meals,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      meals: meals ?? this.meals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'meals': meals.map((meal) => meal.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      meals: (json['meals'] as List<dynamic>)
          .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

@immutable
class MealEntry {
  final String id;
  final String foodName;
  final String? brandName;
  final String? nixItemId;
  final MealType type;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? notes;
  final DateTime loggedAt;

  const MealEntry({
    required this.id,
    required this.foodName,
    this.brandName,
    this.nixItemId,
    required this.type,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.notes,
    required this.loggedAt,
  });

  MealEntry copyWith({
    String? id,
    String? foodName,
    String? brandName,
    String? nixItemId,
    MealType? type,
    double? servingSize,
    String? servingUnit,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? notes,
    DateTime? loggedAt,
  }) {
    return MealEntry(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      brandName: brandName ?? this.brandName,
      nixItemId: nixItemId ?? this.nixItemId,
      type: type ?? this.type,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      notes: notes ?? this.notes,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'food_name': foodName,
      'brand_name': brandName,
      'nix_item_id': nixItemId,
      'type': type.name,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'notes': notes,
      'logged_at': loggedAt.toIso8601String(),
    };
  }

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id'] as String,
      foodName: json['food_name'] as String,
      brandName: json['brand_name'] as String?,
      nixItemId: json['nix_item_id'] as String?,
      type: MealType.values.firstWhere(
        (e) => e.name == json['type'] as String,
      ),
      servingSize: (json['serving_size'] as num).toDouble(),
      servingUnit: json['serving_unit'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      notes: json['notes'] as String?,
      loggedAt: DateTime.parse(json['logged_at'] as String),
    );
  }

  factory MealEntry.fromNutritionix(
    Map<String, dynamic> data,
    MealType type,
    String? notes,
  ) {
    return MealEntry(
      id: const Uuid().v4(),
      foodName: data['food_name'],
      brandName: data['brand_name'],
      nixItemId: data['nix_item_id'],
      type: type,
      servingSize: (data['serving_qty'] ?? 1).toDouble(),
      servingUnit: data['serving_unit'] ?? 'serving',
      calories: (data['nf_calories'] ?? 0).toDouble(),
      protein: (data['nf_protein'] ?? 0).toDouble(),
      carbs: (data['nf_total_carbohydrate'] ?? 0).toDouble(),
      fat: (data['nf_total_fat'] ?? 0).toDouble(),
      notes: notes,
      loggedAt: DateTime.now(),
    );
  }
}
