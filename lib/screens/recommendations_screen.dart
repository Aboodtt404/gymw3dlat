import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymw3dlat/services/recommendation_service.dart';
import 'package:gymw3dlat/providers/user_provider.dart';
import 'package:gymw3dlat/utils/styles.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final RecommendationService _recommendationService = RecommendationService();
  UserRecommendation? _recommendations;
  bool _isLoading = true;
  String? _error;

  // Date range for analysis
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = context.read<UserProvider>().userData;
      if (userData == null) {
        setState(() {
          _isLoading = false;
          _error = 'You need to be logged in to view recommendations';
        });
        return;
      }

      final userId = userData['auth_id'];
      final recommendations =
          await _recommendationService.getUserRecommendations(
        userId,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading recommendations: $e';
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Styles.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
            tooltip: 'Refresh Recommendations',
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

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadRecommendations,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendations == null) {
      return const Center(
        child: Text('No recommendations available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeCard(),
            const SizedBox(height: 16),
            _buildWorkoutRecommendations(),
            const SizedBox(height: 16),
            _buildNutritionRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analysis Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.date_range, color: Styles.primaryColor),
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
              'Last updated: ${_recommendations!.generatedDate.toString().split('.')[0]}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutRecommendations() {
    final workoutRecs = _recommendations!.workoutRecommendations;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fitness_center, color: Styles.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Workout Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              workoutRecs.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (workoutRecs.neglectedBodyParts.isNotEmpty) ...[
              const Text(
                'Body parts you\'ve been neglecting:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: workoutRecs.neglectedBodyParts
                    .map((part) => Chip(
                          label: Text(_capitalizeString(part)),
                          backgroundColor: Colors.red[100],
                          labelStyle: TextStyle(color: Colors.red[900]),
                        ))
                    .toList(),
              ),
            ],
            if (workoutRecs.overtrainedBodyParts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Body parts you might be overtraining:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: workoutRecs.overtrainedBodyParts
                    .map((part) => Chip(
                          label: Text(_capitalizeString(part)),
                          backgroundColor: Colors.amber[100],
                          labelStyle: TextStyle(color: Colors.amber[900]),
                        ))
                    .toList(),
              ),
            ],
            if (workoutRecs.recommendedExercises.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recommended exercises to try:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workoutRecs.recommendedExercises.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: Text(workoutRecs.recommendedExercises[index]),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRecommendations() {
    final nutritionRecs = _recommendations!.nutritionRecommendations;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant, color: Styles.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Nutrition Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              nutritionRecs.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (nutritionRecs.recommendedFoods.isNotEmpty) ...[
              const Text(
                'Recommended foods to include:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: nutritionRecs.recommendedFoods
                    .map((food) => Chip(
                          label: Text(food),
                          backgroundColor: Colors.green[100],
                          labelStyle: TextStyle(color: Colors.green[900]),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Nutrition Status:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildNutritionStatusTile(
              'Calories',
              !nutritionRecs.calorieDeficit,
              Icons.local_fire_department,
            ),
            _buildNutritionStatusTile(
              'Protein',
              !nutritionRecs.proteinDeficit,
              Icons.egg_alt,
            ),
            _buildNutritionStatusTile(
              'Fats',
              !nutritionRecs.fatDeficit,
              Icons.oil_barrel,
            ),
            _buildNutritionStatusTile(
              'Carbs',
              !nutritionRecs.carbDeficit,
              Icons.breakfast_dining,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionStatusTile(String title, bool isGood, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isGood ? Colors.green : Colors.red,
      ),
      title: Text(title),
      trailing: Icon(
        isGood ? Icons.check_circle : Icons.warning,
        color: isGood ? Colors.green : Colors.red,
      ),
    );
  }

  String _capitalizeString(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
