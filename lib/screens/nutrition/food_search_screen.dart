import 'package:flutter/material.dart';
import '../../models/food_model.dart';
import '../../services/food_service.dart';
import '../../utils/styles.dart';
import '../../constants/app_constants.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final FoodService _foodService = FoodService();
  final TextEditingController _searchController = TextEditingController();
  List<Food> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _foodService.searchFoods(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching foods: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Styles.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: Styles.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Styles.primaryColor,
                          ),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? _buildEmptyState()
                        : _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Styles.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Styles.textColor),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: Text(
                  'Search Foods',
                  style: Styles.headingStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for foods...',
              hintStyle: TextStyle(color: Styles.subtleText.withOpacity(0.7)),
              prefixIcon: const Icon(Icons.search, color: Styles.subtleText),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Styles.darkBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
            ),
            style: Styles.bodyStyle,
            onChanged: _searchFoods,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty ? Icons.search : Icons.no_food,
            size: 64,
            color: Styles.subtleText.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            _searchController.text.isEmpty
                ? 'Start typing to search for foods'
                : 'No foods found',
            style: Styles.subheadingStyle.copyWith(
              color: Styles.subtleText.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
          decoration: Styles.cardDecoration,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
            title: Text(
              food.name,
              style: Styles.bodyStyle.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppConstants.smallPadding / 2),
                Text(
                  '${food.servingSize}${food.servingUnit}',
                  style: Styles.bodyStyle.copyWith(
                    color: Styles.subtleText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding / 2),
                Row(
                  children: [
                    _buildNutrientBadge('${food.calories.round()} kcal'),
                    _buildNutrientBadge('${food.protein}g protein'),
                    _buildNutrientBadge('${food.carbs}g carbs'),
                    _buildNutrientBadge('${food.fat}g fat'),
                  ],
                ),
              ],
            ),
            onTap: () async {
              try {
                await _foodService.addFood(food);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Food added successfully'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Styles.successColor,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding food: $e'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Styles.errorColor,
                    ),
                  );
                }
              }
            },
          ),
        );
      },
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
}
