// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'label_namespace_tag.f.freezed.dart';

@freezed
class LabelNamespaceTag with _$LabelNamespaceTag {
  const factory LabelNamespaceTag({
    required String value,
  }) = _LabelNamespaceTag;

  factory LabelNamespaceTag.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length != 2) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return LabelNamespaceTag(value: tag[1]);
  }

  const LabelNamespaceTag._();

  static const String tagName = 'L';

  List<String> toTag() => [tagName, value];
}
