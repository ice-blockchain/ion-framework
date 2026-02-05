// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/text/inline_badge_text.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/holder_avatar.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/models/holder_tile_data.dart';
import 'package:ion/app/router/utils/profile_navigation_utils.dart';
import 'package:ion/app/services/browser/browser.dart';
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
      data: HolderTileData(
        rank: holder.position.rank,
        amountText: formatAmountCompactFromRaw(holder.position.amount),
        basicInfo: HolderBasicInfo(
          displayName: context.i18n.tokenized_community_bonding_curve,
        ),
        supplyShare: holder.position.supplyShare,
        avatarUrl: holder.position.holder?.avatar,
        badgeType: RankBadgeType.bondingCurve,
      ),
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
    final badgeType =
        holder.position.rank == 0 ? RankBadgeType.bondingCurve : RankBadgeType.regular;

    return HolderTile(
      data: HolderTileData(
        rank: holder.position.rank,
        amountText: formatAmountCompactFromRaw(holder.position.amount),
        basicInfo: HolderBasicInfo(
          displayName: holder.position.holder?.display ?? context.i18n.tokenized_community_burned,
          address: holderAddress,
        ),
        supplyShare: holder.position.supplyShare,
        avatarUrl: holder.position.holder?.avatar,
        badgeType: badgeType,
      ),
    );
  }
}

class HolderTile extends StatelessWidget {
  const HolderTile({
    required this.data,
    super.key,
  });

  final HolderTileData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    return GestureDetector(
      onTap: data.badge.isXUser
          ? () => openUrlInAppBrowser('https://x.com/${data.basicInfo.username}')
          : data.holderAddress != null
              ? () => ProfileNavigationUtils.navigateToProfile(
                    context,
                    pubkey: data.holderAddress,
                  )
              : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                _RankBadge(rank: data.rank, type: data.badgeType),
                SizedBox(width: 12.0.s),
                HolderAvatar(
                  imageUrl: data.avatarUrl,
                  seed: data.basicInfo.displayName,
                  isXUser: data.badge.isXUser,
                  isIonConnectUser: data.isIonConnectUser,
                ),
                SizedBox(width: 8.0.s),
                Expanded(
                  child: _NameAndAmount(
                    holderInfo: data.basicInfo,
                    badgeInfo: data.badge,
                    amountText: data.amountText,
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
              '${formatSupplySharePercent(data.supplyShare)}%',
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
    required this.holderInfo,
    required this.badgeInfo,
    required this.amountText,
  });

  final HolderBasicInfo holderInfo;
  final HolderBadge badgeInfo;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        InlineBadgeText(
          titleSpan: TextSpan(text: holderInfo.displayName),
          badges: [
            if (badgeInfo.verified) Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
            if (badgeInfo.isCreator) Assets.svg.iconBadgeCreator.icon(size: 16.0.s),
            if (badgeInfo.isXUser) Assets.svg.iconBadgeXlogo.icon(size: 16.0.s),
          ],
          trailingGap: 8.0.s,
          style: texts.subtitle3.copyWith(
            color: colors.primaryText,
          ),
        ),
        Text(
          holderInfo.username != null ? '@${holderInfo.username} • $amountText' : amountText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: texts.caption.copyWith(color: colors.quaternaryText),
        ),
      ],
    );
  }
}
