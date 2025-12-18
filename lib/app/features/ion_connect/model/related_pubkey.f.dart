// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'related_pubkey.f.freezed.dart';

@freezed
class RelatedPubkey with _$RelatedPubkey {
  const factory RelatedPubkey({
    required String value,
    @Default(false) bool showMarketCap,
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

    // TODO: Check how complatible with protocol
    // TODO: Check if we need to implement this in Swift model
    // Parse optional 4th element for showMarketCap flag (position 3 reserved for relay)
    final showMarketCap = tag.length > 3 && tag[3] == 'showMarketCap';

    return RelatedPubkey(
      value: tag[1],
      showMarketCap: showMarketCap,
    );
  }

  List<String> toTag() {
    // Follow project pattern: [type, value, relay, custom_data...]
    // Position 3 (relay) kept empty, position 4 for custom data
    return showMarketCap ? [tagName, value, '', 'showMarketCap'] : [tagName, value];
  }

  static const String tagName = 'p';
}
