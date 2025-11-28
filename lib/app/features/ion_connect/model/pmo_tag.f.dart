// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'pmo_tag.f.freezed.dart';

/// Represents a PMO (Positional Markdown Override) tag.
@freezed
class PmoTag with _$PmoTag {
  const factory PmoTag({
    required int start,
    required int end,
    required String replacement,
  }) = _PmoTag;

  const PmoTag._();

  factory PmoTag.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length < 3) {
      throw IncorrectEventTagException(tag: tag.toString());
    }
    final indices = tag[1].split(':');
    if (indices.length != 2) {
      throw IncorrectEventTagException(tag: tag.toString());
    }
    final start = int.tryParse(indices[0]);
    final end = int.tryParse(indices[1]);
    if (start == null || end == null) {
      throw IncorrectEventTagException(tag: tag.toString());
    }
    if (start > end) {
      throw IncorrectEventTagException(tag: tag.toString());
    }
    return PmoTag(start: start, end: end, replacement: tag[2]);
  }

  List<String> toTag() {
    return [tagName, '$start:$end', replacement];
  }

  static const String tagName = 'pmo';
}
