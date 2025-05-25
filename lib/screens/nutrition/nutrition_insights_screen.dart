import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/nutrition_analytics_service.dart';

class NutritionInsightsScreen extends StatefulWidget {
  const NutritionInsightsScreen({Key? key}) : super(key: key);

  @override
  State<NutritionInsightsScreen> createState() =>
      _NutritionInsightsScreenState();
}

class _NutritionInsightsScreenState extends State<NutritionInsightsScreen> {
  final NutritionAnalyticsService _analyticsService =
      NutritionAnalyticsService();
  int _selectedTimeRange = 7; // Default to week view

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Insights'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (days) {
              setState(() {
                _selectedTimeRange = days;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 7,
                child: Text('Last 7 days'),
              ),
              const PopupMenuItem(
                value: 30,
                child: Text('Last 30 days'),
              ),
              const PopupMenuItem(
                value: 90,
                child: Text('Last 90 days'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalorieChart(),
                const SizedBox(height: 24),
                _buildMacroDistribution(),
                const SizedBox(height: 24),
                _buildFrequentFoods(),
                const SizedBox(height: 24),
                _buildGoalsProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calorie Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<FlSpot>>(
                future: _analyticsService.getCalorieTrends(_selectedTimeRange),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final spots = snapshot.data ?? [];

                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: const FlTitlesData(show: true),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Theme.of(context).primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroDistribution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Macro Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<Map<String, double>>(
                future: _analyticsService.getMacroDistribution(DateTime.now()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final data = snapshot.data ?? {};
                  final total = data.values.fold<double>(0, (a, b) => a + b);

                  return PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Colors.red,
                          value: data['protein'] ?? 0,
                          title:
                              'Protein\n${((data['protein'] ?? 0) / total * 100).toStringAsFixed(1)}%',
                          radius: 80,
                        ),
                        PieChartSectionData(
                          color: Colors.blue,
                          value: data['carbs'] ?? 0,
                          title:
                              'Carbs\n${((data['carbs'] ?? 0) / total * 100).toStringAsFixed(1)}%',
                          radius: 80,
                        ),
                        PieChartSectionData(
                          color: Colors.yellow,
                          value: data['fat'] ?? 0,
                          title:
                              'Fat\n${((data['fat'] ?? 0) / total * 100).toStringAsFixed(1)}%',
                          radius: 80,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequentFoods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Frequent Foods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _analyticsService.getMostFrequentFoods(5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final foods = snapshot.data ?? [];
                return Column(
                  children: foods.map((food) {
                    return ListTile(
                      title: Text(food['food_name']),
                      trailing: Text('${food['count']} times'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Towards Goals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, double>>(
              future: _analyticsService.getGoalsProgress(DateTime.now()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('No Goals have been set yet'));
                }

                final progress = snapshot.data ?? {};
                return Column(
                  children: [
                    _buildProgressBar('Calories', progress['calories'] ?? 0),
                    const SizedBox(height: 8),
                    _buildProgressBar('Protein', progress['protein'] ?? 0),
                    const SizedBox(height: 8),
                    _buildProgressBar('Carbs', progress['carbs'] ?? 0),
                    const SizedBox(height: 8),
                    _buildProgressBar('Fat', progress['fat'] ?? 0),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 10,
        ),
        const SizedBox(height: 4),
        Text('${(progress * 100).toStringAsFixed(1)}%'),
      ],
    );
  }
}
