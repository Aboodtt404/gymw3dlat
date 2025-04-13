import 'package:flutter/material.dart';
import '../../models/meal_log_model.dart';
import '../../services/meal_log_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/styles.dart';
import 'food_search_screen.dart';

class MealLogScreen extends StatefulWidget {
  const MealLogScreen({super.key});

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  final _mealLogService = MealLogService();
  List<MealLog> _mealLogs = [];
  bool _isLoading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMealLogs();
  }

  Future<void> _loadMealLogs() async {
    try {
      final mealLogs = await _mealLogService.getMealLogsForDate(_selectedDate);
      final summary =
          await _mealLogService.getNutritionSummaryForDate(_selectedDate);
      setState(() {
        _mealLogs = mealLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load meal logs: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildNutritionSummary() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final meal in _mealLogs) {
      totalCalories += meal.calories;
      totalProtein += meal.protein;
      totalCarbs += meal.carbs;
      totalFat += meal.fat;
    }

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                      _loadMealLogs();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientCircle(
                'Calories',
                totalCalories.toStringAsFixed(0),
                'kcal',
                Styles.primaryColor,
              ),
              _buildNutrientCircle(
                'Protein',
                totalProtein.toStringAsFixed(1),
                'g',
                Styles.proteinColor,
              ),
              _buildNutrientCircle(
                'Carbs',
                totalCarbs.toStringAsFixed(1),
                'g',
                Styles.carbsColor,
              ),
              _buildNutrientCircle(
                'Fat',
                totalFat.toStringAsFixed(1),
                'g',
                Styles.fatColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCircle(
      String label, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
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
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildMealSection(String title, List<MealLog> meals) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.defaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${meals.length} items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Center(
                child: Text(
                  'No meals logged',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                final meal = meals[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.defaultPadding / 2,
                  ),
                  title: Text(
                    meal.food.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    '${meal.calories.toStringAsFixed(0)} kcal - ${meal.servingSize} ${meal.servingUnit}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'P: ${meal.protein.toStringAsFixed(1)}g',
                            style: TextStyle(
                              fontSize: 12,
                              color: Styles.proteinColor,
                            ),
                          ),
                          Text(
                            'C: ${meal.carbs.toStringAsFixed(1)}g',
                            style: TextStyle(
                              fontSize: 12,
                              color: Styles.carbsColor,
                            ),
                          ),
                          Text(
                            'F: ${meal.fat.toStringAsFixed(1)}g',
                            style: TextStyle(
                              fontSize: 12,
                              color: Styles.fatColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to meal details
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Styles.errorColor),
        ),
      );
    }

    final breakfastMeals =
        _mealLogs.where((meal) => meal.mealType == MealType.breakfast).toList();
    final lunchMeals =
        _mealLogs.where((meal) => meal.mealType == MealType.lunch).toList();
    final dinnerMeals =
        _mealLogs.where((meal) => meal.mealType == MealType.dinner).toList();
    final snackMeals =
        _mealLogs.where((meal) => meal.mealType == MealType.snack).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMealLogs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNutritionSummary(),
              _buildMealSection('Breakfast', breakfastMeals),
              _buildMealSection('Lunch', lunchMeals),
              _buildMealSection('Dinner', dinnerMeals),
              _buildMealSection('Snacks', snackMeals),
              const SizedBox(height: AppConstants.defaultPadding * 4),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const FoodSearchScreen(mealType: MealType.snack),
            ),
          );
          if (result == true) {
            _loadMealLogs();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
