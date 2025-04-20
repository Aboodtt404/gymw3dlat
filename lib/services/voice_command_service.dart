import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';

class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('Speech recognition error: $error'),
      onStatus: (status) => debugPrint('Speech recognition status: $status'),
    );
    return _isInitialized;
  }

  Future<String?> startListening({
    Duration timeout = const Duration(seconds: 30),
    String? prompt,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    if (_speech.isListening) return null;

    final completer = Completer<String?>();

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          completer.complete(result.recognizedWords);
        }
      },
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
      partialResults: false,
      listenFor: timeout,
    );

    // Add timeout
    Timer(timeout, () {
      if (!completer.isCompleted) {
        _speech.stop();
        completer.complete(null);
      }
    });

    return completer.future;
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;

  // Parse voice command for sets
  Map<String, dynamic>? parseSetCommand(String command) {
    // Common patterns:
    // "10 reps at 100 pounds"
    // "10 reps 100 pounds"
    // "10 at 100"
    // "10 reps"
    // "100 pounds 10 times"

    final RegExp repsPattern = RegExp(r'(\d+)(?:\s*reps?|\s*times?)?');
    final RegExp weightPattern =
        RegExp(r'(\d+)(?:\s*(?:pounds?|lbs?|kilos?|kgs?))');

    final repsMatch = repsPattern.firstMatch(command.toLowerCase());
    final weightMatch = weightPattern.firstMatch(command.toLowerCase());

    if (repsMatch == null) return null;

    return {
      'reps': int.parse(repsMatch.group(1)!),
      'weight':
          weightMatch != null ? double.parse(weightMatch.group(1)!) : null,
    };
  }

  // Parse voice command for exercises
  Map<String, dynamic>? parseExerciseCommand(String command) {
    // Common patterns:
    // "add bench press"
    // "start bench press"
    // "begin bench press"
    // "new exercise bench press"

    final RegExp startPattern = RegExp(
      r'^(?:add|start|begin|new exercise)\s+(.+)$',
      caseSensitive: false,
    );

    final match = startPattern.firstMatch(command.toLowerCase());
    if (match == null) return null;

    return {
      'exerciseName': match.group(1)?.trim(),
    };
  }
}
