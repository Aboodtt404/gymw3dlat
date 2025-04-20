import 'package:flutter/material.dart';
import 'package:gymw3dlat/constants/app_constants.dart';
import 'package:gymw3dlat/models/workout_models.dart';
import 'package:gymw3dlat/services/workout_service.dart';
import 'package:gymw3dlat/utils/styles.dart';

class ExerciseSelectionDialog extends StatefulWidget {
  const ExerciseSelectionDialog({super.key});

  @override
  State<ExerciseSelectionDialog> createState() =>
      _ExerciseSelectionDialogState();
}

class _ExerciseSelectionDialogState extends State<ExerciseSelectionDialog> {
  final _workoutService = WorkoutService();
  final _searchController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '12');
  final _weightController = TextEditingController();
  final _restController = TextEditingController(
    text: AppConstants.defaultRestBetweenSets.toString(),
  );
  final _notesController = TextEditingController();

  List<Exercise> _exercises = [];
  Exercise? _selectedExercise;
  ExerciseCategory _selectedCategory = ExerciseCategory.chest;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises =
          await _workoutService.getExercisesByCategory(_selectedCategory);
      if (mounted) {
        setState(() {
          _exercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exercises: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Styles.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _searchExercises(String query) async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _workoutService.searchExercises(query);
      if (mounted) {
        setState(() {
          _exercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching exercises: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Styles.errorColor,
          ),
        );
      }
    }
  }

  void _addExercise() {
    if (_selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an exercise first'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Styles.errorColor,
        ),
      );
      return;
    }

    final sets = int.tryParse(_setsController.text);
    final reps = int.tryParse(_repsController.text);
    final weight = double.tryParse(_weightController.text);
    final rest = int.tryParse(_restController.text);

    String? errorMessage;
    if (sets == null || sets <= 0) {
      errorMessage = 'Please enter a valid number of sets (greater than 0)';
    } else if (reps == null || reps <= 0) {
      errorMessage = 'Please enter a valid number of reps (greater than 0)';
    } else if (weight != null && weight < 0) {
      errorMessage = 'Weight cannot be negative';
    } else if (rest != null && (rest < 0 || rest > 600)) {
      errorMessage = 'Rest period must be between 0 and 600 seconds';
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Styles.errorColor,
        ),
      );
      return;
    }

    final exerciseSet = ExerciseSet(
      exerciseId: _selectedExercise!.id,
      sets: sets!,
      reps: reps!,
      weight: weight,
      restTime: rest ?? 60, // Default rest period of 60 seconds
      notes: _notesController.text.trim(),
    );

    Navigator.pop(context, exerciseSet);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Exercise',
              style: Styles.headingStyle,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Exercises',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  _loadExercises();
                } else {
                  _searchExercises(value);
                }
              },
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            DropdownButtonFormField<ExerciseCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              items: ExerciseCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                    _searchController.clear();
                  });
                  _loadExercises();
                }
              },
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_exercises.isEmpty)
              Center(
                child: Text(
                  'No exercises found',
                  style: Styles.bodyStyle.copyWith(color: Styles.subtleText),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return RadioListTile<Exercise>(
                      title: Text(exercise.name),
                      subtitle: Text(
                        exercise.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: exercise,
                      groupValue: _selectedExercise,
                      onChanged: (value) {
                        setState(() {
                          _selectedExercise = value;
                        });
                      },
                    );
                  },
                ),
              ),
            if (_selectedExercise != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _setsController,
                      decoration: const InputDecoration(
                        labelText: 'Sets',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: TextField(
                      controller: _restController,
                      decoration: const InputDecoration(
                        labelText: 'Rest (seconds)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                ElevatedButton(
                  onPressed: _selectedExercise == null ? null : _addExercise,
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
