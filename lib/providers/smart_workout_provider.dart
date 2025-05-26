import 'package:flutter/foundation.dart';
import '../models/ai_workout_models.dart';
import '../models/workout_models.dart';
import '../services/ai/smart_workout_service.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartWorkoutProvider with ChangeNotifier {
  final SmartWorkoutService _smartWorkoutService = SmartWorkoutService();

  // State variables
  List<WorkoutRecommendation> _recommendations = [];
  UserFitnessProfile? _fitnessProfile;
  WorkoutPerformanceAnalysis? _lastPerformanceAnalysis;
  ProgressionPlan? _progressionPlan;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<WorkoutRecommendation> get recommendations => _recommendations;
  UserFitnessProfile? get fitnessProfile => _fitnessProfile;
  WorkoutPerformanceAnalysis? get lastPerformanceAnalysis =>
      _lastPerformanceAnalysis;
  ProgressionPlan? get progressionPlan => _progressionPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasRecommendations => _recommendations.isNotEmpty;
  bool get hasFitnessProfile => _fitnessProfile != null;

  /// Initialize smart workout features for the current user
  Future<void> initializeSmartWorkout() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Load user fitness profile
      await loadFitnessProfile(userId);

      // Load last performance analysis
      final performanceAnalyses =
          await _smartWorkoutService.getPerformanceAnalysis(userId);
      if (performanceAnalyses.isNotEmpty) {
        _lastPerformanceAnalysis = performanceAnalyses.first;
        // Cache the performance score
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('last_performance_score',
            _lastPerformanceAnalysis!.performanceScore);
      } else {
        // Try to load cached performance score
        final prefs = await SharedPreferences.getInstance();
        final cachedScore = prefs.getDouble('last_performance_score');
        if (cachedScore != null) {
          _lastPerformanceAnalysis = WorkoutPerformanceAnalysis(
            workoutLogId: 'cached',
            userId: userId,
            performanceScore: cachedScore,
            recoveryStatus: RecoveryStatus.fullyRecovered,
            exercisePerformance: {},
            strengths: [],
            weaknesses: [],
            recommendations: [],
            analyzedAt: DateTime.now(),
          );
        }
      }

      // Only generate recommendations if profile exists
      if (_fitnessProfile != null) {
        await generateRecommendations(userId);
        // Load progression plan if exists
        await loadProgressionPlan(userId);
      }
    } catch (e) {
      _setError('Failed to initialize smart workout features: $e');
      debugPrint('Error initializing smart workout: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load user fitness profile
  Future<void> loadFitnessProfile(String userId) async {
    try {
      _fitnessProfile =
          await _smartWorkoutService.getUserFitnessProfile(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading fitness profile: $e');
      // Don't rethrow - null profile is expected for new users
      _fitnessProfile = null;
      notifyListeners();
    }
  }

  /// Update user fitness profile
  Future<void> updateFitnessProfile(UserFitnessProfile profile) async {
    _setLoading(true);
    _clearError();

    try {
      await _smartWorkoutService.updateFitnessProfile(profile);
      _fitnessProfile = profile;

      // Regenerate recommendations with updated profile
      await generateRecommendations(profile.userId);
    } catch (e) {
      _setError('Failed to update fitness profile: $e');
      debugPrint('Error updating fitness profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Generate new workout recommendations
  Future<void> generateRecommendations(String userId, {int count = 3}) async {
    _setLoading(true);
    _clearError();

    try {
      _recommendations =
          await _smartWorkoutService.generateWorkoutRecommendations(
        userId: userId,
        count: count,
      );
    } catch (e) {
      _setError('Failed to generate recommendations: $e');
      debugPrint('Error generating recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh recommendations
  Future<void> refreshRecommendations() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    await generateRecommendations(userId);
  }

  /// Analyze workout performance
  Future<void> analyzeWorkoutPerformance(WorkoutLog workoutLog) async {
    _setLoading(true);
    _clearError();

    try {
      _lastPerformanceAnalysis =
          await _smartWorkoutService.analyzeWorkoutPerformance(workoutLog);

      // Update fitness profile based on performance if needed
      if (_fitnessProfile != null) {
        await _updateFitnessLevelBasedOnPerformance(_lastPerformanceAnalysis!);
      }
    } catch (e) {
      _setError('Failed to analyze workout performance: $e');
      debugPrint('Error analyzing workout performance: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a progression plan
  Future<void> createProgressionPlan({
    required String goalType,
    required DateTime targetDate,
    required Map<String, dynamic> targetMetrics,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    _setLoading(true);
    _clearError();

    try {
      _progressionPlan = await _smartWorkoutService.createProgressionPlan(
        userId: userId,
        goalType: goalType,
        targetDate: targetDate,
        targetMetrics: targetMetrics,
      );
    } catch (e) {
      _setError('Failed to create progression plan: $e');
      debugPrint('Error creating progression plan: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load existing progression plan
  Future<void> loadProgressionPlan(String userId) async {
    try {
      _progressionPlan = await _smartWorkoutService.getProgressionPlan(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading progression plan: $e');
    }
  }

  /// Adapt a workout based on current performance
  Future<WorkoutRecommendation?> adaptWorkout({
    required WorkoutRecommendation originalWorkout,
    required Map<String, double> currentPerformance,
    required RecoveryStatus recoveryStatus,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final adaptedWorkout = await _smartWorkoutService.adaptWorkout(
        originalWorkout: originalWorkout,
        currentPerformance: currentPerformance,
        recoveryStatus: recoveryStatus,
      );

      // Add adapted workout to recommendations
      _recommendations.insert(0, adaptedWorkout);
      notifyListeners();

      return adaptedWorkout;
    } catch (e) {
      _setError('Failed to adapt workout: $e');
      debugPrint('Error adapting workout: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get workout recommendation by ID
  WorkoutRecommendation? getRecommendationById(String id) {
    try {
      return _recommendations.firstWhere((rec) => rec.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Remove a recommendation
  void removeRecommendation(String id) {
    _recommendations.removeWhere((rec) => rec.id == id);
    notifyListeners();
  }

  /// Mark a recommendation as used
  void markRecommendationAsUsed(String id) {
    final index = _recommendations.indexWhere((rec) => rec.id == id);
    if (index != -1) {
      // Move used recommendation to the end of the list
      final usedRecommendation = _recommendations.removeAt(index);
      _recommendations.add(usedRecommendation);
      notifyListeners();
    }
  }

  /// Get recommendations by intensity
  List<WorkoutRecommendation> getRecommendationsByIntensity(
      WorkoutIntensity intensity) {
    return _recommendations.where((rec) => rec.intensity == intensity).toList();
  }

  /// Get recommendations by focus area
  List<WorkoutRecommendation> getRecommendationsByFocusArea(String focusArea) {
    return _recommendations
        .where((rec) => rec.focusAreas.contains(focusArea))
        .toList();
  }

  /// Get recommendations by duration
  List<WorkoutRecommendation> getRecommendationsByDuration(
      int minDuration, int maxDuration) {
    return _recommendations
        .where((rec) =>
            rec.estimatedDuration >= minDuration &&
            rec.estimatedDuration <= maxDuration)
        .toList();
  }

  /// Check if user needs fitness profile setup
  bool needsFitnessProfileSetup() {
    return _fitnessProfile == null ||
        _fitnessProfile!.fitnessGoals.isEmpty ||
        _fitnessProfile!.availableEquipment.isEmpty;
  }

  /// Get fitness level progress
  double getFitnessLevelProgress() {
    if (_fitnessProfile == null) return 0.0;

    final levelIndex =
        FitnessLevel.values.indexOf(_fitnessProfile!.fitnessLevel);
    return (levelIndex + 1) / FitnessLevel.values.length;
  }

  /// Get average performance score
  double getAveragePerformanceScore() {
    return _lastPerformanceAnalysis?.performanceScore ?? 0.5;
  }

  /// Get recovery status
  RecoveryStatus getCurrentRecoveryStatus() {
    return _lastPerformanceAnalysis?.recoveryStatus ??
        RecoveryStatus.fullyRecovered;
  }

  /// Check if user is ready for next workout
  bool isReadyForNextWorkout() {
    final recovery = getCurrentRecoveryStatus();
    return recovery == RecoveryStatus.fullyRecovered ||
        recovery == RecoveryStatus.partiallyRecovered;
  }

  /// Get next milestone
  ProgressionMilestone? getNextMilestone() {
    if (_progressionPlan == null) return null;

    try {
      return _progressionPlan!.milestones
          .where((milestone) => !milestone.isCompleted)
          .reduce((a, b) => a.targetDate.isBefore(b.targetDate) ? a : b);
    } catch (e) {
      return null;
    }
  }

  /// Calculate progress towards goal
  double calculateGoalProgress() {
    if (_progressionPlan == null) return 0.0;

    final completedMilestones = _progressionPlan!.milestones
        .where((milestone) => milestone.isCompleted)
        .length;

    return completedMilestones / _progressionPlan!.milestones.length;
  }

  // Private helper methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _updateFitnessLevelBasedOnPerformance(
      WorkoutPerformanceAnalysis analysis) async {
    if (_fitnessProfile == null) return;

    // Simple logic to update fitness level based on consistent high performance
    if (analysis.performanceScore > 0.9) {
      final currentLevelIndex =
          FitnessLevel.values.indexOf(_fitnessProfile!.fitnessLevel);
      if (currentLevelIndex < FitnessLevel.values.length - 1) {
        // Consider upgrading fitness level
        final newLevel = FitnessLevel.values[currentLevelIndex + 1];

        final updatedProfile = UserFitnessProfile(
          userId: _fitnessProfile!.userId,
          fitnessLevel: newLevel,
          fitnessGoals: _fitnessProfile!.fitnessGoals,
          preferredExerciseTypes: _fitnessProfile!.preferredExerciseTypes,
          availableEquipment: _fitnessProfile!.availableEquipment,
          maxWorkoutDuration: _fitnessProfile!.maxWorkoutDuration,
          injuries: _fitnessProfile!.injuries,
          strengthLevels: _fitnessProfile!.strengthLevels,
          cardioEndurance: _fitnessProfile!.cardioEndurance,
          lastUpdated: DateTime.now(),
        );

        await updateFitnessProfile(updatedProfile);
      }
    }
  }

  /// Clear all data (useful for logout)
  void clearData() {
    _recommendations.clear();
    _fitnessProfile = null;
    _lastPerformanceAnalysis = null;
    _progressionPlan = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Clear fitness profile from database (for testing)
  Future<void> clearFitnessProfileFromDatabase() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      await _smartWorkoutService.deleteFitnessProfile(userId);
      _fitnessProfile = null;
      _recommendations.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing fitness profile: $e');
    }
  }

  /// Get workout statistics
  Map<String, dynamic> getWorkoutStatistics() {
    if (_recommendations.isEmpty) {
      return {
        'total_recommendations': 0,
        'average_difficulty': 0.0,
        'average_duration': 0,
        'most_common_intensity': 'None',
        'focus_areas': <String>[],
      };
    }

    final totalRecommendations = _recommendations.length;
    final averageDifficulty = _recommendations
            .map((rec) => rec.difficultyScore)
            .reduce((a, b) => a + b) /
        totalRecommendations;

    final averageDuration = _recommendations
            .map((rec) => rec.estimatedDuration)
            .reduce((a, b) => a + b) ~/
        totalRecommendations;

    // Find most common intensity
    final intensityCount = <WorkoutIntensity, int>{};
    for (final rec in _recommendations) {
      intensityCount[rec.intensity] = (intensityCount[rec.intensity] ?? 0) + 1;
    }

    final mostCommonIntensity = intensityCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key
        .toString()
        .split('.')
        .last;

    // Get all focus areas
    final allFocusAreas = <String>{};
    for (final rec in _recommendations) {
      allFocusAreas.addAll(rec.focusAreas);
    }

    return {
      'total_recommendations': totalRecommendations,
      'average_difficulty': averageDifficulty,
      'average_duration': averageDuration,
      'most_common_intensity': mostCommonIntensity,
      'focus_areas': allFocusAreas.toList(),
    };
  }
}
