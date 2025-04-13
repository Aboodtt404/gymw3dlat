import 'package:flutter/material.dart';
import 'package:gymw3dlat/models/meal_log_model.dart';
import 'package:gymw3dlat/services/meal_log_service.dart';
import 'package:gymw3dlat/utils/styles.dart';
import 'package:gymw3dlat/constants/app_constants.dart';
import 'food_search_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class MealLogScreen extends StatefulWidget {
  const MealLogScreen({super.key});

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  final MealLogService _mealLogService = MealLogService();
  NutritionSummary? _nutritionSummary;
  List<MealLog> _todayMealLogs = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    setState(() => _isLoading = true);

    try {
      final logs = await _mealLogService.getMealLogsByDate(_selectedDate);
      final summary = await _mealLogService.getNutritionSummary(_selectedDate);

      if (mounted) {
        setState(() {
          _todayMealLogs = logs;
          _nutritionSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading meal data: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Styles.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Styles.primaryColor,
              surface: Styles.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadTodayData();
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
                    SliverAppBar(
                      floating: true,
                      backgroundColor: Colors.transparent,
                      title: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDate(_selectedDate),
                              style: Styles.headingStyle,
                            ),
                            const SizedBox(width: AppConstants.smallPadding),
                            const Icon(
                              Icons.calendar_today,
                              color: Styles.primaryColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      centerTitle: true,
                    ),
                    if (_nutritionSummary != null) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(AppConstants.defaultPadding),
                          child: Column(
                            children: [
                              _buildCalorieCard(),
                              const SizedBox(
                                  height: AppConstants.defaultPadding),
                              _buildMacronutrientCard(),
                              const SizedBox(
                                  height: AppConstants.defaultPadding),
                              _buildMealDistributionCard(),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.defaultPadding,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Today\'s Meals',
                            style: Styles.subheadingStyle,
                          ),
                        ),
                      ),
                    ],
                    SliverPadding(
                      padding:
                          const EdgeInsets.all(AppConstants.defaultPadding),
                      sliver: _todayMealLogs.isEmpty
                          ? SliverToBoxAdapter(
                              child: Center(
                                child: Text(
                                  'No meals logged today',
                                  style: Styles.bodyStyle.copyWith(
                                    color: Styles.subtleText,
                                  ),
                                ),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildMealCard(_todayMealLogs[index]),
                                childCount: _todayMealLogs.length,
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FoodSearchScreen()),
          );
          _loadTodayData();
        },
        backgroundColor: Styles.primaryColor,
        child: const Icon(Icons.add, color: Styles.textColor),
      ),
    );
  }

  Widget _buildCalorieCard() {
    final summary = _nutritionSummary!;
    final progress = summary.totalCalories / AppConstants.defaultDailyCalories;
    final remaining = AppConstants.defaultDailyCalories - summary.totalCalories;

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
                    'Calories',
                    style: Styles.subheadingStyle,
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style:
                          Styles.bodyStyle.copyWith(color: Styles.subtleText),
                      children: [
                        TextSpan(
                          text: summary.totalCalories.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Styles.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' / ${AppConstants.defaultDailyCalories.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progress > 1
                      ? Styles.errorColor.withOpacity(0.2)
                      : Styles.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Styles.headingStyle.copyWith(
                    color:
                        progress > 1 ? Styles.errorColor : Styles.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              backgroundColor: Styles.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 1 ? Styles.errorColor : Styles.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
          if (remaining > 0) ...[
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Styles.subtleText,
                ),
                const SizedBox(width: 4),
                Text(
                  '${remaining.toStringAsFixed(0)} calories remaining',
                  style: Styles.bodyStyle.copyWith(
                    color: Styles.subtleText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacronutrientCard() {
    final summary = _nutritionSummary!;
    final List<PieChartSectionData> sections = [
      PieChartSectionData(
        value: summary.proteinPercentage,
        title: '',
        color: Styles.primaryColor,
        radius: 50,
        showTitle: false,
      ),
      PieChartSectionData(
        value: summary.carbsPercentage,
        title: '',
        color: Styles.accentColor,
        radius: 50,
        showTitle: false,
      ),
      PieChartSectionData(
        value: summary.fatPercentage,
        title: '',
        color: Colors.orange,
        radius: 50,
        showTitle: false,
      ),
    ];

    return Container(
      decoration: Styles.cardDecoration,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Macronutrients', style: Styles.subheadingStyle),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${summary.totalCalories.toStringAsFixed(0)}',
                            style: Styles.headingStyle.copyWith(
                              fontSize: 24,
                              color: Styles.primaryColor,
                            ),
                          ),
                          Text(
                            'kcal',
                            style: Styles.bodyStyle.copyWith(
                              color: Styles.subtleText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMacroRow(
                      'Protein',
                      summary.totalProtein,
                      summary.proteinPercentage,
                      Styles.primaryColor,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    _buildMacroRow(
                      'Carbs',
                      summary.totalCarbs,
                      summary.carbsPercentage,
                      Styles.accentColor,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    _buildMacroRow(
                      'Fat',
                      summary.totalFat,
                      summary.fatPercentage,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(
      String label, double grams, double percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Styles.bodyStyle.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${grams.toStringAsFixed(1)}g (${percentage.toStringAsFixed(0)}%)',
                style: Styles.bodyStyle.copyWith(
                  color: Styles.subtleText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealDistributionCard() {
    final summary = _nutritionSummary!;
    final mealTotals = summary.mealTypeTotals;

    return Container(
      decoration: Styles.cardDecoration,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meal Distribution', style: Styles.subheadingStyle),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              _buildMealTypeBar(
                'Breakfast',
                mealTotals[MealType.breakfast] ?? 0,
                Colors.orange,
              ),
              _buildMealTypeBar(
                'Lunch',
                mealTotals[MealType.lunch] ?? 0,
                Styles.primaryColor,
              ),
              _buildMealTypeBar(
                'Dinner',
                mealTotals[MealType.dinner] ?? 0,
                Styles.accentColor,
              ),
              _buildMealTypeBar(
                'Snacks',
                mealTotals[MealType.snack] ?? 0,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeBar(String label, double calories, Color color) {
    final totalCalories = _nutritionSummary?.totalCalories ?? 1;
    final percentage = totalCalories > 0
        ? (calories / totalCalories * 100).clamp(0.0, 100.0)
        : 0.0;

    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 120,
            width: 24,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Styles.cardBackground,
                    borderRadius:
                        BorderRadius.circular(AppConstants.smallBorderRadius),
                  ),
                ),
                FractionallySizedBox(
                  heightFactor: percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.8),
                      borderRadius:
                          BorderRadius.circular(AppConstants.smallBorderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                if (percentage > 0)
                  Positioned(
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: Styles.bodyStyle.copyWith(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            label,
            style: Styles.bodyStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${calories.toStringAsFixed(0)} kcal',
            style: Styles.bodyStyle.copyWith(
              fontSize: 11,
              color: Styles.subtleText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(MealLog mealLog) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      decoration: Styles.cardDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.smallPadding,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Styles.primaryColor.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.smallBorderRadius),
              ),
              child: Text(
                _getMealTypeLabel(mealLog.mealType),
                style: Styles.bodyStyle.copyWith(
                  color: Styles.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: Text(
                mealLog.food.name,
                style: Styles.bodyStyle.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              '${mealLog.servingSize}${mealLog.food.servingUnit}',
              style: Styles.bodyStyle.copyWith(
                color: Styles.subtleText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding / 2),
            Row(
              children: [
                _buildNutrientBadge(
                    '${mealLog.calories.toStringAsFixed(0)} kcal'),
                _buildNutrientBadge(
                    '${mealLog.protein.toStringAsFixed(1)}g protein'),
                _buildNutrientBadge(
                    '${mealLog.carbs.toStringAsFixed(1)}g carbs'),
                _buildNutrientBadge('${mealLog.fat.toStringAsFixed(1)}g fat'),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Styles.errorColor),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Styles.cardBackground,
                title: Text(
                  'Delete Meal',
                  style: Styles.headingStyle.copyWith(fontSize: 20),
                ),
                content: Text(
                  'Are you sure you want to delete this meal?',
                  style: Styles.bodyStyle,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: Styles.textButtonStyle(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Styles.errorColor,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              try {
                await _mealLogService.deleteMealLog(mealLog.id);
                _loadTodayData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting meal: $e'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Styles.errorColor,
                    ),
                  );
                }
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildNutrientBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(right: AppConstants.smallPadding),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Styles.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
      ),
      child: Text(
        text,
        style: Styles.bodyStyle.copyWith(
          color: Styles.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getMealTypeLabel(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
