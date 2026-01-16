// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/holder_avatar.dart';
import 'package:ion/app/router/utils/profile_navigation_utils.dart';
import 'package:ion/app/services/browser/browser.dart';
import 'package:ion/app/utils/address.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

enum RankBadgeType {
  regular,
  burning,
  bondingCurve,
}

class BondingCurveHolderTile extends StatelessWidget {
  const BondingCurveHolderTile({
    required this.holder,
    super.key,
  });

  final TopHolder holder;

  @override
  Widget build(BuildContext context) {
    return HolderTile(
      rank: holder.position.rank,
      amountText: formatAmountCompactFromRaw(holder.position.amount),
      displayName: context.i18n.tokenized_community_bonding_curve,
      supplyShare: holder.position.supplyShare,
      avatarUrl: holder.position.holder?.avatar,
      badgeType: RankBadgeType.bondingCurve,
    );
  }
}

class BurningHolderTile extends StatelessWidget {
  const BurningHolderTile({
    required this.holder,
    super.key,
  });

  final TopHolder holder;

  @override
  Widget build(BuildContext context) {
    final holderAddress = holder.position.holder?.addresses?.ionConnect ?? '';

    return HolderTile(
      rank: holder.position.rank,
      amountText: formatAmountCompactFromRaw(holder.position.amount),
      displayName: holder.position.holder?.display ?? context.i18n.tokenized_community_burned,
      supplyShare: holder.position.supplyShare,
      avatarUrl: holder.position.holder?.avatar,
      badgeType: RankBadgeType.burning,
      address: holderAddress,
    );
  }
}

class TopHolderTile extends StatelessWidget {
  const TopHolderTile({
    required this.holder,
    super.key,
  });

  final TopHolder holder;

  @override
  Widget build(BuildContext context) {
    final isXUser = holder.position.holder?.isXUser ?? false;
    final holderAddress = holder.position.holder?.addresses?.ionConnect;
    final creatorAddress = holder.creator.addresses?.ionConnect;
    final isCreator = creatorAddress != null && holderAddress == creatorAddress;

    return HolderTile(
      rank: holder.position.rank,
      amountText: formatAmountCompactFromRaw(holder.position.amount),
      displayName: holder.position.holder?.display ??
          shortenAddress(
            holder.position.holder?.addresses?.ionConnect ??
                holder.position.holder?.addresses?.twitter ??
                '',
          ),
      username: '@${holder.position.holder?.name}',
      supplyShare: holder.position.supplyShare,
      verified: holder.position.holder?.verified ?? false,
      isCreator: isCreator,
      avatarUrl: holder.position.holder?.avatar,
      holderAddress: holderAddress,
      isXUser: isXUser,
    );
  }
}

class HolderTile extends StatelessWidget {
  const HolderTile({
    required this.rank,
    required this.amountText,
    required this.displayName,
    required this.supplyShare,
    this.verified = false,
    this.isCreator = false,
    this.username,
    this.avatarUrl,
    this.holderAddress,
    this.isXUser = false,
    this.badgeType = RankBadgeType.regular,
    this.address,
    super.key,
  });

  final int rank;
  final String amountText;
  final String displayName;
  final double supplyShare;
  final bool isCreator;
  final bool verified;
  final String? username;
  final String? avatarUrl;
  final String? holderAddress;
  final bool isXUser;
  final RankBadgeType badgeType;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    return GestureDetector(
      onTap: isXUser
          ? () => openUrlInAppBrowser('https://x.com/$username')
          : holderAddress != null
              ? () => ProfileNavigationUtils.navigateToProfile(
                    context,
                    externalAddress: holderAddress,
                  )
              : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                _RankBadge(rank: rank, type: badgeType),
                SizedBox(width: 12.0.s),
                HolderAvatar(
                  imageUrl: avatarUrl,
                  seed: displayName,
                  isXUser: isXUser,
                ),
                SizedBox(width: 8.0.s),
                Expanded(
                  child: _NameAndAmount(
                    name: displayName,
                    handle: username,
                    address: address,
                    isCreator: isCreator,
                    verified: verified,
                    amountText: amountText,
                    isXUser: isXUser,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 2.0.s),
            decoration: BoxDecoration(
              color: colors.primaryBackground,
              borderRadius: BorderRadius.circular(12.0.s),
            ),
            child: Text(
              '${formatSupplySharePercent(supplyShare)}%',
              style: texts.caption2
                  .copyWith(color: colors.primaryText, height: 18 / texts.caption2.fontSize!),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.rank,
    required this.type,
  });

  final int rank;
  final RankBadgeType type;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    final child = switch (type) {
      RankBadgeType.burning => Assets.svg.iconTokenFire.icon(),
      RankBadgeType.bondingCurve => Assets.svg.iconMemeBondingcurve.icon(),
      RankBadgeType.regular => rank <= 3
          ? _MedalIcon(rank: rank)
          : Text(
              '$rank',
              style: context.theme.appTextThemes.body.copyWith(color: colors.primaryAccent),
            ),
    };

    return Container(
      width: 30.0.s,
      height: 30.0.s,
      decoration: BoxDecoration(
        color: colors.primaryBackground,
        borderRadius: BorderRadius.circular(10.0.s),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _MedalIcon extends StatelessWidget {
  const _MedalIcon({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return switch (rank) {
      1 => Assets.svg.iconMeme1stplace,
      2 => Assets.svg.iconMeme2ndtplace,
      3 => Assets.svg.iconMeme3rdplace,
      _ => throw UnimplementedError(),
    }
        .icon();
  }
}

class _NameAndAmount extends StatelessWidget {
  const _NameAndAmount({
    required this.name,
    required this.amountText,
    required this.verified,
    required this.isCreator,
    this.handle,
    this.address,
    this.isXUser = true,
  });

  final String name;
  final String? handle;
  final String? address;
  final String amountText;
  final bool verified;
  final bool isCreator;
  final bool isXUser;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: texts.subtitle3.copyWith(
                  color: colors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (verified) ...[
              SizedBox(width: 4.0.s),
              Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
            ],
            if (isCreator) ...[
              SizedBox(width: 4.0.s),
              Assets.svg.iconBadgeCreator.icon(size: 16.0.s),
            ],
            if (isXUser) ...[
              SizedBox(width: 4.0.s),
              Assets.svg.iconBadgeXlogo.icon(size: 16.0.s),
            ],
            SizedBox(width: 8.0.s),
          ],
        ),
        Text(
          address != null
              ? shortenAddress(address!)
              : handle != null
                  ? '$handle • $amountText'
                  : amountText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: texts.caption.copyWith(color: colors.quaternaryText),
        ),
      ],
    );
  }
}
