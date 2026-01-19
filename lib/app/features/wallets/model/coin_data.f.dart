// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/tokenized_communities/enums/tokenized_community_token_type.f.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart' as db;
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion_identity_client/ion_identity.dart' as ion;

part 'coin_data.f.freezed.dart';

/// Domain data model for using inside the app. Contains information about coin.
@freezed
class CoinData with _$CoinData {
  const factory CoinData({
    required String id,
    required String contractAddress,
    required int decimals,
    required String iconUrl,
    required String name,
    required NetworkData network,
    required double priceUSD,
    required String abbreviation,
    required String symbolGroup,
    required Duration syncFrequency,
    @Default(false) bool native,
    @Default(false) bool prioritized,
    String? tokenizedCommunityExternalAddress,
    TokenizedCommunityTokenType? tokenizedCommunityTokenType,
  }) = _CoinData;

  factory CoinData.fromDB(db.Coin coin, NetworkData network) {
    return CoinData(
      id: coin.id,
      contractAddress: coin.contractAddress,
      decimals: coin.decimals,
      iconUrl: coin.iconURL,
      name: coin.name,
      network: network,
      priceUSD: coin.priceUSD,
      abbreviation: coin.symbol.toUpperCase(),
      symbolGroup: coin.symbolGroup,
      syncFrequency: coin.syncFrequency,
      native: coin.native,
      prioritized: coin.prioritized,
      tokenizedCommunityExternalAddress: coin.tokenizedCommunityExternalAddress,
      tokenizedCommunityTokenType: coin.tokenizedCommunityTokenType != null
          ? TokenizedCommunityTokenType.fromJson(coin.tokenizedCommunityTokenType!)
          : null,
    );
  }

  factory CoinData.fromDTO(ion.Coin coin, NetworkData network) {
    return CoinData(
      id: coin.id,
      contractAddress: coin.contractAddress,
      decimals: coin.decimals,
      iconUrl: coin.iconURL,
      name: coin.name,
      network: network,
      priceUSD: coin.priceUSD,
      abbreviation: coin.symbol.toUpperCase(),
      symbolGroup: coin.symbolGroup,
      syncFrequency: coin.syncFrequency,
      native: coin.native ?? false,
      prioritized: coin.prioritized ?? false,
      tokenizedCommunityExternalAddress: coin.tokenizedCommunityExternalAddress,
      tokenizedCommunityTokenType: coin.tokenizedCommunityTokenType != null
          ? TokenizedCommunityTokenType.fromJson(coin.tokenizedCommunityTokenType!)
          : null,
    );
  }

  const CoinData._();

  db.Coin toDB() => db.Coin(
        id: id,
        contractAddress: contractAddress,
        decimals: decimals,
        iconURL: iconUrl,
        name: name,
        networkId: network.id,
        priceUSD: priceUSD,
        symbol: abbreviation,
        symbolGroup: symbolGroup,
        syncFrequency: syncFrequency,
        native: native,
        prioritized: prioritized,
        tokenizedCommunityExternalAddress: tokenizedCommunityExternalAddress,
        tokenizedCommunityTokenType: tokenizedCommunityTokenType?.toJson(),
      );

  bool get isValid =>
      id.isNotEmpty && decimals > 0 && abbreviation.isNotEmpty && symbolGroup.isNotEmpty;
}
