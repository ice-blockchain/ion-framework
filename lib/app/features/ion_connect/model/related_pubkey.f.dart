// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'related_pubkey.f.freezed.dart';

@Freezed(copyWith: false)
class RelatedPubkey with _$RelatedPubkey {
  const factory RelatedPubkey({
    required String value,
  }) = _RelatedPubkey;

  const RelatedPubkey._();

  /// https://github.com/nostr-protocol/nips/blob/master/10.md#the-p-tag
  factory RelatedPubkey.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length < 2) {
      throw IncorrectEventTagException(tag: tag.toString());
    }
    return RelatedPubkey(value: tag[1]);
  }

  List<String> toTag() {
    return [tagName, value];
  }

  static const String tagName = 'p';
}
