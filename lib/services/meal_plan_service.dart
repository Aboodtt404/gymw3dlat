import '../models/meal_plan_model.dart';
import 'supabase_service.dart';

class MealPlanService {
  static const String _tableName = 'meal_plans';

  // Get the current meal plan for a user
  Future<MealPlan?> getCurrentPlan(String userId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isEmpty) return null;
    return MealPlan.fromJson(response[0]);
  }

  // Create a new meal plan
  Future<MealPlan> createPlan(MealPlan plan) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .insert(plan.toJson())
        .select()
        .single();

    return MealPlan.fromJson(response);
  }

  // Update an existing meal plan
  Future<MealPlan> updatePlan(MealPlan plan) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .update(plan.toJson())
        .eq('id', plan.id)
        .select()
        .single();

    return MealPlan.fromJson(response);
  }

  // Delete a meal plan
  Future<void> deletePlan(String id) async {
    await SupabaseService.client.from(_tableName).delete().eq('id', id);
  }
}
