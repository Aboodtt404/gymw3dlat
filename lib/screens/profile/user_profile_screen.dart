import 'package:flutter/material.dart';
import '../../models/user_profile_model.dart';
import '../../services/supabase_service.dart';
import '../../styles/styles.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _supabase = SupabaseService.client;
  final _formKey = GlobalKey<FormState>();

  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  String _gender = 'male';
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;
  FitnessGoal _goal = FitnessGoal.maintenance;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create default profile if none exists
        final defaultProfile = {
          'user_id': userId,
          'age': 30,
          'weight': 70.0,
          'height': 170.0,
          'gender': 'male',
          'activity_level': 'moderatelyActive',
          'goal': 'maintenance',
          'target_weight': 70.0,
        };

        await _supabase.from('user_profiles').insert(defaultProfile);

        setState(() {
          _ageController.text = '30';
          _weightController.text = '70.0';
          _heightController.text = '170.0';
          _targetWeightController.text = '70.0';
          _gender = 'male';
          _activityLevel = ActivityLevel.moderatelyActive;
          _goal = FitnessGoal.maintenance;
          _isLoading = false;
        });
      } else {
        setState(() {
          _ageController.text = response['age'].toString();
          _weightController.text = response['weight'].toString();
          _heightController.text = response['height'].toString();
          _targetWeightController.text = response['target_weight'].toString();
          _gender = response['gender'];
          _activityLevel = ActivityLevel.values.firstWhere(
            (e) => e.toString().split('.').last == response['activity_level'],
          );
          _goal = FitnessGoal.values.firstWhere(
            (e) => e.toString().split('.').last == response['goal'],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create profile data
      final profileData = {
        'user_id': userId,
        'age': int.parse(_ageController.text),
        'weight': double.parse(_weightController.text),
        'height': double.parse(_heightController.text),
        'gender': _gender,
        'activity_level': _activityLevel.toString().split('.').last,
        'goal': _goal.toString().split('.').last,
        'target_weight': double.parse(_targetWeightController.text),
        'last_updated': DateTime.now().toIso8601String(),
      };

      // Use upsert instead of insert
      await _supabase
          .from('user_profiles')
          .upsert(profileData, onConflict: 'user_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
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
                        onPressed: _loadProfile,
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
                        _buildBasicInfo(),
                        const SizedBox(height: 24),
                        _buildActivityAndGoals(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: Styles.inputDecoration('Age'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your age';
                }
                final age = int.tryParse(value);
                if (age == null || age < 1 || age > 120) {
                  return 'Please enter a valid age';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: Styles.inputDecoration('Weight (kg)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your weight';
                }
                final weight = double.tryParse(value);
                if (weight == null || weight <= 0) {
                  return 'Please enter a valid weight';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heightController,
              decoration: Styles.inputDecoration('Height (cm)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your height';
                }
                final height = double.tryParse(value);
                if (height == null || height <= 0) {
                  return 'Please enter a valid height';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: Styles.inputDecoration('Gender'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _gender = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityAndGoals() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity & Goals',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ActivityLevel>(
              value: _activityLevel,
              decoration: Styles.inputDecoration('Activity Level'),
              items: ActivityLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(_getActivityLevelDescription(level)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _activityLevel = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FitnessGoal>(
              value: _goal,
              decoration: Styles.inputDecoration('Fitness Goal'),
              items: FitnessGoal.values.map((goal) {
                return DropdownMenuItem(
                  value: goal,
                  child: Text(_getGoalDescription(goal)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _goal = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetWeightController,
              decoration: Styles.inputDecoration('Target Weight (kg)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your target weight';
                }
                final weight = double.tryParse(value);
                if (weight == null || weight <= 0) {
                  return 'Please enter a valid target weight';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getActivityLevelDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary (little or no exercise)';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active (light exercise 1-3 days/week)';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active (moderate exercise 3-5 days/week)';
      case ActivityLevel.veryActive:
        return 'Very Active (hard exercise 6-7 days/week)';
      case ActivityLevel.extraActive:
        return 'Extra Active (very hard exercise & physical job)';
    }
  }

  String _getGoalDescription(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.muscleGain:
        return 'Muscle Gain';
    }
  }
}
