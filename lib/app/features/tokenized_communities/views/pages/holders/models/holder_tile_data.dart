// SPDX-License-Identifier: ice License 1.0

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

  @override
  String toString() {
    return 'HolderBasicInfo(displayName: $displayName, username: $username, address: $address)';
  }
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

  @override
  String toString() {
    return 'HolderBadge(verified: $verified, isCreator: $isCreator, isXUser: $isXUser)';
  }
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
    this.tokenExternalAddress,
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

  /// When set, this holder is a content token (e.g. pool);
  final String? tokenExternalAddress;
  final RankBadgeType badgeType;
  final bool isIonConnectUser;

  @override
  String toString() {
    return 'HolderTileData(basicInfo: $basicInfo, badge: $badge, rank: $rank, amountText: $amountText, supplyShare: $supplyShare, avatarUrl: $avatarUrl, holderAddress: $holderAddress, tokenExternalAddress: $tokenExternalAddress, badgeType: $badgeType, isIonConnectUser: $isIonConnectUser)';
  }
}
