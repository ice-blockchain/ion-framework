import 'package:ion/app/features/tokenized_communities/views/pages/holders/models/holder_tile_data.dart';
import 'package:ion/app/utils/address.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

extension TopHolderMapping on TopHolder {
  bool get isCreator {
    final holderIonConnectAddress = position.holder?.addresses?.ionConnect;
    final creatorIonConnectAddress = creator.addresses?.ionConnect;
    final holderTwitterAddress = position.holder?.addresses?.twitter;
    final creatorTwitterAddress = creator.addresses?.twitter;

    return (creatorIonConnectAddress != null &&
            holderIonConnectAddress == creatorIonConnectAddress) ||
        (creatorTwitterAddress != null && holderTwitterAddress == creatorTwitterAddress);
  }

  HolderTileData get tileData => HolderTileData(
        rank: position.rank,
        amountText: formatAmountCompactFromRaw(position.amount),
        basicInfo: HolderBasicInfo(
          displayName: position.holder?.display ??
              shortenAddress(
                position.holder?.addresses?.blockchain ?? '',
              ),
          username: position.holder?.name == null ? null : '@${position.holder?.name}',
        ),
        badge: HolderBadge(
          verified: position.holder?.verified ?? false,
          isCreator: isCreator,
          isXUser: position.holder?.isXUser ?? false,
        ),
        supplyShare: position.supplyShare,
        avatarUrl: position.holder?.avatar,
        holderAddress: position.holder?.addresses?.ionConnect,
        isIonConnectUser: position.holder?.addresses?.ionConnect != null,
      );
}
