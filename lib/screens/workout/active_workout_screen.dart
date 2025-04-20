import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gymw3dlat/constants/app_constants.dart';
import 'package:gymw3dlat/models/workout_models.dart';
import 'package:gymw3dlat/services/workout_service.dart';
import 'package:gymw3dlat/utils/styles.dart';
import 'package:provider/provider.dart';
import 'package:gymw3dlat/providers/user_provider.dart';
import 'package:uuid/uuid.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutTemplate? template;

  const ActiveWorkoutScreen({super.key, this.template});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final _workoutService = WorkoutService();
  final _notesController = TextEditingController();
  late WorkoutLog _workoutLog;
  bool _isLoading = false;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isPaused = false;
  DateTime? _pauseTime;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
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

  void _initializeWorkout() {
    try {
      final userData = context.read<UserProvider>().userData;
      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to start a workout'),
              backgroundColor: Styles.errorColor,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      final exercises = widget.template?.exercises.map((e) {
            return ExerciseLog(
              exerciseId: e.exerciseId,
              name: e.exerciseId,
              sets: List.generate(
                e.sets,
                (index) => SetLog(
                  setNumber: index + 1,
                  reps: e.reps,
                  weight: e.weight,
                  completed: false,
                ),
              ),
            );
          }).toList() ??
          [];

      _workoutLog = WorkoutLog(
        id: const Uuid().v4(),
        userId: userData['auth_id'],
        templateId: widget.template?.id,
        name: widget.template?.name ?? 'Quick Workout',
        exercises: exercises,
        startTime: DateTime.now(),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing workout: $e'),
            backgroundColor: Styles.errorColor,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _completeSet(bool completed) async {
    final exercise = _workoutLog.exercises[_currentExerciseIndex];
    final set = exercise.sets[_currentSetIndex];
    final updatedSet = SetLog(
      setNumber: set.setNumber,
      reps: set.reps,
      weight: set.weight,
      completed: completed,
      notes: set.notes,
    );

    setState(() {
      _workoutLog.exercises[_currentExerciseIndex].sets[_currentSetIndex] =
          updatedSet;
    });

    // Move to next set or exercise
    if (_currentSetIndex < exercise.sets.length - 1) {
      setState(() {
        _currentSetIndex++;
      });
    } else if (_currentExerciseIndex < _workoutLog.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSetIndex = 0;
      });
    }
  }

  Future<void> _finishWorkout() async {
    setState(() => _isLoading = true);
    try {
      final updatedLog = _workoutLog.copyWith(
        endTime: DateTime.now(),
        notes: _notesController.text,
        updatedAt: DateTime.now(),
      );

      await _workoutService.endWorkout(updatedLog);
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

  @override
  Widget build(BuildContext context) {
    if (_workoutLog.exercises.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentExercise = _workoutLog.exercises[_currentExerciseIndex];
    final currentSet = currentExercise.sets[_currentSetIndex];
    final isLastSet = _currentSetIndex == currentExercise.sets.length - 1;
    final isLastExercise =
        _currentExerciseIndex == _workoutLog.exercises.length - 1;

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
          title: Text(_workoutLog.name),
          actions: [
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
    final totalSets = _workoutLog.exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.sets.length,
    );
    final completedSets = _workoutLog.exercises.fold<int>(
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
              Text(
                'Progress',
                style: Styles.bodyStyle,
              ),
              Text(
                '${completedSets}/${totalSets} sets',
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
}
