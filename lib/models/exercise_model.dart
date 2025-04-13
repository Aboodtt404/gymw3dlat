import 'package:flutter/foundation.dart';

@immutable
class Exercise {
  final String id;
  final String name;
  final String bodyPart;
  final String equipment;
  final String gifUrl;
  final String target;
  final List<String> instructions;

  const Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.gifUrl,
    required this.target,
    required this.instructions,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      bodyPart: json['bodyPart'] as String,
      equipment: json['equipment'] as String,
      gifUrl: json['gifUrl'] as String,
      target: json['target'] as String,
      instructions: (json['instructions'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bodyPart': bodyPart,
      'equipment': equipment,
      'gifUrl': gifUrl,
      'target': target,
      'instructions': instructions,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          bodyPart == other.bodyPart &&
          equipment == other.equipment &&
          gifUrl == other.gifUrl &&
          target == other.target;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      bodyPart.hashCode ^
      equipment.hashCode ^
      gifUrl.hashCode ^
      target.hashCode;
}
