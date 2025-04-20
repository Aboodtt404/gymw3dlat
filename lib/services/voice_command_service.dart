import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';

class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );
    }
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function() onComplete,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Failed to initialize speech recognition');
      }
    }

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords.toLowerCase();
          onResult(text);
          onComplete();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: false,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;

  // Parse voice command for sets
  Map<String, dynamic>? parseSetCommand(String command) {
    // Common patterns:
    // "log set 12 reps at 100 pounds"
    // "record 10 reps with 45 kilos"
    // "add set 8 reps 60 kg"

    final RegExp repsPattern = RegExp(r'(\d+)\s*reps?');
    final RegExp weightPattern = RegExp(r'(\d+)\s*(pounds?|lbs?|kilos?|kg)');

    final repsMatch = repsPattern.firstMatch(command);
    final weightMatch = weightPattern.firstMatch(command);

    if (repsMatch == null) return null;

    final reps = int.parse(repsMatch.group(1)!);
    double? weight;
    String? unit;

    if (weightMatch != null) {
      weight = double.parse(weightMatch.group(1)!);
      unit = weightMatch.group(2);

      // Standardize unit to kg if pounds/lbs
      if (unit!.startsWith('p') || unit.startsWith('l')) {
        weight = weight * 0.453592; // Convert pounds to kg
        unit = 'kg';
      } else {
        unit = 'kg';
      }
    }

    return {
      'reps': reps,
      'weight': weight,
      'unit': unit,
    };
  }

  // Parse voice command for exercises
  Map<String, dynamic>? parseExerciseCommand(String command) {
    // Common patterns:
    // "start bench press"
    // "begin squats"
    // "switch to deadlift"

    final RegExp startPattern = RegExp(r'(start|begin|switch to)\s+(.+)');
    final match = startPattern.firstMatch(command);

    if (match == null) return null;

    return {
      'action': match.group(1),
      'exercise': match.group(2),
    };
  }
}
