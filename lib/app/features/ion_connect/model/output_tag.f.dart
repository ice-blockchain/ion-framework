// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';

part 'output_tag.f.freezed.dart';

@freezed
class OutputTag with _$OutputTag {
  const factory OutputTag({required MimeType value}) = _OutputTag;

  const OutputTag._();

  factory OutputTag.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length != 2) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return OutputTag(value: MimeType.values.byName(tag[1]));
  }

  List<String> toTag() => [tagName, value.name];

  static const String tagName = 'output';
}
