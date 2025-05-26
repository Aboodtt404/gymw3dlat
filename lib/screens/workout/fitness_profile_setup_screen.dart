import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ai_workout_models.dart';
import '../../models/workout_models.dart';
import '../../providers/smart_workout_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/styles.dart';
import '../../constants/app_constants.dart';

class FitnessProfileSetupScreen extends StatefulWidget {
  const FitnessProfileSetupScreen({super.key});

  @override
  State<FitnessProfileSetupScreen> createState() =>
      _FitnessProfileSetupScreenState();
}

class _FitnessProfileSetupScreenState extends State<FitnessProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

  // Form data
  FitnessLevel _selectedFitnessLevel = FitnessLevel.beginner;
  List<String> _selectedGoals = [];
  List<String> _selectedExerciseTypes = [];
  List<String> _selectedEquipment = [];
  int _maxWorkoutDuration = 60;
  List<String> _selectedInjuries = [];
  Map<ExerciseCategory, double> _strengthLevels = {};
  double _cardioEndurance = 3.0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeStrengthLevels();
  }

  void _initializeStrengthLevels() {
    for (final category in ExerciseCategory.values) {
      _strengthLevels[category] = AppConstants.defaultStrengthLevel;
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
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildFitnessLevelPage(),
                    _buildGoalsPage(),
                    _buildExerciseTypesPage(),
                    _buildEquipmentPage(),
                    _buildDurationAndInjuriesPage(),
                    _buildStrengthLevelsPage(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Fitness Profile Setup',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalPages, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < _totalPages - 1 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: index <= _currentPage
                        ? Styles.primaryColor
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Step ${_currentPage + 1} of $_totalPages',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessLevelPage() {
    return _buildPageContainer(
      title: 'What\'s your fitness level?',
      subtitle:
          'This helps us create workouts that match your current abilities.',
      child: Column(
        children: FitnessLevel.values.map((level) {
          return _buildSelectionCard(
            title: level.toString().split('.').last.toUpperCase(),
            subtitle: _getFitnessLevelDescription(level),
            isSelected: _selectedFitnessLevel == level,
            onTap: () => setState(() => _selectedFitnessLevel = level),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoalsPage() {
    return _buildPageContainer(
      title: 'What are your fitness goals?',
      subtitle:
          'Select all that apply. We\'ll tailor your workouts accordingly.',
      child: Wrap(
        spacing: AppConstants.smallPadding,
        runSpacing: AppConstants.smallPadding,
        children: AppConstants.fitnessGoals.map((goal) {
          final isSelected = _selectedGoals.contains(goal);
          return _buildChip(
            label: goal,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedGoals.remove(goal);
                } else {
                  _selectedGoals.add(goal);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExerciseTypesPage() {
    return _buildPageContainer(
      title: 'What types of exercise do you prefer?',
      subtitle: 'We\'ll focus on the exercise styles you enjoy most.',
      child: Wrap(
        spacing: AppConstants.smallPadding,
        runSpacing: AppConstants.smallPadding,
        children: AppConstants.exerciseTypes.map((type) {
          final isSelected = _selectedExerciseTypes.contains(type);
          return _buildChip(
            label: type,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedExerciseTypes.remove(type);
                } else {
                  _selectedExerciseTypes.add(type);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEquipmentPage() {
    return _buildPageContainer(
      title: 'What equipment do you have access to?',
      subtitle: 'We\'ll only suggest exercises you can actually do.',
      child: Wrap(
        spacing: AppConstants.smallPadding,
        runSpacing: AppConstants.smallPadding,
        children: AppConstants.availableEquipment.map((equipment) {
          final isSelected = _selectedEquipment.contains(equipment);
          return _buildChip(
            label: equipment,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedEquipment.remove(equipment);
                } else {
                  _selectedEquipment.add(equipment);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDurationAndInjuriesPage() {
    return _buildPageContainer(
      title: 'Workout preferences & limitations',
      subtitle: 'Help us create safe and suitable workouts for you.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Maximum workout duration:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Slider(
            value: _maxWorkoutDuration.toDouble(),
            min: 15,
            max: 180,
            divisions: 11,
            label: '$_maxWorkoutDuration minutes',
            activeColor: Styles.primaryColor,
            inactiveColor: Colors.white.withOpacity(0.3),
            onChanged: (value) {
              setState(() => _maxWorkoutDuration = value.round());
            },
          ),
          Text(
            '$_maxWorkoutDuration minutes',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          const Text(
            'Any current injuries or limitations?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Wrap(
            spacing: AppConstants.smallPadding,
            runSpacing: AppConstants.smallPadding,
            children: AppConstants.commonInjuries.map((injury) {
              final isSelected = _selectedInjuries.contains(injury);
              return _buildChip(
                label: injury,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInjuries.remove(injury);
                    } else {
                      _selectedInjuries.add(injury);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthLevelsPage() {
    return _buildPageContainer(
      title: 'Rate your current strength levels',
      subtitle: 'This helps us set appropriate weights and progressions.',
      child: Column(
        children: [
          ...ExerciseCategory.values.map((category) {
            return _buildStrengthSlider(category);
          }).toList(),
          const SizedBox(height: AppConstants.defaultPadding),
          const Text(
            'Cardio Endurance:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: _cardioEndurance,
            min: 1,
            max: 10,
            divisions: 9,
            label: _cardioEndurance.toStringAsFixed(1),
            activeColor: Styles.primaryColor,
            inactiveColor: Colors.white.withOpacity(0.3),
            onChanged: (value) {
              setState(() => _cardioEndurance = value);
            },
          ),
          Text(
            '${_cardioEndurance.toStringAsFixed(1)}/10',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthSlider(ExerciseCategory category) {
    final categoryName = category.toString().split('.').last.toUpperCase();
    final value =
        _strengthLevels[category] ?? AppConstants.defaultStrengthLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Styles.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)}/10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Styles.primaryColor,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: Colors.white,
              overlayColor: Styles.primaryColor.withOpacity(0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 16,
              ),
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (newValue) {
                setState(() => _strengthLevels[category] = newValue);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          child,
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              gradient: isSelected ? Styles.sportGradient : Styles.cardGradient,
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Styles.primaryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: isSelected ? 15 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: AppConstants.defaultIconSize,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: AppConstants.smallPadding,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? Styles.sportGradient : Styles.cardGradient,
            borderRadius:
                BorderRadius.circular(AppConstants.defaultBorderRadius),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Styles.primaryColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.2),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0.5,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousPage,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.defaultPadding),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          if (_currentPage > 0)
            const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.primaryColor,
                padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.defaultPadding),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentPage == _totalPages - 1
                          ? 'Complete Setup'
                          : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppConstants.defaultAnimation,
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      if (_validateCurrentPage()) {
        _pageController.nextPage(
          duration: AppConstants.defaultAnimation,
          curve: Curves.easeInOut,
        );
      }
    } else {
      _completeSetup();
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 1: // Goals page
        if (_selectedGoals.isEmpty) {
          _showValidationError('Please select at least one fitness goal.');
          return false;
        }
        break;
      case 2: // Exercise types page
        if (_selectedExerciseTypes.isEmpty) {
          _showValidationError('Please select at least one exercise type.');
          return false;
        }
        break;
      case 3: // Equipment page
        if (_selectedEquipment.isEmpty) {
          _showValidationError('Please select at least one equipment option.');
          return false;
        }
        break;
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final profile = UserFitnessProfile(
        userId: userId,
        fitnessLevel: _selectedFitnessLevel,
        fitnessGoals: _selectedGoals,
        preferredExerciseTypes: _selectedExerciseTypes,
        availableEquipment: _selectedEquipment,
        maxWorkoutDuration: _maxWorkoutDuration,
        injuries: _selectedInjuries,
        strengthLevels: _strengthLevels,
        cardioEndurance: _cardioEndurance,
        lastUpdated: DateTime.now(),
      );

      await context.read<SmartWorkoutProvider>().updateFitnessProfile(profile);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.profileUpdatedMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getFitnessLevelDescription(FitnessLevel level) {
    switch (level) {
      case FitnessLevel.beginner:
        return 'New to exercise or returning after a long break';
      case FitnessLevel.intermediate:
        return 'Regular exercise routine for 6+ months';
      case FitnessLevel.advanced:
        return 'Consistent training for 2+ years with good form';
      case FitnessLevel.expert:
        return 'Highly experienced with advanced training techniques';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
