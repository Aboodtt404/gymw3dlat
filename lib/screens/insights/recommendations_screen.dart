import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/recommendation_service.dart';
import '../../services/food_service.dart';
import '../../services/workout_service.dart';
import '../../providers/user_provider.dart';
import '../../styles/styles.dart';
import '../../models/meal_log_model.dart';
import '../../models/food_model.dart';
import '../../models/nutrition_models.dart';
import '../../models/workout_models.dart' show WorkoutIntensity;
import '../../models/ai_workout_models.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final RecommendationService _recommendationService = RecommendationService();
  final FoodService _foodService = FoodService();
  final WorkoutService _workoutService = WorkoutService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<AIWorkoutRecommendation> _workoutRecommendations = [];
  NutritionRecommendation? _nutritionRecommendations;
  NutritionStatus? _nutritionStatus;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<UserProvider>().userData?['auth_id'];
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get workout recommendations
      final workoutRecs = await _workoutService.getWorkoutRecommendations(
        userId,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Get nutrition recommendations
      final nutritionRecs = await _recommendationService.getUserRecommendations(
        userId,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Get nutrition status
      final nutritionStatus = await _foodService.getNutritionStatus(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _workoutRecommendations = workoutRecs;
        _nutritionRecommendations = nutritionRecs;
        _nutritionStatus = nutritionStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading recommendations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalysisPeriod(),
            const SizedBox(height: 16),
            _buildWorkoutRecommendations(),
            const SizedBox(height: 16),
            _buildNutritionRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisPeriod() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analysis Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.date_range),
                const SizedBox(width: 8),
                Text(
                  '${_startDate.toString().split(' ')[0]} to ${_endDate.toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectDateRange,
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().split('.')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutRecommendations() {
    if (_workoutRecommendations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.fitness_center),
                  SizedBox(width: 8),
                  Text(
                    'Workout Recommendations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'No workout data available for analysis. Try to log some workouts first!',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fitness_center),
                SizedBox(width: 8),
                Text(
                  'Workout Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ..._workoutRecommendations.map((rec) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(rec.description),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: rec.focusAreas
                          .map((area) => Chip(
                                label: Text(area),
                                backgroundColor: Colors.blue[100],
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRecommendations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant),
                SizedBox(width: 8),
                Text(
                  'Nutrition Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (_nutritionRecommendations != null) ...[
              Text(
                _nutritionRecommendations!.message,
                style: const TextStyle(fontSize: 16),
              ),
              if (_nutritionRecommendations!.recommendedFoods.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Recommended Foods:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _nutritionRecommendations!.recommendedFoods
                      .map((food) => Chip(
                            label: Text(food),
                            backgroundColor: Colors.green[100],
                          ))
                      .toList(),
                ),
              ],
            ] else
              const Text(
                'No nutrition data available for analysis. Try logging your meals first!',
                style: TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 16),
            _buildNutritionStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionStatus() {
    if (_nutritionStatus == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrition Status:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildStatusItem('Calories', _nutritionStatus!.caloriesInRange),
        _buildStatusItem('Protein', _nutritionStatus!.proteinInRange),
        _buildStatusItem('Fats', _nutritionStatus!.fatsInRange),
        _buildStatusItem('Carbs', _nutritionStatus!.carbsInRange),
      ],
    );
  }

  Widget _buildStatusItem(String name, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning,
            color: isGood ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }
}
