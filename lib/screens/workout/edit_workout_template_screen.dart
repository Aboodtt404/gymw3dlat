import 'package:flutter/material.dart';
import 'package:gymw3dlat/constants/app_constants.dart';
import 'package:gymw3dlat/models/workout_models.dart';
import 'package:gymw3dlat/services/workout_service.dart';
import 'package:gymw3dlat/utils/styles.dart';
import 'package:provider/provider.dart';
import 'package:gymw3dlat/providers/user_provider.dart';
import 'package:uuid/uuid.dart';
import 'exercise_selection_dialog.dart';

class EditWorkoutTemplateScreen extends StatefulWidget {
  final WorkoutTemplate? template;

  const EditWorkoutTemplateScreen({super.key, this.template});

  @override
  State<EditWorkoutTemplateScreen> createState() =>
      _EditWorkoutTemplateScreenState();
}

class _EditWorkoutTemplateScreenState extends State<EditWorkoutTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workoutService = WorkoutService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  List<ExerciseSet> _exercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _descriptionController.text = widget.template!.description;
      _durationController.text = widget.template!.estimatedDuration.toString();
      _exercises = List.from(widget.template!.exercises);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userData = context.read<UserProvider>().userData;
      if (userData == null) {
        throw Exception('User not logged in');
      }

      final template = WorkoutTemplate(
        id: widget.template?.id ?? const Uuid().v4(),
        userId: userData['id'],
        name: _nameController.text,
        description: _descriptionController.text,
        exercises: _exercises,
        estimatedDuration: int.parse(_durationController.text),
        createdAt: widget.template?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.template == null) {
        await _workoutService.addWorkoutTemplate(template);
      } else {
        await _workoutService.updateWorkoutTemplate(template);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving template: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Styles.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addExercise() async {
    final exerciseSet = await showDialog<ExerciseSet>(
      context: context,
      builder: (context) => const ExerciseSelectionDialog(),
    );

    if (exerciseSet != null) {
      setState(() {
        _exercises.add(exerciseSet);
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _updateExercise(int index, ExerciseSet exercise) {
    setState(() {
      _exercises[index] = exercise;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.template == null ? 'Create Template' : 'Edit Template'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveTemplate,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Template Name',
                      hintText: 'e.g., Upper Body Strength',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g., Focus on chest and shoulders',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Duration (minutes)',
                      hintText: 'e.g., 45',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter duration';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.largePadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exercises',
                        style: Styles.subheadingStyle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addExercise,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  if (_exercises.isEmpty)
                    Center(
                      child: Text(
                        'No exercises added yet',
                        style:
                            Styles.bodyStyle.copyWith(color: Styles.subtleText),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        return Card(
                          margin: const EdgeInsets.only(
                              bottom: AppConstants.defaultPadding),
                          child: ListTile(
                            title: Text(exercise.exerciseId),
                            subtitle: Text(
                              '${exercise.sets} sets × ${exercise.reps} reps' +
                                  (exercise.weight != null
                                      ? ' @ ${exercise.weight}kg'
                                      : ''),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final updatedExercise =
                                        await showDialog<ExerciseSet>(
                                      context: context,
                                      builder: (context) =>
                                          const ExerciseSelectionDialog(),
                                    );
                                    if (updatedExercise != null) {
                                      _updateExercise(index, updatedExercise);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeExercise(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
