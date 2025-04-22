import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_template_model.dart';
import '../../services/exercise_service.dart';
import '../../services/workout_template_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/styles.dart';
import 'workout_templates_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final WorkoutTemplateService _templateService = WorkoutTemplateService();
  List<Exercise> _exercises = [];
  List<WorkoutExercise> _selectedExercises = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _selectedValue = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      List<Exercise> exercises;
      switch (_selectedFilter) {
        case 'bodyPart':
          exercises =
              await _exerciseService.getExercisesByBodyPart(_selectedValue);
          break;
        case 'target':
          exercises =
              await _exerciseService.getExercisesByTarget(_selectedValue);
          break;
        case 'equipment':
          exercises =
              await _exerciseService.getExercisesByEquipment(_selectedValue);
          break;
        default:
          exercises = await _exerciseService.getAllExercises();
      }
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exercises: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Filter Exercises',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterTile('All Exercises', 'all', null),
            _buildFilterTile('By Body Part', 'bodyPart', [
              'back',
              'cardio',
              'chest',
              'lower arms',
              'lower legs',
              'neck',
              'shoulders',
              'upper arms',
              'upper legs',
              'waist'
            ]),
            _buildFilterTile('By Target Muscle', 'target', [
              'abs',
              'biceps',
              'calves',
              'cardiovascular system',
              'delts',
              'forearms',
              'glutes',
              'hamstrings',
              'lats',
              'pectorals',
              'quads',
              'traps',
              'triceps'
            ]),
            _buildFilterTile('By Equipment', 'equipment', [
              'body weight',
              'cable',
              'dumbbell',
              'barbell',
              'kettlebell',
              'leverage machine',
              'resistance band',
              'stability ball',
              'smith machine'
            ]),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFilterTile(String title, String filter, List<String>? options) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: _selectedFilter == filter ? Styles.primaryColor : null,
          fontWeight: _selectedFilter == filter ? FontWeight.bold : null,
        ),
      ),
      selected: _selectedFilter == filter,
      onTap: () {
        if (options == null) {
          setState(() {
            _selectedFilter = filter;
            _selectedValue = '';
          });
          Navigator.pop(context);
          _loadExercises();
        } else {
          _showSecondaryFilterDialog(filter, options);
        }
      },
      trailing: options != null ? const Icon(Icons.chevron_right) : null,
    );
  }

  void _showSecondaryFilterDialog(String filter, List<String> options) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select ${filter == 'bodyPart' ? 'Body Part' : filter == 'target' ? 'Target Muscle' : 'Equipment'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((option) => ListTile(
                      title: Text(
                        _capitalizeWords(option),
                        style: TextStyle(
                          color: _selectedValue == option
                              ? Styles.primaryColor
                              : null,
                          fontWeight:
                              _selectedValue == option ? FontWeight.bold : null,
                        ),
                      ),
                      selected: _selectedValue == option,
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                          _selectedValue = option;
                        });
                        Navigator.pop(context);
                        _loadExercises();
                      },
                    ))
                .toList(),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exercise Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkoutTemplatesScreen(),
                ),
              );
            },
            tooltip: 'View Templates',
          ),
          if (_selectedExercises.isNotEmpty)
            Badge(
              label: Text(_selectedExercises.length.toString()),
              child: IconButton(
                icon: const Icon(Icons.fitness_center),
                onPressed: _showCreateTemplateDialog,
                tooltip: 'Create workout template',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter exercises',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search exercises',
                hintText: 'Search by name, target muscle, or body part',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                setState(() {
                  if (value.isEmpty) {
                    _loadExercises();
                  } else {
                    _exercises = _exercises
                        .where((exercise) =>
                            exercise.name
                                .toLowerCase()
                                .contains(value.toLowerCase()) ||
                            exercise.target
                                .toLowerCase()
                                .contains(value.toLowerCase()) ||
                            exercise.bodyPart
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                        .toList();
                  }
                });
              },
            ),
          ),
          if (_selectedFilter != 'all' && _selectedValue.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Chip(
                label: Text(
                  '${_selectedFilter == 'bodyPart' ? 'Body Part' : _selectedFilter == 'target' ? 'Target' : 'Equipment'}: ${_capitalizeWords(_selectedValue)}',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Styles.primaryColor,
                onDeleted: () {
                  setState(() {
                    _selectedFilter = 'all';
                    _selectedValue = '';
                  });
                  _loadExercises();
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _exercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No exercises found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _exercises.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final exercise = _exercises[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                _capitalizeWords(exercise.name),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  _buildInfoRow(Icons.track_changes, 'Target',
                                      exercise.target),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(Icons.accessibility_new,
                                      'Body Part', exercise.bodyPart),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(Icons.fitness_center,
                                      'Equipment', exercise.equipment),
                                ],
                              ),
                              onTap: () => _showExerciseDetails(exercise),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            _capitalizeWords(value),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showExerciseDetails(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    exercise.gifUrl,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 300,
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isExerciseSelected(exercise)
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color: Colors.white,
                        ),
                        onPressed: () => _toggleExerciseSelection(exercise),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalizeWords(exercise.name),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Instructions:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...exercise.instructions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Styles.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isExerciseSelected(Exercise exercise) {
    return _selectedExercises.any((e) => e.exerciseId == exercise.id);
  }

  void _toggleExerciseSelection(Exercise exercise) {
    setState(() {
      if (_isExerciseSelected(exercise)) {
        _selectedExercises.removeWhere((e) => e.exerciseId == exercise.id);
      } else {
        _showAddExerciseDialog(exercise);
      }
    });
  }

  void _showAddExerciseDialog(Exercise exercise) {
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '12');
    final weightController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${_capitalizeWords(exercise.name)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sets',
                  hintText: 'Enter number of sets',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  hintText: 'Enter number of reps',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (optional)',
                  hintText: 'Enter weight in kg',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any notes for this exercise',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final sets = int.tryParse(setsController.text) ?? 3;
              final reps = int.tryParse(repsController.text) ?? 12;
              final weight = double.tryParse(weightController.text);
              final notes =
                  notesController.text.isEmpty ? null : notesController.text;

              setState(() {
                _selectedExercises.add(
                  WorkoutExercise(
                    exerciseId: exercise.id,
                    name: exercise.name,
                    bodyPart: exercise.bodyPart,
                    equipment: exercise.equipment,
                    target: exercise.target,
                    gifUrl: exercise.gifUrl,
                    sets: sets,
                    reps: reps,
                    weight: weight,
                    notes: notes,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showCreateTemplateDialog() {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one exercise first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Workout Template'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name',
                  hintText: 'Enter a name for your workout template',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter a description for your workout template',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selected Exercises:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                _selectedExercises.length,
                (index) => ListTile(
                  title: Text(_capitalizeWords(_selectedExercises[index].name)),
                  subtitle: Text(
                    '${_selectedExercises[index].sets} sets x ${_selectedExercises[index].reps} reps'
                    '${_selectedExercises[index].weight != null ? ' @ ${_selectedExercises[index].weight}kg' : ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      setState(() {
                        _selectedExercises.removeAt(index);
                      });
                      if (_selectedExercises.isEmpty) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a template name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final template = WorkoutTemplate(
                id: Uuid().v4(),
                userId: SupabaseService.currentUser!.id,
                name: nameController.text,
                description: descriptionController.text,
                exercises: List.from(_selectedExercises),
                createdAt: DateTime.now(),
              );

              try {
                await _templateService.createTemplate(template);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _selectedExercises.clear());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout template created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating template: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
