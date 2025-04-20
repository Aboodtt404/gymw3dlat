import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/water_service.dart';
import '../../services/food_service.dart';
import '../../utils/styles.dart';
import '../../constants/app_constants.dart';
import '../auth/login_screen.dart';
import '../workout/active_workout_screen.dart';
import '../nutrition/nutrition_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final _waterService = WaterService();
  final _foodService = FoodService();
  double _waterAmount = 0;
  Map<String, double> _nutritionTotals = {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fat': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        SupabaseService().getCurrentUser(),
        _waterService.getTodayWaterAmount(),
        _foodService.getMealsByType(),
      ]);

      final userData = futures[0] as Map<String, dynamic>;
      final waterAmount = futures[1] as double;
      final meals = futures[2] as Map<dynamic, List<dynamic>>;

      // Calculate nutrition totals
      double calories = 0;
      double protein = 0;
      double carbs = 0;
      double fat = 0;

      for (var foods in meals.values) {
        for (var food in foods) {
          calories += food.calories;
          protein += food.protein;
          carbs += food.carbs;
          fat += food.fat;
        }
      }

      if (mounted) {
        setState(() {
          _userData = userData;
          _waterAmount = waterAmount;
          _nutritionTotals = {
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Styles.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _logWater() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Water Intake'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.water_drop),
                title: const Text('250ml'),
                onTap: () => Navigator.of(context).pop(0.25),
              ),
              ListTile(
                leading: const Icon(Icons.water_drop),
                title: const Text('500ml'),
                onTap: () => Navigator.of(context).pop(0.5),
              ),
              ListTile(
                leading: const Icon(Icons.water_drop),
                title: const Text('1000ml'),
                onTap: () => Navigator.of(context).pop(1.0),
              ),
            ],
          ),
        );
      },
    );

    if (amount != null) {
      try {
        await _waterService.logWater(amount);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logged ${amount * 1000}ml of water'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to log water: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Styles.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: Styles.backgroundGradient),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Styles.primaryColor),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeCard(),
                            const SizedBox(height: AppConstants.defaultPadding),
                            _buildDailySummaryCard(),
                            const SizedBox(height: AppConstants.defaultPadding),
                            Text(
                              'Quick Actions',
                              style: Styles.subheadingStyle,
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            _buildQuickActionsGrid(),
                            const SizedBox(height: AppConstants.defaultPadding),
                            Text(
                              'Your Progress',
                              style: Styles.subheadingStyle,
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            _buildProgressCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final greeting = _getGreeting();
    return Container(
      decoration: Styles.cardDecoration,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Styles.bodyStyle.copyWith(color: Styles.subtleText),
                ),
                const SizedBox(height: AppConstants.smallPadding / 2),
                Text(
                  _userData?['name'] ?? 'Athlete',
                  style: Styles.headingStyle,
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Styles.primaryColor.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.person,
              color: Styles.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard() {
    return Container(
      decoration: Styles.cardDecoration,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Summary',
            style: Styles.subheadingStyle,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                icon: Icons.local_fire_department,
                value: _nutritionTotals['calories']!.round().toString(),
                label: 'Calories',
                color: Colors.orange,
              ),
              _buildSummaryItem(
                icon: Icons.restaurant_menu,
                value: _nutritionTotals['protein']!.round().toString(),
                label: 'Protein (g)',
                color: Styles.primaryColor,
              ),
              _buildSummaryItem(
                icon: Icons.water_drop,
                value: (_waterAmount * 1000).round().toString(),
                label: 'Water (ml)',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppConstants.smallPadding,
      crossAxisSpacing: AppConstants.smallPadding,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          icon: Icons.add_circle_outline,
          title: 'Log Food',
          color: Styles.primaryColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NutritionScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          icon: Icons.fitness_center,
          title: 'Start Workout',
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActiveWorkoutScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          icon: Icons.water_drop_outlined,
          title: 'Log Water',
          color: Colors.blue,
          onTap: _logWater,
        ),
        _buildActionCard(
          icon: Icons.insights_outlined,
          title: 'View Stats',
          color: Colors.purple,
          onTap: () {
            // TODO: Implement stats screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Stats screen coming soon!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final targetCalories = 2000.0; // TODO: Make configurable
    final progress = _nutritionTotals['calories']! / targetCalories;

    return Container(
      decoration: Styles.cardDecoration,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Goal',
                    style: Styles.subheadingStyle,
                  ),
                  Text(
                    '${_nutritionTotals['calories']!.round()} / ${targetCalories.round()} kcal',
                    style: Styles.bodyStyle.copyWith(color: Styles.subtleText),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Styles.headingStyle.copyWith(
                  color: Styles.primaryColor,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Styles.cardBackground,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Styles.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          value,
          style: Styles.headingStyle.copyWith(fontSize: 20),
        ),
        Text(
          label,
          style: Styles.bodyStyle.copyWith(
            color: Styles.subtleText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: Styles.cardDecoration,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              title,
              style: Styles.bodyStyle.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}
