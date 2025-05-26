import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/ai_workout_models.dart';
import '../../models/workout_models.dart';
import '../../services/supabase_service.dart';
import '../../providers/smart_workout_provider.dart';
import '../../utils/styles.dart';
import '../../constants/app_constants.dart';
import 'workout_recommendation_card.dart';
import 'fitness_profile_setup_screen.dart';
import 'workout_adaptation_dialog.dart';
import 'active_workout_screen.dart';

class SmartWorkoutScreen extends StatefulWidget {
  const SmartWorkoutScreen({super.key});

  @override
  State<SmartWorkoutScreen> createState() => _SmartWorkoutScreenState();
}

class _SmartWorkoutScreenState extends State<SmartWorkoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize smart workout features
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SmartWorkoutProvider>().initializeSmartWorkout();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: Styles.backgroundGradient),
        child: SafeArea(
          child: Consumer<SmartWorkoutProvider>(
            builder: (context, provider, child) {
              if (provider.needsFitnessProfileSetup()) {
                return _buildProfileSetupPrompt(provider);
              }

              return Column(
                children: [
                  _buildHeader(provider),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRecommendationsTab(provider),
                        _buildProgressTab(provider),
                        _buildInsightsTab(provider),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader(SmartWorkoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: Styles.cardGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.defaultBorderRadius),
          bottomRight: Radius.circular(AppConstants.defaultBorderRadius),
        ),
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
              const Text(
                'Smart Workouts',
                style: Styles.headingStyle,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            await provider.clearFitnessProfileFromDatabase();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile cleared for testing'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Styles.primaryColor),
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.refreshRecommendations(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          _buildStatusIndicator(provider),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(SmartWorkoutProvider provider) {
    final isReady = provider.isReadyForNextWorkout();
    final recoveryStatus = provider.getCurrentRecoveryStatus();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isReady ? Colors.green : Colors.orange,
            isReady
                ? Colors.green.withOpacity(0.8)
                : Colors.orange.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: (isReady ? Colors.green : Colors.orange).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReady ? Icons.check_circle : Icons.schedule,
              color: Colors.white,
              size: AppConstants.defaultIconSize,
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReady
                      ? 'Ready for your next workout!'
                      : 'Recovery in progress',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isReady
                      ? 'Your body is well-recovered'
                      : 'Status: ${recoveryStatus.toString().split('.').last}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: Styles.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: Styles.sportGradient,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Styles.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: 'Recommendations'),
          Tab(text: 'Progress'),
          Tab(text: 'Insights'),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab(SmartWorkoutProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return _buildErrorState(provider.error!, provider);
    }

    if (!provider.hasRecommendations) {
      return _buildEmptyState(provider);
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshRecommendations(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: provider.recommendations.length,
        itemBuilder: (context, index) {
          final recommendation = provider.recommendations[index];
          return WorkoutRecommendationCard(
            recommendation: recommendation,
            onTap: () => _handleRecommendationTap(recommendation, provider),
            onAdapt: () => _showAdaptationDialog(recommendation, provider),
            onFavorite: () => _toggleFavorite(recommendation, provider),
            isFavorite: false, // TODO: Implement favorites functionality
          );
        },
      ),
    );
  }

  Widget _buildProgressTab(SmartWorkoutProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFitnessLevelCard(provider),
          const SizedBox(height: AppConstants.defaultPadding),
          _buildProgressionPlanCard(provider),
          const SizedBox(height: AppConstants.defaultPadding),
          _buildPerformanceCard(provider),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(SmartWorkoutProvider provider) {
    final stats = provider.getWorkoutStatistics();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsCard(stats),
          const SizedBox(height: AppConstants.defaultPadding),
          _buildRecommendationsInsights(provider),
          const SizedBox(height: AppConstants.defaultPadding),
          _buildPerformanceInsights(provider),
        ],
      ),
    );
  }

  Widget _buildProfileSetupPrompt(SmartWorkoutProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 80,
              color: Styles.primaryColor,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            const Text(
              'Set Up Your Fitness Profile',
              style: Styles.headingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            const Text(
              'To get personalized workout recommendations, we need to know more about your fitness goals and preferences.',
              style: Styles.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton(
              onPressed: () => _navigateToProfileSetup(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.largePadding,
                  vertical: AppConstants.defaultPadding,
                ),
              ),
              child: const Text(
                'Set Up Profile',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, SmartWorkoutProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Styles.errorColor,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Something went wrong',
              style: Styles.headingStyle.copyWith(color: Styles.errorColor),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              error,
              style: Styles.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton(
              onPressed: () => provider.refreshRecommendations(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(SmartWorkoutProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 64,
              color: Styles.subtleText,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            const Text(
              'No Recommendations Yet',
              style: Styles.headingStyle,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            const Text(
              'Complete a few workouts to get personalized recommendations.',
              style: Styles.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton(
              onPressed: () => provider.refreshRecommendations(),
              child: const Text('Generate Recommendations'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitnessLevelCard(SmartWorkoutProvider provider) {
    final progress = provider.getFitnessLevelProgress();
    final level =
        provider.fitnessProfile?.fitnessLevel.toString().split('.').last ??
            'Unknown';

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: Styles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fitness Level', style: Styles.subheadingStyle),
          const SizedBox(height: AppConstants.smallPadding),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Styles.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Styles.primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Styles.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionPlanCard(SmartWorkoutProvider provider) {
    final plan = provider.progressionPlan;
    final nextMilestone = provider.getNextMilestone();
    final goalProgress = provider.calculateGoalProgress();

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: Styles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progression Plan', style: Styles.subheadingStyle),
              if (plan == null)
                TextButton(
                  onPressed: () => _showCreateProgressionPlanDialog(provider),
                  child: const Text('Create Plan'),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          if (plan != null) ...[
            Text(
              plan.goalType.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Styles.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            LinearProgressIndicator(
              value: goalProgress,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Styles.primaryColor),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text('${(goalProgress * 100).toInt()}% Complete'),
            if (nextMilestone != null) ...[
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Next: ${nextMilestone.description}',
                style: Styles.bodyStyle,
              ),
            ],
          ] else ...[
            const Text(
              'Create a progression plan to track your fitness goals and milestones.',
              style: Styles.bodyStyle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(SmartWorkoutProvider provider) {
    final analysis = provider.lastPerformanceAnalysis;
    final performanceScore = provider.getAveragePerformanceScore();

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: Styles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Analysis', style: Styles.subheadingStyle),
          const SizedBox(height: AppConstants.smallPadding),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(performanceScore * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Styles.primaryColor,
                      ),
                    ),
                    const Text('Average Performance'),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: performanceScore,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  performanceScore > 0.8
                      ? Colors.green
                      : performanceScore > 0.6
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
          ),
          if (analysis != null) ...[
            const SizedBox(height: AppConstants.defaultPadding),
            if (analysis.strengths.isNotEmpty) ...[
              const Text('Strengths:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...analysis.strengths.map((strength) => Text('• $strength')),
            ],
            if (analysis.weaknesses.isNotEmpty) ...[
              const SizedBox(height: AppConstants.smallPadding),
              const Text('Areas for Improvement:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...analysis.weaknesses.map((weakness) => Text('• $weakness')),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: Styles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Workout Statistics', style: Styles.subheadingStyle),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Recommendations',
                  stats['total_recommendations'].toString(),
                  Icons.fitness_center,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Avg Duration',
                  '${stats['average_duration']} min',
                  Icons.schedule,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Avg Difficulty',
                  '${stats['average_difficulty'].toStringAsFixed(1)}/10',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Most Common',
                  stats['most_common_intensity'],
                  Icons.flash_on,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon,
            color: Styles.primaryColor, size: AppConstants.largeIconSize),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Styles.primaryColor,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecommendationsInsights(SmartWorkoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: Styles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recommendation Insights', style: Styles.subheadingStyle),
          const SizedBox(height: AppConstants.smallPadding),
          if (provider.hasRecommendations) ...[
            const Text(
                'Your AI coach has analyzed your fitness profile and workout history to create personalized recommendations.'),
            const SizedBox(height: AppConstants.smallPadding),
            const Text('• Workouts are adapted to your fitness level'),
            const Text(
                '• Exercise selection considers your available equipment'),
            const Text('• Intensity is adjusted based on your recovery status'),
            const Text('• Progressive overload is applied when you\'re ready'),
          ] else ...[
            const Text(
                'Complete more workouts to unlock detailed insights and better recommendations.'),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceInsights(SmartWorkoutProvider provider) {
    final analysis = provider.lastPerformanceAnalysis;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: Styles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Insights', style: Styles.subheadingStyle),
          const SizedBox(height: AppConstants.smallPadding),
          if (analysis != null && analysis.recommendations.isNotEmpty) ...[
            const Text('AI Recommendations:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...analysis.recommendations.map((rec) => Text('• $rec')),
          ] else ...[
            const Text(
                'Complete a workout to get personalized performance insights and recommendations.'),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<SmartWorkoutProvider>(
      builder: (context, provider, child) {
        return FloatingActionButton.extended(
          onPressed: provider.isLoading
              ? null
              : () => provider.refreshRecommendations(),
          backgroundColor: Styles.primaryColor,
          icon: provider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.auto_awesome, color: Colors.white),
          label: Text(
            provider.isLoading ? 'Generating...' : 'New Recommendations',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  void _handleRecommendationTap(
      WorkoutRecommendation recommendation, SmartWorkoutProvider provider) {
    // Convert AI recommendation to WorkoutTemplate for ActiveWorkoutScreen
    final workoutTemplate = _convertRecommendationToTemplate(recommendation);

    // Mark recommendation as used
    provider.markRecommendationAsUsed(recommendation.id);

    // Navigate to active workout screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutScreen(template: workoutTemplate),
      ),
    ).then((completed) {
      if (completed == true) {
        // Workout was completed successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Great job completing ${recommendation.name}!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Progress',
              textColor: Colors.white,
              onPressed: () {
                // Switch to Progress tab
                _tabController.animateTo(1);
              },
            ),
          ),
        );

        // Refresh recommendations after workout completion
        provider.refreshRecommendations();
      }
    });
  }

  void _showAdaptationDialog(
      WorkoutRecommendation recommendation, SmartWorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (context) => WorkoutAdaptationDialog(
        originalWorkout: recommendation,
      ),
    ).then((adaptedWorkout) {
      if (adaptedWorkout != null) {
        // Handle the adapted workout
        _handleRecommendationTap(adaptedWorkout, provider);
      }
    });
  }

  void _navigateToProfileSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FitnessProfileSetupScreen(),
      ),
    );
  }

  void _toggleFavorite(
      WorkoutRecommendation recommendation, SmartWorkoutProvider provider) {
    // TODO: Implement favorites functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favorites feature coming soon!')),
    );
  }

  void _showCreateProgressionPlanDialog(SmartWorkoutProvider provider) {
    // Show dialog to create progression plan
    // This would be a separate dialog widget
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Progression plan creation coming soon!'),
      ),
    );
  }

  /// Convert AI workout recommendation to WorkoutTemplate for ActiveWorkoutScreen
  WorkoutTemplate _convertRecommendationToTemplate(
      WorkoutRecommendation recommendation) {
    final userId = SupabaseService.currentUser?.id ?? '';

    final templateExercises = recommendation.exercises.map((smartExercise) {
      return ExerciseSet(
        exerciseId: smartExercise.exerciseId,
        sets: smartExercise.sets,
        reps: smartExercise.reps,
        weight: smartExercise.weight,
        restTime: smartExercise.restTime,
        notes: smartExercise.notes,
      );
    }).toList();

    return WorkoutTemplate(
      id: const Uuid()
          .v4(), // Generate a proper UUID instead of using recommendation ID
      userId: userId,
      name: recommendation.name,
      description: recommendation.description,
      exercises: templateExercises,
      estimatedDuration: recommendation.estimatedDuration,
      createdAt: recommendation.createdAt,
      updatedAt: recommendation.createdAt,
    );
  }
}
