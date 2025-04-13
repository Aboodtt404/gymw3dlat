import 'package:gymw3dlat/models/food_model.dart';

enum MealType { breakfast, lunch, dinner, snack }

class MealLog {
  final String id;
  final String userId;
  final String foodId;
  final Food food;
  final double servingSize;
  final MealType mealType;
  final DateTime loggedAt;
  final DateTime? updatedAt;

  MealLog({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.food,
    required this.servingSize,
    required this.mealType,
    required this.loggedAt,
    this.updatedAt,
  });

  // Calculate actual nutritional values based on serving size
  double get calories => (food.calories * servingSize) / food.servingSize;
  double get protein => (food.protein * servingSize) / food.servingSize;
  double get carbs => (food.carbs * servingSize) / food.servingSize;
  double get fat => (food.fat * servingSize) / food.servingSize;

  factory MealLog.fromJson(Map<String, dynamic> json, {required Food food}) {
    return MealLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      foodId: json['food_id'] as String,
      food: food,
      servingSize: (json['serving_size'] as num).toDouble(),
      mealType: MealType.values.firstWhere(
        (e) => e.toString().split('.').last == json['meal_type'],
      ),
      loggedAt: DateTime.parse(json['logged_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'food_id': foodId,
      'serving_size': servingSize,
      'meal_type': mealType.toString().split('.').last,
      'logged_at': loggedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  MealLog copyWith({
    String? id,
    String? userId,
    String? foodId,
    Food? food,
    double? servingSize,
    MealType? mealType,
    DateTime? loggedAt,
    DateTime? updatedAt,
  }) {
    return MealLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      food: food ?? this.food,
      servingSize: servingSize ?? this.servingSize,
      mealType: mealType ?? this.mealType,
      loggedAt: loggedAt ?? this.loggedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
