// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/views/pages/holders/models/holder_tile_data.dart';
import 'package:ion/app/utils/address.dart';
import 'package:ion/app/utils/crypto.dart';
import 'package:ion/app/utils/formatters.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

extension TopHolderListSorting on List<TopHolder> {
  List<TopHolder> sortedByPriority({required String bondingCurveAddress}) {
    final indexedHolders = asMap().entries.toList()
      ..sort((a, b) {
        final left = a.value;
        final right = b.value;

        int priority(TopHolder h) {
          if (h.isBoundingCurve(bondingCurveAddress)) return 0;
          if (h.isBurning) return 1;
          return 2;
        }

        final byPriority = priority(left).compareTo(priority(right));
        if (byPriority != 0) return byPriority;

        final byRank = left.position.rank.compareTo(right.position.rank);
        if (byRank != 0) return byRank;

        return a.key.compareTo(b.key);
      });
    return indexedHolders.map((entry) => entry.value).toList(growable: false);
  }
}

extension TopHolderMapping on TopHolder {
  HolderTileData get tileData {
    final ionConnect = position.holder?.addresses?.ionConnect;
    final isContentToken = ionConnect != null && (ionConnect.split(':').length >= 3);
    return HolderTileData(
      rank: position.rank,
      amountText: formatTokenAmountWithSubscript(
        fromBlockchainUnits(position.amount),
      ),
      basicInfo: HolderBasicInfo(
        displayName: position.holder?.display ??
            shortenAddress(
              position.holder?.addresses?.blockchain ?? '',
            ),
        username: position.holder?.name == null ? null : '@${position.holder?.name}',
      ),
      badge: HolderBadge(
        verified: position.holder?.verified ?? false,
        isCreator: position.holder.isCreator(creator),
        isXUser: position.holder?.isXUser ?? false,
      ),
      supplyShare: position.supplyShare,
      avatarUrl: position.holder?.avatar,
      holderAddress: isContentToken ? null : ionConnect,
      tokenExternalAddress: isContentToken ? ionConnect : null,
      isIonConnectUser: ionConnect != null,
    );
  }
}
