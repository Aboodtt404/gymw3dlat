import 'package:flutter/material.dart';
import 'package:gymw3dlat/constants/app_constants.dart';
import 'package:gymw3dlat/models/workout_models.dart';
import 'package:gymw3dlat/services/workout_service.dart';
import 'package:gymw3dlat/utils/styles.dart';
import 'package:gymw3dlat/models/exercise_model.dart' as api_model;

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

  List<dynamic> _exercises = [];
  dynamic _selectedExercise;
  bool _isSearchResult = false;
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
          _isSearchResult = false;
          _selectedExercise = null;
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
    if (query.trim().length < 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least 3 characters to search'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final exercises = await _workoutService.searchExercises(query);
      if (mounted) {
        setState(() {
          _exercises = exercises;
          _isSearchResult = true;
          _selectedExercise = null;
          _isLoading = false;
        });

        // Show feedback if no results found
        if (exercises.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No exercises found for "$query"'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error searching exercises: $e');
      if (mounted) {
        setState(() => _isLoading = false);

        String errorMessage = 'Error searching exercises';

        // Show a more useful error message for common issues
        if (e.toString().contains('Host not found')) {
          errorMessage = 'Network error: Please check your internet connection';
        } else if (e.toString().contains('403')) {
          errorMessage = 'API key error: Please check your ExerciseDB API key';
        } else if (e.toString().contains('429')) {
          errorMessage = 'API rate limit exceeded: Please try again later';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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

    if (_isSearchResult) {
      // Handle API exercise model
      final apiExercise = _selectedExercise as api_model.Exercise;

      // Convert API exercise to ExerciseSet
      final exerciseSet = ExerciseSet(
        exerciseId: apiExercise.id,
        sets: sets!,
        reps: reps!,
        weight: weight,
        restTime: rest ?? 60, // Default rest period of 60 seconds
        notes: _notesController.text.trim(),
      );

      Navigator.pop(context, exerciseSet);
    } else {
      // Handle local database exercise model
      final exercise = _selectedExercise as Exercise;

      final exerciseSet = ExerciseSet(
        exerciseId: exercise.id,
        sets: sets!,
        reps: reps!,
        weight: weight,
        restTime: rest ?? 60, // Default rest period of 60 seconds
        notes: _notesController.text.trim(),
      );

      Navigator.pop(context, exerciseSet);
    }
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
            const Text(
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
                    String title, subtitle;

                    if (_isSearchResult) {
                      // API Exercise model
                      final apiExercise = exercise as api_model.Exercise;
                      title = apiExercise.name;
                      subtitle =
                          'Target: ${apiExercise.target}, Body Part: ${apiExercise.bodyPart}';
                    } else {
                      // Local Exercise model
                      final localExercise = exercise as Exercise;
                      title = localExercise.name;
                      subtitle = localExercise.description;
                    }

                    return RadioListTile<dynamic>(
                      title: Text(title),
                      subtitle: Text(
                        subtitle,
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
