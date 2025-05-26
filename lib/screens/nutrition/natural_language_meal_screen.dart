import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../models/food_model.dart';
import '../../models/meal_log_model.dart';
import '../../services/natural_language_meal_service.dart';
import '../../services/meal_log_service.dart';
import '../../services/supabase_service.dart';
import '../../styles/styles.dart';
import 'food_image_recognition_screen.dart';

class NaturalLanguageMealScreen extends StatefulWidget {
  const NaturalLanguageMealScreen({super.key});

  @override
  State<NaturalLanguageMealScreen> createState() =>
      _NaturalLanguageMealScreenState();
}

class _NaturalLanguageMealScreenState extends State<NaturalLanguageMealScreen> {
  final _mealInputController = TextEditingController();
  final _nlpService = NaturalLanguageMealService();
  final _mealLogService = MealLogService();
  final _speech = stt.SpeechToText();

  List<Food>? _parsedFoods;
  bool _isLoading = false;
  bool _isListening = false;
  String? _error;
  MealType _selectedMealType = MealType.breakfast;
  bool _hasMicPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final status = await Permission.microphone.status;
      setState(() => _hasMicPermission = status.isGranted);
      if (status.isGranted) {
        await _initializeSpeech();
      }
    } catch (e) {
      setState(() => _error = 'Error checking permissions: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.microphone.request();
      setState(() => _hasMicPermission = status.isGranted);
      if (status.isGranted) {
        await _initializeSpeech();
      } else {
        setState(() => _error = 'Microphone permission denied');
      }
    } catch (e) {
      setState(() => _error = 'Error requesting permissions: $e');
    }
  }

  Future<void> _initializeSpeech() async {
    if (!_hasMicPermission) {
      if (mounted) {
        setState(() => _error = 'Microphone permission not granted');
      }
      return;
    }

    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (mounted && (status == 'done' || status == 'notListening')) {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _error = 'Error with speech recognition: $error';
            });
          }
        },
      );
      if (!available && mounted) {
        setState(
            () => _error = 'Speech recognition not available on this device');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to initialize speech recognition: $e');
      }
    }
  }

  Future<void> _startListening() async {
    if (!_hasMicPermission) {
      await _requestPermissions();
      return;
    }

    try {
      if (!_isListening) {
        HapticFeedback.mediumImpact();
        bool started = await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _mealInputController.text = result.recognizedWords;
              });
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
        if (mounted) {
          setState(() => _isListening = started);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _error = 'Failed to start listening: $e';
        });
      }
    }
  }

  void _stopListening() {
    HapticFeedback.mediumImpact();
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _mealInputController.dispose();
    _speech.cancel(); // Cancel any ongoing speech recognition
    _speech.stop(); // Stop listening
    super.dispose();
  }

  Future<void> _parseMealInput() async {
    if (_mealInputController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter what you ate');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _parsedFoods = null;
    });

    try {
      debugPrint('Parsing meal input: ${_mealInputController.text}');
      final foods = await _nlpService
          .parseNaturalLanguageInput(_mealInputController.text);
      debugPrint(
          'Parsed ${foods.length} foods: ${foods.map((f) => f.name).join(', ')}');
      setState(() {
        _parsedFoods = foods;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error parsing meal input: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMealLog() async {
    if (_parsedFoods == null || _parsedFoods!.isEmpty) {
      setState(() => _error = 'No foods to log');
      return;
    }

    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _error = 'You must be logged in to save meals');
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint(
          'Creating meal log with ${_parsedFoods!.length} foods for user $userId');
      final mealLog = MealLog(
        userId: userId,
        foods: _parsedFoods!,
        mealType: _selectedMealType,
        loggedAt: DateTime.now(),
      );

      debugPrint('Meal log created: ${mealLog.toJson()}');
      await _mealLogService.logMeal(mealLog);
      debugPrint('Meal log saved successfully');

      // Learn from this meal log for future suggestions
      await _nlpService.learnFromMealLog(mealLog);
      debugPrint('Learned from meal log');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal logged successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Error saving meal log: $e');
      setState(() {
        _error = 'Failed to log meal: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Meal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What did you eat?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Type or speak naturally, like "2 eggs with toast and a cup of coffee"',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mealInputController,
                    decoration: InputDecoration(
                      hintText: 'Enter what you ate...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _mealInputController.clear(),
                      ),
                      enabledBorder: _isListening
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            )
                          : null,
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _parseMealInput(),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'voice_input_button',
                      onPressed:
                          _isListening ? _stopListening : _startListening,
                      tooltip:
                          _isListening ? 'Stop listening' : 'Start listening',
                      backgroundColor:
                          _isListening ? Theme.of(context).primaryColor : null,
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'camera_button',
                      onPressed: () async {
                        final foods = await Navigator.push<List<Food>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const FoodImageRecognitionScreen(),
                          ),
                        );
                        if (foods != null && mounted) {
                          setState(() => _parsedFoods = foods);
                        }
                      },
                      tooltip: 'Take food photo',
                      child: const Icon(Icons.camera_alt),
                    ),
                  ],
                ),
              ],
            ),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Listening...',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MealType>(
              value: _selectedMealType,
              decoration: InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: MealType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMealType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _parseMealInput,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Analyze Meal'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            if (_parsedFoods != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Analyzed Foods:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _parsedFoods!.length,
                  itemBuilder: (context, index) {
                    final food = _parsedFoods![index];
                    return Card(
                      child: ListTile(
                        title: Text(food.name),
                        subtitle: Text(
                          '${food.calories.round()} cal • '
                          '${food.protein.round()}g protein • '
                          '${food.carbs.round()}g carbs • '
                          '${food.fat.round()}g fat',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMealLog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save Meal Log'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
