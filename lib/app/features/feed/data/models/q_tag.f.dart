// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'q_tag.f.freezed.dart';

@freezed
class QTag with _$QTag {
  const factory QTag({
    required String? value,
  }) = _QTag;

  const QTag._();

  /// Accepts tags of the form [tagName, null, null, value]
  factory QTag.fromTag(List<String?> tag) {
    if (tag.isEmpty || tag[0] != tagName) {
      throw IncorrectEventTagNameException(
        actual: tag[0]!,
        expected: tagName,
      );
    }

    if (tag.length != 4) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return QTag(value: tag[3]);
  }

  static const String tagName = 'Q';

  /// Returns a tag of the form [tagName, null, null, value]
  List<dynamic> toTag() {
    if (value == null) {
      throw IncorrectEventTagValueException(tag: tagName, value: value);
    }
    return [tagName, null, null, value];
  }
}
