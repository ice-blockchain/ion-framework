// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'label_tag.f.freezed.dart';

@freezed
class LabelTag with _$LabelTag {
  const factory LabelTag({required String value}) = _LabelTag;

  const LabelTag._();

  factory LabelTag.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length != 2) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return LabelTag(value: tag[1]);
  }

  static const String tagName = 'l';

  List<String> toTag() => [tagName, value];
}
