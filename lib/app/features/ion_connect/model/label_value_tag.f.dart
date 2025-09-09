// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'label_value_tag.f.freezed.dart';

@freezed
class LabelValueTag with _$LabelValueTag {
  const factory LabelValueTag({
    required String value,
    required String namespace,
  }) = _LabelValueTag;

  const LabelValueTag._();

  factory LabelValueTag.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length != 3) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return LabelValueTag(value: tag[1], namespace: tag[2]);
  }

  static List<LabelValueTag>? fromTags(
    Map<String, List<List<String>>> tags, {
    required String namespace,
  }) {
    final namespaceTags = tags[tagName]?.where((tag) => tag.lastOrNull == namespace);
    return namespaceTags?.map(LabelValueTag.fromTag).toList();
  }

  static const String tagName = 'l';

  List<String> toTag() => [tagName, value, namespace];
}
