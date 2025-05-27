import 'package:flutter/material.dart';
import '../../models/food_model.dart';
import '../../models/meal_log_model.dart';
import '../../services/food_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodSearchScreen extends StatefulWidget {
  final MealType mealType;

  const FoodSearchScreen({
    super.key,
    required this.mealType,
  });

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _searchController = TextEditingController();
  final _foodService = FoodService();
  List<Food> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  final _supabase = Supabase.instance.client;

  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _foodService.searchFoods(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to search foods: $e';
        _isLoading = false;
      });
    }
  }

  void _selectFood(Food food) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final mealLog = MealLog(
        userId: userId,
        foods: [food],
        mealType: widget.mealType,
        loggedAt: DateTime.now(),
        storedCalories: food.calories,
        storedProtein: food.protein,
        storedCarbs: food.carbs,
        storedFat: food.fat,
      );
      await _foodService.logFood(food, widget.mealType);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log food: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFood(Food food) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Food'),
          content: const Text(
              'Are you sure you want to delete this food from your meal?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && food.mealLogId != null) {
      try {
        await _foodService.deleteMealLog(food.mealLogId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food deleted successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete food: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Food to ${widget.mealType.name}'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for foods...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.defaultBorderRadius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
              onChanged: _searchFoods,
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Text(
                _error!,
                style: const TextStyle(color: Styles.errorColor),
              ),
            )
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Text(
                      'No foods found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final food = _searchResults[index];
                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.defaultPadding / 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding,
                        vertical: AppConstants.defaultPadding / 2,
                      ),
                      title: Text(
                        food.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        '${food.calories.toStringAsFixed(0)} kcal per ${food.servingSize} ${food.servingUnit}',
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
                                'P: ${food.protein.toStringAsFixed(1)}g',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Styles.proteinColor,
                                ),
                              ),
                              Text(
                                'C: ${food.carbs.toStringAsFixed(1)}g',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Styles.carbsColor,
                                ),
                              ),
                              Text(
                                'F: ${food.fat.toStringAsFixed(1)}g',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Styles.fatColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          if (food.mealLogId != null)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => _deleteFood(food),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _selectFood(food),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
