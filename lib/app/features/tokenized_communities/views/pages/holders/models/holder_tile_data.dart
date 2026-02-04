import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/holder_tile.dart';

class HolderBasicInfo {
  const HolderBasicInfo({
    required this.displayName,
    this.username,
    this.address,
  });

  final String displayName;
  final String? username;
  final String? address;
}

class HolderBadge {
  const HolderBadge({
    this.verified = false,
    this.isCreator = false,
    this.isXUser = false,
  });

  final bool verified;
  final bool isCreator;
  final bool isXUser;
}

class HolderTileData {
  const HolderTileData({
    required this.basicInfo,
    required this.rank,
    required this.amountText,
    required this.supplyShare,
    this.badge = const HolderBadge(),
    this.avatarUrl,
    this.holderAddress,
    this.badgeType = RankBadgeType.regular,
    this.isIonConnectUser = false,
  });
  final HolderBasicInfo basicInfo;
  final HolderBadge badge;
  final int rank;
  final String amountText;
  final double supplyShare;
  final String? avatarUrl;
  final String? holderAddress;
  final RankBadgeType badgeType;
  final bool isIonConnectUser;
}
