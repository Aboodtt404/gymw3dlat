import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/adaptive_plan_model.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/adaptive_plan_service.dart';
import '../services/meal_plan_service.dart';
import '../services/workout_template_service.dart';
import '../services/ai_plan_service.dart';
import '../utils/styles.dart';
import 'workout/workout_templates_screen.dart';
import 'ai_plan_suggestions_screen.dart';

class AdaptivePlanScreen extends StatefulWidget {
  const AdaptivePlanScreen({super.key});

  @override
  State<AdaptivePlanScreen> createState() => _AdaptivePlanScreenState();
}

class _AdaptivePlanScreenState extends State<AdaptivePlanScreen> {
  final _adaptivePlanService = AdaptivePlanService();
  final _mealPlanService = MealPlanService();
  final _workoutTemplateService = WorkoutTemplateService();
  final _aiPlanService = AIPlanService();
  bool _isLoading = true;
  bool _isUpdating = false;
  AdaptivePlan? _currentPlan;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.user;
      if (user == null) return;

      _user = user;
      _currentPlan = await _adaptivePlanService.getCurrentPlan(user.id);

      if (_currentPlan == null) {
        // Create initial plan if none exists
        final mealPlan = await _mealPlanService.getCurrentPlan(user.id);
        final workoutPlan =
            await _workoutTemplateService.getUserTemplates().then(
                  (templates) => templates.isNotEmpty ? templates.first : null,
                );

        if (mealPlan != null && workoutPlan != null) {
          _currentPlan = await _adaptivePlanService.createPlan(
            user,
            mealPlan,
            workoutPlan,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePlanUsingAI() async {
    if (_user == null || _currentPlan == null) return;

    setState(() => _isUpdating = true);

    try {
      // Calculate days away from last active date
      final daysAway = DateTime.now()
          .difference(_currentPlan!.lastActiveDate ?? _currentPlan!.startDate)
          .inDays;

      // Generate updated meal plan
      final updatedMealPlan = await _aiPlanService.generateMealPlan(
        _user!,
        _currentPlan!.currentMealPlan,
        daysAway,
        _currentPlan!.progressScore,
      );

      // Generate updated workout plan
      final updatedWorkoutPlan = await _aiPlanService.generateWorkoutPlan(
        _user!,
        _currentPlan!.currentWorkoutPlan,
        daysAway,
        _currentPlan!.progressScore,
      );

      // Create adjustment log
      final adjustment = PlanAdjustment(
        id: const Uuid().v4(),
        date: DateTime.now(),
        type: 'ai_update',
        reason: 'AI-based update after ${daysAway} days away',
        changes: {
          'days_away': daysAway,
          'adjustment_factor': _currentPlan!.adjustmentFactor,
          'meal_plan_updated': true,
          'workout_plan_updated': true,
        },
        createdAt: DateTime.now(),
      );

      // Update the plan with new data
      final updatedPlan = _currentPlan!.copyWith(
        lastActiveDate: DateTime.now(),
        daysAway: daysAway,
        currentMealPlan: updatedMealPlan,
        currentWorkoutPlan: updatedWorkoutPlan,
        adjustments: [..._currentPlan!.adjustments, adjustment],
        updatedAt: DateTime.now(),
      );

      // Save the updated plan
      final savedPlan = await _adaptivePlanService.updatePlan(
        updatedPlan,
        _user!,
        [], // Not using recent meal plans directly as AI service handles this
        [], // Not using recent workouts directly as AI service handles this
      );

      // Store training data for AI model improvement
      await _aiPlanService.storeTrainingData(
        userId: _user!.id,
        daysAway: daysAway,
        adjustmentFactor: _currentPlan!.adjustmentFactor,
        beforeProgressScore: _currentPlan!.progressScore,
        afterProgressScore:
            _currentPlan!.progressScore, // Will be updated later
        planChanges: {
          'meal_plan_calories_before':
              _currentPlan!.currentMealPlan.totalCalories,
          'meal_plan_calories_after': updatedMealPlan.totalCalories,
          'workout_sets_before': _currentPlan!.currentWorkoutPlan.exercises
              .fold(0, (sum, e) => sum + e.sets),
          'workout_sets_after':
              updatedWorkoutPlan.exercises.fold(0, (sum, e) => sum + e.sets),
        },
      );

      setState(() {
        _currentPlan = savedPlan;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Your plan has been updated based on your activity pattern'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentPlan == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Adaptive Plan'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No plan available',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPlan,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Adaptive Plan'),
        actions: [
          _isUpdating
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadPlan,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressCard(),
            const SizedBox(height: 16),
            _buildMealPlanCard(),
            const SizedBox(height: 16),
            _buildWorkoutPlanCard(),
            const SizedBox(height: 16),
            _buildAdjustmentsCard(),
            const SizedBox(height: 24),
            if ((_currentPlan!.daysAway > 3 ||
                    DateTime.now()
                            .difference(_currentPlan!.updatedAt ??
                                _currentPlan!.createdAt)
                            .inDays >
                        7) &&
                !_isUpdating)
              _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressItem(
                    'Days Away',
                    _currentPlan!.daysAway.toString(),
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildProgressItem(
                    'Progress Score',
                    '${(_currentPlan!.progressScore * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildProgressItem(
                    'Adjustment Factor',
                    '${(_currentPlan!.adjustmentFactor * 100).toStringAsFixed(0)}%',
                    Icons.tune,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMealPlanCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Meal Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to meal plan details
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNutritionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInfo() {
    final plan = _currentPlan!.currentMealPlan;
    return Column(
      children: [
        _buildNutritionRow(
            'Total Calories', '${plan.totalCalories.toStringAsFixed(0)} kcal'),
        const SizedBox(height: 8),
        _buildNutritionRow(
            'Protein', '${plan.totalProtein.toStringAsFixed(1)}g'),
        const SizedBox(height: 8),
        _buildNutritionRow('Carbs', '${plan.totalCarbs.toStringAsFixed(1)}g'),
        const SizedBox(height: 8),
        _buildNutritionRow('Fat', '${plan.totalFat.toStringAsFixed(1)}g'),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutPlanCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Workout Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutTemplatesScreen(),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWorkoutInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutInfo() {
    final plan = _currentPlan!.currentWorkoutPlan;
    return Column(
      children: [
        _buildWorkoutRow('Total Exercises', plan.exercises.length.toString()),
        const SizedBox(height: 8),
        _buildWorkoutRow(
          'Estimated Duration',
          '${plan.exercises.length * 3} minutes', // Assuming 3 minutes per exercise
        ),
      ],
    );
  }

  Widget _buildWorkoutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustmentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Adjustments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_currentPlan!.adjustments.isEmpty)
              const Center(
                child: Text('No adjustments made yet'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentPlan!.adjustments.length,
                itemBuilder: (context, index) {
                  final adjustment = _currentPlan!.adjustments[index];
                  return ListTile(
                    leading: Icon(
                      adjustment.type == 'meal'
                          ? Icons.restaurant
                          : Icons.fitness_center,
                    ),
                    title: Text(adjustment.reason),
                    subtitle: Text(
                      '${adjustment.date.day}/${adjustment.date.month}/${adjustment.date.year}',
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AIPlanSuggestionsScreen(
                currentPlan: _currentPlan!,
              ),
            ),
          );

          // If the plan was updated, reload it
          if (result == true) {
            _loadPlan();
          }
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Get AI Plan Suggestions'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
