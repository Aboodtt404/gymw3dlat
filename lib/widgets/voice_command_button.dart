import 'package:flutter/material.dart';

class VoiceCommandButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const VoiceCommandButton({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none,
          key: ValueKey<bool>(isListening),
          color: isListening ? Colors.red : null,
        ),
      ),
      tooltip: isListening ? 'Stop listening' : 'Start voice command',
      onPressed: onPressed,
    );
  }
}
