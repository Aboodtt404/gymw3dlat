import 'package:flutter/material.dart';
import '../../models/meal_log_model.dart';
import '../../utils/app_constants.dart';
import '../../utils/styles.dart';

class MealDetailsScreen extends StatelessWidget {
  final MealLog mealLog;

  const MealDetailsScreen({
    super.key,
    required this.mealLog,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mealLog.food.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (mealLog.food.brand != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  mealLog.food.brand!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildNutritionCard(),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildServingInfo(),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildTimingInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrition Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutrientRow(
                'Calories', '${mealLog.calories.toStringAsFixed(0)} kcal'),
            _buildNutrientRow(
                'Protein', '${mealLog.protein.toStringAsFixed(1)}g'),
            _buildNutrientRow(
                'Carbohydrates', '${mealLog.carbs.toStringAsFixed(1)}g'),
            _buildNutrientRow('Fat', '${mealLog.fat.toStringAsFixed(1)}g'),
          ],
        ),
      ),
    );
  }

  Widget _buildServingInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Serving Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutrientRow(
              'Serving Size',
              '${mealLog.servingSize} ${mealLog.servingUnit}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timing Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutrientRow('Meal Type', mealLog.mealType.name),
            _buildNutrientRow(
              'Logged At',
              mealLog.loggedAt.toLocal().toString().split('.')[0],
            ),
            if (mealLog.updatedAt != null)
              _buildNutrientRow(
                'Last Updated',
                mealLog.updatedAt!.toLocal().toString().split('.')[0],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
