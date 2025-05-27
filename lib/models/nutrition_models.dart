class NutritionStatus {
  final bool caloriesInRange;
  final bool proteinInRange;
  final bool fatsInRange;
  final bool carbsInRange;
  final double caloriesPercentage;
  final double proteinPercentage;
  final double fatsPercentage;
  final double carbsPercentage;

  NutritionStatus({
    this.caloriesInRange = false,
    this.proteinInRange = false,
    this.fatsInRange = false,
    this.carbsInRange = false,
    this.caloriesPercentage = 0,
    this.proteinPercentage = 0,
    this.fatsPercentage = 0,
    this.carbsPercentage = 0,
  });
}

class NutritionRecommendation {
  final String message;
  final List<String> recommendedFoods;
  final bool calorieDeficit;
  final bool proteinDeficit;
  final bool fatDeficit;
  final bool carbDeficit;

  NutritionRecommendation({
    required this.message,
    required this.recommendedFoods,
    required this.calorieDeficit,
    required this.proteinDeficit,
    required this.fatDeficit,
    required this.carbDeficit,
  });
}
