import 'package:flutter/material.dart';
import '../../models/meal_log_model.dart';
import '../../models/food_model.dart';
import '../../services/food_service.dart';
import '../../styles/styles.dart';
import 'food_search_screen.dart';
import 'nutrition_insights_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
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
          SnackBar(
            content: Text('Failed to load meals: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
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
      await _loadMeals();
    }
  }

  Future<void> _deleteFood(Food food, MealType mealType) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Food'),
          content: Text(
              'Are you sure you want to delete "${food.name}" from ${mealType.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        if (food.mealLogId != null) {
          setState(() {
            _meals[mealType]!.remove(food);
          });

          await _foodService.deleteMealLog(food.mealLogId!);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Food deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _meals[mealType]!.add(food);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete food: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildDailySummary() {
    final totals = _calculateDayTotals();
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNutrientCircle(
                  totals['calories']!.round(),
                  'kcal',
                  Colors.purple,
                ),
                _buildNutrientCircle(
                  totals['protein']!.round(),
                  'g',
                  Styles.proteinColor,
                  label: 'Protein',
                ),
                _buildNutrientCircle(
                  totals['carbs']!.round(),
                  'g',
                  Styles.carbsColor,
                  label: 'Carbs',
                ),
                _buildNutrientCircle(
                  totals['fat']!.round(),
                  'g',
                  Styles.fatColor,
                  label: 'Fat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCircle(int value, String unit, Color color,
      {String? label}) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildMealSection(MealType mealType) {
    final foods = _meals[mealType]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mealType.name[0].toUpperCase() + mealType.name.substring(1),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${foods.length} items',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addFood(mealType),
                    tooltip: 'Add food to ${mealType.name}',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (foods.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No meals logged',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: foods.length,
            itemBuilder: (context, index) {
              final food = foods[index];
              return ListTile(
                title: Text(food.name),
                subtitle: Row(
                  children: [
                    Text(
                      '${food.calories.round()} kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'P: ${food.protein.toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 12,
                        color: Styles.proteinColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'C: ${food.carbs.toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 12,
                        color: Styles.carbsColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'F: ${food.fat.toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 12,
                        color: Styles.fatColor,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteFood(food, mealType),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: 'Nutrition Insights',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NutritionInsightsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // TODO: Implement date selection
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildDailySummary(),
                _buildMealSection(MealType.breakfast),
                _buildMealSection(MealType.lunch),
                _buildMealSection(MealType.dinner),
                _buildMealSection(MealType.snack),
              ],
            ),
    );
  }
}
