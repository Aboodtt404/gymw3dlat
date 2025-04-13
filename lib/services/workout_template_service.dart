import '../models/workout_template_model.dart';
import 'supabase_service.dart';

class WorkoutTemplateService {
  static const String _tableName = 'workout_templates';

  // Create a new workout template
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .insert(template.toJson())
        .select()
        .single();

    return WorkoutTemplate.fromJson(response);
  }

  // Get all templates for the current user
  Future<List<WorkoutTemplate>> getUserTemplates() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => WorkoutTemplate.fromJson(json))
        .toList();
  }

  // Get a specific template by ID
  Future<WorkoutTemplate> getTemplateById(String id) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('id', id)
        .single();

    return WorkoutTemplate.fromJson(response);
  }

  // Update an existing template
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .update(template.toJson())
        .eq('id', template.id)
        .select()
        .single();

    return WorkoutTemplate.fromJson(response);
  }

  // Delete a template
  Future<void> deleteTemplate(String id) async {
    await SupabaseService.client.from(_tableName).delete().eq('id', id);
  }
}
