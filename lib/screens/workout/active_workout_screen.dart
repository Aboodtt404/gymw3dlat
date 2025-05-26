import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gymw3dlat/constants/app_constants.dart';
import 'package:gymw3dlat/models/workout_models.dart';
import 'package:gymw3dlat/services/workout_service.dart';
import 'package:gymw3dlat/services/exercise_db_service.dart';
import 'package:gymw3dlat/utils/styles.dart';
import 'package:provider/provider.dart';
import 'package:gymw3dlat/providers/user_provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/voice_command_service.dart';
import '../../widgets/voice_command_button.dart';
import '../../providers/smart_workout_provider.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutTemplate? template;

  const ActiveWorkoutScreen({super.key, this.template});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final _workoutService = WorkoutService();
  final _exerciseDBService = ExerciseDBService();
  final _notesController = TextEditingController();
  WorkoutLog? _workoutLog;
  bool _isLoading = false;
  bool _hasInitialized = false;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isPaused = false;
  DateTime? _pauseTime;
  final _voiceCommandService = VoiceCommandService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized && !_isLoading) {
      _initializeWorkout();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _startTime = DateTime.now();
    if (_pauseTime != null) {
      // Adjust start time to account for paused duration
      _startTime = _startTime!.subtract(_elapsed);
      _pauseTime = null;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
      _pauseTime = DateTime.now();
      _timer?.cancel();
    });
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
      _startTimer();
    });
  }

  Future<void> _initializeWorkout() async {
    setState(() {
      _isLoading = true;
      _hasInitialized = true;
    });

    try {
      final userData = context.read<UserProvider>().userData;
      if (userData == null) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please log in to start a workout'),
                backgroundColor: Styles.errorColor,
              ),
            );
            Navigator.pop(context);
          });
        }
        return;
      }

      final exercises = <ExerciseLog>[];

      // Fetch exercise details from ExerciseDB API
      if (widget.template != null) {
        for (final e in widget.template!.exercises) {
          final exerciseDetails =
              await _exerciseDBService.getExerciseById(e.exerciseId);
          exercises.add(
            ExerciseLog(
              exerciseId: e.exerciseId,
              name: exerciseDetails.name, // Use the name from the API
              gifUrl: exerciseDetails.gifUrl, // Add the GIF URL
              sets: List.generate(
                e.sets,
                (index) => SetLog(
                  setNumber: index + 1,
                  reps: e.reps,
                  weight: e.weight,
                  completed: false,
                ),
              ),
            ),
          );
        }
      }

      final workoutLog = WorkoutLog(
        id: const Uuid().v4(),
        userId: userData['auth_id'],
        templateId: widget.template?.id,
        name: widget.template?.name ?? 'Quick Workout',
        exercises: exercises,
        startTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Save the workout to the database
      _workoutLog = await _workoutService.startWorkout(workoutLog);
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error initializing workout: $e'),
              backgroundColor: Styles.errorColor,
            ),
          );
          Navigator.pop(context);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeSet(bool completed) async {
    final workoutLog = _workoutLog;
    if (workoutLog == null) return;

    final exercise = workoutLog.exercises[_currentExerciseIndex];
    final set = exercise.sets[_currentSetIndex];
    final updatedSet = SetLog(
      setNumber: set.setNumber,
      reps: set.reps,
      weight: set.weight,
      completed: completed,
      notes: set.notes,
    );

    setState(() {
      workoutLog.exercises[_currentExerciseIndex].sets[_currentSetIndex] =
          updatedSet;
    });

    // Move to next set or exercise
    if (_currentSetIndex < exercise.sets.length - 1) {
      setState(() {
        _currentSetIndex++;
      });
    } else if (_currentExerciseIndex < workoutLog.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSetIndex = 0;
      });
    }
  }

  Future<void> _finishWorkout() async {
    final workoutLog = _workoutLog;
    if (workoutLog == null) return;

    // Check if all sets are completed
    final uncompletedSets = <String>[];
    for (final exercise in workoutLog.exercises) {
      final incompleteSets =
          exercise.sets.where((set) => !set.completed).length;
      if (incompleteSets > 0) {
        uncompletedSets.add('${exercise.name}: $incompleteSets sets remaining');
      }
    }

    if (uncompletedSets.isNotEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Incomplete Workout'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('You still have uncompleted sets:'),
                const SizedBox(height: 8),
                ...uncompletedSets.map((set) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('• $set'),
                    )),
                const SizedBox(height: 16),
                const Text(
                    'Do you want to mark these sets as failed and finish the workout?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue Workout'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _finishIncompleteWorkout();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Mark as Failed & Finish'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updatedLog = workoutLog.copyWith(
        endTime: DateTime.now(),
        notes: _notesController.text,
        updatedAt: DateTime.now(),
      );

      await _workoutService.endWorkout(updatedLog);

      // Analyze workout performance
      final smartWorkoutProvider = context.read<SmartWorkoutProvider>();
      await smartWorkoutProvider.analyzeWorkoutPerformance(updatedLog);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
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

  Future<void> _finishIncompleteWorkout() async {
    final workoutLog = _workoutLog;
    if (workoutLog == null) return;

    setState(() => _isLoading = true);
    try {
      // Mark all incomplete sets as failed
      for (final exercise in workoutLog.exercises) {
        for (int i = 0; i < exercise.sets.length; i++) {
          if (!exercise.sets[i].completed) {
            exercise.sets[i] = exercise.sets[i].copyWith(completed: false);
          }
        }
      }

      final updatedLog = workoutLog.copyWith(
        endTime: DateTime.now(),
        notes: '${_notesController.text}\n[Workout ended with incomplete sets]',
        updatedAt: DateTime.now(),
      );

      await _workoutService.endWorkout(updatedLog);

      // Analyze workout performance even for incomplete workouts
      final smartWorkoutProvider = context.read<SmartWorkoutProvider>();
      await smartWorkoutProvider.analyzeWorkoutPerformance(updatedLog);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
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

  void _handleVoiceCommand(String command) {
    // Try to parse as a set command first
    final setData = _voiceCommandService.parseSetCommand(command);
    if (setData != null) {
      _handleSetCommand(setData);
      return;
    }

    // Try to parse as an exercise command
    final exerciseData = _voiceCommandService.parseExerciseCommand(command);
    if (exerciseData != null) {
      _handleExerciseCommand(exerciseData);
      return;
    }

    // Show error if command not recognized
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Command not recognized. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSetCommand(Map<String, dynamic> data) {
    final reps = data['reps'] as int;
    final weight = data['weight'] as double?;
    final unit = data['unit'] as String?;

    // TODO: Add set to current exercise
    setState(() {
      // Update your workout state here
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          weight != null
              ? 'Logged set: $reps reps at $weight $unit'
              : 'Logged set: $reps reps (bodyweight)',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExerciseCommand(Map<String, dynamic> data) {
    final exercise = data['exercise'] as String;

    // TODO: Switch to or start new exercise
    setState(() {
      // Update your workout state here
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to exercise: $exercise'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      try {
        await _voiceCommandService.startListening(
          onResult: _handleVoiceCommand,
          onComplete: () => setState(() => _isListening = false),
        );
        setState(() => _isListening = true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting voice recognition: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await _voiceCommandService.stopListening();
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _workoutLog == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final workoutLog = _workoutLog!;
    final currentExercise = workoutLog.exercises[_currentExerciseIndex];
    final currentSet = currentExercise.sets[_currentSetIndex];
    final isLastSet = _currentSetIndex == currentExercise.sets.length - 1;
    final isLastExercise =
        _currentExerciseIndex == workoutLog.exercises.length - 1;

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('End Workout?'),
            content: const Text('Are you sure you want to end this workout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('End'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(workoutLog.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save as Template',
              onPressed: _saveAsTemplate,
            ),
            IconButton(
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: () {
                if (_isPaused) {
                  _resumeTimer();
                } else {
                  _pauseTimer();
                }
              },
            ),
            TextButton(
              onPressed: _finishWorkout,
              child: const Text('Finish'),
            ),
            VoiceCommandButton(
              isListening: _isListening,
              onPressed: _toggleListening,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildTimer(),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildProgress(),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            currentExercise.name,
                            style: Styles.headingStyle,
                          ),
                          const SizedBox(height: AppConstants.smallPadding),
                          Text(
                            'Set ${currentSet.setNumber} of ${currentExercise.sets.length}',
                            style: Styles.bodyStyle
                                .copyWith(color: Styles.subtleText),
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          _buildSetDetails(currentSet),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _completeSet(false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.red.withOpacity(0.1),
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Failed'),
                                ),
                              ),
                              const SizedBox(
                                  width: AppConstants.defaultPadding),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _completeSet(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.green.withOpacity(0.1),
                                    foregroundColor: Colors.green,
                                  ),
                                  child: Text(
                                    isLastSet && isLastExercise
                                        ? 'Complete Workout'
                                        : 'Complete Set',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTimer() {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes.remainder(60);
    final seconds = _elapsed.inSeconds.remainder(60);

    return Container(
      color: Styles.primaryColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: Styles.primaryColor),
          const SizedBox(width: AppConstants.smallPadding),
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: Styles.headingStyle.copyWith(
              color: Styles.primaryColor,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final workoutLog = _workoutLog;
    if (workoutLog == null) return const SizedBox();

    final totalSets = workoutLog.exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.sets.length,
    );
    final completedSets = workoutLog.exercises.fold<int>(
      0,
      (sum, exercise) =>
          sum + exercise.sets.where((set) => set.completed).length,
    );
    final progress = completedSets / totalSets;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: Styles.bodyStyle,
              ),
              Text(
                '$completedSets/$totalSets sets',
                style: Styles.bodyStyle.copyWith(color: Styles.subtleText),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Styles.cardBackground,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Styles.primaryColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetDetails(SetLog set) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            if (_workoutLog != null &&
                _workoutLog!.exercises[_currentExerciseIndex].gifUrl != null)
              Container(
                height: 200,
                width: double.infinity,
                margin:
                    const EdgeInsets.only(bottom: AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppConstants.defaultBorderRadius),
                  color: Colors.black.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppConstants.defaultBorderRadius),
                  child: Image.network(
                    _workoutLog!.exercises[_currentExerciseIndex].gifUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSetDetail(
                  icon: Icons.repeat,
                  label: 'Reps',
                  value: set.reps.toString(),
                ),
                if (set.weight != null)
                  _buildSetDetail(
                    icon: Icons.fitness_center,
                    label: 'Weight',
                    value: '${set.weight}kg',
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add notes for this set...',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Styles.primaryColor),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          label,
          style: Styles.bodyStyle.copyWith(color: Styles.subtleText),
        ),
        Text(
          value,
          style: Styles.headingStyle.copyWith(fontSize: 20),
        ),
      ],
    );
  }

  Future<void> _saveAsTemplate() async {
    final workoutLog = _workoutLog;
    if (workoutLog == null) return;

    final nameController = TextEditingController(text: workoutLog.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Template Name',
            hintText: 'Enter template name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        setState(() => _isLoading = true);

        // Convert workout log to template
        final exercises = workoutLog.exercises
            .map((e) => ExerciseSet(
                  exerciseId: e.exerciseId,
                  sets: e.sets.length,
                  reps: e.sets.isNotEmpty ? e.sets.first.reps : 0,
                  weight: e.sets.isNotEmpty ? e.sets.first.weight : null,
                ))
            .toList();

        // Calculate estimated duration based on workout log
        final estimatedDuration = workoutLog.endTime != null
            ? workoutLog.endTime!.difference(workoutLog.startTime).inMinutes
            : _elapsed.inMinutes;

        final template = WorkoutTemplate(
          id: const Uuid().v4(),
          userId: workoutLog.userId,
          name: result.trim(),
          description: '',
          exercises: exercises,
          estimatedDuration: estimatedDuration > 0
              ? estimatedDuration
              : 30, // Default to 30 minutes if zero
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _workoutService.addWorkoutTemplate(template);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout saved as template'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving template: $e'),
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
  }
}
