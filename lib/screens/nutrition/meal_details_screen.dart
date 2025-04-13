import 'package:flutter/material.dart';
import '../../models/meal_log_model.dart';
import '../../models/food_model.dart';
import '../../services/food_service.dart';
import '../../styles/styles.dart';
import 'food_search_screen.dart';

class MealDetailsScreen extends StatefulWidget {
  const MealDetailsScreen({super.key});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  final _foodService = FoodService();
  Map<MealType, List<Food>> _meals = {
    MealType.breakfast: [],
    MealType.lunch: [],
    MealType.dinner: [],
    MealType.snack: [],
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    try {
      final meals = await _foodService.getMealsByType();
      setState(() {
        _meals = meals;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load meals: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Map<String, double> _calculateMealTotals(List<Food> foods) {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (var food in foods) {
      calories += food.calories;
      protein += food.protein;
      carbs += food.carbs;
      fat += food.fat;
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  Map<String, double> _calculateDayTotals() {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (var foods in _meals.values) {
      for (var food in foods) {
        calories += food.calories;
        protein += food.protein;
        carbs += food.carbs;
        fat += food.fat;
      }
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  Future<void> _addFood(MealType mealType) async {
    final food = await Navigator.push<Food>(
      context,
      MaterialPageRoute(
        builder: (context) => FoodSearchScreen(mealType: mealType),
      ),
    );

    if (food != null) {
      setState(() {
        _meals[mealType]!.add(food);
      });
      await _loadMeals(); // Refresh all meals
    }
  }

  Future<void> _deleteFood(Food food, MealType mealType) async {
    try {
      if (food.mealLogId != null) {
        await _foodService.deleteMealLog(food.mealLogId!);
        setState(() {
          _meals[mealType]!.remove(food);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete food: $e')),
        );
      }
    }
  }

  Widget _buildMealCard(MealType mealType, List<Food> foods) {
    final totals = _calculateMealTotals(foods);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              mealType.name[0].toUpperCase() + mealType.name.substring(1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addFood(mealType),
            ),
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: foods.length,
            itemBuilder: (context, index) {
              final food = foods[index];
              return ListTile(
                title: Text(food.name),
                subtitle: Text(food.brand ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'P: ${food.protein.toStringAsFixed(1)}g',
                          style: TextStyle(
                            fontSize: 12,
                            color: Styles.proteinColor,
                          ),
                        ),
                        Text(
                          'C: ${food.carbs.toStringAsFixed(1)}g',
                          style: TextStyle(
                            fontSize: 12,
                            color: Styles.carbsColor,
                          ),
                        ),
                        Text(
                          'F: ${food.fat.toStringAsFixed(1)}g',
                          style: TextStyle(
                            fontSize: 12,
                            color: Styles.fatColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteFood(food, mealType),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Calories: ${totals['calories']!.toStringAsFixed(1)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'P: ${totals['protein']!.toStringAsFixed(1)}g',
                      style: TextStyle(color: Styles.proteinColor),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'C: ${totals['carbs']!.toStringAsFixed(1)}g',
                      style: TextStyle(color: Styles.carbsColor),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'F: ${totals['fat']!.toStringAsFixed(1)}g',
                      style: TextStyle(color: Styles.fatColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayTotals = _calculateDayTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Totals',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Calories: ${dayTotals['calories']!.toStringAsFixed(1)} kcal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'P: ${dayTotals['protein']!.toStringAsFixed(1)}g',
                              style: TextStyle(
                                color: Styles.proteinColor,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'C: ${dayTotals['carbs']!.toStringAsFixed(1)}g',
                              style: TextStyle(
                                color: Styles.carbsColor,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'F: ${dayTotals['fat']!.toStringAsFixed(1)}g',
                              style: TextStyle(
                                color: Styles.fatColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildMealCard(
                          MealType.breakfast, _meals[MealType.breakfast]!),
                      _buildMealCard(MealType.lunch, _meals[MealType.lunch]!),
                      _buildMealCard(MealType.dinner, _meals[MealType.dinner]!),
                      _buildMealCard(MealType.snack, _meals[MealType.snack]!),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
