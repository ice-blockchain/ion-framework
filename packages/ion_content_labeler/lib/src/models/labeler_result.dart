// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:ion_content_labeler/ion_content_labeler.dart';

abstract class LabelerResult {
  List<Label> get labels;
}

@immutable
class TextLabelerResult implements LabelerResult {
  const TextLabelerResult({
    required this.labels,
    required this.input,
  });

  @override
  final List<Label> labels;

  final String input;

  @override
  bool operator ==(covariant TextLabelerResult other) {
    if (identical(this, other)) return true;

    return listEquals(other.labels, labels) && other.input == input;
  }

  @override
  int get hashCode => labels.hashCode ^ input.hashCode;

  @override
  String toString() => 'TextLabelerResult(labels: $labels, input: $input)';

  TextLabelerResult copyWith({
    List<Label>? labels,
    String? input,
  }) {
    return TextLabelerResult(
      labels: labels ?? this.labels,
      input: input ?? this.input,
    );
  }
}
