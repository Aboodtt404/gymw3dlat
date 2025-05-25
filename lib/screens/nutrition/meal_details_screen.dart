import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/meal_log_model.dart';
import '../../models/food_model.dart';
import '../../services/food_service.dart';
import '../../styles/styles.dart';
import 'food_search_screen.dart';
import 'nutrition_insights_screen.dart';

class MealDetailsScreen extends StatefulWidget {
  const MealDetailsScreen({super.key});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _foodService = FoodService();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  Map<MealType, List<Food>> _meals = {
    MealType.breakfast: [],
    MealType.lunch: [],
    MealType.dinner: [],
    MealType.snack: [],
  };

  bool _isLoading = true;
  final double _targetCalories = 2000; // TODO: Make this configurable
  final double _targetProtein = 150; // in grams
  final double _targetCarbs = 250; // in grams
  final double _targetFat = 65; // in grams

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadMeals();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    try {
      final meals = await _foodService.getMealsByType();
      setState(() {
        _meals = meals;
        _isLoading = false;
      });
      _animationController.forward();
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
          await _foodService.deleteMealLog(food.mealLogId!);
          setState(() {
            _meals[mealType]!.remove(food);
          });
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

  Widget _buildNutritionChart(Map<String, double> dayTotals) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Styles.proteinColor,
              value: dayTotals['protein']! * 4, // 4 calories per gram
              title: 'P',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              color: Styles.carbsColor,
              value: dayTotals['carbs']! * 4, // 4 calories per gram
              title: 'C',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              color: Styles.fatColor,
              value: dayTotals['fat']! * 9, // 9 calories per gram
              title: 'F',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
      String label, double current, double target, Color color) {
    final percentage = (current / target).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: percentage,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 8,
              ),
              Center(
                child: Text(
                  '${(percentage * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          '${current.round()}/${target.round()}g',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection(MealType mealType, List<Food> foods) {
    final totals = _calculateMealTotals(foods);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${totals['calories']!.round()} kcal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _addFood(mealType),
                  tooltip: 'Add food',
                ),
              ],
            ),
          ),
          if (foods.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No foods logged yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: foods.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final food = foods[index];
                return Dismissible(
                  key: Key(food.mealLogId ?? food.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return _deleteFood(food, mealType).then((_) => true);
                  },
                  child: ListTile(
                    title: Text(
                      food.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          'P: ${food.protein.toStringAsFixed(1)}g',
                          style: const TextStyle(
                            color: Styles.proteinColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'C: ${food.carbs.toStringAsFixed(1)}g',
                          style: const TextStyle(
                            color: Styles.carbsColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'F: ${food.fat.toStringAsFixed(1)}g',
                          style: const TextStyle(
                            color: Styles.fatColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${food.calories.round()} kcal',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayTotals = _calculateDayTotals();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 320.0,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text('Nutrition'),
                    background: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 32),
                            _buildNutritionChart(dayTotals),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildProgressIndicator(
                                  'Protein',
                                  dayTotals['protein']!,
                                  _targetProtein,
                                  Styles.proteinColor,
                                ),
                                _buildProgressIndicator(
                                  'Carbs',
                                  dayTotals['carbs']!,
                                  _targetCarbs,
                                  Styles.carbsColor,
                                ),
                                _buildProgressIndicator(
                                  'Fat',
                                  dayTotals['fat']!,
                                  _targetFat,
                                  Styles.fatColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildMealSection(
                              MealType.breakfast, _meals[MealType.breakfast]!),
                          _buildMealSection(
                              MealType.lunch, _meals[MealType.lunch]!),
                          _buildMealSection(
                              MealType.dinner, _meals[MealType.dinner]!),
                          _buildMealSection(
                              MealType.snack, _meals[MealType.snack]!),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
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
      ],
    );
  }
}
