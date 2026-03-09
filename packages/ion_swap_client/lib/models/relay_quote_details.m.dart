// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'relay_quote_details.m.freezed.dart';
part 'relay_quote_details.m.g.dart';

@freezed
class RelayQuoteDetails with _$RelayQuoteDetails {
  factory RelayQuoteDetails({
    required String rate,
    RelaySwapImpact? swapImpact,
  }) = _RelayQuoteDetails;

  factory RelayQuoteDetails.fromJson(Map<String, dynamic> json) =>
      _$RelayQuoteDetailsFromJson(json);
}

@freezed
class RelaySwapImpact with _$RelaySwapImpact {
  factory RelaySwapImpact({
    String? percent,
  }) = _RelaySwapImpact;

  factory RelaySwapImpact.fromJson(Map<String, dynamic> json) =>
      _$RelaySwapImpactFromJson(json);
}
