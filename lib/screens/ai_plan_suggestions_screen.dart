import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/adaptive_plan_model.dart';
import '../models/meal_plan_model.dart';
import '../models/workout_template_model.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/adaptive_plan_service.dart';
import '../services/ai_plan_service.dart';
import '../utils/styles.dart';
import '../constants/app_constants.dart';

class AIPlanSuggestionsScreen extends StatefulWidget {
  final AdaptivePlan currentPlan;

  const AIPlanSuggestionsScreen({
    super.key,
    required this.currentPlan,
  });

  @override
  State<AIPlanSuggestionsScreen> createState() =>
      _AIPlanSuggestionsScreenState();
}

class _AIPlanSuggestionsScreenState extends State<AIPlanSuggestionsScreen> {
  final _aiPlanService = AIPlanService();
  final _adaptivePlanService = AdaptivePlanService();

  bool _isLoading = true;
  bool _isApplying = false;

  UserModel? _user;
  MealPlan? _suggestedMealPlan;
  WorkoutTemplate? _suggestedWorkoutPlan;
  late int _daysAway;

  @override
  void initState() {
    super.initState();
    _generateSuggestions();
  }

  Future<void> _generateSuggestions() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      _user = userProvider.user;

      if (_user == null) {
        throw Exception('User not available');
      }

      // Calculate days away
      _daysAway = DateTime.now()
          .difference(
              widget.currentPlan.lastActiveDate ?? widget.currentPlan.startDate)
          .inDays;

      // Generate suggestions
      final mealPlanFuture = _aiPlanService.generateMealPlan(
        _user!,
        widget.currentPlan.currentMealPlan,
        _daysAway,
        widget.currentPlan.progressScore,
      );

      final workoutPlanFuture = _aiPlanService.generateWorkoutPlan(
        _user!,
        widget.currentPlan.currentWorkoutPlan,
        _daysAway,
        widget.currentPlan.progressScore,
      );

      final results = await Future.wait([mealPlanFuture, workoutPlanFuture]);

      _suggestedMealPlan = results[0] as MealPlan;
      _suggestedWorkoutPlan = results[1] as WorkoutTemplate;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating suggestions: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyChanges() async {
    if (_user == null ||
        _suggestedMealPlan == null ||
        _suggestedWorkoutPlan == null) {
      return;
    }

    setState(() => _isApplying = true);

    try {
      // Create adjustment log
      final adjustment = PlanAdjustment(
        id: const Uuid().v4(),
        date: DateTime.now(),
        type: 'ai_suggestion',
        reason: 'AI-suggested plan after ${_daysAway} days away',
        changes: {
          'days_away': _daysAway,
          'adjustment_factor': widget.currentPlan.adjustmentFactor,
          'meal_plan_updated': true,
          'workout_plan_updated': true,
        },
        createdAt: DateTime.now(),
      );

      // Update the plan with new data
      final updatedPlan = widget.currentPlan.copyWith(
        lastActiveDate: DateTime.now(),
        daysAway: _daysAway,
        currentMealPlan: _suggestedMealPlan,
        currentWorkoutPlan: _suggestedWorkoutPlan,
        adjustments: [...widget.currentPlan.adjustments, adjustment],
        updatedAt: DateTime.now(),
      );

      // Save the updated plan
      await _adaptivePlanService.updatePlan(
        updatedPlan,
        _user!,
        [], // Not using recent meal plans
        [], // Not using recent workouts
      );

      // Store training data for AI model improvement
      await _aiPlanService.storeTrainingData(
        userId: _user!.id,
        daysAway: _daysAway,
        adjustmentFactor: widget.currentPlan.adjustmentFactor,
        beforeProgressScore: widget.currentPlan.progressScore,
        afterProgressScore:
            widget.currentPlan.progressScore, // Will be updated later
        planChanges: {
          'meal_plan_calories_before':
              widget.currentPlan.currentMealPlan.totalCalories,
          'meal_plan_calories_after': _suggestedMealPlan!.totalCalories,
          'workout_sets_before': widget.currentPlan.currentWorkoutPlan.exercises
              .fold(0, (sum, e) => sum + e.sets),
          'workout_sets_after': _suggestedWorkoutPlan!.exercises
              .fold(0, (sum, e) => sum + e.sets),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to previous screen
        Navigator.of(context).pop(true); // true indicates the plan was updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Plan Suggestions'),
        actions: [
          if (_isApplying)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      bottomNavigationBar: _isLoading || _isApplying ? null : _buildBottomBar(),
    );
  }

  Widget _buildContent() {
    if (_suggestedMealPlan == null || _suggestedWorkoutPlan == null) {
      return const Center(
        child: Text('Unable to generate suggestions. Please try again.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: AppConstants.defaultPadding),
          _buildMealPlanComparison(),
          const SizedBox(height: AppConstants.defaultPadding),
          _buildWorkoutPlanComparison(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final factor = _aiPlanService.calculateAdjustmentFactor(
        _daysAway, widget.currentPlan.progressScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Plan Suggestion',
              style: Styles.headingStyle,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Our AI has analyzed your activity pattern and created a personalized plan based on:',
              style: Styles.bodyStyle,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Days Away',
                    _daysAway.toString(),
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Progress Score',
                    '${(widget.currentPlan.progressScore * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Adjustment',
                    '${(factor * 100).toStringAsFixed(0)}%',
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

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Styles.primaryColor),
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

  Widget _buildMealPlanComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Plan Changes',
              style: Styles.subheadingStyle,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildComparisonRow(
              'Daily Calories',
              '${widget.currentPlan.currentMealPlan.totalCalories.round()} kcal',
              '${_suggestedMealPlan!.totalCalories.round()} kcal',
              _suggestedMealPlan!.totalCalories >
                  widget.currentPlan.currentMealPlan.totalCalories,
            ),
            const Divider(),
            _buildComparisonRow(
              'Protein',
              '${widget.currentPlan.currentMealPlan.totalProtein.round()} g',
              '${_suggestedMealPlan!.totalProtein.round()} g',
              _suggestedMealPlan!.totalProtein >
                  widget.currentPlan.currentMealPlan.totalProtein,
            ),
            const Divider(),
            _buildComparisonRow(
              'Carbs',
              '${widget.currentPlan.currentMealPlan.totalCarbs.round()} g',
              '${_suggestedMealPlan!.totalCarbs.round()} g',
              _suggestedMealPlan!.totalCarbs >
                  widget.currentPlan.currentMealPlan.totalCarbs,
            ),
            const Divider(),
            _buildComparisonRow(
              'Fat',
              '${widget.currentPlan.currentMealPlan.totalFat.round()} g',
              '${_suggestedMealPlan!.totalFat.round()} g',
              _suggestedMealPlan!.totalFat >
                  widget.currentPlan.currentMealPlan.totalFat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutPlanComparison() {
    // Calculate total sets and reps for both plans
    final currentTotalSets = widget.currentPlan.currentWorkoutPlan.exercises
        .fold(0, (sum, e) => sum + e.sets);
    final suggestedTotalSets =
        _suggestedWorkoutPlan!.exercises.fold(0, (sum, e) => sum + e.sets);

    final currentTotalReps = widget.currentPlan.currentWorkoutPlan.exercises
        .fold(0, (sum, e) => sum + (e.sets * e.reps));
    final suggestedTotalReps = _suggestedWorkoutPlan!.exercises
        .fold(0, (sum, e) => sum + (e.sets * e.reps));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Plan Changes',
              style: Styles.subheadingStyle,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildComparisonRow(
              'Total Sets',
              currentTotalSets.toString(),
              suggestedTotalSets.toString(),
              suggestedTotalSets > currentTotalSets,
            ),
            const Divider(),
            _buildComparisonRow(
              'Total Reps',
              currentTotalReps.toString(),
              suggestedTotalReps.toString(),
              suggestedTotalReps > currentTotalReps,
            ),
            const Divider(),
            _buildComparisonRow(
              'Exercises',
              widget.currentPlan.currentWorkoutPlan.exercises.length.toString(),
              _suggestedWorkoutPlan!.exercises.length.toString(),
              _suggestedWorkoutPlan!.exercises.length >
                  widget.currentPlan.currentWorkoutPlan.exercises.length,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            const Text(
              'Exercise Adjustments:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            _buildExerciseList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suggestedWorkoutPlan!.exercises.length,
      itemBuilder: (context, index) {
        final exercise = _suggestedWorkoutPlan!.exercises[index];

        // Try to find matching exercise in current plan
        final matchingExercises = widget
            .currentPlan.currentWorkoutPlan.exercises
            .where((e) => e.exerciseId == exercise.exerciseId)
            .toList();
        final currentExercise =
            matchingExercises.isNotEmpty ? matchingExercises.first : null;

        final isNewExercise = currentExercise == null;
        final setsChanged =
            !isNewExercise && currentExercise.sets != exercise.sets;
        final repsChanged =
            !isNewExercise && currentExercise.reps != exercise.reps;

        return ListTile(
          title: Text(exercise.name),
          subtitle: Text(
            '${exercise.sets} sets × ${exercise.reps} reps',
            style: TextStyle(
              color: (setsChanged || repsChanged) ? Styles.primaryColor : null,
              fontWeight: (setsChanged || repsChanged) ? FontWeight.bold : null,
            ),
          ),
          leading: Icon(
            isNewExercise ? Icons.add_circle : Icons.fitness_center,
            color: isNewExercise ? Colors.green : null,
          ),
          trailing: isNewExercise
              ? const Chip(label: Text('NEW'))
              : (setsChanged || repsChanged)
                  ? const Chip(label: Text('UPDATED'))
                  : null,
        );
      },
    );
  }

  Widget _buildComparisonRow(
      String label, String current, String suggested, bool isIncrease) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(current),
        ),
        const Icon(Icons.arrow_forward),
        Expanded(
          flex: 2,
          child: Text(
            suggested,
            style: TextStyle(
              color: isIncrease ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Icon(
          isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
          color: isIncrease ? Colors.green : Colors.red,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Dismiss'),
            ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
