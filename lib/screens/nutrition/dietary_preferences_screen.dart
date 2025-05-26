import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../styles/styles.dart';

class DietaryPreferencesScreen extends StatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  State<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen> {
  final _supabase = SupabaseService.client;
  final _formKey = GlobalKey<FormState>();

  bool _isVegetarian = false;
  bool _isVegan = false;
  bool _isGlutenFree = false;
  List<String> _preferredFoods = [];
  List<String> _dislikedFoods = [];
  List<String> _allergies = [];
  bool _isLoading = true;
  String? _error;

  final _preferredFoodController = TextEditingController();
  final _dislikedFoodController = TextEditingController();
  final _allergyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _preferredFoodController.dispose();
    _dislikedFoodController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('user_dietary_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create default preferences if none exist
        final defaultPrefs = {
          'user_id': userId,
          'is_vegetarian': false,
          'is_vegan': false,
          'is_gluten_free': false,
          'preferred_foods': [],
          'disliked_foods': [],
          'allergies': [],
        };

        await _supabase.from('user_dietary_preferences').insert(defaultPrefs);

        setState(() {
          _isVegetarian = false;
          _isVegan = false;
          _isGlutenFree = false;
          _preferredFoods = [];
          _dislikedFoods = [];
          _allergies = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isVegetarian = response['is_vegetarian'] ?? false;
          _isVegan = response['is_vegan'] ?? false;
          _isGlutenFree = response['is_gluten_free'] ?? false;
          _preferredFoods =
              List<String>.from(response['preferred_foods'] ?? []);
          _dislikedFoods = List<String>.from(response['disliked_foods'] ?? []);
          _allergies = List<String>.from(response['allergies'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load preferences: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create preferences data
      final preferencesData = {
        'user_id': userId,
        'is_vegetarian': _isVegetarian,
        'is_vegan': _isVegan,
        'is_gluten_free': _isGlutenFree,
        'preferred_foods': _preferredFoods,
        'disliked_foods': _dislikedFoods,
        'allergies': _allergies,
      };

      // Use upsert instead of insert
      await _supabase
          .from('user_dietary_preferences')
          .upsert(preferencesData, onConflict: 'user_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addPreferredFood() {
    final food = _preferredFoodController.text.trim();
    if (food.isNotEmpty && !_preferredFoods.contains(food)) {
      setState(() {
        _preferredFoods.add(food);
        _preferredFoodController.clear();
      });
    }
  }

  void _addDislikedFood() {
    final food = _dislikedFoodController.text.trim();
    if (food.isNotEmpty && !_dislikedFoods.contains(food)) {
      setState(() {
        _dislikedFoods.add(food);
        _dislikedFoodController.clear();
      });
    }
  }

  void _addAllergy() {
    final allergy = _allergyController.text.trim();
    if (allergy.isNotEmpty && !_allergies.contains(allergy)) {
      setState(() {
        _allergies.add(allergy);
        _allergyController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietary Preferences'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePreferences,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPreferences,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDietaryRestrictions(),
                        const SizedBox(height: 24),
                        _buildPreferredFoods(),
                        const SizedBox(height: 24),
                        _buildDislikedFoods(),
                        const SizedBox(height: 24),
                        _buildAllergies(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDietaryRestrictions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dietary Restrictions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Vegetarian'),
              value: _isVegetarian,
              onChanged: (value) => setState(() => _isVegetarian = value),
            ),
            SwitchListTile(
              title: const Text('Vegan'),
              value: _isVegan,
              onChanged: (value) => setState(() => _isVegan = value),
            ),
            SwitchListTile(
              title: const Text('Gluten Free'),
              value: _isGlutenFree,
              onChanged: (value) => setState(() => _isGlutenFree = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferredFoods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferred Foods',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _preferredFoodController,
                    decoration: Styles.inputDecoration('Add food')
                        .copyWith(hintText: 'e.g., Chicken, Rice, etc.'),
                    onFieldSubmitted: (_) => _addPreferredFood(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addPreferredFood,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _preferredFoods.map((food) {
                return Chip(
                  label: Text(food),
                  onDeleted: () {
                    setState(() => _preferredFoods.remove(food));
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDislikedFoods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disliked Foods',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dislikedFoodController,
                    decoration: Styles.inputDecoration('Add food')
                        .copyWith(hintText: 'e.g., Mushrooms, Olives, etc.'),
                    onFieldSubmitted: (_) => _addDislikedFood(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addDislikedFood,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _dislikedFoods.map((food) {
                return Chip(
                  label: Text(food),
                  onDeleted: () {
                    setState(() => _dislikedFoods.remove(food));
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergies() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allergies',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _allergyController,
                    decoration: Styles.inputDecoration('Add allergy')
                        .copyWith(hintText: 'e.g., Peanuts, Shellfish, etc.'),
                    onFieldSubmitted: (_) => _addAllergy(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addAllergy,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _allergies.map((allergy) {
                return Chip(
                  label: Text(allergy),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  onDeleted: () {
                    setState(() => _allergies.remove(allergy));
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
