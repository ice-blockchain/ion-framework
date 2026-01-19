// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'coin.f.freezed.dart';
part 'coin.f.g.dart';

@freezed
class Coin with _$Coin {
  factory Coin({
    required String contractAddress,
    required int decimals,
    required String iconURL,
    required String id,
    required String name,
    required String network,
    required double priceUSD,
    required String symbol,
    required String symbolGroup,
    @SyncFrequencyConverter() required Duration syncFrequency,
    @Default(false) bool? native,
    @Default(false) bool? prioritized,
    String? tokenizedCommunityExternalAddress,
    String? tokenizedCommunityTokenType,
  }) = _Coin;

  factory Coin.fromJson(Map<String, dynamic> json) => _$CoinFromJson(json);
}

class SyncFrequencyConverter implements JsonConverter<Duration, int> {
  const SyncFrequencyConverter();

  @override
  Duration fromJson(int nanos) => Duration(microseconds: nanos ~/ 1000);

  @override
  int toJson(Duration object) => object.inMicroseconds * 1000;
}
