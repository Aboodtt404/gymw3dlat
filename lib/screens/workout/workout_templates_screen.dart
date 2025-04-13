import 'package:flutter/material.dart';
import 'package:gymw3dlat/constants/app_constants.dart';
import 'package:gymw3dlat/models/workout_models.dart';
import 'package:gymw3dlat/services/workout_service.dart';
import 'package:gymw3dlat/utils/styles.dart';
import 'package:provider/provider.dart';
import 'package:gymw3dlat/providers/user_provider.dart';
import 'edit_workout_template_screen.dart';

class WorkoutTemplatesScreen extends StatefulWidget {
  const WorkoutTemplatesScreen({super.key});

  @override
  State<WorkoutTemplatesScreen> createState() => _WorkoutTemplatesScreenState();
}

class _WorkoutTemplatesScreenState extends State<WorkoutTemplatesScreen> {
  final WorkoutService _workoutService = WorkoutService();
  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final userData = context.read<UserProvider>().userData;
      if (userData != null) {
        final templates =
            await _workoutService.getUserWorkoutTemplates(userData['id']);
        if (mounted) {
          setState(() {
            _templates = templates;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading templates: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Styles.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _navigateToEditScreen([WorkoutTemplate? template]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditWorkoutTemplateScreen(template: template),
      ),
    );

    if (result == true) {
      _loadTemplates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToEditScreen(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmptyState()
              : _buildTemplatesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Styles.subtleText,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'No Workout Templates',
            style: Styles.headingStyle,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Create your first workout template',
            style: Styles.bodyStyle.copyWith(color: Styles.subtleText),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          ElevatedButton.icon(
            onPressed: () => _navigateToEditScreen(),
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
          child: InkWell(
            onTap: () => _navigateToEditScreen(template),
            borderRadius:
                BorderRadius.circular(AppConstants.defaultBorderRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: Styles.subheadingStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${template.estimatedDuration} min',
                        style:
                            Styles.bodyStyle.copyWith(color: Styles.subtleText),
                      ),
                    ],
                  ),
                  if (template.description.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      template.description,
                      style:
                          Styles.bodyStyle.copyWith(color: Styles.subtleText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppConstants.defaultPadding),
                  Row(
                    children: [
                      _buildExerciseCount(template),
                      const SizedBox(width: AppConstants.defaultPadding),
                      _buildMuscleGroups(template),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseCount(WorkoutTemplate template) {
    return Row(
      children: [
        const Icon(Icons.fitness_center, size: 16),
        const SizedBox(width: 4),
        Text(
          '${template.exercises.length} exercises',
          style: Styles.bodyStyle.copyWith(
            color: Styles.subtleText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleGroups(WorkoutTemplate template) {
    // Get unique categories from exercises
    final categories = template.exercises
        .map((e) => ExerciseCategory.values.firstWhere(
              (cat) =>
                  cat.toString().split('.').last == e.exerciseId.split('_')[0],
              orElse: () => ExerciseCategory.other,
            ))
        .toSet();

    return Row(
      children: [
        const Icon(Icons.sports_gymnastics, size: 16),
        const SizedBox(width: 4),
        Text(
          categories.map((e) => e.toString().split('.').last).join(', '),
          style: Styles.bodyStyle.copyWith(
            color: Styles.subtleText,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
