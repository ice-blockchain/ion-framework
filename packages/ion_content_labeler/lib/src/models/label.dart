// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class Label {
  const Label({
    required this.name,
    required this.score,
  });

  factory Label.fromMap(Map<String, dynamic> map) {
    return Label(
      name: map['name'] as String,
      score: map['score'] as double,
    );
  }

  factory Label.fromJson(String source) =>
      Label.fromMap(json.decode(source) as Map<String, dynamic>);

  final String name;
  final double score;

  Label copyWith({
    String? name,
    double? score,
  }) {
    return Label(
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'score': score,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => 'Label(name: $name, score: $score)';

  @override
  bool operator ==(covariant Label other) {
    if (identical(this, other)) return true;

    return other.name == name && other.score == score;
  }

  @override
  int get hashCode => name.hashCode ^ score.hashCode;
}
