// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'token_input.f.freezed.dart';

enum TokenInput {
  priceChange,
  trending,
  inspectTokenBuyingActivity,
}

@freezed
class TokenInputTag with _$TokenInputTag {
  const factory TokenInputTag({required TokenInput value}) = _TokenInputTag;

  const TokenInputTag._();

  factory TokenInputTag.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length != 3) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return TokenInputTag(value: TokenInput.values.byName(tag[1]));
  }

  List<String> toTag() => [tagName, value.name, 'text'];

  static const String tagName = 'i';
}
