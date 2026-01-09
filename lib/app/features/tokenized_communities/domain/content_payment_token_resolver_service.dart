// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/tokenized_communities/utils/creator_token_utils.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

enum ContentPaymentTokenSource {
  creatorToken,
  supportedTokenFallback,
}

final class ContentPaymentTokenContext {
  const ContentPaymentTokenContext({
    required this.token,
    required this.coinsGroup,
    required this.source,
  });

  final CoinData token;
  final CoinsGroup coinsGroup;
  final ContentPaymentTokenSource source;
}

class ContentPaymentTokenResolverService {
  const ContentPaymentTokenResolverService();

  Future<ContentPaymentTokenContext?> resolve({
    required CommunityToken? creatorTokenInfo,
    required String creatorTokenExternalAddress,
    required NetworkData bscNetwork,
    required List<CoinData> supportedSwapTokens,
  }) async {
    final creatorTokenAddress = creatorTokenInfo?.addresses.blockchain?.trim() ?? '';
    if (creatorTokenInfo != null && creatorTokenAddress.isNotEmpty) {
      final group = await CreatorTokenUtils.deriveCreatorTokenCoinsGroup(
        token: creatorTokenInfo,
        externalAddress: creatorTokenExternalAddress,
        network: bscNetwork,
      );
      final token = group?.coins.firstOrNull?.coin;
      if (group != null && token != null) {
        return ContentPaymentTokenContext(
          token: token,
          coinsGroup: group,
          source: ContentPaymentTokenSource.creatorToken,
        );
      }
    }

    final fallback = supportedSwapTokens.firstOrNull;
    if (fallback == null) {
      return null;
    }

    return ContentPaymentTokenContext(
      token: fallback,
      coinsGroup: CoinsGroup.fromCoin(fallback),
      source: ContentPaymentTokenSource.supportedTokenFallback,
    );
  }
}
