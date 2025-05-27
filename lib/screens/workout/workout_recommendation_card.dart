import 'package:flutter/material.dart';
import '../../models/ai_workout_models.dart';
import '../../models/workout_models.dart' show WorkoutIntensity;
import '../../utils/styles.dart';
import '../../constants/app_constants.dart';

class WorkoutRecommendationCard extends StatelessWidget {
  final AIWorkoutRecommendation recommendation;
  final VoidCallback? onTap;
  final VoidCallback? onAdapt;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const WorkoutRecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
    this.onAdapt,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppConstants.defaultBorderRadius),
            gradient: _getIntensityGradient(recommendation.intensity),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppConstants.smallPadding),
              _buildDescription(),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildMetrics(),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildFocusAreas(),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildExercisePreview(),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: _getIntensityGradient(recommendation.intensity),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConstants.defaultBorderRadius),
          topRight: Radius.circular(AppConstants.defaultBorderRadius),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildIntensityChip(),
                    const SizedBox(width: AppConstants.smallPadding),
                    _buildDifficultyChip(),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (onFavorite != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: onFavorite,
                  ),
                ),
              if (onAdapt != null)
                Container(
                  margin: const EdgeInsets.only(top: AppConstants.smallPadding),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.tune,
                      color: Colors.white,
                    ),
                    onPressed: onAdapt,
                    tooltip: 'Adapt Workout',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      recommendation.description,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetrics() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: Styles.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            Icons.schedule,
            '${recommendation.estimatedDuration}',
            'Minutes',
          ),
          _buildMetricItem(
            Icons.fitness_center,
            '${recommendation.exercises.length}',
            'Exercises',
          ),
          _buildMetricItem(
            Icons.trending_up,
            recommendation.difficultyScore.toStringAsFixed(1),
            'Difficulty',
          ),
          _buildMetricItem(
            Icons.psychology,
            '${(recommendation.confidenceScore * 100).toInt()}%',
            'AI Match',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: AppConstants.defaultIconSize,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusAreas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Focus Areas:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Wrap(
          spacing: AppConstants.smallPadding,
          runSpacing: 4,
          children: recommendation.focusAreas.map((area) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.smallPadding,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius:
                    BorderRadius.circular(AppConstants.smallBorderRadius),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                area,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExercisePreview() {
    final previewExercises = recommendation.exercises.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: Styles.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Exercise Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          ...previewExercises.map((exercise) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(AppConstants.smallPadding),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.smallBorderRadius),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Styles.primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${previewExercises.indexOf(exercise) + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${exercise.sets} sets × ${exercise.reps} reps',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (exercise.weight != null)
                          Text(
                            'Weight: ${exercise.weight}kg',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (recommendation.exercises.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${recommendation.exercises.length - 3} more exercises',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: Styles.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AI Reasoning',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.reasoning,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
            decoration: BoxDecoration(
              gradient: Styles.sportGradient,
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Styles.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                const Text(
                  'Start Workout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityChip() {
    final intensityColor = _getIntensityColor(recommendation.intensity);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: intensityColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        border: Border.all(color: intensityColor),
      ),
      child: Text(
        recommendation.intensity.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          color: intensityColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDifficultyChip() {
    final difficultyColor = _getDifficultyColor(recommendation.difficultyScore);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: difficultyColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        border: Border.all(color: difficultyColor),
      ),
      child: Text(
        'LEVEL ${recommendation.difficultyScore.toInt()}',
        style: TextStyle(
          color: difficultyColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  LinearGradient _getIntensityGradient(WorkoutIntensity intensity) {
    switch (intensity) {
      case WorkoutIntensity.light:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF2E7D32),
          ],
        );
      case WorkoutIntensity.moderate:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2196F3),
            Color(0xFF1565C0),
          ],
        );
      case WorkoutIntensity.vigorous:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9800),
            Color(0xFFE65100),
          ],
        );
      case WorkoutIntensity.extreme:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF44336),
            Color(0xFFB71C1C),
          ],
        );
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

  Color _getDifficultyColor(double difficulty) {
    if (difficulty <= 3) {
      return Colors.green;
    } else if (difficulty <= 6) {
      return Colors.yellow;
    } else if (difficulty <= 8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
