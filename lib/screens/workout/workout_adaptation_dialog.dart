import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ai_workout_models.dart';
import '../../models/workout_models.dart' show WorkoutIntensity;
import '../../providers/smart_workout_provider.dart';
import '../../utils/styles.dart';
import '../../constants/app_constants.dart';

class WorkoutAdaptationDialog extends StatefulWidget {
  final AIWorkoutRecommendation originalWorkout;

  const WorkoutAdaptationDialog({
    super.key,
    required this.originalWorkout,
  });

  @override
  State<WorkoutAdaptationDialog> createState() =>
      _WorkoutAdaptationDialogState();
}

class _WorkoutAdaptationDialogState extends State<WorkoutAdaptationDialog> {
  RecoveryStatus _selectedRecoveryStatus = RecoveryStatus.fullyRecovered;
  Map<String, double> _exercisePerformance = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePerformanceData();
  }

  void _initializePerformanceData() {
    for (final exercise in widget.originalWorkout.exercises) {
      _exercisePerformance[exercise.exerciseId] = 1.0; // Default performance
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppConstants.defaultPadding),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecoveryStatusSection(),
                    const SizedBox(height: AppConstants.defaultPadding),
                    _buildPerformanceSection(),
                    const SizedBox(height: AppConstants.defaultPadding),
                    _buildAdaptationPreview(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adapt Workout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Customize "${widget.originalWorkout.name}" based on your current state',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildRecoveryStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How are you feeling today?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        const Text(
          'This helps us adjust the workout intensity appropriately.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ...RecoveryStatus.values.map((status) {
          return _buildRecoveryStatusCard(status);
        }).toList(),
      ],
    );
  }

  Widget _buildRecoveryStatusCard(RecoveryStatus status) {
    final isSelected = _selectedRecoveryStatus == status;
    final statusInfo = _getRecoveryStatusInfo(status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedRecoveryStatus = status),
          borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              gradient: isSelected ? Styles.sportGradient : Styles.cardGradient,
              borderRadius:
                  BorderRadius.circular(AppConstants.smallBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Styles.primaryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusInfo['color'],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusInfo['color'].withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusInfo['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusInfo['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white70 : Colors.white60,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: AppConstants.defaultIconSize,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exercise Performance Adjustment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        const Text(
          'Adjust the difficulty for each exercise based on your recent performance.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ...widget.originalWorkout.exercises.map((exercise) {
          return _buildExercisePerformanceSlider(exercise);
        }).toList(),
      ],
    );
  }

  Widget _buildExercisePerformanceSlider(SmartExerciseSet exercise) {
    final performance = _exercisePerformance[exercise.exerciseId] ?? 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: Styles.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise ${exercise.exerciseId}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getPerformanceColor(performance).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(performance * 100).toInt()}%',
                  style: TextStyle(
                    color: _getPerformanceColor(performance),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Row(
            children: [
              const Text(
                'Easier',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Styles.primaryColor,
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    thumbColor: Colors.white,
                    overlayColor: Styles.primaryColor.withOpacity(0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
                  child: Slider(
                    value: performance,
                    min: 0.5,
                    max: 1.5,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() {
                        _exercisePerformance[exercise.exerciseId] = value;
                      });
                    },
                  ),
                ),
              ),
              const Text(
                'Harder',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            _getPerformanceDescription(performance),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white60,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptationPreview() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Styles.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        border: Border.all(color: Styles.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: Styles.primaryColor,
                size: AppConstants.defaultIconSize,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              const Text(
                'Adaptation Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          _buildAdaptationSummary(),
        ],
      ),
    );
  }

  Widget _buildAdaptationSummary() {
    final adaptationFactor = _getOverallAdaptationFactor();
    final newIntensity = _getAdaptedIntensity();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(
          'Recovery Status',
          _getRecoveryStatusInfo(_selectedRecoveryStatus)['title'],
          _getRecoveryStatusInfo(_selectedRecoveryStatus)['color'],
        ),
        const SizedBox(height: AppConstants.smallPadding),
        _buildSummaryRow(
          'Overall Adjustment',
          '${(adaptationFactor * 100).toInt()}%',
          _getAdaptationColor(adaptationFactor),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        _buildSummaryRow(
          'New Intensity',
          newIntensity.toString().split('.').last.toUpperCase(),
          _getIntensityColor(newIntensity),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Text(
          _getAdaptationExplanation(adaptationFactor),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.smallPadding,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: AppConstants.defaultPadding),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _adaptWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Adapt Workout',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _adaptWorkout() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<SmartWorkoutProvider>();
      final adaptedWorkout = await provider.adaptWorkout(
        originalWorkout: widget.originalWorkout,
        currentPerformance: _exercisePerformance,
        recoveryStatus: _selectedRecoveryStatus,
      );

      if (mounted && adaptedWorkout != null) {
        Navigator.pop(context, adaptedWorkout);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout adapted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adapting workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _getRecoveryStatusInfo(RecoveryStatus status) {
    switch (status) {
      case RecoveryStatus.fullyRecovered:
        return {
          'title': 'Fully Recovered',
          'description': 'Feeling great and ready for a challenging workout',
          'color': Colors.green,
        };
      case RecoveryStatus.partiallyRecovered:
        return {
          'title': 'Partially Recovered',
          'description': 'Some fatigue but can handle moderate intensity',
          'color': Colors.yellow,
        };
      case RecoveryStatus.fatigued:
        return {
          'title': 'Fatigued',
          'description': 'Tired and need a lighter workout',
          'color': Colors.orange,
        };
      case RecoveryStatus.overreached:
        return {
          'title': 'Overreached',
          'description': 'Very tired, need significant recovery',
          'color': Colors.red,
        };
    }
  }

  String _getPerformanceDescription(double performance) {
    if (performance < 0.7) {
      return 'Reduce difficulty significantly';
    } else if (performance < 0.9) {
      return 'Slightly reduce difficulty';
    } else if (performance > 1.3) {
      return 'Increase difficulty significantly';
    } else if (performance > 1.1) {
      return 'Slightly increase difficulty';
    } else {
      return 'Keep current difficulty';
    }
  }

  double _getOverallAdaptationFactor() {
    final recoveryFactor = _getRecoveryFactor(_selectedRecoveryStatus);
    final avgPerformance = _exercisePerformance.values.isEmpty
        ? 1.0
        : _exercisePerformance.values.reduce((a, b) => a + b) /
            _exercisePerformance.values.length;

    return recoveryFactor * avgPerformance;
  }

  double _getRecoveryFactor(RecoveryStatus status) {
    switch (status) {
      case RecoveryStatus.fullyRecovered:
        return 1.0;
      case RecoveryStatus.partiallyRecovered:
        return 0.85;
      case RecoveryStatus.fatigued:
        return 0.7;
      case RecoveryStatus.overreached:
        return 0.5;
    }
  }

  WorkoutIntensity _getAdaptedIntensity() {
    final adaptationFactor = _getOverallAdaptationFactor();
    final originalIntensity = widget.originalWorkout.intensity;
    final intensityIndex = WorkoutIntensity.values.indexOf(originalIntensity);

    if (adaptationFactor < 0.7) {
      // Reduce intensity
      final newIndex =
          (intensityIndex - 1).clamp(0, WorkoutIntensity.values.length - 1);
      return WorkoutIntensity.values[newIndex];
    } else if (adaptationFactor > 1.2) {
      // Increase intensity
      final newIndex =
          (intensityIndex + 1).clamp(0, WorkoutIntensity.values.length - 1);
      return WorkoutIntensity.values[newIndex];
    } else {
      // Keep same intensity
      return originalIntensity;
    }
  }

  Color _getAdaptationColor(double factor) {
    if (factor < 0.7) {
      return Colors.red;
    } else if (factor < 0.9) {
      return Colors.orange;
    } else if (factor > 1.2) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }

  Color _getIntensityColor(WorkoutIntensity intensity) {
    switch (intensity) {
      case WorkoutIntensity.light:
        return Colors.green;
      case WorkoutIntensity.moderate:
        return Colors.blue;
      case WorkoutIntensity.vigorous:
        return Colors.orange;
      case WorkoutIntensity.extreme:
        return Colors.red;
    }
  }

  String _getAdaptationExplanation(double factor) {
    if (factor < 0.7) {
      return 'Workout will be significantly easier to match your current recovery state.';
    } else if (factor < 0.9) {
      return 'Workout will be slightly easier to accommodate your current state.';
    } else if (factor > 1.2) {
      return 'Workout will be more challenging based on your performance feedback.';
    } else {
      return 'Workout difficulty will remain similar to the original.';
    }
  }

  Color _getPerformanceColor(double performance) {
    if (performance < 0.7) return Colors.red;
    if (performance < 0.9) return Colors.orange;
    if (performance > 1.3) return Colors.blue;
    if (performance > 1.1) return Colors.green;
    return Colors.white;
  }
}
