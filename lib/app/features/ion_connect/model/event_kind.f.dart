// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'event_kind.f.freezed.dart';

@freezed
class EventKind with _$EventKind {
  const factory EventKind({required int value}) = _EventKind;

  const EventKind._();

  factory EventKind.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length != 2) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    final value = int.tryParse(tag[1]);

    if (value == null) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return EventKind(value: value);
  }

  static const String tagName = 'k';

  List<String> toTag() => [tagName, value.toString()];
}
