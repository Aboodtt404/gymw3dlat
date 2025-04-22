import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/adaptive_plan_model.dart';
import '../models/meal_plan_model.dart';
import '../models/workout_template_model.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class AdaptivePlanService {
  static const String _tableName = 'adaptive_plans';

  // Create a new adaptive plan
  Future<AdaptivePlan> createPlan(
    UserModel user,
    MealPlan mealPlan,
    WorkoutTemplate workoutPlan,
  ) async {
    final plan = AdaptivePlan(
      id: Uuid().v4(),
      userId: user.id,
      startDate: DateTime.now(),
      lastActiveDate: DateTime.now(),
      daysAway: 0,
      progressScore: 0.0,
      currentMealPlan: mealPlan,
      currentWorkoutPlan: workoutPlan,
      adjustments: [],
      createdAt: DateTime.now(),
    );

    final response = await SupabaseService.client
        .from(_tableName)
        .insert(plan.toJson())
        .select()
        .single();

    return AdaptivePlan.fromJson(response);
  }

  // Get the current plan for a user
  Future<AdaptivePlan?> getCurrentPlan(String userId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isEmpty) return null;
    return AdaptivePlan.fromJson(response[0]);
  }

  // Update plan based on user activity and progress
  Future<AdaptivePlan> updatePlan(
    AdaptivePlan plan,
    UserModel user,
    List<MealPlan> recentMealPlans,
    List<WorkoutTemplate> recentWorkouts,
  ) async {
    final daysAway =
        DateTime.now().difference(plan.lastActiveDate ?? plan.startDate).inDays;
    final progressScore =
        _calculateProgressScore(recentMealPlans, recentWorkouts);

    // Adjust meal plan based on progress and time away
    final adjustedMealPlan = _adjustMealPlan(
      plan.currentMealPlan,
      progressScore,
      plan.adjustmentFactor,
      user,
    );

    // Adjust workout plan based on progress and time away
    final adjustedWorkoutPlan = _adjustWorkoutPlan(
      plan.currentWorkoutPlan,
      progressScore,
      plan.adjustmentFactor,
      user,
    );

    final updatedPlan = plan.copyWith(
      lastActiveDate: DateTime.now(),
      daysAway: daysAway,
      progressScore: progressScore,
      currentMealPlan: adjustedMealPlan,
      currentWorkoutPlan: adjustedWorkoutPlan,
      adjustments: [
        ...plan.adjustments,
        PlanAdjustment(
          id: Uuid().v4(),
          date: DateTime.now(),
          type: 'plan',
          reason: 'Progress update and time away adjustment',
          changes: {
            'days_away': daysAway,
            'progress_score': progressScore,
            'adjustment_factor': plan.adjustmentFactor,
          },
          createdAt: DateTime.now(),
        ),
      ],
      updatedAt: DateTime.now(),
    );

    final response = await SupabaseService.client
        .from(_tableName)
        .update(updatedPlan.toJson())
        .eq('id', plan.id)
        .select()
        .single();

    return AdaptivePlan.fromJson(response);
  }

  // Calculate progress score based on recent activity
  double _calculateProgressScore(
    List<MealPlan> recentMealPlans,
    List<WorkoutTemplate> recentWorkouts,
  ) {
    if (recentMealPlans.isEmpty || recentWorkouts.isEmpty) return 0.0;

    // Calculate meal plan adherence
    final mealAdherence = recentMealPlans.fold(0.0, (sum, plan) {
          final targetCalories = 2000.0; // This should come from user goals
          final calorieDiff = (plan.totalCalories - targetCalories).abs();
          return sum + (1.0 - min(calorieDiff / targetCalories, 1.0));
        }) /
        recentMealPlans.length;

    // Calculate workout consistency
    final workoutConsistency =
        recentWorkouts.length / 7.0; // Assuming 7 days as target

    // Combine scores with weights
    return (mealAdherence * 0.6) + (workoutConsistency * 0.4);
  }

  // Adjust meal plan based on progress and time away
  MealPlan _adjustMealPlan(
    MealPlan currentPlan,
    double progressScore,
    double adjustmentFactor,
    UserModel user,
  ) {
    // Calculate target adjustments based on progress and time away
    final targetCalories = _calculateTargetCalories(user, progressScore);
    final currentCalories = currentPlan.totalCalories;
    final calorieAdjustment =
        (targetCalories - currentCalories) * adjustmentFactor;

    // Adjust each meal proportionally
    final adjustedMeals = currentPlan.meals.map((meal) {
      final ratio = meal.calories / currentCalories;
      final adjustedCalories = meal.calories + (calorieAdjustment * ratio);

      return meal.copyWith(
        calories: adjustedCalories,
        protein: meal.protein * (adjustedCalories / meal.calories),
        carbs: meal.carbs * (adjustedCalories / meal.calories),
        fat: meal.fat * (adjustedCalories / meal.calories),
      );
    }).toList();

    return currentPlan.copyWith(meals: adjustedMeals);
  }

  // Adjust workout plan based on progress and time away
  WorkoutTemplate _adjustWorkoutPlan(
    WorkoutTemplate currentPlan,
    double progressScore,
    double adjustmentFactor,
    UserModel user,
  ) {
    // Adjust intensity based on progress and time away
    final intensityMultiplier =
        1.0 + ((progressScore - 0.5) * 0.2) * adjustmentFactor;

    final adjustedExercises = currentPlan.exercises.map((exercise) {
      return exercise.copyWith(
        sets: (exercise.sets * intensityMultiplier).round(),
        reps: (exercise.reps * intensityMultiplier).round(),
        weight: exercise.weight != null
            ? exercise.weight! * intensityMultiplier
            : null,
      );
    }).toList();

    return currentPlan.copyWith(exercises: adjustedExercises);
  }

  // Calculate target calories based on user goals and progress
  double _calculateTargetCalories(UserModel user, double progressScore) {
    final baseCalories =
        2000.0; // This should be calculated based on user metrics
    final goal = user.goal?.toLowerCase() ?? 'maintain';

    switch (goal) {
      case 'lose weight':
        return baseCalories * (0.9 + (progressScore * 0.1));
      case 'build muscle':
        return baseCalories * (1.1 - (progressScore * 0.1));
      default: // maintain weight
        return baseCalories;
    }
  }
}
