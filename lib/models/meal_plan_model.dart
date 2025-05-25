import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:gymw3dlat/services/supabase_service.dart';

enum MealType { breakfast, lunch, dinner, snack, preworkout, postworkout }

@immutable
class MealPlan {
  final String id;
  final String userId;
  final DateTime date;
  final List<Meal> meals;
  final double? targetCalories;
  final double? targetProtein;
  final double? targetFat;
  final double? targetCarbs;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MealPlan({
    required this.id,
    required this.userId,
    required this.date,
    required this.meals,
    this.targetCalories,
    this.targetProtein,
    this.targetFat,
    this.targetCarbs,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  double get totalCalories => meals.fold(0, (sum, meal) => sum + meal.calories);
  double get totalProtein => meals.fold(0, (sum, meal) => sum + meal.protein);
  double get totalCarbs => meals.fold(0, (sum, meal) => sum + meal.carbs);
  double get totalFat => meals.fold(0, (sum, meal) => sum + meal.fat);

  double get caloriesPercentage => targetCalories != null && targetCalories! > 0
      ? (totalCalories / targetCalories! * 100)
      : 0;

  double get proteinPercentage => targetProtein != null && targetProtein! > 0
      ? (totalProtein / targetProtein! * 100)
      : 0;

  double get fatPercentage =>
      targetFat != null && targetFat! > 0 ? (totalFat / targetFat! * 100) : 0;

  double get carbsPercentage => targetCarbs != null && targetCarbs! > 0
      ? (totalCarbs / targetCarbs! * 100)
      : 0;

  Map<String, List<Meal>> get mealsByType {
    final result = <String, List<Meal>>{};
    for (final type in MealType.values) {
      result[type.name] = meals.where((meal) => meal.type == type).toList();
    }
    return result;
  }

  MealPlan copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<Meal>? meals,
    double? targetCalories,
    double? targetProtein,
    double? targetFat,
    double? targetCarbs,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      meals: meals ?? this.meals,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetFat: targetFat ?? this.targetFat,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      notes: notes ?? this.notes,
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
      'target_calories': targetCalories,
      'target_protein': targetProtein,
      'target_fat': targetFat,
      'target_carbs': targetCarbs,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      meals: (json['meals'] as List).map((e) => Meal.fromJson(e)).toList(),
      targetCalories: json['target_calories'] as double?,
      targetProtein: json['target_protein'] as double?,
      targetFat: json['target_fat'] as double?,
      targetCarbs: json['target_carbs'] as double?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  factory MealPlan.create({
    required String userId,
    required DateTime date,
    List<Meal> meals = const [],
    double? targetCalories,
    double? targetProtein,
    double? targetFat,
    double? targetCarbs,
    String? notes,
  }) {
    return MealPlan(
      id: const Uuid().v4(),
      userId: userId,
      date: date,
      meals: meals,
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetFat: targetFat,
      targetCarbs: targetCarbs,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}

@immutable
class Meal {
  final String id;
  final String name;
  final MealType type;
  final List<FoodItem> foods;
  final DateTime time;
  final String? notes;

  const Meal({
    required this.id,
    required this.name,
    required this.type,
    required this.foods,
    required this.time,
    this.notes,
  });

  double get calories => foods.fold(0, (sum, food) => sum + food.calories);
  double get protein => foods.fold(0, (sum, food) => sum + food.protein);
  double get fat => foods.fold(0, (sum, food) => sum + food.fat);
  double get carbs => foods.fold(0, (sum, food) => sum + food.carbs);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'foods': foods.map((e) => e.toJson()).toList(),
      'time': time.toIso8601String(),
      'notes': notes,
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      type: MealType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      foods: (json['foods'] as List).map((e) => FoodItem.fromJson(e)).toList(),
      time: DateTime.parse(json['time'] as String),
      notes: json['notes'] as String?,
    );
  }

  Meal copyWith({
    String? id,
    String? name,
    MealType? type,
    List<FoodItem>? foods,
    DateTime? time,
    String? notes,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      foods: foods ?? this.foods,
      time: time ?? this.time,
      notes: notes ?? this.notes,
    );
  }

  factory Meal.create({
    required String name,
    required MealType type,
    List<FoodItem> foods = const [],
    required DateTime time,
    String? notes,
  }) {
    return Meal(
      id: const Uuid().v4(),
      name: name,
      type: type,
      foods: foods,
      time: time,
      notes: notes,
    );
  }
}

class FoodItem {
  final String id;
  final String name;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double? fiber;
  final double? sugar;
  final String? imageUrl;

  const FoodItem({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.fiber,
    this.sugar,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'fiber': fiber,
      'sugar': sugar,
      'image_url': imageUrl,
    };
  }

  factory FoodItem.create({
    required String name,
    required double servingSize,
    required String servingUnit,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    double? fiber,
    double? sugar,
    String? imageUrl,
  }) {
    return FoodItem(
      id: const Uuid().v4(),
      name: name,
      servingSize: servingSize,
      servingUnit: servingUnit,
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      fiber: fiber,
      sugar: sugar,
      imageUrl: imageUrl,
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      servingSize: json['serving_size'] as double,
      servingUnit: json['serving_unit'] as String,
      calories: json['calories'] as double,
      protein: json['protein'] as double,
      fat: json['fat'] as double,
      carbs: json['carbs'] as double,
      fiber: json['fiber'] as double?,
      sugar: json['sugar'] as double?,
      imageUrl: json['image_url'] as String?,
    );
  }

  FoodItem copyWith({
    String? id,
    String? name,
    double? servingSize,
    String? servingUnit,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? fiber,
    double? sugar,
    String? imageUrl,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

@immutable
class MealEntry {
  final String id;
  final String foodName;
  final String? brandName;
  final MealType type;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime loggedAt;

  const MealEntry({
    required this.id,
    required this.foodName,
    this.brandName,
    required this.type,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'food_name': foodName,
      'brand_name': brandName,
      'type': type.toString().split('.').last,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'logged_at': loggedAt.toIso8601String(),
    };
  }

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id'] as String,
      foodName: json['food_name'] as String,
      brandName: json['brand_name'] as String?,
      type: MealType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      servingSize: (json['serving_size'] as num).toDouble(),
      servingUnit: json['serving_unit'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      loggedAt: DateTime.parse(json['logged_at'] as String),
    );
  }
}
