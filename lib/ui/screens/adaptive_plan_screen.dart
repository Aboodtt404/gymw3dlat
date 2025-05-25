import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adaptive_plan_service/adaptive_plan_service.dart';
import 'package:auth_service/auth_service.dart';

class AdaptivePlanScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _AdaptivePlanScreenState createState() => _AdaptivePlanScreenState();
}

class _AdaptivePlanScreenState extends State<AdaptivePlanScreen> {
  // ... (existing code)

  Future<void> _loadAdaptivePlan() async {
    setState(() => _isLoading = true);

    try {
      // Get current user
      final user = await AuthService().getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      // Get all user meal plans and workout templates
      final mealPlans =
          await AdaptivePlanService().getAllUserMealPlans(user.id);
      final workoutTemplates =
          await AdaptivePlanService().getAllUserWorkoutTemplates(user.id);

      // Check if user has meal plans and workout templates
      if (mealPlans.isEmpty || workoutTemplates.isEmpty) {
        setState(() {
          _error =
              'You need to create at least one meal plan and workout template';
          _isLoading = false;
        });
        return;
      }

      // Get or create adaptive plan
      AdaptivePlan? plan = await AdaptivePlanService().getCurrentPlan(user.id);

      if (plan == null) {
        // Create a new plan with the most recent meal plan and workout template
        plan = await AdaptivePlanService().createPlan(
          user,
          mealPlans.first,
          workoutTemplates.first,
        );
      } else {
        // Update plan with all meal plans and workout templates
        plan = await AdaptivePlanService().updatePlan(
          plan,
          user,
          mealPlans,
          workoutTemplates,
        );
      }

      setState(() {
        _adaptivePlan = plan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // AdaptivePlanOverview widget
  Widget _buildAdaptivePlanOverview() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adaptive Plan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your plan is intelligently adapted based on your progress and activity.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.insights),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress Score',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${(_adaptivePlan!.progressScore * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Recommendations based on all your meal plans and workout templates',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Recent Adjustments'),
              children: _adaptivePlan!.adjustments.reversed
                  .take(3)
                  .map((adjustment) => ListTile(
                        title: Text(adjustment.reason),
                        subtitle: Text(
                          DateFormat('MM/dd/yyyy').format(adjustment.date),
                        ),
                        trailing: adjustment.changes
                                    .containsKey('meal_plan_updated') &&
                                adjustment.changes['meal_plan_updated'] == true
                            ? const Icon(Icons.restaurant, color: Colors.green)
                            : adjustment.changes
                                        .containsKey('workout_plan_updated') &&
                                    adjustment
                                            .changes['workout_plan_updated'] ==
                                        true
                                ? const Icon(Icons.fitness_center,
                                    color: Colors.blue)
                                : null,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ... (rest of the existing code)
}
