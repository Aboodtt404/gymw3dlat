import 'package:flutter/material.dart';
import '../../models/food_model.dart';
import '../../models/meal_log_model.dart';
import '../../services/natural_language_meal_service.dart';
import '../../services/meal_log_service.dart';
import '../../services/supabase_service.dart';
import '../../styles/styles.dart';

class NaturalLanguageMealScreen extends StatefulWidget {
  const NaturalLanguageMealScreen({super.key});

  @override
  State<NaturalLanguageMealScreen> createState() =>
      _NaturalLanguageMealScreenState();
}

class _NaturalLanguageMealScreenState extends State<NaturalLanguageMealScreen> {
  final _mealInputController = TextEditingController();
  final _nlpService = NaturalLanguageMealService();
  final _mealLogService = MealLogService();

  List<Food>? _parsedFoods;
  bool _isLoading = false;
  String? _error;
  MealType _selectedMealType = MealType.breakfast;

  @override
  void dispose() {
    _mealInputController.dispose();
    super.dispose();
  }

  Future<void> _parseMealInput() async {
    if (_mealInputController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter what you ate');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _parsedFoods = null;
    });

    try {
      debugPrint('Parsing meal input: ${_mealInputController.text}');
      final foods = await _nlpService
          .parseNaturalLanguageInput(_mealInputController.text);
      debugPrint(
          'Parsed ${foods.length} foods: ${foods.map((f) => f.name).join(', ')}');
      setState(() {
        _parsedFoods = foods;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error parsing meal input: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMealLog() async {
    if (_parsedFoods == null || _parsedFoods!.isEmpty) {
      setState(() => _error = 'No foods to log');
      return;
    }

    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _error = 'You must be logged in to save meals');
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint(
          'Creating meal log with ${_parsedFoods!.length} foods for user $userId');
      final mealLog = MealLog(
        userId: userId,
        foods: _parsedFoods!,
        mealType: _selectedMealType,
        loggedAt: DateTime.now(),
      );

      debugPrint('Meal log created: ${mealLog.toJson()}');
      await _mealLogService.logMeal(mealLog);
      debugPrint('Meal log saved successfully');

      // Learn from this meal log for future suggestions
      await _nlpService.learnFromMealLog(mealLog);
      debugPrint('Learned from meal log');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal logged successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Error saving meal log: $e');
      setState(() {
        _error = 'Failed to log meal: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Meal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What did you eat?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Type naturally, like "2 eggs with toast and a cup of coffee"',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mealInputController,
              decoration: InputDecoration(
                hintText: 'Enter what you ate...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _mealInputController.clear(),
                ),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _parseMealInput(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MealType>(
              value: _selectedMealType,
              decoration: InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: MealType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMealType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _parseMealInput,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Analyze Meal'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            if (_parsedFoods != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Analyzed Foods:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _parsedFoods!.length,
                  itemBuilder: (context, index) {
                    final food = _parsedFoods![index];
                    return Card(
                      child: ListTile(
                        title: Text(food.name),
                        subtitle: Text(
                          '${food.calories.round()} cal • '
                          '${food.protein.round()}g protein • '
                          '${food.carbs.round()}g carbs • '
                          '${food.fat.round()}g fat',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMealLog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save Meal Log'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
