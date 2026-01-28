// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';
import 'package:ion/app/features/tokenized_communities/utils/prefix_x_token_ticker.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chart_title_provider.r.g.dart';

// For profile tokens: Returns "@nickname (ticker)" where:
//   - nickname comes from the profile this token represents (resolved from externalAddress)
//   - ticker is lowercase
// For content tokens: Returns ticker with $ prefix
@riverpod
Future<String?> chartTitle(
  Ref ref, {
  required String externalAddress,
  required bool isRTL,
}) async {
  final tokenInfo = await ref.watch(tokenMarketInfoProvider(externalAddress).future);
  if (tokenInfo == null) {
    return null;
  }

  final ticker = tokenInfo.marketData.ticker ?? '';

  if (tokenInfo.source.isTwitter) {
    return prefixXTokenTicker(ticker);
  }

  if (tokenInfo.type == CommunityTokenType.profile) {
    final profileExternalAddress = tokenInfo.addresses.ionConnect;
    if (profileExternalAddress == null) {
      return null;
    }

    final profilePubkey = MasterPubkeyResolver.resolve(profileExternalAddress);

    try {
      final userData = await ref.watch(userPreviewDataProvider(profilePubkey).future);
      final profileNickname = userData?.data.name;

      if (profileNickname == null || profileNickname.isEmpty) {
        return null;
      }

      final tickerLower = ticker.toLowerCase();
      final usernameLower = profileNickname.toLowerCase();
      final usernamePart = isRTL ? '$usernameLower@' : '@$usernameLower';

      return tickerLower.isNotEmpty
          ? (isRTL ? '($tickerLower) $usernamePart' : '$usernamePart ($tickerLower)')
          : usernamePart;
    } catch (e, st) {
      Logger.error(
        e,
        stackTrace: st,
        message: 'Error normalizing chart title - Exception: ${e.runtimeType}, Message: $e',
      );
      return null;
    }
  }

  // Content token with $ prefix
  return '\$$ticker';
}
