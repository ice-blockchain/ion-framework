// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'delegation_pubkey_tag.f.freezed.dart';

@freezed
class DelegationPubkeyTag with _$DelegationPubkeyTag {
  const factory DelegationPubkeyTag({
    required String? value,
  }) = _DelegationPubkeyTag;

  const DelegationPubkeyTag._();

  factory DelegationPubkeyTag.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }

    if (tag.length != 4) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return DelegationPubkeyTag(value: tag[1]);
  }

  static const String tagName = 'p';

  List<String> toTag() {
    if (value == null) {
      throw IncorrectEventTagValueException(tag: tagName, value: value);
    }
    return [tagName, value!];
  }
}
